class_name ConsumableConfig
extends Node

# 消耗品配置 - 集中管理所有消耗品
# 格式: "item_id": {
#   "name": 显示名称,
#   "icon": 图标路径,
#   "heal": 使用后回复的生命值（恢复类，如食物），
#   "cure_status": 使用后治愈的状态 id 数组（治愈类，如绷带的 ["bleed"]），
#   "buff_status": 使用后附加的状态 id（增益类，如狗粮的 dogfood_buff），
#   "buff_duration": 增益状态持续的回合数（配合 buff_status 使用）
# }
# 三类效果可单用也可共存：先结算治愈，再结算增益，最后结算回复。

static var ITEMS: Dictionary = {
	"food": {
		"name": "Food",
		"icon": "res://panels/icons_equip/provision/inv_provision+_3.png",
		"heal": 2,
		"description": "在战斗中使用，为当前行动的英雄恢复少量生命。",
	},
	"bandage": {
		"name": "Bandage",
		"icon": "res://panels/icons_equip/supply/inv_supply+bandage.png",
		# 治愈类：移除目标身上的流血（DoT），在流血结算扣血前使用可救回残血英雄
		"cure_status": ["bleed"],
		"description": "在战斗中使用，为当前行动的英雄治愈流血效果。",
	},
	"dogfood": {
		"name": "Dog Food",
		"icon": "res://panels/icons_equip/supply/inv_supply+dog_treats.png",
		# 增益类：为当前行动的英雄附加攻击力增益（伤害 +20%，持续 1 回合）
		"buff_status": "dogfood_buff",
		"buff_duration": 1,
		"description": "在战斗中使用，使当前行动的英雄伤害提高 20%，持续 1 回合。",
	}
}

# 消耗品背包：最多 16 个格子，同种消耗品无限堆叠（count 可无限累加）
# 每个槽位格式：{"item_id": String, "count": int}
# 默认携带初始补给，方便直接运行战斗场景调试
static var INVENTORY: Array[Dictionary] = [
	{"item_id": "food", "count": 4},
	{"item_id": "bandage", "count": 2},
	{"item_id": "dogfood", "count": 2}
]

const MAX_SLOTS := 16

# 开始新的一局时重置背包，并发放初始补给（食物 4 / 绷带 2 / 狗粮 2）
static func reset_inventory(initial_food: int = 4, initial_bandage: int = 2, initial_dogfood: int = 2) -> void:
	INVENTORY = []
	if initial_food > 0 and ("food" in ITEMS):
		INVENTORY.append({"item_id": "food", "count": initial_food})
	if initial_bandage > 0 and ("bandage" in ITEMS):
		INVENTORY.append({"item_id": "bandage", "count": initial_bandage})
	if initial_dogfood > 0 and ("dogfood" in ITEMS):
		INVENTORY.append({"item_id": "dogfood", "count": initial_dogfood})

# 向背包中添加消耗品；同种物品堆叠，新种类占用新格子（受 16 格上限约束）
static func add_item(item_id: String, amount: int) -> bool:
	if amount <= 0 or not (item_id in ITEMS):
		return false
	for slot in INVENTORY:
		if slot.get("item_id", "") == item_id:
			slot["count"] = int(slot.get("count", 0)) + amount
			return true
	if INVENTORY.size() < MAX_SLOTS:
		INVENTORY.append({"item_id": item_id, "count": amount})
		return true
	return false

static func get_count(item_id: String) -> int:
	for slot in INVENTORY:
		if slot.get("item_id", "") == item_id:
			return int(slot.get("count", 0))
	return 0

# 消耗指定数量的消耗品；数量不足时返回 false
static func consume_item(item_id: String, amount: int = 1) -> bool:
	if amount <= 0 or not (item_id in ITEMS):
		return false
	for i in range(INVENTORY.size()):
		var slot: Dictionary = INVENTORY[i]
		if slot.get("item_id", "") == item_id:
			var count: int = int(slot.get("count", 0))
			if count < amount:
				return false
			count -= amount
			if count <= 0:
				INVENTORY.remove_at(i)
			else:
				slot["count"] = count
			return true
	return false

static func get_item(item_id: String) -> Dictionary:
	if item_id in ITEMS:
		return ITEMS[item_id].duplicate(true)
	return {}
