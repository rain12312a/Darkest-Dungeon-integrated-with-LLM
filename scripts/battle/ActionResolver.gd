class_name ActionResolver
extends Node

# -------------------------------------------------------
# 伤害 / 治疗 计算
# -------------------------------------------------------

# 根据技能的 attack_ratio 计算伤害值
static func calculate_damage(actor: Dictionary, skill_data: Dictionary) -> int:
	var ratio: float = skill_data.get("attack_ratio", 1.0)
	return int(actor.get("attack", 0) * ratio)

# 对单个目标扣血（不低于 0）
static func apply_damage(target: Dictionary, amount: int) -> void:
	if target.is_empty():
		return
	target["hp"] = max(target.get("hp", 0) - amount, 0)

# 对单个目标回血（不超过 max_hp）
static func apply_heal(target: Dictionary, amount: int) -> void:
	if target.is_empty():
		return
	target["hp"] = min(target.get("hp", 0) + amount, target.get("max_hp", 0))

# 对单个目标施加压力（上限为 200，满则受到 999 伤害并通过重设清零）
static func apply_stress(target: Dictionary, amount: int) -> void:
	if target.is_empty():
		return
	if not target.has("stress") and target.has("hp"):
		target["stress"] = 0
		
	if target.has("stress"):
		target["stress"] = clamp(target["stress"] + amount, 0, 200)
		if target["stress"] >= 200:
			target["stress"] = 0
			apply_damage(target, 999)

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
			apply_heal(target, skill_data.get("heal_amount", 0))
		"composite_heal":
			# 第一段效果：对选中单位
			var s1 = skill_data.get("stage_one", {})
			if not s1.is_empty():
				if s1.has("heal_amount"):
					apply_heal(target, s1["heal_amount"])
				if s1.has("stress_heal"):
					apply_stress(target, -int(s1["stress_heal"]))
			
			# 第二段效果：对除选中单位外的其他所有友方单位
			var s2 = skill_data.get("stage_two", {})
			if not s2.is_empty() and not context_allies.is_empty():
				for a in context_allies:
					if a.get("hp", 0) > 0 and not is_same(a, target):
						if s2.has("heal_amount"):
							apply_heal(a, s2["heal_amount"])
						if s2.has("stress_heal"):
							apply_stress(a, -int(s2["stress_heal"]))
			
	var stress_dmg := int(skill_data.get("stress_damage", 0))
	if stress_dmg > 0:
		apply_stress(target, stress_dmg)

# 对数组中所有存活目标执行技能（用于 all_enemies / all_allies 类型）
static func resolve_on_all(actor: Dictionary, skill_data: Dictionary, targets: Array[Dictionary]) -> void:
	if skill_data.is_empty():
		return
	for target in targets:
		if target.get("hp", 0) > 0:
			resolve_on_target(actor, skill_data, target)
