class_name ActionResolver
extends Node

# -------------------------------------------------------
# 伤害 / 治疗 计算
# -------------------------------------------------------

# 从区间 [min, max] 中随机取一个浮点数；传入单个数值时原样返回
static func roll_range(value) -> float:
	if value is Array:
		var arr: Array = value
		if arr.size() == 2:
			return randf_range(float(arr[0]), float(arr[1]))
	return float(value)

# 从区间 [min, max] 中随机取一个整数；传入单个数值时原样返回
static func roll_range_int(value) -> int:
	if value is Array:
		var arr: Array = value
		if arr.size() == 2:
			return randi_range(int(arr[0]), int(arr[1]))
	return int(value)

# 根据技能的 attack_ratio 计算伤害值（attack_ratio 支持 [min, max] 区间）
# 两个增益分属不同乘区（字段含义见 StatusConfig 顶部说明）：
#   ① 攻击力加成 attack_mult —— **彼此加算**：如"美德激励" / "战意高涨"
#   ② 伤害加成 damage_mult  —— **彼此乘算**（最后结算）：如"狗粮"
# 伤害 = int(攻击力 × 攻击力总倍率 × attack_ratio × 伤害总倍率)
static func calculate_damage(actor: Dictionary, skill_data: Dictionary) -> int:
	var ratio: float = roll_range(skill_data.get("attack_ratio", 1.0))
	var attack_mult := get_attack_multiplier(actor)
	var damage_mult := get_damage_multiplier(actor)
	return int(float(actor.get("attack", 0)) * attack_mult * ratio * damage_mult)

# 攻击力总倍率：所有 attack_mult 状态的加成**加算**（无则 1.0）
# 例：美德激励 1.2 + 战意高涨 1.2 → 1.0 + 0.2 + 0.2 = 1.4（不是 1.44）
static func get_attack_multiplier(unit: Dictionary) -> float:
	var statuses: Dictionary = unit.get("statuses", {})
	if statuses.is_empty():
		return 1.0
	var bonus := 0.0
	for status_id in statuses.keys():
		var cfg := StatusConfig.get_status(str(status_id))
		bonus += float(cfg.get("attack_mult", 1.0)) - 1.0
	# 1.2 - 1.0 的浮点误差在加算时会累积（0.2 + 0.2 = 0.39999999999999997），
	# 不抹平的话 1.4 会变成 1.3999999999999999，乘完再 int() 截断会平白少 1 点伤害
	return snappedf(1.0 + bonus, 0.0001)

# 伤害总倍率：所有 damage_mult 状态的加成**连乘**（无则 1.0），如"狗粮"的 1.2
static func get_damage_multiplier(unit: Dictionary) -> float:
	var statuses: Dictionary = unit.get("statuses", {})
	if statuses.is_empty():
		return 1.0
	var mult := 1.0
	for status_id in statuses.keys():
		var cfg := StatusConfig.get_status(str(status_id))
		mult *= float(cfg.get("damage_mult", 1.0))
	return snappedf(mult, 0.0001)

# 对单个目标扣血（不低于 0）
# apply_mark_mult = true 时结算"标记"等易伤状态；DoT（流血/腐蚀）结算应传 false，
# 因为持续伤害不吃标记加成
static func apply_damage(target: Dictionary, amount: int, apply_mark_mult: bool = true) -> void:
	if target.is_empty():
		return
	if apply_mark_mult and amount > 0:
		var mult := get_damage_taken_multiplier(target)
		if mult != 1.0:
			amount = int(round(float(amount) * mult))
	target["hp"] = max(target.get("hp", 0) - amount, 0)

# 目标承受伤害的倍率：取所有带 damage_taken_mult 状态中的最大值（无则 1.0）
static func get_damage_taken_multiplier(target: Dictionary) -> float:
	var statuses: Dictionary = target.get("statuses", {})
	if statuses.is_empty():
		return 1.0
	var mult := 1.0
	for status_id in statuses.keys():
		var cfg := StatusConfig.get_status(str(status_id))
		mult = max(mult, float(cfg.get("damage_taken_mult", 1.0)))
	return mult

# 对单个目标回血（不超过 max_hp）
static func apply_heal(target: Dictionary, amount: int) -> void:
	if target.is_empty():
		return
	target["hp"] = min(target.get("hp", 0) + amount, target.get("max_hp", 0))

