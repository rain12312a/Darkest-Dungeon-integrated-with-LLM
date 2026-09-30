class_name HeroConfig
extends Node

# 英雄模板配置 - 集中管理所有英雄的初始配置
# 格式: "hero_id": { "name": "名字", "max_hp": 血量, "attack": 攻击力, "speed": 速度,
#                    "skills": [技能列表], "death_blow_chance": 死门死亡概率, "personality": 性格 }
#
# 死门（Death's Door / 濒死）机制：
#   · 生命值降至 0 时不会立刻死亡，而是进入濒死状态（is_death_door = true），仍可正常行动、被治疗与受守护；
#   · 在濒死状态下【受到任何伤害】时，按 death_blow_chance 掷一次骰：命中则当场阵亡，否则继续苦苦支撑；
#   · 治疗等非伤害结算不掷骰，只要生命值回复到 0 以上即自动脱离濒死。
# death_blow_chance 写在每个角色自己的条目里（0.0~1.0）；未配置时回落到 DEFAULT_DEATH_BLOW_CHANCE。

# 死门默认死亡概率（角色未单独配置时使用）
const DEFAULT_DEATH_BLOW_CHANCE := 0.5

static var HEROES: Dictionary = {
	"crusader": {
		"name": "Crusader",
		"max_hp": 50,
		"attack": 17,
		"speed": 4,
		"skills": ["slash", "heal", "holy spear", "battle_cry"],
		"death_blow_chance": 0.5, # 死门状态（濒死）下受到伤害时的死亡概率
		"personality": "恪守誓言、圣光庇护、语气庄严充满信仰。无论身处多么绝望的境地，都对神灵的力量坚信不疑。喜爱用：『圣光』、『正义』、『誓言』等词。"
	},
	"highwayman": {
		"name": "Highwayman",
		"max_hp": 40,
		"attack": 20,
		"speed": 5,
		"skills": ["shotgun", "cut", "Close-range shooting", "pistol_shot"],
		"death_blow_chance": 0.5, # 死门状态（濒死）下受到伤害时的死亡概率
		"personality": "冷酷寡言、玩世不恭、看重实用、身手敏捷。不信神佛只信手中的枪与刀，对漂亮的客套话极度抵触。喜爱用：『子弹』、『利益』、『活下去』等词。"
	},
	"occultist": {
		"name": "Occultist",
		"max_hp": 30,
		"attack": 25,
		"speed": 3,
		"skills": ["命运重构", "祭祀切割", "深渊之手", "灵魂之触"],
		"death_blow_chance": 0.5, # 死门状态（濒死）下受到伤害时的死亡概率
		"personality": "神秘莫测、深谙黑魔法、言语晦涩。对未知力量充满渴望，不惜一切代价追求知识与力量。喜爱用：『诅咒』、『灵魂』、『黑暗』等词。"
	},
	"houndmaster": {
		"name": "Houndmaster",
		"max_hp": 45,
		"attack": 18,
		"speed": 4,
		"skills": ["释放猎犬", "标记弱点", "振奋犬吠", "守护队友"],
		"death_blow_chance": 0.5, # 死门状态（濒死）下受到伤害时的死亡概率
		"personality": "忠诚勇猛、与野兽为伍、言语粗犷。对忠诚的伙伴无比信任，对敌人则毫不留情。喜爱用：『猎物』、『犬吠』、『森林』等词。"
	}
}

# 固定初始编队（编队选择功能已移除，开始界面直接使用该组合：十字军 / 强盗 / 神秘学者 / 训犬师）
static var DEFAULT_TEAM: Array[String] = ["crusader", "highwayman", "occultist", "houndmaster"]

# 当前战斗的英雄队伍配置（开新局时由 StartController 按固定编队写入）
static var CURRENT_TEAM: Array[String] = ["crusader", "highwayman", "occultist", "houndmaster"]

