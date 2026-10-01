class_name LLMClient
extends Node

# 激励结果枚举：英雄被领主喊话后的四种真实反应
enum Outcome {
	RELIEVE = 0, # ① 减压：受到鼓舞，精神压力下降
	BUFF = 1, # ② 增益：战意高涨，获得攻击力增益（由 BattleController 附加 StatusConfig.inspired）
	STRESS = 2, # ③ 加压：动摇恐惧，精神压力上升
	BETRAY = 3, # ④ 倒戈：精神崩溃，当场向队友挥刀
}

# 结果标签（模型输出 / 本地关键词兜底共用）
const OUTCOME_TAGS := {
	"RELIEVE": Outcome.RELIEVE,
	"BUFF": Outcome.BUFF,
	"STRESS": Outcome.STRESS,
	"BETRAY": Outcome.BETRAY,
}

# ============================================================
# API 配置加载
# 优先级（低 → 高），全部为空则自动降级为离线 Mock：
#   ① res://scripts/battle/api_public.gd —— 自建代理（可选；真 Key 只存 Worker 环境变量里，最安全）
#   ② exe 同目录 api_config.json（编辑器内读工程根目录）—— 便携覆盖，免重新打包
#   ③ user://llm_config.json —— 开始界面右上角「LLM 设置」面板写入（玩家自己填的 Key，最高）
#
# ⚠️ 本工程**不内置 / 不发布任何 Key**：
#    Key 由玩家在开始界面右上角「LLM 设置」里自己填写，只写入本机 user://llm_config.json，
#    既不随导出包发布，也不会进 Git 仓库。仓库里出现 sk- 明文应立即吊销该 Key。
# ============================================================
const PUBLIC_CONFIG_PATH := "res://scripts/battle/api_public.gd"
const EXTERNAL_CONFIG_NAME := "api_config.json"
const USER_CONFIG_PATH := "user://llm_config.json"
const DEFAULT_API_URL := "https://api.deepseek.com/v1/chat/completions"
const DEFAULT_MODEL := "deepseek-chat"

var api_key: String = ""
var api_url: String = DEFAULT_API_URL
var model: String = DEFAULT_MODEL
# 当前生效的配置来源（仅用于 UI 展示：开始界面的 LLM 设置面板）
var config_source: String = "离线 Mock 引擎"

func _init() -> void:
	reload()

# 清空后按优先级重新加载（设置面板保存 / 清除后调用）
func reload() -> void:
	api_key = ""
	api_url = DEFAULT_API_URL
	model = DEFAULT_MODEL
	config_source = "离线 Mock 引擎"
	# 从低到高依次应用，后面的来源会覆盖前面的同名非空字段
	_apply_gd_config(PUBLIC_CONFIG_PATH, "内置代理（api_public.gd）")
	_apply_json_file(_external_config_path(), EXTERNAL_CONFIG_NAME)
	_apply_json_file(USER_CONFIG_PATH, "游戏内设置")
	if api_key.strip_edges().is_empty():
		config_source = "离线 Mock 引擎"
	# 玩家报「LLM 不生效」时，看这一行就知道当前吃的是哪一层配置
	print("[LLM] 配置来源=", config_source, " 在线=", has_online_config(), " 模型=", model)

# 读取 .gd 常量配置（文件不存在时静默跳过）
func _apply_gd_config(path: String, source: String = "") -> void:
	if not ResourceLoader.exists(path):
		return
	var cfg: Resource = load(path)
	if cfg == null:
		return
	_assign_config(_variant_str(cfg.get("API_KEY")), _variant_str(cfg.get("API_URL")), _variant_str(cfg.get("MODEL")), source)

# 外置 JSON 配置路径：导出后取 exe 同目录，编辑器内取工程根目录
func _external_config_path() -> String:
	if OS.has_feature("template"):
		return OS.get_executable_path().get_base_dir().path_join(EXTERNAL_CONFIG_NAME)
	return "res://" + EXTERNAL_CONFIG_NAME