# 对单个目标施加压力
# 规则（数值见 StressConfig）：
#   · 折磨（afflicted）携带者受到的压力提高 20%（只放大加压，减压不受影响）
#   · **未处于折磨/美德状态**的英雄压力越过阈值（100）→ 钳制到阈值并打上 stress_resolve_pending 标记，
#     由战斗层（BattleController._resolve_pending_stress_states）掷骰决定"折磨 / 美德"
#   · 压力归零 → 折磨随之解除（平静下来）
#   · 达到上限（200）→ 心脏骰停：清除美德 → 压力清零（连带清除折磨）→ 999 真实伤害；
#     若此时处于折磨且已在瀕死，则打上 instant_death 标记（无视死门死扛，直接处决）
static func apply_stress(target: Dictionary, amount: int) -> void:
	if target.is_empty():
		return
	if not target.has("stress") and target.has("hp"):
		target["stress"] = 0
	
	if target.has("stress"):
		if amount > 0:
			var stress_mult := get_stress_taken_multiplier(target)
			if stress_mult != 1.0:
				amount = int(round(float(amount) * stress_mult))
		target["stress"] = clamp(target["stress"] + amount, 0, StressConfig.MAX_STRESS)
		
		# 越阈：只要该英雄当前既没有折磨也没有美德，就先钳到阈值、等待战斗层掷骰
		var can_roll: bool = not has_status(target, StressConfig.AFFLICTION_STATUS) and not has_status(target, StressConfig.VIRTUE_STATUS)
		if amount > 0 and can_roll and int(target["stress"]) > StressConfig.AFFLICTION_THRESHOLD:
			target["stress"] = StressConfig.AFFLICTION_THRESHOLD
			target["stress_resolve_pending"] = true
		
		if int(target["stress"]) >= StressConfig.MAX_STRESS:
			var at_deaths_door: bool = bool(target.get("is_death_door", false)) or int(target.get("hp", 1)) <= 0
			# ① 折磨 + 濒死：心脏骤停直接处决（无视死门死扛）
			if at_deaths_door and has_status(target, StressConfig.AFFLICTION_STATUS):
				target["instant_death"] = true
			# ② 清除美德（精神崩溃）
			remove_status(target, StressConfig.VIRTUE_STATUS)
			# ③ 压力清零（并按"压力归零"规则清除折磨）
			target["stress"] = 0
			remove_status(target, StressConfig.AFFLICTION_STATUS)
			apply_damage(target, 999)
		elif int(target["stress"]) <= 0:
			# 压力归零（美德清空 / 激励减压 / 鼓舞犬吠…）→ 折磨解除
			remove_status(target, StressConfig.AFFLICTION_STATUS)

# 心脏骤停的"直接处决"标记：由 BattleController._handle_hero_damage_aftermath 消费
static func consume_instant_death(unit: Dictionary) -> bool:
	if unit.get("instant_death", false):
		unit["instant_death"] = false
		return true
	return false

# 受到压力值的倍率：取所有带 stress_taken_mult 状态中的最大值（无则 1.0，如"折磨"的 1.2）
static func get_stress_taken_multiplier(unit: Dictionary) -> float:
	var statuses: Dictionary = unit.get("statuses", {})
	if statuses.is_empty():
		return 1.0
	var mult := 1.0
	for status_id in statuses.keys():
		var cfg := StatusConfig.get_status(str(status_id))
		mult = max(mult, float(cfg.get("stress_taken_mult", 1.0)))
	return mult

# -------------------------------------------------------
# 状态异常（DoT）支持
# -------------------------------------------------------

# 对目标施加状态异常（叠加层数并刷新持续时间）
static func apply_status(target: Dictionary, status_id: String, stacks: int = 1, duration: int = 3) -> void:
	if target.is_empty() or status_id == "" or stacks <= 0:
		return
	if not target.has("statuses"):
		target["statuses"] = {}
	var statuses: Dictionary = target["statuses"]
	if statuses.has(status_id):
		var s: Dictionary = statuses[status_id]
		s["stacks"] = int(s.get("stacks", 0)) + stacks
		s["duration"] = max(int(s.get("duration", 0)), duration)
	else:
		statuses[status_id] = {"stacks": stacks, "duration": duration}

# 该单位是否带有指定状态
static func has_status(unit: Dictionary, status_id: String) -> bool:
	if unit.is_empty() or status_id == "":
		return false
	var statuses: Dictionary = unit.get("statuses", {})
	return statuses.has(status_id)

# 移除指定状态（如消耗品"绷带"治愈流血）；实际移除返回 true
static func remove_status(unit: Dictionary, status_id: String) -> bool:
	if unit.is_empty() or status_id == "":
		return false
	if not unit.has("statuses"):
		return false
	var statuses: Dictionary = unit["statuses"]
	if not statuses.has(status_id):
		return false
	statuses.erase(status_id)
	return true

# 每回合结算一次持续伤害：扣血值 = 当前层数，随后持续时间 -1，到期移除
# 返回本次结算造成的总伤害（用于上层显示浮字/处理尸体）
static func tick_statuses(unit: Dictionary) -> int:
	if unit.is_empty():
		return 0
	var statuses: Dictionary = unit.get("statuses", {})
	if statuses.is_empty():
		return 0
	var total_damage := 0
	var expired: Array = []
	for status_id in statuses.keys():
		var s: Dictionary = statuses[status_id]
		var cfg := StatusConfig.get_status(str(status_id))
		var stacks: int = int(s.get("stacks", 0))
		if cfg.get("dot", false) and stacks > 0:
			total_damage += stacks
			# DoT 不吃"标记"等易伤加成
			apply_damage(unit, stacks, false)
		# 控制类状态（skip_turn，如晕眩）的存续由"单位行动时"的专门判定负责，
		# 不参与这里的按回合衰减，避免它在触发之前就被 duration 归零移除
		if cfg.get("skip_turn", false):
			continue
		# 事件驱动状态（manual_duration，如首领的"爆破标记"）：引爆/解除时机由 BattleController 掌握，
		# 同样不参与按回合衰减，否则它可能在炸药落地之前就自行消失
		if cfg.get("manual_duration", false):
			continue
		s["duration"] = int(s.get("duration", 0)) - 1
		if int(s.get("duration", 0)) <= 0 or stacks <= 0:
			expired.append(str(status_id))
	for status_id in expired:
		statuses.erase(status_id)
	return total_damage

