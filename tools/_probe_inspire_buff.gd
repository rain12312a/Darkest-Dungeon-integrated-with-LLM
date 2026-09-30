extends SceneTree

# 临时探针脚本（端到端验证用，非游戏运行时代码）
# 用途：验证「AI 激励喊话」的 ② 增益（BUFF）分支已真正结算效果
#   · StatusConfig.inspired（攻击力 +20%，3 回合）
#   · BattleController.INSPIRE_BUFF_STATUS / INSPIRE_BUFF_ROUNDS 接线
#   · 走真实 _execute_llm_inspiration()，把 llm_client 换成固定返回 BUFF 的桩
# 运行：godot --headless --path <项目> --script res://tools/_probe_inspire_buff.gd

# 固定返回 BUFF 结果的 LLM 桩（必须是 LLMClient 子类，llm_client 是强类型成员）
class StubLLM extends LLMClient:
	func get_hero_reply(_hero_name: String, _personality: String, _player_input: String, _hp: int, _max_hp: int, _stress: int, _monsters: int, _parent: Node) -> Dictionary:
		return {"reply": "\u201c力量涌上来了，看我的！\u201d", "outcome": LLMClient.Outcome.BUFF}

var _battle: Node = null
var _frame := 0
var _pass := 0
var _fail := 0
var _hero: Dictionary = {}

func _initialize() -> void:
	HeroConfig.reset_party_state()
	ConsumableConfig.reset_inventory()
	MonsterConfig.CURRENT_ENCOUNTER = ["skeleton_common", "skeleton_defender"]
	var packed := load("res://scenes/battle/Battle.tscn") as PackedScene
	if packed == null:
		print("[INSP] FAILED: cannot load Battle.tscn")
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
		_test_config()
		_run_buff_branch()
		return false
	if _frame == 5:
		_assert_buff_applied()
		print("[INSP] ===== PASS=%d FAIL=%d ====" % [_pass, _fail])
		quit(0 if _fail == 0 else 1)
	return false

func _expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("[INSP]   PASS  ", label)
	else:
		_fail += 1
		print("[INSP]   FAIL  ", label)

# ------------------------------------------------------------ ① 配置

func _test_config() -> void:
	print("[INSP] --- ① inspired 状态配置 ---")
	var cfg: Dictionary = StatusConfig.get_status("inspired")
	_expect(not cfg.is_empty(), "StatusConfig 中存在 inspired")
	_expect(is_equal_approx(float(cfg.get("attack_mult", 0.0)), 1.2), "inspired 攻击力倍率 = 1.2")
	_expect(not bool(cfg.get("dot", false)), "inspired 不是 DoT")
	_expect(ResourceLoader.exists(str(cfg.get("icon", ""))), "inspired 图标资源存在（%s）" % str(cfg.get("icon", "")))
	# 常量不能用 Object.get() 读，得看脚本的常量表
	var consts: Dictionary = (_battle.get_script() as Script).get_script_constant_map()
	_expect(str(consts.get("INSPIRE_BUFF_STATUS", "")) == "inspired", "BUFF 分支状态 id 常量 = inspired")
	_expect(int(consts.get("INSPIRE_BUFF_ROUNDS", 0)) == 3, "BUFF 增益持续 3 回合")
	# 激励按钮的 tooltip 不再宣称“预留”
	var btn: Button = _battle.get("inspire_button")
	_expect(btn != null and "增益" in btn.tooltip_text, "Inspire 按钮 tooltip 仍列出四种结果")

# ------------------------------------------------------------ ② 跑真实的 BUFF 分支

func _run_buff_branch() -> void:
	print("[INSP] --- ② 走真实 _execute_llm_inspiration()（llm 桩固定返回 BUFF） ---")
	_battle.set("battle_over", true) # 先冻结自动战斗循环
	_hero = (_battle.get("heroes") as Array)[0]
	_expect(not ActionResolver.has_status(_hero, "inspired"), "激励前没有战意高涨")
	var base_dmg: int = ActionResolver.calculate_damage(_hero, {"attack_ratio": 1.0})

	# 换桩 + 解除冻结（_execute_llm_inspiration 开头会检查 battle_over）
	_battle.set("llm_client", StubLLM.new())
	_battle.set("current_actor", {"unit_type": "hero", "index": 0})
	_battle.set("battle_over", false)
	_battle.call("_execute_llm_inspiration", "圣光保佑！我们绝不会在此折戟！")
	_battle.set("battle_over", true)
	print("[INSP]   激励前基准伤害 = ", base_dmg)

# ------------------------------------------------------------ ③ 断言效果

func _assert_buff_applied() -> void:
	print("[INSP] --- ③ BUFF 分支结算结果 ---")
	_expect(ActionResolver.has_status(_hero, "inspired"), "激励后身上带有 inspired 状态")
	var statuses: Dictionary = _hero.get("statuses", {})
	_expect(int(statuses.get("inspired", {}).get("duration", 0)) == 3, "增益剩余回合 = 3")
	_expect(is_equal_approx(ActionResolver.get_attack_multiplier(_hero), 1.2), "攻击力倍率 = 1.2")
	var buffed: int = ActionResolver.calculate_damage(_hero, {"attack_ratio": 1.0})
	_expect(is_equal_approx(float(buffed), round(float(_hero.get("attack", 0)) * 1.2)), "伤害确实提升为 %d（攻击力 %d × 1.2）" % [buffed, int(_hero.get("attack", 0))])

	var lbl: Label = _battle.get("reply_status_lbl")
	_expect(lbl != null, "回复面板状态行存在")
	if lbl != null:
		print("[INSP]   状态行文本 = ", lbl.text)
		_expect("战意高涨" in lbl.text, "状态行显示「战意高涨」")
		_expect("20%" in lbl.text and "3 回合" in lbl.text, "状态行显示「20% / 3 回合」（%% 转义正确）")
		_expect(not ("暂未开放" in lbl.text), "不再出现「暂未开放」占位文案")
	var title: Label = _battle.get("reply_title_lbl")
	var body: Label = _battle.get("reply_text_lbl")
	_expect(title != null and body != null and body.text.length() > 0, "回复面板已填好台词")