func _apply_json_file(path: String, source: String = "") -> void:
	if not FileAccess.file_exists(path):
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("[LLM] " + path + " 不是合法 JSON，已忽略")
		return
	var dict: Dictionary = parsed
	_assign_config(_dict_str(dict, "API_KEY"), _dict_str(dict, "API_URL"), _dict_str(dict, "MODEL"), source)
	print("[LLM] 已加载", source, "：", path)

func _assign_config(key: String, url: String, model_name: String, source: String = "") -> void:
	# 只有真正带来 Key 的那一层才算「当前生效来源」（否则空的 api_public.gd 仅因为写了 MODEL
	# 就会把来源标签抢走，UI 上会误导）
	if not key.strip_edges().is_empty():
		api_key = key
		if not source.is_empty():
			config_source = source
	if not url.strip_edges().is_empty():
		api_url = url
	if not model_name.strip_edges().is_empty():
		model = model_name

# ============================================================
# 在线请求熔断：连续失败（被墙 / Key 被吊销 / 超额 / 超时）后，
# 本次运行内直接走离线 Mock，不再每次白白等 3.5 秒超时。
# static → 跨战斗生效；设置面板「保存并测试」成功会自动恢复。
# ============================================================
const FAIL_STREAK_LIMIT := 2
static var fail_streak: int = 0
static var online_disabled: bool = false

func _note_online_failure(why: String) -> void:
	fail_streak += 1
	if fail_streak >= FAIL_STREAK_LIMIT and not online_disabled:
		online_disabled = true
		config_source = "离线 Mock 引擎（在线不可达）"
		print("[LLM] 连续 ", fail_streak, " 次在线请求失败（", why, "）→ 本次运行内改用离线 Mock")

func _note_online_success() -> void:
	if online_disabled:
		print("[LLM] 在线请求恢复正常")
	fail_streak = 0
	online_disabled = false

func reset_online_failure_state() -> void:
	fail_streak = 0
	online_disabled = false

# ============================================================
# 开始界面「LLM 设置」面板用的接口（玩家填 Key → 点击即用，无需重新下载）
# ============================================================

# 是否已配置在线模型（false = 走离线 Mock 引擎）
func has_online_config() -> bool:
	return not api_key.strip_edges().is_empty()

# 写入 user://llm_config.json 并立即对当前实例生效；返回是否写入成功
func save_user_config(key: String, url: String, model_name: String) -> bool:
	var k := key.strip_edges()
	var u := url.strip_edges()
	var m := model_name.strip_edges()
	var f := FileAccess.open(USER_CONFIG_PATH, FileAccess.WRITE)
	if f == null:
		push_warning("[LLM] 无法写入 " + USER_CONFIG_PATH)
		return false
	f.store_string(JSON.stringify({"API_KEY": k, "API_URL": u, "MODEL": m}, "\t"))
	f.close()
	api_key = k
	api_url = u if not u.is_empty() else DEFAULT_API_URL
	model = m if not m.is_empty() else DEFAULT_MODEL
	config_source = "游戏内设置" if has_online_config() else "离线 Mock 引擎"
	return true

# 删除游戏内设置的文件，回落到内置 / 外置配置（没有则离线 Mock）
func clear_user_config() -> void:
	if FileAccess.file_exists(USER_CONFIG_PATH):
		DirAccess.remove_absolute(USER_CONFIG_PATH)
	reload()