# 队伍持久状态（按 CURRENT_TEAM 槽位对齐）：
# 每项为 {} 表示空槽位；{"dead": true} 表示该槽位英雄已阵亡；
# {"hp": int, "stress": int, "is_death_door": bool, "is_afflicted": bool, "is_virtuous": bool}
# 表示存活英雄的血量 / 压力 / 瀕死状态 / 折磨 / 美德
# 注：折磨与美德与压力一起**跨战斗保留**（"压力越阈后是否矫骰"看的是当前是否已有这两个状态）
static var PARTY_STATES: Array[Dictionary] = []

static func get_hero_template(hero_id: String) -> Dictionary:
	if hero_id in HEROES:
		var template: Dictionary = HEROES[hero_id].duplicate(true)
		template["id"] = hero_id
		template["hp"] = template["max_hp"]
		return template
	return {}

# 取指定角色的死门死亡概率（0.0~1.0）；未配置或未知角色时回落到默认值
static func get_death_blow_chance(hero_id: String) -> float:
	if hero_id in HEROES:
		return clampf(float(HEROES[hero_id].get("death_blow_chance", DEFAULT_DEATH_BLOW_CHANCE)), 0.0, 1.0)
	return DEFAULT_DEATH_BLOW_CHANCE

static func get_team_heroes() -> Array[Dictionary]:
	var team: Array[Dictionary] = []
	for i in range(CURRENT_TEAM.size()):
		var hero_id: String = CURRENT_TEAM[i]
		var hero_template: Dictionary = get_hero_template(hero_id)
		if hero_template.is_empty():
			continue
		hero_template["slot"] = i
		if PARTY_STATES.size() > i:
			var st: Dictionary = PARTY_STATES[i]
			if st.get("dead", false):
				continue # 阵亡英雄不再加入队伍
			if not st.is_empty():
				hero_template["hp"] = int(st.get("hp", hero_template["max_hp"]))
				hero_template["stress"] = int(st.get("stress", 0))
				hero_template["is_death_door"] = bool(st.get("is_death_door", false))
				# 折磨 / 美德跨战斗保留（由 BattleController._build_hero_runtime 还原成状态）
				hero_template["is_afflicted"] = bool(st.get("is_afflicted", false))
				hero_template["is_virtuous"] = bool(st.get("is_virtuous", false))
		team.append(hero_template)
	return team

# 战斗胜利后持久化队伍状态（按槽位对齐，阵亡槽位标记为 dead）
static func persist_party_after_battle(heroes: Array[Dictionary]) -> void:
	PARTY_STATES = []
	for i in range(CURRENT_TEAM.size()):
		var hero_id: String = CURRENT_TEAM[i]
		if hero_id == "" or not hero_exists(hero_id):
			PARTY_STATES.append({})
			continue
		var matched: Dictionary = {}
		for h in heroes:
			if int(h.get("slot", -1)) == i:
				matched = h
				break
		if matched.is_empty():
			PARTY_STATES.append({"dead": true})
		else:
			# 状态 id 取自 StressConfig（唯一来源），从原始 statuses 字典里判定，避免数据层依赖战斗层
			var battle_statuses: Dictionary = matched.get("statuses", {})
			PARTY_STATES.append({
				"hp": int(matched.get("hp", 0)),
				"stress": int(matched.get("stress", 0)),
				"is_death_door": bool(matched.get("is_death_door", false)),
				"is_afflicted": battle_statuses.has(StressConfig.AFFLICTION_STATUS),
				"is_virtuous": battle_statuses.has(StressConfig.VIRTUE_STATUS),
			})

# 开始新的一局时清空队伍状态
static func reset_party_state() -> void:
	PARTY_STATES = []

static func hero_exists(hero_id: String) -> bool:
	return hero_id in HEROES

static func set_team(team: Array[String]) -> void:
	CURRENT_TEAM = team

static func get_all_hero_ids() -> Array[String]:
	var result: Array[String] = []
	for hero_id in HEROES.keys():
		result.append(hero_id as String)
	return result
