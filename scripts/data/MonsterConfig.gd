class_name MonsterConfig
extends Node

# 怪物模板配置 - 集中管理所有怪物数据
# speed_delta_base: 每轮重置的速度浮动值（负值让怪物比英雄慢）
# skills: 该怪物持有的技能 id 列表（按各自 use_positions / 使用条件自动筛选）
# inert: true 表示惰性单位（如弹药桶）：永不行动，不进入行动队列
# life_link: 生命链接的怪物 id——该怪物阵亡时，身上带 life_link 指向它的怪物一同倒下
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
		"skills": ["militia_slash", "militia_ranged"]
	},
	"skeleton_spear": {
		"id": "skeleton_spear",
		"name": "Bone Spearman",
		"max_hp": 30,
		"attack": 6,
		"speed": 5,
		"speed_delta_base": - 1,
		"skills": ["spear_thrust", "spear_pierce"]
	},
	# =========================================================
	# 门前恶狼 BOSS 战（Brigand 火器小队）
	# 参考暗黑地牢原版的 Vvulf / 迫击炮（Brigand Pounder）编队设计：
	#   · 首领：弹药桶在场时投出炸药锁定英雄（下一回合引爆）；
	#           弹药桶不在场时召回新的弹药桶，或炮击前排
	#   · 弹药桶：惰性单位，永不行动，血量偏高（摧毁它可解除首领的爆破标记）
	#   · 点火员：行动时为大炮装填引信（大炮阵亡时一同倒下）
	#   · 大炮：被装填后行动时向全体英雄开火（高额 AoE）；点火员不在场时召回点火员
	# =========================================================
	"brigand_sapper": {
		"id": "brigand_sapper",
		"name": "Brigand Vvulf",
		"max_hp": 80,
		"attack": 7,
		"speed": 5,
		"speed_delta_base": 0,
		"skills": ["sapper_throw", "sapper_summon", "sapper_barrage"]
	},
	"brigand_barrel": {
		"id": "brigand_barrel",
		"name": "Brigand Barrel",
		"max_hp": 50,
		"attack": 0,
		"speed": 0,
		"speed_delta_base": 0,
		"skills": [],
		"inert": true, # 惰性：永不行动（仅作为首领的"弹药"存在）
		"life_link": "brigand_sapper" # 首领阵亡时弹药桶随之损毁
	},
	"brigand_fuseman": {
		"id": "brigand_fuseman",
		"name": "Brigand Fuseman",
		"max_hp": 16,
		"attack": 4,
		"speed": 3,
		"speed_delta_base": - 1,
		"skills": ["fuseman_light_fuse", "fuseman_hot_shot"],
		"life_link": "brigand_cannon" # 大炮被摧毁时点火员一同倒下
	},
	"brigand_cannon": {
		"id": "brigand_cannon",
		"name": "Brigand Cannon",
		"max_hp": 60,
		"attack": 6,
		"speed": 2,
		"speed_delta_base": - 1,
		"skills": ["cannon_fire", "cannon_summon", "cannon_blast"]
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