# 连通性自检：填完 Key 先ping 一下，避免进战斗才发现连不上
# 返回 {"ok": bool, "message": String}（message 直接显示在设置面板里）
func test_connection(parent_node: Node) -> Dictionary:
	if not has_online_config():
		return {"ok": false, "message": "未填写 API Key（当前为离线 Mock 模式）"}
	if parent_node == null or parent_node.get_tree() == null:
		return {"ok": false, "message": "内部错误：缺少场景树"}

	var http := HTTPRequest.new()
	parent_node.add_child(http)
	http.set_use_threads(true)
	var headers: PackedStringArray = [
		"Content-Type: application/json",
		"Authorization: Bearer " + api_key,
	]
	var payload := {
		"model": model,
		"messages": [ {"role": "user", "content": "ping"}],
		"max_tokens": 4,
	}
	var err: int = http.request(api_url, headers, HTTPClient.METHOD_POST, JSON.stringify(payload))
	if err != OK:
		http.queue_free()
		_note_online_failure("发送失败 %d" % err)
		return {"ok": false, "message": "请求发送失败（错误码 %d），请检查 API 地址格式" % err}

	var state := {"done": false, "data": []}
	http.request_completed.connect(func(res: int, code: int, _h: PackedStringArray, body: PackedByteArray):
		if not state["done"]:
			state["done"] = true
			state["data"] = [res, code, body])

	var timer := parent_node.get_tree().create_timer(8.0)
	while not state["done"]:
		if not is_instance_valid(http):
			break
		await parent_node.get_tree().process_frame
		if timer.time_left <= 0.0:
			state["done"] = true
			if is_instance_valid(http):
				http.cancel_request()
				http.queue_free()
			_note_online_failure("8s 超时")
			return {"ok": false, "message": "连接超时（8 秒）：请检查网络，或换一个 API 地址"}

	if is_instance_valid(http):
		http.queue_free()

	var data: Array = state["data"]
	if data.is_empty():
		_note_online_failure("无响应")
		return {"ok": false, "message": "未收到响应"}
	var result: int = data[0]
	var code: int = data[1]
	if result != HTTPRequest.RESULT_SUCCESS:
		_note_online_failure("result=%d" % result)
		return {"ok": false, "message": "网络错误（result=%d）：地址不可达，或被墙 / 代理未启动" % result}
	var described: Dictionary = describe_http_result(code)
	if bool(described.get("ok", false)):
		reset_online_failure_state()
	else:
		_note_online_failure("HTTP %d" % code)
	return described

# HTTP 状态码 → 面板提示（纯函数，便于离线探针覆盖）
func describe_http_result(code: int) -> Dictionary:
	match code:
		200:
			return {"ok": true, "message": "连接成功！喊话判定由在线模型 %s 完成" % model}
		401, 403:
			return {"ok": false, "message": "鉴权失败（HTTP %d）：API Key / 代理令牌不正确" % code}
		404:
			return {"ok": false, "message": "地址不存在（HTTP 404）：API 地址可能写错了"}
		429:
			return {"ok": false, "message": "被限流（HTTP 429）：请求过于频繁或额度用尽"}
	var suffix := "服务端错误" if code >= 500 else "请检查地址 / Key / 模型名"
	return {"ok": false, "message": "接口返回 HTTP %d：%s" % [code, suffix]}

func _variant_str(v: Variant) -> String:
	if v is String:
		return v
	return ""

func _dict_str(dict: Dictionary, key: String) -> String:
	return _variant_str(dict.get(key, ""))

# ============================================================
# 备用的离线/优雅降级高保真本地语料库（正面 / 中性 / 负面）
# ============================================================

const MOCK_CRUSADER_POSITIVE := [
	"遵命，领主。正义的裁决永远不会迟到。",
	"主的光辉洗涤了我的疲惫，让我们继续前行！",
	"只要信念不灭，圣光必将驱散眼前的阴霾！",
	"钢铁般的誓言，不可动摇！",
]
const MOCK_CRUSADER_NEUTRAL := [
	"我听到了……继续坚守阵地。",
	"圣光在上，我会尽我所能。",
	"无需多言，剑已出鞘。",
	"在黑暗中祈祷，在战斗中前行。",
]
const MOCK_CRUSADER_NEGATIVE := [
	"我……我感到圣光正在离我远去……",
	"（颤抖地握紧十字架）这些该死的怪物，它们无穷无尽……",
	"领主……如果连你也质疑我的信仰，那我还能依赖什么？",
	"黑暗在蚕食我的灵魂……我快撑不住了……",
]

