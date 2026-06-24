class_name SkillConfig
extends Node

# 技能数据库 - 集中管理所有技能
# 格式: "skill_id": { 
#   "name": "技能名",
#   "effect_type": "damage" | "heal",
#   "target_type": "single_enemy" | "all_enemies" | "single_ally",
#   "attack_ratio": 攻击力百分比（仅damage），
#   "heal_amount": 治疗量（仅heal）
# }

static var SKILLS: Dictionary = {
	# 十字军技能
	# use_positions: 可使用该技能的己方站位（1=前排，4=后排）
	# target_positions: 可命中的对方站位
	"slash": {
		"name": "Slash",
		"effect_type": "damage",
		"target_type": "single_enemy",
		"attack_ratio": 1.0, # 100% 攻击力
		"description": "A strong slash attack",
		"use_positions": [1, 2],
		"target_positions": [1, 2],
		"icon_num": 1
	},
	"heal": {
		"name": "Heal",
		"effect_type": "heal",
		"target_type": "single_ally",
		"heal_amount": 10,
		"description": "Restore 10 HP to an ally",
		"use_positions": [1, 2, 3, 4],
		"target_positions": [1, 2, 3, 4],
		"icon_num": 5
	},
	"holy spear": {
		"name": "Holy Spear",
		"effect_type": "damage",
		"target_type": "single_enemy",
		"attack_ratio": 1.2,
		"description": "前进1，攻击234",
		"use_positions": [2, 3, 4],
		"target_positions": [2, 3, 4],
		"move_forward": 1,
		"icon_num": 6
	},
	#新建激励呐喊技能
	"battle_cry": {
		"name": "Battle Cry",
		"effect_type": "composite_heal",
		"target_type": "single_ally",
		"description": "Inspire selected ally (Heal 2 HP, Heal 7 Stress) and clear 2 Stress on other allies",
		"use_positions": [1, 2, 3, 4],
		"target_positions": [1, 2, 3, 4],
		"icon_num": 7,
		"stage_one": {
			"heal_amount": 2,
			"stress_heal": 7
		},
		"stage_two": {
			"stress_heal": 2
		}
	},
	
	# 强盗技能
	"shotgun": {
		"name": "Shotgun",
		"effect_type": "damage",
		"target_type": "all_enemies",
		"attack_ratio": 0.5, # 50% 攻击力
		"description": "Shotgun blast to enemies at pos 1-3",
		"use_positions": [2, 3, 4],
		"target_positions": [1, 2, 3],
		"icon_num": 4
	},
	"cut": {
		"name": "Cut",
		"effect_type": "damage",
		"target_type": "single_enemy",
		"attack_ratio": 1.1, # 110% 攻击力
		"description": "A quick cutting attack",
		"use_positions": [1, 2, 3],
		"target_positions": [1, 2, 3],
		"icon_num": 1
	},
	"Close-range shooting": {
		"name": "Close-range shooting",
		"effect_type": "damage",
		"target_type": "single_enemy",
		"attack_ratio": 1.5, # 150% 攻击力
		"description": "Close-range shooting to an enemy at pos 1",
		"use_positions": [1],
		"target_positions": [1],
		"move_forward": - 1,
		"icon_num": 3
	},
	#手枪射击
	"pistol_shot": {
		"name": "Pistol Shot",
		"effect_type": "damage",
		"target_type": "single_enemy",
		"attack_ratio": 0.9, # 90% 攻击力
		"description": "A precise pistol shot to an enemy at pos 1",
		"use_positions": [2, 3, 4],
		"target_positions": [1,2,3,4],
		"icon_num": 2
	},
	
	# 怪物专用技能
	"cutthroat_strike": {
		"name": "Cutthroat Strike",
		"effect_type": "damage",
		"target_type": "single_enemy",
		"attack_ratio": 1.0,
		"description": "Cutthroat's basic slash attack",
		"use_positions": [1, 2, 3],
		"target_positions": [1, 2],
		"target_priority": "lowest_hp"
	},
	"temptation": {
		"name": "Temptation",
		"effect_type": "damage",
		"target_type": "single_enemy",
		"attack_ratio": 0.5,
		"stress_damage": 30, # 造成 30 点压力值伤害词条
		"description": "Inflict minor damage and accumulate 30 stress on critical hit thoughts",
		"use_positions": [3, 4],
		"target_positions": [1, 2, 3, 4],
		"target_priority": "highest_stress"
	},
	"troll_smash": {
		"name": "Troll Smash",
		"effect_type": "damage",
		"target_type": "single_enemy",
		"attack_ratio": 1.2,
		"description": "A heavy blunt attack from Troll",
		"use_positions": [1, 2],
		"target_positions": [1, 2],
		"target_priority": "random"
	},
	
	# === 骷髅弩手技能 ===
	"arbalist_crossbow": {
		"name": "Crossbow Shot",
		"effect_type": "damage",
		"target_type": "single_enemy",
		"attack_ratio": 1.3,
		"description": "Aimed bolt from afar, strikes any rank",
		"use_positions": [3, 4],
		"target_positions": [1, 2, 3, 4],
		"target_priority": "random"
	},
	"arbalist_bayonet": {
		"name": "Bayonet Jab",
		"effect_type": "damage",
		"target_type": "single_enemy",
		"attack_ratio": 0.7,
		"description": "Desperate melee stab against front ranks",
		"use_positions": [1, 2],
		"target_positions": [1, 2],
		"target_priority": "lowest_hp"
	},
	
	# === 骷髅酒杯技能 ===
	"courtier_goblet": {
		"name": "Goblet Toss",
		"effect_type": "damage",
		"target_type": "all_enemies",
		"attack_ratio": 0.3,
		"stress_damage": 15,
		"description": "Fling foul liquid, stressing the entire party",
		"use_positions": [3, 4],
		"target_positions": [1, 2, 3, 4],
		"target_priority": "highest_stress"
	},
	"courtier_dagger": {
		"name": "Poisoned Dagger",
		"effect_type": "damage",
		"target_type": "single_enemy",
		"attack_ratio": 0.6,
		"stress_damage": 20,
		"description": "Insidious stab that chips away at sanity",
		"use_positions": [1, 2],
		"target_positions": [1, 2, 3],
		"target_priority": "highest_stress"
	},
	
	# === 骷髅勇士技能 ===
	"skeleton_melee": {
		"name": "Rusty Blade",
		"effect_type": "damage",
		"target_type": "single_enemy",
		"attack_ratio": 1.0,
		"description": "Standard skeleton slash against front ranks",
		"use_positions": [1, 2, 3],
		"target_positions": [1, 2],
		"target_priority": "random"
	},
	
	# === 骷髅盾卫技能 ===
	"defender_axe": {
		"name": "Axe Cleave",
		"effect_type": "damage",
		"target_type": "single_enemy",
		"attack_ratio": 0.8,
		"description": "Heavy axe blow to the frontline",
		"use_positions": [1, 2],
		"target_positions": [1, 2],
		"target_priority": "random"
	},
	"defender_shield": {
		"name": "Shield Bash",
		"effect_type": "damage",
		"target_type": "single_enemy",
		"attack_ratio": 0.5,
		"stress_damage": 10,
		"description": "Bone-rattling shield slam that staggers the mind",
		"use_positions": [1, 2],
		"target_positions": [1, 2],
		"target_priority": "lowest_hp"
	},
	
	# === 骷髅剑士技能 ===
	"militia_slash": {
		"name": "Militia Slash",
		"effect_type": "damage",
		"target_type": "single_enemy",
		"attack_ratio": 1.0,
		"description": "Trained sword strike against front ranks",
		"use_positions": [1, 2, 3],
		"target_positions": [1, 2],
		"target_priority": "random"
	},
	
	# === 骷髅枪兵技能 ===
	"spear_thrust": {
		"name": "Spear Thrust",
		"effect_type": "damage",
		"target_type": "single_enemy",
		"attack_ratio": 1.0,
		"description": "Long-reach spear that pierces deep into enemy lines",
		"use_positions": [1, 2, 3],
		"target_positions": [2, 3, 4],
		"target_priority": "lowest_hp"
	}
}

static func get_skill(skill_id: String) -> Dictionary:
	if skill_id in SKILLS:
		return SKILLS[skill_id].duplicate()
	return {}

static func skill_exists(skill_id: String) -> bool:
	return skill_id in SKILLS
