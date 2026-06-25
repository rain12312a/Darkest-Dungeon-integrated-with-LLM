class_name LLMClient
extends Node

# 情感极性枚举：负面动摇 / 中性 / 正面激励
enum Sentiment { NEGATIVE = -1, NEUTRAL = 0, POSITIVE = 1 }

# API 配置 —— 从外部文件加载（api_config.gd 已加入 .gitignore，不会上传到 GitHub）
# 若文件不存在，api_key 默认为空字符串，自动降级为离线 Mock 模式
var api_key: String = ""
var api_url: String = "https://api.deepseek.com/v1/chat/completions"
var model: String = "deepseek-chat"

func _init() -> void:
	# 尝试加载外部 API 配置文件（gitignored）
	var cfg := load("res://scripts/battle/api_config.gd")
	if cfg:
		api_key = cfg.get("API_KEY") if cfg.get("API_KEY") else ""
		api_url = cfg.get("API_URL") if cfg.get("API_URL") else api_url
		model = cfg.get("MODEL") if cfg.get("MODEL") else model

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

# ============================================================
# 公开接口：返回 {"reply": String, "sentiment": int (Sentiment)}
# ============================================================

func get_hero_reply(hero_name: String, personality: String, player_input: String, hero_hp: int, hero_max_hp: int, hero_stress: int, monsters_count: int, parent_node: Node) -> Dictionary:
	var is_crusader := hero_name.to_lower().contains("crusader")
	
	# 如果没有配置 API Key，直接使用极速离线 Mock
	if api_key.strip_edges().is_empty():
		return _generate_mock_result(is_crusader, hero_hp, hero_stress)
		
	# 构造 Prompt —— 要求模型输出情感标签 [POSITIVE]/[NEUTRAL]/[NEGATIVE]
	var system_prompt := (
		"你目前在扮演'暗黑地牢'风格策略RPG《Dark Dungeon》中性格为【" + personality + "】的英雄【" + hero_name + "】。"
		+ "玩家作为领主输入了激励你的话：' " + player_input + " '。"
		+ "目前的战场形势：你的生命值为 " + str(hero_hp) + "/" + str(hero_max_hp) + "，"
		+ "精神压力累积到了 " + str(hero_stress) + "/200，"
		+ "全队面临 " + str(monsters_count) + " 个敌人的包围。"
		+ "【关键规则】请先判断你的角色对领主这番话的真实内心反应属于哪一种情感极性，"
		+ "然后在回复开头用标签标注：[POSITIVE]（受到鼓舞、振奋）/[NEUTRAL]（平淡接受）/[NEGATIVE]（动摇、恐惧、抵触）。"
		+ "注意：精神压力越高（>150），越可能产生负面动摇；血量极低（<25%）时也可能陷入绝望。"
		+ "【硬性约束】：直接输出标签+一句精简台词，不带旁白或大括号心理动作描述；"
		+ "严格限制在25字以内（不含标签）。禁止输出无关客套话和分析。"
		+ "示例输出：[POSITIVE]圣光不灭，我必将战至最后一息！"
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
		http_request.queue_free()
		return _generate_mock_result(is_crusader, hero_hp, hero_stress)
		
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
			req_state["is_completed"] = true
			if is_instance_valid(http_request):
				http_request.cancel_request()
				http_request.queue_free()
			return _generate_mock_result(is_crusader, hero_hp, hero_stress)
			
	if is_instance_valid(http_request):
		http_request.queue_free()
		
	var r_data: Array = req_state["response_data"]
	if r_data.is_empty():
		return _generate_mock_result(is_crusader, hero_hp, hero_stress)
		
	var result = r_data[0]
	var response_code = r_data[1]
	var body = r_data[2]
	
	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		print("[LLM] Request failed, result: ", result, " code: ", response_code)
		return _generate_mock_result(is_crusader, hero_hp, hero_stress)
		
	# 解析 Response JSON
	var json = JSON.new()
	var parse_err = json.parse(body.get_string_from_utf8())
	if parse_err != OK:
		print("[LLM] Parse JSON failed")
		return _generate_mock_result(is_crusader, hero_hp, hero_stress)
		
	var parsed_res = json.get_data()
	if not parsed_res is Dictionary or not parsed_res.has("choices") or parsed_res["choices"].is_empty():
		print("[LLM] Invalid OpenAI API standard scheme: ", parsed_res)
		return _generate_mock_result(is_crusader, hero_hp, hero_stress)
		
	var reply_content = parsed_res["choices"][0]["message"]["content"]
	return _parse_sentiment_reply(reply_content)

# ============================================================
# 情感标签解析：从模型原始输出中提取标签与纯文本
# ============================================================

func _parse_sentiment_reply(raw: String) -> Dictionary:
	var sentiment := Sentiment.NEUTRAL
	var clean := raw.strip_edges()
	
	# 检测 [POSITIVE] / [NEGATIVE] / [NEUTRAL] 标签
	if clean.to_upper().begins_with("[POSITIVE]"):
		sentiment = Sentiment.POSITIVE
		clean = clean.substr(10).strip_edges()
	elif clean.to_upper().begins_with("[NEGATIVE]"):
		sentiment = Sentiment.NEGATIVE
		clean = clean.substr(10).strip_edges()
	elif clean.to_upper().begins_with("[NEUTRAL]"):
		sentiment = Sentiment.NEUTRAL
		clean = clean.substr(9).strip_edges()
	
	# 兜底：基于关键词的简易情感判定（无标签时启用）
	if sentiment == Sentiment.NEUTRAL:
		sentiment = _keyword_sentiment(clean)
	
	# 清理残留引号
	clean = clean.replace("\"", "").replace("\u201c", "").replace("\u201d", "")
	print("[LLM] Parsed sentiment: ", sentiment, " reply: ", clean)
	return {"reply": "\u201c" + clean + "\u201d", "sentiment": sentiment}

# 简易关键词情感兜底分析
func _keyword_sentiment(text: String) -> int:
	var lower := text.to_lower()
	var positive_words := ["圣光", "信仰", "誓", "前行", "战斗", "正义", "荣耀", "守护", "不灭", "必胜", "活下去"]
	var negative_words := ["绝望", "黑暗", "恐惧", "死亡", "撑不住", "放弃", "诅咒", "够了", "受够了", "无望", "完了", "吞噬"]
	
	var pos_score := 0
	var neg_score := 0
	for w in positive_words:
		if w in lower:
			pos_score += 1
	for w in negative_words:
		if w in lower:
			neg_score += 1
	
	if neg_score > pos_score:
		return Sentiment.NEGATIVE
	elif pos_score > neg_score:
		return Sentiment.POSITIVE
	return Sentiment.NEUTRAL

# ============================================================
# Mock 生成：情感极性受压力/血量加权随机
# ============================================================

func _generate_mock_result(is_crusader: bool, hp: int, stress: int) -> Dictionary:
	# 根据压力与血量计算情感分布权重（压力越高 → 负面概率越大）
	var neg_weight := 0.05
	var neu_weight := 0.25
	var pos_weight := 0.70
	
	# 压力影响：0~200 映射到 0%~60% 负面权重增量
	neg_weight += clamp(float(stress) / 200.0 * 0.60, 0.0, 0.60)
	# 低血量影响
	if hp < 25:
		neg_weight += 0.15
	if hp <= 15:
		neg_weight += 0.10
	# 濒危进一步拉高负面
	if stress >= 160 or hp <= 8:
		neg_weight = min(neg_weight + 0.08, 0.80)
	
	# 归一化
	var total := neg_weight + neu_weight + pos_weight
	neg_weight /= total
	neu_weight /= total
	pos_weight /= total
	
	# 按权重随机选择情感极性
	var roll := randf()
	var sentiment: int
	if roll < neg_weight:
		sentiment = Sentiment.NEGATIVE
	elif roll < neg_weight + neu_weight:
		sentiment = Sentiment.NEUTRAL
	else:
		sentiment = Sentiment.POSITIVE
	
	# 选择对应情感语料
	var pos_list: Array
	var neu_list: Array
	var neg_list: Array
	if is_crusader:
		pos_list = MOCK_CRUSADER_POSITIVE
		neu_list = MOCK_CRUSADER_NEUTRAL
		neg_list = MOCK_CRUSADER_NEGATIVE
	else:
		pos_list = MOCK_HIGHWAYMAN_POSITIVE
		neu_list = MOCK_HIGHWAYMAN_NEUTRAL
		neg_list = MOCK_HIGHWAYMAN_NEGATIVE
	
	var reply: String
	match sentiment:
		Sentiment.POSITIVE:
			reply = pos_list[randi() % pos_list.size()]
		Sentiment.NEUTRAL:
			reply = neu_list[randi() % neu_list.size()]
		Sentiment.NEGATIVE:
			reply = neg_list[randi() % neg_list.size()]
		_:
			reply = "我们在生死边缘战斗，领主！"
	
	print("[LLM Mock] stress=", stress, " hp=", hp, " → sentiment=", sentiment, " reply=", reply)
	return {"reply": "\u201c" + reply + "\u201d", "sentiment": sentiment}