const MOCK_HIGHWAYMAN_POSITIVE := [
	"哼，行吧……如果这样真能帮我们多活几分钟。",
	"别废话了，子弹已上膛，随时准备让它们的脑袋开花。",
	"历经无数背叛，至少这次你的指引还算让人安心。",
	"呼，抽根烟的功夫，我们再给它们来上一刀！",
]
const MOCK_HIGHWAYMAN_NEUTRAL := [
	"知道了，继续干活。",
	"行，那就按你说的办。",
	"别浪费口舌了，我还有子弹要装。",
	"这趟买卖还没完，我懂。",
]
const MOCK_HIGHWAYMAN_NEGATIVE := [
	"哈……说得倒轻巧。我见过太多像你一样自信的人，最后都成了尸体。",
	"（冷笑）激励？在这鬼地方，能活着走出去的只有运气。",
	"别对我指手画脚。我闻到了死亡的气味，这次比以往都浓。",
	"够了……我受够了这些废话和这些该死的怪物。",
]

# ── ② 增益（战意高涨）语料 ──
const MOCK_CRUSADER_BUFF := [
	"圣光已注入我的血脉，我的剑将更加锋利！",
	"受此感召，我将化作坚不可摧的壁垒，护住所有人！",
	"誓言在燃烧，我感觉力量正在回归！",
]
const MOCK_HIGHWAYMAN_BUFF := [
	"行……既然你这么说了，那就让你们看看我的真正手段。",
	"有意思。这活儿我接了，看好了——我不会再留手。",
	"哼，别说我没提醒你，接下来会很血腥。",
]

# ── ④ 倒戈（精神崩溃，挥刀向队友）语料 ──
const MOCK_CRUSADER_BETRAY := [
	"闭嘴！……你们谁都别靠近我！（剑锋转向同伴）",
	"这不是圣光……这是我自己要杀。（举剑劈向身侧）",
	"我知道了——你们才是把我拖进地狱的元凶！",
]
const MOCK_HIGHWAYMAN_BETRAY := [
	"受够你们了……（枪口转向身旁）先解决身边的人。",
	"别怪我，是你们把我逼到这一步的。（刀已出鞘）",
	"哈！既然要死，那就一起死——我先送你们一程。",
]

# ============================================================
# 领主话语的语气分析（本地）
# 返回整数评分：负数 = 贬低/嘲讽/轻蔑/威胁（越负越恶劣），正数 = 鼓舞/信任
# 评分会直接参与 Mock 权重修正，并作为“语气预判”写进在线模型的 System Prompt
# 说明：每个档位只取首个命中（break），避免“蠢货”同时命中“蠢”与“蠢货”而重复扣分
# ============================================================

# 明确羞辱 / 贬低（-3）：这类措辞应当显著抬高负面反应
const TONE_INSULT_HEAVY := [
	"废物", "垃圾", "蠢", "傻", "白痴", "没用", "无能", "懦弱", "懦夫",
	"胆小鬼", "怕死", "窝囊", "饭桶", "不如狗", "我养的狗", "养的狗",
	"拖后腿", "拖累", "丢人", "没出息", "软蛋", "娘们", "该死", "去死",
	"滚", "闭嘴", "跪下", "狗东西", "畜生", "杂碎", "你算什么东西",
]
# 一般负面（-1）：命令式、不耐烦、轻蔑、威胁抛弃
const TONE_NEGATIVE := [
	"必须", "少废话", "别废话", "赶紧", "快点", "你敢", "否则", "军法", "处决",
	"不管你", "丢下你", "滚出去", "失望", "就知道", "每次都", "行不行",
	"别拖", "别让我", "再这样", "受够", "不值得", "活该",
]
# 高度鼓舞（+3）：真诚的肯定、信任与托付
const TONE_PRAISE_HEAVY := [
	"相信你", "我信你", "依靠你", "靠你了", "佩服", "敬佩", "英雄", "了不起",
	"光荣", "荣誉", "骄傲", "功劳", "谢谢你", "辛苦", "多亏", "最好的",
	"最勇敢", "与你同在", "以你为荣", "顶梁柱", "拜托你",
]
# 一般正面（+1）
const TONE_POSITIVE := [
	"勇敢", "勇猛", "坚强", "坚持", "挺住", "圣光", "信仰", "正义", "荣耀",
	"我们", "一起", "拜托", "感激", "赞美", "守护", "活下去", "必胜",
]

