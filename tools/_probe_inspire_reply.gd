extends SceneTree

# 临时探针脚本（端到端验证用，非游戏运行时代码）
# 用途：验证激励喊话的两项改动
#   ① 回应窗口：必须玩家点击「确定」才收起并推进回合（不再 2.5s 自动散去）
#   ② 结果更看重玩家原话：明确贬低 → 负面（加压/倒戈）概率大幅上升；真诚鼓舞 → 正面上升
# 运行：godot --headless --path <项目> --script res://tools/_probe_inspire_reply.gd

# 固定返回 RELIEVE 的桩，用来观察“窗口是否卡住等待确认”
class StubLLM extends LLMClient:
	func get_hero_reply(_hero_name: String, _personality: String, _player_input: String, _hp: int, _max_hp: int, _stress: int, _monsters: int, _parent: Node) -> Dictionary:
		return {"reply": "\u201c（点了点头）\u201d", "outcome": LLMClient.Outcome.RELIEVE}

const INSULT := "你这废物，真是个没用的懦夫，给我闭嘴赶紧上，否则我丢了你自己走。"
const NEUTRAL := "继续前进吧，保持阵型。"
const PRAISE := "我一直相信你，你是我们最勇敢的英雄，拜托你了，辛苦了。"

var _battle: Node = null
var _client := LLMClient.new()
var _frame := 0
var _pass := 0
var _fail := 0
var _hero: Dictionary = {}
var _modal_was_visible := false

func _initialize() -> void:
	HeroConfig.reset_party_state()
	MonsterConfig.CURRENT_ENCOUNTER = ["skeleton_common", "skeleton_defender"]
	var packed := load("res://scenes/battle/Battle.tscn") as PackedScene
	if packed == null:
		print("[RPLY] FAILED: cannot load Battle.tscn")
		quit(1)
		return
	_battle = packed.instantiate()
	root.add_child(_battle)

func _process(_delta: float) -> bool:
	_frame += 1
	if _frame < 3:
		return false
	if _battle == null:
		quit(1)
		return true
	if _frame == 3:
		_test_tone()
		_test_distribution()
		_test_untagged_fallback()
		return false
	if _frame == 4:
		_start_reply_flow()
		return false
	if _frame == 6:
		_test_reply_waits_for_confirm()
		return false
	if _frame == 8:
		_test_confirm_closes_and_advances()
		print("[RPLY] ===== PASS=%d FAIL=%d ====" % [_pass, _fail])
		quit(0 if _fail == 0 else 1)
	return false

func _expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("[RPLY]   PASS  ", label)
	else:
		_fail += 1
		print("[RPLY]   FAIL  ", label)

# ------------------------------------------------------------ ① 语气分析

func _test_tone() -> void:
	print("[RPLY] --- ① 领主原话语气分析 ---")
	var insult_tone: int = _client.evaluate_input_tone(INSULT)
	var neutral_tone: int = _client.evaluate_input_tone(NEUTRAL)
	var praise_tone: int = _client.evaluate_input_tone(PRAISE)
	print("[RPLY]   贬低=%d 中性=%d 鼓舞=%d" % [insult_tone, neutral_tone, praise_tone])
	_expect(insult_tone <= -3, "明确贬低被判为强负面（%d）" % insult_tone)
	_expect(neutral_tone == 0, "中性陈述评分为 0（%d）" % neutral_tone)
	_expect(praise_tone >= 3, "真诚鼓舞被判为强正面（%d）" % praise_tone)
	_expect(_client.evaluate_input_tone("你个蠢货") == -3, "单个重贬词只扣一档（不因“蠢/蠢货”重复扣分）")
	_expect(_client.input_tone_label(insult_tone).contains("贬低"), "贬低语气有可读标签")

# ------------------------------------------------------------ ② Mock 分布