# -------------------------------------------------------
# 守护（guard）支持
# -------------------------------------------------------

# 守护：把守护者绑定到目标身上，敌人单体攻击时伤害转移给守护者
# 不叠加层数，重复施放直接覆盖；守护者身份用 (id, slot) 记录——
# 英雄在战斗中会因换位改变 heroes 数组下标，但 id/slot 始终跟随本人
static func apply_guard(guardian: Dictionary, target: Dictionary, duration: int = 3) -> void:
	if guardian.is_empty() or target.is_empty():
		return
	if not target.has("statuses"):
		target["statuses"] = {}
	target["statuses"]["guard"] = {
		"stacks": 1,
		"duration": max(1, duration),
		"guardian_id": str(guardian.get("id", "")),
		"guardian_slot": int(guardian.get("slot", -1)),
	}

# -------------------------------------------------------
# 控制类状态（skip_turn）支持
# -------------------------------------------------------

# 该单位是否处于"跳过行动"类控制状态（如晕眩）
static func has_skip_turn(unit: Dictionary) -> bool:
	if unit.is_empty():
		return false
	var statuses: Dictionary = unit.get("statuses", {})
	for status_id in statuses.keys():
		var cfg := StatusConfig.get_status(str(status_id))
		if cfg.get("skip_turn", false):
			return true
	return false

# 消耗"跳过行动"类控制状态：返回 true 表示本次行动应被跳过，并立即解除该状态
# 设计约定：判定发生在单位行动时（BattleController._tick_current_actor_statuses），跳过之后即解除
static func consume_skip_turn(unit: Dictionary) -> bool:
	if not has_skip_turn(unit):
		return false
	var statuses: Dictionary = unit.get("statuses", {})
	var to_erase: Array = []
	for status_id in statuses.keys():
		var cfg := StatusConfig.get_status(str(status_id))
		if cfg.get("skip_turn", false):
			to_erase.append(status_id)
	for status_id in to_erase:
		statuses.erase(status_id)
	return true

# -------------------------------------------------------
# 技能分发 —— 根据 effect_type 自动路由到 damage / heal
# -------------------------------------------------------

# 对单个目标执行技能
static func resolve_on_target(actor: Dictionary, skill_data: Dictionary, target: Dictionary, context_allies: Array = []) -> void:
	if target.is_empty() or skill_data.is_empty():
		return
	match skill_data.get("effect_type", ""):
		"damage":
			apply_damage(target, calculate_damage(actor, skill_data))
		"heal":
			apply_heal(target, roll_range_int(skill_data.get("heal_amount", 0)))
		"composite_heal":
			# 第一段效果：对选中单位
			var s1 = skill_data.get("stage_one", {})
			if not s1.is_empty():
				if s1.has("heal_amount"):
					apply_heal(target, roll_range_int(s1["heal_amount"]))
				if s1.has("stress_heal"):
					apply_stress(target, -roll_range_int(s1["stress_heal"]))
			
			# 第二段效果：对除选中单位外的其他所有友方单位
			var s2 = skill_data.get("stage_two", {})
			if not s2.is_empty() and not context_allies.is_empty():
				for a in context_allies:
					if a.get("hp", 0) > 0 and not is_same(a, target):
						if s2.has("heal_amount"):
							apply_heal(a, roll_range_int(s2["heal_amount"]))
						if s2.has("stress_heal"):
							apply_stress(a, -roll_range_int(s2["stress_heal"]))
		"guard":
			# 守护：把施法者登记为目标身上的"守护者"
			apply_guard(actor, target, int(skill_data.get("guard_duration", 3)))
	var stress_dmg := roll_range_int(skill_data.get("stress_damage", 0))
	if stress_dmg > 0:
		apply_stress(target, stress_dmg)

	# 施加技能附带的状态异常（如流血/腐蚀等 DoT）
	var status_effects: Array = skill_data.get("status_effects", [])
	for se in status_effects:
		apply_status(target, str(se.get("status_id", "")), int(se.get("stacks", 1)), int(se.get("duration", 3)))

# 对数组中所有存活目标执行技能（用于 all_enemies / all_allies 类型）
static func resolve_on_all(actor: Dictionary, skill_data: Dictionary, targets: Array[Dictionary]) -> void:
	if skill_data.is_empty():
		return
	for target in targets:
		if target.get("hp", 0) > 0:
			resolve_on_target(actor, skill_data, target)
