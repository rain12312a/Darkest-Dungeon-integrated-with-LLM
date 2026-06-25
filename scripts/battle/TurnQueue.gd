class_name TurnQueue
extends Node

# 当前行动队列，元素格式：{"unit_type": "hero"/"monster", "index": int}
var _queue: Array[Dictionary] = []

# -------------------------------------------------------
# 构建 & 排序
# -------------------------------------------------------

# 从存活且有剩余行动次数的单位构建队列，并立即按速度排序
func build(heroes: Array[Dictionary], monsters: Array[Dictionary]) -> void:
	_queue.clear()
	for i in range(heroes.size()):
		var h := heroes[i]
		# 英雄：存活(HP>0)或濒死状态均可行动；尸体不进入队列
		if (h["hp"] > 0 or h.get("is_death_door", false)) and h["actions_remaining"] > 0:
			_queue.append({"unit_type": "hero", "index": i})
	for i in range(monsters.size()):
		var m := monsters[i]
		# 怪物：存活且非尸体才进入队列
		if m["hp"] > 0 and not m.get("is_corpse", false) and m["actions_remaining"] > 0:
			_queue.append({"unit_type": "monster", "index": i})
	sort_by_speed(heroes, monsters)

# 按有效速度（speed + speed_delta）降序排序
func sort_by_speed(heroes: Array[Dictionary], monsters: Array[Dictionary]) -> void:
	_queue.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return _effective_speed(a, heroes, monsters) > _effective_speed(b, heroes, monsters)
	)

# -------------------------------------------------------
# 取值
# -------------------------------------------------------

# 弹出队列头部的第一个存活单位（自动跳过已死亡的条目）
# 返回空字典 {} 表示队列已耗尽
func pop_next_alive(heroes: Array[Dictionary], monsters: Array[Dictionary]) -> Dictionary:
	while not _queue.is_empty():
		var entry: Dictionary = _queue.pop_front()
		if _is_alive(entry, heroes, monsters):
			return entry
	return {}

func is_empty() -> bool:
	return _queue.is_empty()

# -------------------------------------------------------
# 状态查询
# -------------------------------------------------------

# 检查给定的英雄 / 怪物数组中是否还有任何存活单位仍有剩余行动次数
func has_remaining_actions(heroes: Array[Dictionary], monsters: Array[Dictionary]) -> bool:
	for unit in heroes:
		if (unit["hp"] > 0 or unit.get("is_death_door", false)) and unit["actions_remaining"] > 0:
			return true
	for unit in monsters:
		if unit["hp"] > 0 and not unit.get("is_corpse", false) and unit["actions_remaining"] > 0:
			return true
	return false

# -------------------------------------------------------
# 内部辅助
# -------------------------------------------------------

func _effective_speed(entry: Dictionary, heroes: Array[Dictionary], monsters: Array[Dictionary]) -> int:
	var unit: Dictionary = heroes[entry["index"]] if entry["unit_type"] == "hero" else monsters[entry["index"]]
	return unit.get("speed", 0) + unit.get("speed_delta", 0)

func _is_alive(entry: Dictionary, heroes: Array[Dictionary], monsters: Array[Dictionary]) -> bool:
	var unit: Dictionary = heroes[entry["index"]] if entry["unit_type"] == "hero" else monsters[entry["index"]]
	if entry["unit_type"] == "hero":
		return unit.get("hp", 0) > 0 or unit.get("is_death_door", false)
	return unit.get("hp", 0) > 0 and not unit.get("is_corpse", false)