func evaluate_input_tone(text: String) -> int:
	var lower := text.to_lower()
	var score := 0
	for word in TONE_INSULT_HEAVY:
		if str(word) in lower:
			score -= 3
			break
	for word in TONE_NEGATIVE:
		if str(word) in lower:
			score -= 1
			break
	for word in TONE_PRAISE_HEAVY:
		if str(word) in lower:
			score += 3
			break
	for word in TONE_POSITIVE:
		if str(word) in lower:
			score += 1
			break
	return score

# 语气评分的可读标签（写进 Prompt 供模型参考）
func input_tone_label(score: int) -> String:
	if score <= -3:
		return "明显贬低/羞辱（领主正在羞辱这名英雄）"
	if score <= -1:
		return "偏向负面（命令、不耐烦或轻蔑）"
	if score >= 3:
		return "高度鼓舞（真诚的肯定与托付）"
	if score >= 1:
		return "偏向正面（鼓励与支持）"
	return "中性陈述"

# ============================================================
# 公开接口：返回 {"reply": String, "outcome": int (Outcome)}
# ============================================================

func get_hero_reply(hero_name: String, personality: String, player_input: String, hero_hp: int, hero_max_hp: int, hero_stress: int, monsters_count: int, parent_node: Node) -> Dictionary:
	var is_crusader := hero_name.to_lower().contains("crusader")
	
	# 没有 Key，或已被熔断（连续失败 2 次）→ 直接走极速离线 Mock，不再等 3.5 秒超时
	if api_key.strip_edges().is_empty() or online_disabled:
		return _generate_mock_result(is_crusader, hero_hp, hero_stress, player_input)

	# 本地语气预判：把“玩家说了什么”的权重前置给模型
	var tone: int = evaluate_input_tone(player_input)
	
	# 构造 Prompt —— 要求模型在四种行为标签中选择一种
	var system_prompt := (
		"你目前在扮演'暗黑地牢'风格策略RPG《Dark Dungeon》中性格为【" + personality + "】的英雄【" + hero_name + "】。"
		+"玩家作为领主输入了激励你的话：' " + player_input + " '。"
		+"目前的战场形势：你的生命值为 " + str(hero_hp) + "/" + str(hero_max_hp) + "，"
		+"精神压力累积到了 " + str(hero_stress) + "/200，"
		+"全队面临 " + str(monsters_count) + " 个敌人的包围。"
		+"【本地语气预判（仅供参考）】" + input_tone_label(tone) + "（评分 " + str(tone) + "，负=贬低/敌意，正=鼓舞/信任）。"
		+"【关键规则】请先判断你的角色对领主这番话的真实内心反应，然后在回复开头用以下四个标签之一标注："
		+"[RELIEVE]（受到鼓舞、精神平复，压力下降）／"
		+"[BUFF]（热血沸腾、战意高涨，获得增益）／"
		+"[STRESS]（动摇、恐惧、抵触，压力进一步上升）／"
		+"[BETRAY]（精神彻底崩溃或被激怒，当场向身边队友挥刀相向）。"
		+"【判定尺度】领主的原话是首要依据，战场形势是次要依据："
		+"① 真诚的鼓舞、信任、感谢、承诺 → 倾向 [RELIEVE] 或 [BUFF]；"
		+"② 明显的质疑、不耐烦、轻蔑、冷嘲 → 倾向 [STRESS]；"
		+"③ 明确贬低、羞辱、辱骂、诅咒、威胁抛弃（如骂他废物/无能/不如狗、叫他闭嘴、说后悔带他出来）"
		+" → 必须偏向 [STRESS]，措辞极其恶劣且他精神脆弱时可直接判定 [BETRAY]；"
		+"④ 只有当领主的原话本身不刺人时，才按战况判定：精神压力偏高（>70）倾向 [STRESS]，"
		+"压力极度濒临崩溃（>100）或血量低于 20% 时可能触发 [BETRAY]。"
		+"【硬性约束】：直接输出标签+一句精简台词，不带旁白或大括号心理动作描述；"
		+"严格限制在100字以内（不含标签）。禁止输出无关客套话和分析。"
		+"示例输出：[RELIEVE]圣光不灭，我必将战至最后一息！"
	)

	var messages := [
		{"role": "system", "content": system_prompt},
		{"role": "user", "content": player_input}
	]
	
	var payload := {
		"model": model,
		"messages": messages,
		"temperature": 0.7,
		"max_tokens": 100
	}
	
	var json_payload = JSON.stringify(payload)
	
	# 利用 HTTPRequest 与 API 通信
	var http_request = HTTPRequest.new()
	parent_node.add_child(http_request)
	
	http_request.set_use_threads(true)
	
	var headers = [
		"Content-Type: application/json",
		"Authorization: Bearer " + api_key
	]
	
	var error = http_request.request(api_url, headers, HTTPClient.METHOD_POST, json_payload)
	if error != OK:
		print("[LLM] Send HTTP Request failed with error code: ", error)
		_note_online_failure("发送失败 %d" % error)
		http_request.queue_free()
		return _generate_mock_result(is_crusader, hero_hp, hero_stress, player_input)
		
	# 异步超时锁：如果 3.5 秒内未返回则立即优雅降级为 Mock
	var req_state = {"is_completed": false, "response_data": []}
	
	var on_completed = func(res: int, code: int, _headers: PackedStringArray, response_body: PackedByteArray):
		if not req_state["is_completed"]:
			req_state["is_completed"] = true
			req_state["response_data"] = [res, code, response_body]
			
	http_request.request_completed.connect(on_completed)
	
	# 超时检测机制
	var timeout_timer := parent_node.get_tree().create_timer(3.5)
	while not req_state["is_completed"]:
		if not is_instance_valid(http_request):
			break
		await parent_node.get_tree().process_frame
		if timeout_timer.time_left <= 0.0:
			print("[LLM] Request timeout (3.5s). Falling back to mock engine.")
			_note_online_failure("3.5s 超时")
			req_state["is_completed"] = true
			if is_instance_valid(http_request):
				http_request.cancel_request()
				http_request.queue_free()
			return _generate_mock_result(is_crusader, hero_hp, hero_stress, player_input)
			
	if is_instance_valid(http_request):
		http_request.queue_free()
		
	var r_data: Array = req_state["response_data"]
	if r_data.is_empty():
		_note_online_failure("无响应")
		return _generate_mock_result(is_crusader, hero_hp, hero_stress, player_input)
		
	var result = r_data[0]
	var response_code = r_data[1]
	var body = r_data[2]
	
	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		print("[LLM] Request failed, result: ", result, " code: ", response_code)
		_note_online_failure("result=%d code=%d" % [result, response_code])
		return _generate_mock_result(is_crusader, hero_hp, hero_stress, player_input)
		
	# 解析 Response JSON
	var json = JSON.new()
	var parse_err = json.parse(body.get_string_from_utf8())
	if parse_err != OK:
		print("[LLM] Parse JSON failed")
		_note_online_failure("响应不是合法 JSON")
		return _generate_mock_result(is_crusader, hero_hp, hero_stress, player_input)
		
	var parsed_res = json.get_data()
	if not parsed_res is Dictionary or not parsed_res.has("choices") or parsed_res["choices"].is_empty():
		print("[LLM] Invalid OpenAI API standard scheme: ", parsed_res)
		_note_online_failure("响应缺少 choices")
		return _generate_mock_result(is_crusader, hero_hp, hero_stress, player_input)
		
	var reply_content = parsed_res["choices"][0]["message"]["content"]
	_note_online_success()
	return _parse_outcome_reply(reply_content, player_input)

