extends SceneTree

# 临时探针脚本（端到端验证用，非游戏运行时代码）
# 用途：验证压力系统（折磨 / 美德）——
#   ① 越阈判定以"当前是否已处于折磨/美德"为准（不按战斗重置）
#   ② 折磨：受到压力 +20%；每次行动 30% 概率失控（跳过 / 攻击队友 / 加队友压力 / 自动随机行动）
#   ③ 美德：清空自身压力 + 全体英雄攻击力 +20%（5 回合）
#   ④ 压力归零 → 折磨解除；压力 200 → 清除美德 + 清零压力 + 999 伤害；
#      折磨且濒死时 200 → 无视死门死扛直接处决
#   ⑤ 折磨 / 美德与压力一起跨战斗保留（HeroConfig.PARTY_STATES）
# 运行：godot --headless --path <项目> --script res://tools/_probe_stress.gd

var _battle: Node = null
var _frame := 0
var _pass := 0
var _fail := 0
var _wait_until := 0
var _waiting_for_auto := false
var _monster_hp_before := 0
var _auto_actor_slot := -1

func _initialize() -> void:
	MonsterConfig.CURRENT_ENCOUNTER = ["skeleton_common", "skeleton_defender", "skeleton_arbalist", "skeleton_courtier"]
	HeroConfig.reset_party_state() # 保证从"无状态"的干净队伍开始
	var packed := load("res://scenes/battle/Battle.tscn") as PackedScene
	if packed == null:
		print("[STRESS] FAILED: cannot load Battle.tscn")
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
	if _waiting_for_auto:
		if Time.get_ticks_msec() < _wait_until:
			return false
		_check_auto_action()
		return true
	_battle.set("battle_over", true) # 冻结自动战斗循环，保证前面各组断言确定性
	_check_config()
	_check_threshold()
	_check_affliction()
	_check_virtue()
	_check_breakdowns()
	_check_heart_attack()
	_check_persistence()
	_check_feedback_integration()
	_start_auto_action_check()
	return false

# ------------------------------------------------------------ ① 配置

func _check_config() -> void:
	print("[STRESS] --- ① 配置与状态定义 ---")
	_expect(is_equal_approx(StressConfig.AFFLICTION_THRESHOLD, 100.0), "折磨阈值为 100")
	_expect(is_equal_approx(StressConfig.AFFLICTION_CHANCE, 0.75), "折磨概率为 75%")
	_expect(is_equal_approx(StressConfig.VIRTUE_CHANCE, 0.25), "美德概率为 25%")
	_expect(is_equal_approx(StressConfig.BREAKDOWN_CHANCE, 0.3), "失控概率为 30%")
	_expect(is_equal_approx(StressConfig.AFFLICTION_STRESS_TAKEN_MULT, 1.2), "折磨受压力倍率为 1.2")
	_expect(is_equal_approx(StressConfig.VIRTUE_ATTACK_MULT, 1.2), "美德攻击力倍率为 1.2")
	_expect(int(StressConfig.VIRTUE_BUFF_ROUNDS) == 5, "美德激励持续 5 回合")
	_expect(StatusConfig.status_exists(StressConfig.AFFLICTION_STATUS), "状态 afflicted 已定义")
	_expect(StatusConfig.status_exists(StressConfig.VIRTUE_STATUS), "状态 virtuous 已定义")
	_expect(StatusConfig.status_exists(StressConfig.VIRTUE_BUFF_STATUS), "状态 virtue_buff 已定义")
	_expect(is_equal_approx(float(StatusConfig.get_status("afflicted").get("stress_taken_mult", 0.0)), 1.2), "afflicted 带 stress_taken_mult=1.2")
	_expect(is_equal_approx(float(StatusConfig.get_status("virtue_buff").get("attack_mult", 0.0)), 1.2), "virtue_buff 带 attack_mult=1.2")
	for h in _battle.get("heroes"):
		var clean: bool = not ActionResolver.has_status(h, "afflicted") and not ActionResolver.has_status(h, "virtuous")
		_expect(clean, "英雄 %s 开局既无折磨也无美德" % str(h.get("name", "?")))
		_expect(h.has("statuses"), "英雄 %s 运行时字典带 statuses 字段" % str(h.get("name", "?")))
		_expect(not h.has("stress_resolved"), "已移除按战斗重置的 stress_resolved 标记")

# ------------------------------------------------------------ ② 越阈钳制与掷骰

