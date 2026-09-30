extends SceneTree

# 临时探针脚本（端到端验证用，非游戏运行时代码）
# 用途：不冻结战斗循环，而是逐只怪物真实调用 _execute_monster_action()，
#       走完整流程（技能筛选 → 聚焦 → 特效 → 数值结算 → 召唤/状态消耗），
#       验证 BOSS 战在真实行动管线下的行为与特效资源是否可用。
# 运行：godot --headless --path <项目> --script res://tools/_probe_boss_live.gd
# 输出中若出现 SCRIPT ERROR / 特效资源缺失警告即为异常。

const WAIT_MS := 2400 # 每次怪物行动的内部 await 合计约 1.7s，留足余量

var _battle: Node = null
var _frame := 0
var _step := -1
var _waiting := false
var _wait_until := 0
var _pass := 0
var _fail := 0
var _hp_before: Dictionary = {}

func _initialize() -> void:
	MonsterConfig.CURRENT_ENCOUNTER = ["brigand_sapper", "brigand_barrel", "brigand_fuseman", "brigand_cannon"]
	var packed := load("res://scenes/battle/Battle.tscn") as PackedScene
	if packed == null:
		print("[LIVE] FAILED: cannot load Battle.tscn")
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
	if _waiting:
		if Time.get_ticks_msec() < _wait_until:
			return false
		_waiting = false
	_step += 1
	_run_step(_step)
	return false

# ------------------------------------------------------------ 步骤驱动

func _run_step(step: int) -> void:
	match step:
		0:
			_battle.set("battle_over", true) # 停住内置自动循环，改由本脚本逐只驱动
			print("[LIVE] --- 逐只怪物执行真实行动管线 ---")
			_next()
		1:
			# ① 弹药桶在场 → 首领投弹标记
			_new_round()
			print("[LIVE] ① 首领行动（弹药桶在场）")
			_snap_heroes()
			_act(0)
		2:
			var bombs: Array = _battle.get("_pending_bombs")
			_expect(bombs.size() == 1, "首领投弹 → 登记 1 枚待引爆炸药")
			var marked := _count_marked()
			_expect(marked == 1, "英雄身上出现 bomb_mark（%d 人）" % marked)
			print("[LIVE] ② 推进到下一回合（引爆在回合开始时结算）")
			_new_round()
			_next()
		3:
			_expect(_total_hero_hp() < _total_snapshot_hp(), "炸药引爆造成伤害（%d → %d）" % [_total_snapshot_hp(), _total_hero_hp()])
			_expect(_count_marked() == 0, "引爆后标记被清除")
			_expect((_battle.get("_pending_bombs") as Array).is_empty(), "引爆炸药队列已清空")
			print("[LIVE] ③ 大炮行动（未装填，点火员在场）")
			_snap_heroes()
			_act(3)
		4:
			_expect(_total_hero_hp() < _total_snapshot_hp(), "未装填的大炮使用散弹并造成单体伤害")
			print("[LIVE] ④ 点火员行动（为大炮装填）")
			_act(2)
		5:
			var cannon: Dictionary = _battle.get("monsters")[3]
			_expect(ActionResolver.has_status(cannon, "cannon_loaded"), "点火员装填 → 大炮获得 cannon_loaded")
			print("[LIVE] ⑤ 大炮行动（装填完毕 → 全体轰击）")
			_new_round()
			_snap_heroes()
			_act(3)
		6:
			var hurt := 0
			for h in _heroes():
				var slot := int(h.get("slot", -1))
				if int(h.get("hp", 0)) < int(_hp_before.get(slot, 0)):
					hurt += 1
			_expect(hurt == _heroes().size(), "装填后的大炮对全体英雄造成伤害（%d/%d 受伤）" % [hurt, _heroes().size()])
			var cannon2: Dictionary = _battle.get("monsters")[3]
			_expect(not ActionResolver.has_status(cannon2, "cannon_loaded"), "开火后自动卸弹")
			print("[LIVE] ⑥ 摧毁弹药桶后首领行动（应召回弹药桶或炮击前排）")
			var monsters: Array = _battle.get("monsters")
			monsters[1]["hp"] = 0
			_battle.call("_handle_monster_damage_aftermath", 1)
			_new_round()
			_snap_heroes()
			_act(0)
		7:
			var barrel: Dictionary = _battle.get("monsters")[1]
			var summoned: bool = str(barrel.get("id", "")) == "brigand_barrel" and not bool(barrel.get("is_corpse", false))
			var barraged: bool = _total_hero_hp() < _total_snapshot_hp()
			_expect(summoned or barraged, "弹药桶不在场：首领%s" % ("召回了新弹药桶" if summoned else "改用炮击前排"))
			print("[LIVE] ⑦ 摧毁点火员后大炮行动（应召回点火员）")
			var monsters2: Array = _battle.get("monsters")
			monsters2[2]["hp"] = 0
			_battle.call("_handle_monster_damage_aftermath", 2)
			_new_round()
			_act(3)
		8:
			# 召唤会优先占用第一个尸体槽位（位置不固定），故只断言"场上重新出现了活着的点火员"
			var found := -1
			var monsters3: Array = _battle.get("monsters")
			for i in range(monsters3.size()):
				if str(monsters3[i].get("id", "")) == "brigand_fuseman" and not monsters3[i].get("is_corpse", false):
					found = i
			_expect(found >= 0, "点火员不在场：大炮召回了新点火员（slot=%d）" % (found + 1))
			print("[LIVE] ===== PASS=%d FAIL=%d =====" % [_pass, _fail])
			quit(0 if _fail == 0 else 1)
		_:
			quit(0 if _fail == 0 else 1)

# ------------------------------------------------------------ 工具

func _next() -> void:
	_waiting = true
	_wait_until = Time.get_ticks_msec() + 200

func _new_round() -> void:
	_battle.call("_start_new_round")

func _act(monster_idx: int) -> void:
	_battle.set("current_actor", {"unit_type": "monster", "index": monster_idx})
	_battle.set("_in_fx_pause", false)
	_battle.call("_execute_monster_action")
	_waiting = true
	_wait_until = Time.get_ticks_msec() + WAIT_MS

func _heroes() -> Array:
	return _battle.get("heroes")

func _snap_heroes() -> void:
	_hp_before.clear()
	for h in _heroes():
		_hp_before[int(h.get("slot", -1))] = int(h.get("hp", 0))

func _total_hero_hp() -> int:
	var total := 0
	for h in _heroes():
		total += int(h.get("hp", 0))
	return total

func _total_snapshot_hp() -> int:
	var total := 0
	for k in _hp_before.keys():
		total += int(_hp_before[k])
	return total

func _count_marked() -> int:
	var n := 0
	for h in _heroes():
		if ActionResolver.has_status(h, "bomb_mark"):
			n += 1
	return n

func _expect(condition: bool, label: String) -> void:
	if condition:
		_pass += 1
		print("[LIVE] PASS  ", label)
	else:
		_fail += 1
		print("[LIVE] FAIL  ", label)