# ============================================================
# 行为标签解析：从模型原始输出中提取四种行为之一与纯文本
# ============================================================

func _parse_outcome_reply(raw: String, player_input: String = "") -> Dictionary:
	var outcome := Outcome.RELIEVE
	var tagged := false
	var clean := raw.strip_edges()
	var upper := clean.to_upper()
	
	# 检测 [RELIEVE] / [BUFF] / [STRESS] / [BETRAY] 标签
	for tag in OUTCOME_TAGS.keys():
		var token: String = "[%s]" % tag
		if upper.begins_with(token):
			outcome = OUTCOME_TAGS[tag]
			clean = clean.substr(token.length()).strip_edges()
			tagged = true
			break
	
	# 兜底：模型未给标签时按关键词判定（倒戈需显式暴力措辞，宁可漏判也不误伤队友）
	if not tagged:
		outcome = _keyword_outcome(clean)
		# 领主明确贬低时不应给出“减压”：无标签且台词无明确姿态时至少按加压处理
		if evaluate_input_tone(player_input) <= -2 and outcome == Outcome.RELIEVE:
			outcome = Outcome.STRESS
	
	# 清理残留引号
	clean = clean.replace("\"", "").replace("\u201c", "").replace("\u201d", "")
	print("[LLM] Parsed outcome: ", outcome, " reply: ", clean)
	return {"reply": "\u201c" + clean + "\u201d", "outcome": outcome}

