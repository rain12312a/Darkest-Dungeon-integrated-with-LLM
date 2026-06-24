class_name LLMClient
extends Node

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

# 备用的离线/优雅降级高保真本地语料库
const MOCK_CRUSADER_RESPONSES := {
	"normal": [
		"“遵命，领主。正义的裁决永远不会迟到。”",
		"“主的光辉洗涤了我的疲惫，让我们继续前行！”",
		"“只要信念不灭，圣光必将驱散眼前的阴霾！”",
		"“钢铁般的誓言，不可动摇！”"
	],
	"low_hp": [
		"“（口吐鲜血却依然挺立）这点外伤... 圣光将赐予我重生的英勇！”",
		"“只要我一息尚存，这身重铠便不会倒下！”"
	],
	"high_stress": [
		"“（闭眼深呼吸，抚摸着十字架）我感到黑暗在耳边低语... 但您的言语唤醒了我！”",
		"“压不垮的！唯有圣洁的信念在指引我对抗疯狂！”"
	]
}

const MOCK_HIGHWAYMAN_RESPONSES := {
	"normal": [
		"“哼，行吧... 如果这样真能帮我们多活几分钟。”",
		"“别废话了，子弹已上膛，随时准备让它们的脑袋开花。”",
		"“历经无数背叛，至少这次你的指引还算让人安心。”",
		"“呼，抽根烟的功夫，我们再给它们来上一刀！”"
	],
	"low_hp": [
		"“切，还真够险的。不过只要我的手指还能扣动扳机，就还没结束！”",
		"“（啐了一口血）想送我去见阎王？没那么容易！”"
	],
	"high_stress": [
		"“别对我狂吠，我经历过比这痛苦百倍的泥潭... 还能撑得住。”",
		"“疯狂的阴霾在抓我的脚踝，但我保证死前会把更多的怪物拖下水！”"
	]
}

# 异步获取英雄的回复
func get_hero_reply(hero_name: String, personality: String, player_input: String, hero_hp: int, hero_max_hp: int, hero_stress: int, monsters_count: int, parent_node: Node) -> String:
	var is_crusader := hero_name.to_lower().contains("crusader")
	
	# 如果没有配置 API Key，直接使用极速离线 Mock
	if api_key.strip_edges().is_empty():
		return _generate_mock_reply(is_crusader, hero_hp, hero_stress)
		
	# 构造 Prompt
	var system_prompt := "你目前在扮演‘暗黑地牢’风格策略RPG《Dark Dungeon》中性格为【" + personality + "】的英雄【" + hero_name + "】。玩家作为领主输入了激励你的话：' " + player_input + " '。由于目前的战场形势如下：你的生命值目前为 " + str(hero_hp) + "/" + str(hero_max_hp) + "，你的精神精神压力累积到了 " + str(hero_stress) + "/200，目前全队面临 " + str(monsters_count) + " 个敌人的包围。请用极大符合你性格和当前战场生存状态的一句精简台词，代表这个角色来回复玩家的激励。【硬性约束】：语意内容需带有一丢丢暗黑、严肃生存、英雄使命感；直接输出角色的内心回复/大喊话，不带任何旁白或大括号心理动作描述；严格限制在25字以内。禁止输出无关客套话和分析。"

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
		return _generate_mock_reply(is_crusader, hero_hp, hero_stress)
		
	# 异步超时锁：如果 3.5 秒内未返回则立即优雅降级为 Mock
	# 用字典形式来传递引用，完美解决 GDScript 的并列及 lambda 变量冲突
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
		# 等待微小帧
		await parent_node.get_tree().process_frame
		# 若超出 3.5 秒
		if timeout_timer.time_left <= 0.0:
			print("[LLM] Request timeout (3.5s). Falling back to mock engine.")
			req_state["is_completed"] = true
			if is_instance_valid(http_request):
				http_request.cancel_request()
				http_request.queue_free()
			return _generate_mock_reply(is_crusader, hero_hp, hero_stress)
			
	if is_instance_valid(http_request):
		http_request.queue_free()
		
	var r_data: Array = req_state["response_data"]
	if r_data.is_empty():
		return _generate_mock_reply(is_crusader, hero_hp, hero_stress)
		
	var result = r_data[0]
	var response_code = r_data[1]
	var body = r_data[2]
	
	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		print("[LLM] Request failed, result: ", result, " code: ", response_code)
		return _generate_mock_reply(is_crusader, hero_hp, hero_stress)
		
	# 解析 Response JSON
	var json = JSON.new()
	var parse_err = json.parse(body.get_string_from_utf8())
	if parse_err != OK:
		print("[LLM] Parse JSON failed")
		return _generate_mock_reply(is_crusader, hero_hp, hero_stress)
		
	var parsed_res = json.get_data()
	if not parsed_res is Dictionary or not parsed_res.has("choices") or parsed_res["choices"].is_empty():
		print("[LLM] Invalid OpenAI API standard scheme: ", parsed_res)
		return _generate_mock_reply(is_crusader, hero_hp, hero_stress)
		
	var reply_content = parsed_res["choices"][0]["message"]["content"]
	reply_content = reply_content.strip_edges().replace("\"", "").replace("“", "").replace("”", "")
	return "“" + reply_content + "”"

func _generate_mock_reply(is_crusader: bool, hp: int, stress: int) -> String:
	# 根据血量和压力进行语意匹配
	var is_low_hp = hp <= 15
	var is_high_stress = stress >= 120
	
	var dict := MOCK_CRUSADER_RESPONSES if is_crusader else MOCK_HIGHWAYMAN_RESPONSES
	var list: Array = []
	if is_low_hp:
		list = dict["low_hp"] as Array
	elif is_high_stress:
		list = dict["high_stress"] as Array
	else:
		list = dict["normal"] as Array
		
	# 最终随机捞一句
	if list.size() > 0:
		return list[randi() % list.size()]
	return "“我们在生死边缘战斗，领主！”"