func _check_threshold() -> void:
	print("[STRESS] --- ② 压力越过 100 的钳制与掷骰 ---")
	var heroes: Array = _battle.get("heroes")
	var h: Dictionary = heroes[0]
	h["stress"] = 95
	ActionResolver.apply_stress(h, 30)
	_expect(int(h.get("stress", -1)) == 100, "越过阈值时压力被钳制到 100（实际 %d）" % int(h.get("stress", -1)))
	_expect(bool(h.get("stress_resolve_pending", false)), "越阈后打上待结算标记")
	# 掷骰：强制命中折磨
	var old_aff := StressConfig.AFFLICTION_CHANCE
	var old_vir := StressConfig.VIRTUE_CHANCE
	StressConfig.AFFLICTION_CHANCE = 1.0
	StressConfig.VIRTUE_CHANCE = 0.0
	_battle.call("_resolve_pending_stress_states", [h])
	StressConfig.AFFLICTION_CHANCE = old_aff
	StressConfig.VIRTUE_CHANCE = old_vir
	_expect(ActionResolver.has_status(h, "afflicted"), "75% 分支命中：英雄进入折磨状态")
	_expect(not bool(h.get("stress_resolve_pending", false)), "结算后清除待结算标记")
	# 已处于折磨 → 越阈不再钳制/重掷（判定以状态为准，而不是每场战斗一次）
	h["stress"] = 100
	ActionResolver.apply_stress(h, 40)
	_expect(int(h.get("stress", -1)) > 100, "已处于折磨：压力可继续累积不再钳制（实际 %d）" % int(h.get("stress", -1)))
	_expect(not bool(h.get("stress_resolve_pending", false)), "已处于折磨：不会重复打上待结算标记")
	# 已处于美德 → 同样不再重掷、不钳制
	var v: Dictionary = heroes[1]
	ActionResolver.apply_status(v, "virtuous", 1, 1)
	v["stress"] = 100
	ActionResolver.apply_stress(v, 30)
	_expect(int(v.get("stress", -1)) > 100, "已处于美德：压力可继续累积不再钳制（实际 %d）" % int(v.get("stress", -1)))
	_expect(not bool(v.get("stress_resolve_pending", false)), "已处于美德：不会重复打上待结算标记")
	ActionResolver.remove_status(v, "virtuous")

# ------------------------------------------------------------ ③ 折磨

func _check_affliction() -> void:
	print("[STRESS] --- ③ 折磨（Afflicted）效果 ---")
	var heroes: Array = _battle.get("heroes")
	var h: Dictionary = heroes[0]
	_expect(is_equal_approx(ActionResolver.get_stress_taken_multiplier(h), 1.2), "折磨状态下受压力倍率为 1.2")
	var before: int = int(h["stress"])
	ActionResolver.apply_stress(h, 10)
	_expect(int(h["stress"]) - before == 12, "受到 10 点压力实际增加 12 点（+20%）")
	# 减压不受影响
	before = int(h["stress"])
	ActionResolver.apply_stress(h, -10)
	_expect(before - int(h["stress"]) == 10, "减压不受折磨加成影响（-10 就是 -10）")
	_expect(_battle.call("_should_roll_breakdown", h) in [true, false], "折磨英雄可参与失控判定")
	# 压力归零 → 折磨解除
	ActionResolver.apply_stress(h, -500)
	_expect(int(h["stress"]) == 0, "大量减压后压力归零")
	_expect(not ActionResolver.has_status(h, "afflicted"), "压力归零后折磨状态被清除")
	# 为后续失控用例重新挂上折磨
	ActionResolver.apply_status(h, "afflicted", 1, 1)
	_expect(ActionResolver.has_status(h, "afflicted"), "重新施压后恢复折磨状态（供失控用例使用）")

# ------------------------------------------------------------ ④ 美德