# 简易关键词兜底分析：把台词映射到四种行为
func _keyword_outcome(text: String) -> int:
	var lower := text.to_lower()
	
	# ① 倒戈：必须出现明确的暴力/背叛措辞才判定，避免误伤队友
	for w in ["砍向", "挥刀", "砍死", "杀了你", "一起死", "先解决你", "闭嘴", "别怪我", "背叛", "倒戈", "受够你们"]:
		if w in lower:
			return Outcome.BETRAY
	
	var buff_hits := 0
	for w in ["力量", "壁垒", "赐福", "更锋利", "不会留手", "战意", "燃烧", "注入", "护住"]:
		if w in lower:
			buff_hits += 1
	
	var relieve_hits := 0
	for w in ["圣光", "信仰", "誓", "前行", "战斗", "正义", "荣耀", "不灭", "必胜", "活下去"]:
		if w in lower:
			relieve_hits += 1
	
	var stress_hits := 0
	for w in ["绝望", "黑暗", "恐惧", "死亡", "撑不住", "放弃", "诅咒", "够了", "受够了", "无望", "完了", "吞噬", "离我远去"]:
		if w in lower:
			stress_hits += 1
	
	if stress_hits > relieve_hits and stress_hits > buff_hits:
		return Outcome.STRESS
	if buff_hits > relieve_hits:
		return Outcome.BUFF
	return Outcome.RELIEVE

# ============================================================
# Mock 生成：四种行为的分布权重受压力/血量/领主语气加权
# ============================================================

