class_name HeroConfig
extends Node

# 英雄模板配置 - 集中管理所有英雄的初始配置
# 格式: "hero_id": { "name": "名字", "max_hp": 血量, "attack": 攻击力, "speed": 速度, "skills": [技能列表] }

static var HEROES: Dictionary = {
	"crusader": {
		"name": "Crusader",
		"max_hp": 50,
		"attack": 17,
		"speed": 4,
		"skills": ["slash", "heal", "holy spear", "battle_cry"],
		"personality": "恪守誓言、圣光庇护、语气庄严充满信仰。无论身处多么绝望的境地，都对神灵的力量坚信不疑。喜爱用：『圣光』、『正义』、『誓言』等词。"
	},
	"highwayman": {
		"name": "Highwayman",
		"max_hp": 40,
		"attack": 20,
		"speed": 5,
		"skills": ["shotgun", "cut", "Close-range shooting", "pistol_shot"],
		"personality": "冷酷寡言、玩世不恭、看重实用、身手敏捷。不信神佛只信手中的枪与刀，对漂亮的客套话极度抵触。喜爱用：『子弹』、『利益』、『活下去』等词。"
	}
}

# 当前战斗的英雄队伍配置
static var CURRENT_TEAM: Array[String] = ["crusader", "highwayman", "crusader", "highwayman"]

static func get_hero_template(hero_id: String) -> Dictionary:
	if hero_id in HEROES:
		var template: Dictionary = HEROES[hero_id].duplicate(true)
		template["id"] = hero_id
		template["hp"] = template["max_hp"]
		return template
	return {}

static func get_team_heroes() -> Array[Dictionary]:
	var team: Array[Dictionary] = []
	for hero_id in CURRENT_TEAM:
		var hero_template: Dictionary = get_hero_template(hero_id)
		if not hero_template.is_empty():
			team.append(hero_template)
	return team

static func hero_exists(hero_id: String) -> bool:
	return hero_id in HEROES

static func set_team(team: Array[String]) -> void:
	CURRENT_TEAM = team

static func get_all_hero_ids() -> Array[String]:
	var result: Array[String] = []
	for hero_id in HEROES.keys():
		result.append(hero_id as String)
	return result