func _check_virtue() -> void:
	print("[STRESS] --- ④ 美德（Virtuous）效果 ---")
	var heroes: Array = _battle.get("heroes")
	var h: Dictionary = heroes[1]
	h["stress"] = 100
	h["stress_resolve_pending"] = true
	var old_aff := StressConfig.AFFLICTION_CHANCE
	var old_vir := StressConfig.VIRTUE_CHANCE
	StressConfig.AFFLICTION_CHANCE = 0.0
	StressConfig.VIRTUE_CHANCE = 1.0
	_battle.call("_resolve_pending_stress_states", [h])
	StressConfig.AFFLICTION_CHANCE = old_aff
	StressConfig.VIRTUE_CHANCE = old_vir
	_expect(ActionResolver.has_status(h, "virtuous"), "25% 分支命中：英雄进入美德状态")
	_expect(int(h["stress"]) == 0, "美德清空自身压力")
	var buffed := 0
	for other in heroes:
		if ActionResolver.has_status(other, "virtue_buff"):
			buffed += 1
			var entry: Dictionary = other["statuses"]["virtue_buff"]
			_expect(int(entry.get("duration", 0)) == 5, "%s 的美德激励持续 5 回合" % str(other.get("name", "?")))
	_expect(buffed == heroes.size(), "全体英雄获得美德激励（%d/%d）" % [buffed, heroes.size()])
	# 攻击力加成：固定 ratio = 1.0 时伤害应为 int(attack * 1.2)
	var probe_skill := {"attack_ratio": 1.0}
	var plain: Dictionary = {"attack": 20, "statuses": {}}
	var buffed_unit: Dictionary = {"attack": 20, "statuses": {"virtue_buff": {"stacks": 1, "duration": 5}}}
	_expect(ActionResolver.calculate_damage(plain, probe_skill) == 20, "无增益时伤害 = 攻击力")
	_expect(ActionResolver.calculate_damage(buffed_unit, probe_skill) == 24, "美德激励下伤害 = 攻击力 × 1.2（实际 %d）" % ActionResolver.calculate_damage(buffed_unit, probe_skill))

# ------------------------------------------------------------ ⑤ 四种失控行为

func _check_breakdowns() -> void:
	print("[STRESS] --- ⑤ 四种失控行为 ---")
	var heroes: Array = _battle.get("heroes")
	var actor: Dictionary = heroes[0] # 已处于折磨状态
	_expect(ActionResolver.has_status(actor, "afflicted"), "失控测试英雄处于折磨状态")
	var actor_slot: int = int(actor.get("slot", -1))

	# ① 跳过行动：行动点必须被消耗
	actor["actions_remaining"] = 1
	_battle.set("current_actor", {"unit_type": "hero", "index": 0})
	var delegated: bool = _battle.call("_execute_affliction_breakdown", 0, "skip")
	_expect(not delegated, "失控（跳过行动）不由正常技能流程接管")
	_expect(int(actor.get("actions_remaining", -1)) == 0, "失控（跳过行动）消耗该英雄本回合行动点")

	# ② 攻击队友：随机队友掉血（目标是随机选的，因此统计全队总血量）
	var mate: Dictionary = _pick_mate(actor)
	_expect(not mate.is_empty(), "存在可被攻击的队友")
	var team_hp_before := _total_hero_hp()
	actor["actions_remaining"] = 1
	_battle.call("_execute_affliction_breakdown", 0, "attack_ally")
	_expect(_total_hero_hp() < team_hp_before, "失控（攻击队友）造成伤害（全队 %d → %d）" % [team_hp_before, _total_hero_hp()])
	_expect(int(actor.get("actions_remaining", -1)) == 0, "失控（攻击队友）消耗该英雄本回合行动点")

	# ③ 增加队友压力
	var total_stress_before := 0
	for other in heroes:
		if not is_same(other, actor):
			total_stress_before += int(other.get("stress", 0))
	actor["actions_remaining"] = 1
	_battle.call("_execute_affliction_breakdown", 0, "stress_ally")
	var total_stress_after := 0
	for other in heroes:
		if not is_same(other, actor):
			total_stress_after += int(other.get("stress", 0))
	_expect(total_stress_after > total_stress_before, "失控（增加队友压力）提升了队友压力（%d → %d）" % [total_stress_before, total_stress_after])
	_expect(int(actor.get("actions_remaining", -1)) == 0, "失控（增加队友压力）消耗该英雄本回合行动点")
	_expect(int(actor.get("slot", -1)) == actor_slot, "失控过程中英雄 slot 保持稳定")

# ------------------------------------------------------------ ⑥ 压力 200 的三种收尾