func _generate_mock_result(is_crusader: bool, hp: int, stress: int, player_input: String = "") -> Dictionary:
	# 根据压力与血量计算四种行为的分布权重（压力越高 → 负面/倒戈概率越大）
	# 注意：clamp() 返回 Variant，必须显式标注 float，否则触发"从 Variant 推断类型"的编译错误
	var stress_ratio: float = clamp(float(stress) / 200.0, 0.0, 1.0)
	
	var w_relieve: float = 0.55 - stress_ratio * 0.45 # 0.55 → 0.10
	var w_buff: float = 0.20 - stress_ratio * 0.15 # 0.20 → 0.05
	var w_stress: float = 0.22 + stress_ratio * 0.55 # 0.22 → 0.77
	# 倒戈仅在极端状态下开放：压力 > 170（0.85）或因濒死而崩溃
	var w_betray: float = 0.0
	if stress_ratio > 0.85:
		w_betray = (stress_ratio - 0.85) / 0.15 * 0.30
	if hp <= 10:
		w_betray += 0.15
	if hp < 25:
		w_stress += 0.10
	
	# ---- 领主原话的语气修正：玩家“说了什么”比战况更关键 ----
	var tone: int = evaluate_input_tone(player_input)
	if tone < 0:
		# 明确贬低/羞辱：正面反应几乎被抹平，加压大幅上升，恶劣到一定程度就会倒戈
		var severity: float = clampf(float(-tone) / 4.0, 0.0, 1.0)
		w_relieve *= maxf(1.0 - severity, 0.05)
		w_buff *= maxf(1.0 - severity * 0.8, 0.05)
		w_stress *= 1.0 + severity * 2.0
		# 只有“明确贬低”（评分 ≤ -2）才会额外打开倒戈概率：
		# 单个重贬词 ≈ +12%，重贬 + 命令/威胁 ≈ +25%（再叠加高压/瀕死，总上限仍为 0.35）
		w_betray += maxf(severity - 0.5, 0.0) * 0.5
	elif tone > 0:
		# 真诚鼓舞：减压/增益显著提升，加压被压低
		var warmth: float = clampf(float(tone) / 4.0, 0.0, 1.0)
		w_relieve *= 1.0 + warmth * 1.2
		w_buff *= 1.0 + warmth * 0.8
		w_stress *= maxf(1.0 - warmth * 0.7, 0.2)
	
	w_betray = min(w_betray, 0.35)
	w_relieve = max(w_relieve, 0.05)
	w_buff = max(w_buff, 0.03)
	
	# 归一化
	var total: float = w_relieve + w_buff + w_stress + w_betray
	w_relieve /= total
	w_buff /= total
	w_stress /= total
	w_betray /= total
	
	# 按权重选择行为
	var roll: float = randf()
	var outcome: int
	if roll < w_betray:
		outcome = Outcome.BETRAY
	elif roll < w_betray + w_stress:
		outcome = Outcome.STRESS
	elif roll < w_betray + w_stress + w_buff:
		outcome = Outcome.BUFF
	else:
		outcome = Outcome.RELIEVE
	
	# 选择对应行为语料
	var relieve_list: Array
	var buff_list: Array
	var stress_list: Array
	var betray_list: Array
	if is_crusader:
		relieve_list = MOCK_CRUSADER_POSITIVE
		buff_list = MOCK_CRUSADER_BUFF
		stress_list = MOCK_CRUSADER_NEGATIVE
		betray_list = MOCK_CRUSADER_BETRAY
	else:
		relieve_list = MOCK_HIGHWAYMAN_POSITIVE
		buff_list = MOCK_HIGHWAYMAN_BUFF
		stress_list = MOCK_HIGHWAYMAN_NEGATIVE
		betray_list = MOCK_HIGHWAYMAN_BETRAY
	
	var reply: String
	match outcome:
		Outcome.RELIEVE:
			reply = relieve_list[randi() % relieve_list.size()]
		Outcome.BUFF:
			reply = buff_list[randi() % buff_list.size()]
		Outcome.STRESS:
			reply = stress_list[randi() % stress_list.size()]
		Outcome.BETRAY:
			reply = betray_list[randi() % betray_list.size()]
		_:
			reply = "我们在生死边缘战斗，领主！"
	
	print("[LLM Mock] stress=", stress, " hp=", hp, " → outcome=", outcome,
		" (relieve=%.2f buff=%.2f stress=%.2f betray=%.2f)" % [w_relieve, w_buff, w_stress, w_betray],
		" reply=", reply)
	return {"reply": "\u201c" + reply + "\u201d", "outcome": outcome}
