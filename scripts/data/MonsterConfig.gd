class_name MonsterConfig
extends Node

# 怪物模板配置 - 集中管理所有怪物数据
# speed_delta_base: 每轮重置的速度浮动值（负值让怪物比英雄慢）
static var MONSTERS: Dictionary = {
	"cutthroat": {
		"id": "cutthroat",
		"name": "Cutthroat",
		"max_hp": 40,
		"attack": 5,
		"speed": 4,
		"speed_delta_base": - 1,
		"skills": ["cutthroat_strike", "temptation"]
	},
	"troll": {
		"id": "troll",
		"name": "Troll",
		"max_hp": 60,
		"attack": 5,
		"speed": 3,
		"speed_delta_base": - 2,
		"skills": ["troll_smash"]
	},
	# === 骷髅系怪物 ===
	"skeleton_arbalist": {
		"id": "skeleton_arbalist",
		"name": "Bone Arbalist",
		"max_hp": 27,
		"attack": 7,
		"speed": 5,
		"speed_delta_base": - 1,
		"skills": ["arbalist_crossbow", "arbalist_bayonet"]
	},
	"skeleton_courtier": {
		"id": "skeleton_courtier",
		"name": "Bone Courtier",
		"max_hp": 22,
		"attack": 4,
		"speed": 6,
		"speed_delta_base": - 1,
		"skills": ["courtier_goblet", "courtier_dagger"]
	},
	"skeleton_common": {
		"id": "skeleton_common",
		"name": "Bone Soldier",
		"max_hp": 32,
		"attack": 5,
		"speed": 4,
		"speed_delta_base": - 1,
		"skills": ["skeleton_melee"]
	},
	"skeleton_defender": {
		"id": "skeleton_defender",
		"name": "Bone Defender",
		"max_hp": 45,
		"attack": 3,
		"speed": 2,
		"speed_delta_base": - 2,
		"skills": ["defender_axe", "defender_shield"]
	},
	"skeleton_militia": {
		"id": "skeleton_militia",
		"name": "Bone Militia",
		"max_hp": 30,
		"attack": 5,
		"speed": 4,
		"speed_delta_base": - 1,
		"skills": ["militia_slash"]
	},
	"skeleton_spear": {
		"id": "skeleton_spear",
		"name": "Bone Spearman",
		"max_hp": 30,
		"attack": 6,
		"speed": 5,
		"speed_delta_base": - 1,
		"skills": ["spear_thrust"]
	},
}

# 当前关卡的遭遇怪物列表（可按关卡覆盖）
static var CURRENT_ENCOUNTER: Array[String] = ["skeleton_common", "skeleton_defender", "skeleton_arbalist", "skeleton_courtier"]

# 获取怪物模板（深拷贝，附加运行时字段 id / hp）
static func get_monster_template(monster_id: String) -> Dictionary:
	if monster_id in MONSTERS:
		var template: Dictionary = MONSTERS[monster_id].duplicate(true)
		template["id"] = monster_id
		template["hp"] = template["max_hp"]
		return template
	return {}

# 根据 CURRENT_ENCOUNTER 构建本场战斗的怪物列表
static func get_encounter_monsters() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for monster_id in CURRENT_ENCOUNTER:
		var template: Dictionary = get_monster_template(monster_id)
		if not template.is_empty():
			result.append(template)
	return result

static func monster_exists(monster_id: String) -> bool:
	return monster_id in MONSTERS

static func get_all_monster_ids() -> Array[String]:
	var result: Array[String] = []
	for monster_id in MONSTERS.keys():
		result.append(monster_id as String)
	return result