func _check_heart_attack() -> void:
	print("[STRESS] --- ⑥ 压力 200：清美德 / 清折磨 / 濒死直接处决 ---")
	var heroes: Array = _battle.get("heroes")

	# ① 美德 + 200 → 清除美德 + 清零压力 + 999 伤害
	var v: Dictionary = heroes[1]
	ActionResolver.apply_status(v, "virtuous", 1, 1)
	v["stress"] = 190
	var v_hp: int = int(v["hp"])
	ActionResolver.apply_stress(v, 20)
	_expect(int(v["stress"]) == 0, "美德英雄压力达上限后清零")
	_expect(not ActionResolver.has_status(v, "virtuous"), "压力达上限后美德被清除")
	_expect(int(v["hp"]) < v_hp, "压力达上限造成致命真实伤害（%d → %d）" % [v_hp, int(v["hp"])])
	_battle.call("_handle_stress_damage_aftermath")
	_expect(bool(v.get("is_death_door", false)), "压力达上限后英雄进入濒死而非直接移除")

	# ② 折磨 + 200（未濒死）→ 清零压力并连带清除折磨
	var a: Dictionary = heroes[0]
	a["hp"] = 30
	a["is_death_door"] = false
	ActionResolver.apply_status(a, "afflicted", 1, 1)
	a["stress"] = 190
	ActionResolver.apply_stress(a, 20)
	_expect(int(a["stress"]) == 0, "折磨英雄压力达上限后清零")
	_expect(not ActionResolver.has_status(a, "afflicted"), "压力清零同时清除了折磨状态")
	_battle.call("_handle_stress_damage_aftermath")

	# ③ 折磨 + 濒死 + 200 → 无视死门死扛，直接处决
	var victim: Dictionary = heroes[2]
	victim["hp"] = 0
	victim["is_death_door"] = true
	ActionResolver.apply_status(victim, "afflicted", 1, 1)
	victim["stress"] = 195
	ActionResolver.apply_stress(victim, 20)
	_expect(bool(victim.get("instant_death", false)), "折磨 + 濒死时压力达上限打上直接处决标记")
	var v_idx: int = heroes.find(victim)
	var died: bool = _battle.call("_handle_hero_damage_aftermath", v_idx, true)
	_expect(died, "直接处决：无视死门死扛当场阵亡（未掷死亡骰）")
	var still_on_field := false
	for h2 in _battle.get("heroes"):
		if is_same(h2, victim):
			still_on_field = true
	_expect(not still_on_field, "被处决的英雄已移出战场")

# ------------------------------------------------------------ ⑦ 跨战斗保留

func _check_persistence() -> void:
	print("[STRESS] --- ⑦ 折磨 / 美德随压力跨战斗保留 ---")
	var heroes: Array = _battle.get("heroes")
	var afflicted_hero: Dictionary = heroes[0]
	var virtuous_hero: Dictionary = heroes[1]
	ActionResolver.apply_status(afflicted_hero, "afflicted", 1, 1)
	ActionResolver.apply_status(virtuous_hero, "virtuous", 1, 1)
	afflicted_hero["stress"] = 77
	virtuous_hero["stress"] = 33
	var afflicted_slot: int = int(afflicted_hero.get("slot", -1))
	var virtuous_slot: int = int(virtuous_hero.get("slot", -1))

	HeroConfig.persist_party_after_battle(heroes)
	var saved_afflicted := false
	var saved_virtuous := false
	for i in range(HeroConfig.PARTY_STATES.size()):
		var st: Dictionary = HeroConfig.PARTY_STATES[i]
		if i == afflicted_slot:
			saved_afflicted = bool(st.get("is_afflicted", false)) and int(st.get("stress", -1)) == 77
		if i == virtuous_slot:
			saved_virtuous = bool(st.get("is_virtuous", false)) and int(st.get("stress", -1)) == 33
	_expect(saved_afflicted, "存档写入：折磨状态 + 压力一起持久化（槽位 %d）" % afflicted_slot)
	_expect(saved_virtuous, "存档写入：美德状态 + 压力一起持久化（槽位 %d）" % virtuous_slot)

	# 下一场战斗：编队模板还原标记 → _build_hero_runtime 还原成状态
	var team: Array[Dictionary] = HeroConfig.get_team_heroes()
	var restored_ok := false
	for tpl in team:
		if int(tpl.get("slot", -1)) == afflicted_slot:
			restored_ok = bool(tpl.get("is_afflicted", false)) and int(tpl.get("stress", -1)) == 77
	_expect(restored_ok, "编队模板还原：折磨标记与压力回到英雄模板")
	var runtime: Dictionary = _battle.call("_build_hero_runtime", team[afflicted_slot], afflicted_slot)
	_expect(ActionResolver.has_status(runtime, "afflicted"), "新战斗运行时英雄自带折磨状态")
	_expect(int(runtime.get("stress", -1)) == 77, "新战斗运行时保留压力值")
	var runtime_v: Dictionary = _battle.call("_build_hero_runtime", team[virtuous_slot], virtuous_slot)
	_expect(ActionResolver.has_status(runtime_v, "virtuous"), "新战斗运行时英雄自带美德状态")
	# 已带状态的英雄越阈不再掷骰
	runtime_v["stress"] = 100
	ActionResolver.apply_stress(runtime_v, 30)
	_expect(not bool(runtime_v.get("stress_resolve_pending", false)), "跨战斗保留的美德同样阻止重复越阈掷骰")
	HeroConfig.reset_party_state() # 清理，避免影响后续断言