func _test_distribution() -> void:
	print("[RPLY] --- ② Mock 结果分布（每档 600 次，健康状态 hp45/stress0） ---")
	var insult := _sample(INSULT, 600)
	var neutral := _sample(NEUTRAL, 600)
	var praise := _sample(PRAISE, 600)
	print("[RPLY]   贬低  减压 %.1f%% 增益 %.1f%% 加压 %.1f%% 倒戈 %.1f%%" % insult)
	print("[RPLY]   中性  减压 %.1f%% 增益 %.1f%% 加压 %.1f%% 倒戈 %.1f%%" % neutral)
	print("[RPLY]   鼓舞  减压 %.1f%% 增益 %.1f%% 加压 %.1f%% 倒戈 %.1f%%" % praise)
	_expect(insult[2] + insult[3] >= 70.0, "贬低时负面（加压+倒戈）≥70%%（实际 %.1f%%）" % (insult[2] + insult[3]))
	_expect(insult[3] >= 5.0, "贬低会让零压力英雄也出现倒戈（实际 %.1f%%）" % insult[3])
	_expect(insult[0] <= 10.0, "贬低时减压被压到很低（实际 %.1f%%）" % insult[0])
	_expect(insult[2] > neutral[2] + 20.0, "贬低显著抬高加压（%.1f%% vs 中性 %.1f%%）" % [insult[2], neutral[2]])
	_expect(praise[0] + praise[1] >= 85.0, "鼓舞时正面（减压+增益）≥85%%（实际 %.1f%%）" % (praise[0] + praise[1]))
	_expect(neutral[3] < 0.5, "中性且健康时几乎不会倒戈（实际 %.1f%%）" % neutral[3])

# 采样 4 种结果的出现比例（减压/增益/加压/倒戈）
func _sample(input_text: String, rounds: int) -> Array:
	var counts := [0, 0, 0, 0]
	for _i in range(rounds):
		var r: Dictionary = _client._generate_mock_result(true, 45, 0, input_text)
		counts[int(r["outcome"])] += 1
	var pct: Array = []
	for c in counts:
		pct.append(100.0 * float(c) / float(rounds))
	return pct

# ------------------------------------------------------------ ③ 无标签兜底

func _test_untagged_fallback() -> void:
	print("[RPLY] --- ③ 模型未给标签时的兜底 ---")
	var passive: Dictionary = _client._parse_outcome_reply("……（沉默不语）", INSULT)
	_expect(int(passive["outcome"]) != LLMClient.Outcome.RELIEVE, "贬低 + 无标签的中性台词不会被判成减压")
	var relieved: Dictionary = _client._parse_outcome_reply("……（沉默不语）", PRAISE)
	_expect(int(relieved["outcome"]) == LLMClient.Outcome.RELIEVE, "鼓舞 + 无标签仍按减压")

# ------------------------------------------------------------ ④ 回应窗口需点击确认

func _start_reply_flow() -> void:
	print("[RPLY] --- ④ 回应窗口等待确认 ---")
	_battle.set("battle_over", true) # 冻结自动战斗循环
	_hero = (_battle.get("heroes") as Array)[0]
	_battle.set("llm_client", StubLLM.new())
	_battle.set("current_actor", {"unit_type": "hero", "index": 0})
	_battle.set("battle_over", false)
	print("[RPLY]   激励前压力 = ", int(_hero.get("stress", 0)), " 行动点 = ", int(_hero.get("actions_remaining", 0)))
	_battle.call("_execute_llm_inspiration", "圣光保佑我们！")
	# 协程已停在 await reply_confirmed；顺手冻结战斗循环，避免后续帧里自动战斗干扰断言
	_battle.set("battle_over", true)

func _test_reply_waits_for_confirm() -> void:
	var modal: ColorRect = _battle.get("reply_modal")
	var btn: Button = _battle.get("reply_confirm_button")
	_modal_was_visible = modal != null and modal.visible
	_expect(_modal_was_visible, "回应窗口仍显示（未自动散去）")
	_expect(btn != null and btn.visible, "确定按钮已亮出")
	_expect(not btn.disabled, "确定按钮可点击")
	var status_lbl: Label = _battle.get("reply_status_lbl")
	_expect(status_lbl != null and "减压" in status_lbl.text, "结算文案已写入（%s）" % (status_lbl.text if status_lbl != null else ""))
	# 等待期间行动点未被扣除（回合未推进）
	_expect(int(_hero.get("actions_remaining", 0)) == 1, "未确认前不扣行动点（仍为 1）")

func _test_confirm_closes_and_advances() -> void:
	_battle.call("_on_reply_confirm_pressed")
	var modal: ColorRect = _battle.get("reply_modal")
	var btn: Button = _battle.get("reply_confirm_button")
	_expect(modal == null or not modal.visible, "点击确定后回应窗口收起")
	_expect(btn == null or not btn.visible, "确定按钮随之隐藏")
	_expect(not bool(_battle.get("_is_requesting_llm")), "关闭后解除 LLM 锁")
	_expect(not bool(_battle.get("_in_fx_pause")), "关闭后解除特效暂停锁")
	_expect(int(_hero.get("actions_remaining", 1)) == 0, "确认后扣除该英雄本回合行动点")