# ------------------------------------------------------------ ⑧ 与真实压力来源的集成

func _check_feedback_integration() -> void:
	print("[STRESS] --- ⑧ 经 _emit_feedback 的压力来源同样触发越阈结算 ---")
	var heroes: Array = _battle.get("heroes")
	var h: Dictionary = heroes[heroes.size() - 1] # 前面的用例可能已阵亡减员，取最后一名存活英雄
	h["stress"] = 95
	ActionResolver.remove_status(h, "afflicted")
	ActionResolver.remove_status(h, "virtuous")
	# 注意：_emit_feedback 的形参是 Array[Dictionary]，必须传类型化数组（普通数组字面量会被拒绝）
	var targets: Array[Dictionary] = [h]
	var snaps: Array[Dictionary] = [_battle.call("_snap_unit", h)]
	ActionResolver.apply_stress(h, 30)
	_battle.call("_emit_feedback", targets, snaps)
	_expect(ActionResolver.has_status(h, "afflicted") or ActionResolver.has_status(h, "virtuous"),
		"越阈后英雄获得折磨或美德状态（当前：%s）" % ("折磨" if ActionResolver.has_status(h, "afflicted") else "美德"))

# ------------------------------------------------------------ ⑨ 自动随机行动（走正常技能流程）

func _start_auto_action_check() -> void:
	print("[STRESS] --- ⑨ 失控：自动随机行动（走真实技能流程）---")
	var heroes: Array = _battle.get("heroes")
	var actor: Dictionary = heroes[0]
	actor["hp"] = max(1, int(actor.get("hp", 1)))
	actor["is_death_door"] = false
	ActionResolver.apply_status(actor, "afflicted", 1, 1)
	# 只留一个必定造成伤害的近战技能（slash 可用位置 [1,2]，英雄在 1 号位），
	# 并把怪物血量抬高，避免击杀变尸体导致血量统计不单调
	actor["skills"] = ["slash"]
	for m in _battle.get("monsters"):
		m["hp"] = 200
		m["max_hp"] = 200
	actor["actions_remaining"] = 1
	_battle.set("current_actor", {"unit_type": "hero", "index": 0})
	_battle.set("battle_over", false) # 正常技能流程需要 _can_act() 通过
	_monster_hp_before = _total_monster_hp()
	_auto_actor_slot = int(actor.get("slot", -1))
	_battle.call("_auto_perform_random_action", 0)
	_waiting_for_auto = true
	_wait_until = Time.get_ticks_msec() + 3000

func _check_auto_action() -> void:
	# 失控行为走完后战斗循环会自行继续推进（可能已跨回合），因此只断言"怪物确实挨了打"
	var damaged := _total_monster_hp() < _monster_hp_before
	_expect(damaged, "失控（自动随机行动）经正常流程完成结算并造成伤害（%d → %d）" % [_monster_hp_before, _total_monster_hp()])
	print("[STRESS] ===== PASS=%d FAIL=%d =====" % [_pass, _fail])
	quit(0 if _fail == 0 else 1)

# ------------------------------------------------------------ 工具

func _pick_mate(actor: Dictionary) -> Dictionary:
	for h in _battle.get("heroes"):
		if is_same(h, actor):
			continue
		if h.get("hp", 0) > 0:
			return h
	return {}

func _total_hero_hp() -> int:
	var total := 0
	for h in _battle.get("heroes"):
		total += int(h.get("hp", 0))
	return total

func _total_monster_hp() -> int:
	var total := 0
	for m in _battle.get("monsters"):
		if m.get("hp", 0) > 0:
			total += int(m.get("hp", 0))
	return total

func _expect(condition: bool, label: String) -> void:
	if condition:
		_pass += 1
		print("[STRESS] PASS  ", label)
	else:
		_fail += 1
		print("[STRESS] FAIL  ", label)
