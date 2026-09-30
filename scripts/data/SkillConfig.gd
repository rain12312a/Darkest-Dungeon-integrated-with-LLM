class_name SkillConfig
extends Node

# 技能数据库 - 集中管理所有技能
# 格式: "skill_id": { 
#   "name": "技能名",
#   "effect_type": "damage" | "heal",
#   "target_type": "single_enemy" | "all_enemies" | "single_ally",
#   "attack_ratio": 攻击力百分比区间 [min, max]（仅damage），
#   "heal_amount": 治疗量区间 [min, max]（仅heal），
#   "move_forward": 施法者结算后位移（正数=向排头方向前进，负数=向排尾方向后退），
#   "target_move_forward": 目标结算后强制位移（正数=向排头方向拉前，负数=向排尾方向推后），
#   "status_effects": 附加状态异常数组，如 [{"status_id": "stun", "stacks": 1, "duration": 1}]
#                     （dot=true 每回合扣血；skip_turn=true 如 stun，在目标行动时判定并跳过该次行动，随后解除；
#                       damage_taken_mult>1 如 mark，使目标承受伤害提高）
#   "guard_duration": 守护类技能（effect_type: "guard"）的持续回合数
#   "stress_damage": 附加压力值伤害区间 [min, max]（仅damage，命中后对目标增加压力）
#   "target_priority": 怪物AI选目标的优先级："random" | "lowest_hp" | "highest_stress"
#   "skill_priority": 怪物AI选招的优先级（整数，默认 0）：只有最高档的候选技能参与随机，
#                      低档技能仅在高档技能不可用时兜底（例：点火员能装填就一定装填）
# }
#
# === 新增效果类型（BOSS 联动机制）===
#   "apply_status"：不造成伤害，仅向目标施加 status_effects（如首领投弹标记、点火员装填引信）
#   "summon"：召唤新单位，配合 "summon_monster_id" 使用（目标类型写 "self"）
#
# === 技能使用条件（仅对怪物生效）===
#   "requires_alive_ally": ["id"]     场上必须存在存活的这些怪物（全部满足）
#   "requires_absent_ally": ["id"]    场上必须不存在存活的这些怪物（全部满足）
#   "requires_self_status": "id"       自身必须带有该状态（如大炮需处于装填完毕）
#   "requires_self_status_absent": "id" 自身必须不带有该状态
#   "consume_self_status": "id"        技能结算后移除自身该状态（如开火后卸弹）
# === 友方目标筛选（target_type 为 single_ally / all_allies 时生效）===
#   "target_ally_id": "id"            仅能选中该 id 的友军（点火员只给大炮装填）
#   "target_ally_status_absent": "id"  身上带有该状态的友军不可选（避免重复装填）
#   "summon_monster_id": "id"          "summon" 效果要召唤的怪物 id
# 所有数值字段均支持 [min, max] 区间，结算时在区间内随机取值；
# 同时也兼容单个数值（按固定值结算）。

static var SKILLS: Dictionary = {
	# 十字军技能
	# use_positions: 可使用该技能的己方站位（1=前排，4=后排）
	# target_positions: 可命中的对方站位
	"slash": {
		"name": "Slash",
		"effect_type": "damage",
		"target_type": "single_enemy",
		"attack_ratio": [0.8, 1.2], # 90%~110% 攻击力（区间浮动）
		"description": "A strong slash attack",
		"use_positions": [1, 2],
		"target_positions": [1, 2],
		"icon_num": 1
	},
	"heal": {
		"name": "Heal",
		"effect_type": "heal",
		"target_type": "single_ally",
		"heal_amount": [3, 5],
		"description": "Restore 3~5 HP to an ally",
		"use_positions": [1, 2, 3, 4],
		"target_positions": [1, 2, 3, 4],
		"icon_num": 5
	},
	"holy spear": {
		"name": "Holy Spear",
		"effect_type": "damage",
		"target_type": "single_enemy",
		"attack_ratio": [1.1, 1.4],
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
		"description": "Inspire selected ally (Heal 1~3 HP, Heal 5~9 Stress) and clear 1~3 Stress on other allies",
		"use_positions": [1, 2, 3, 4],
		"target_positions": [1, 2, 3, 4],
		"icon_num": 7,
		"stage_one": {
			"heal_amount": [1, 2],
			"stress_heal": [5, 5]
		},
		"stage_two": {
			"stress_heal": [1, 1]
		}
	},
	
	# 强盗技能
	"shotgun": {
		"name": "Shotgun",
		"effect_type": "damage",
		"target_type": "all_enemies",
		"attack_ratio": [0.45, 0.55], # 45%~55% 攻击力（区间浮动）
		"description": "Shotgun blast to enemies at pos 1-3",
		"use_positions": [2, 3, 4],
		"target_positions": [1, 2, 3],
		"icon_num": 4
	},
	"cut": {
		"name": "Cut",
		"effect_type": "damage",
		"target_type": "single_enemy",
		"attack_ratio": [1.0, 1.2], # 100%~120% 攻击力（区间浮动）
		"description": "A quick cutting attack",
		"use_positions": [1, 2, 3],
		"target_positions": [1, 2, 3],
		"icon_num": 1
	},
	"Close-range shooting": {
		"name": "Close-range shooting",
		"effect_type": "damage",
		"target_type": "single_enemy",
		"attack_ratio": [1.4, 1.6], # 140%~160% 攻击力（区间浮动）
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
		"attack_ratio": [0.8, 1.0], # 80%~100% 攻击力（区间浮动）
		"description": "A precise pistol shot that causes Bleed and Blight",
		"use_positions": [2, 3, 4],
		"target_positions": [1, 2, 3, 4],
		"icon_num": 2,
		"status_effects": [
			{"status_id": "bleed", "stacks": 3, "duration": 3},
			{"status_id": "blight", "stacks": 2, "duration": 3}
		]
	},
	
	# 神秘学者技能
	"命运重构": {
		"name": "Wyrd Reconstruction",
		"effect_type": "heal",
		"target_type": "single_ally",
		"heal_amount": [0, 14],
		"description": "Restore 0~14 HP to an ally (unstable dark healing)",
		"use_positions": [2, 3, 4],
		"target_positions": [1, 2, 3, 4],
		"icon_num": 4
	},
	"祭祀切割": {
		"name": "Sacrificial Stab",
		"effect_type": "damage",
		"target_type": "single_enemy",
		"attack_ratio": [0.9, 1.1],
		"description": "Ritual melee stab against front ranks",
		"use_positions": [1, 2, 3],
		"target_positions": [1, 2],
		"icon_num": 1
	},
	"深渊之手": {
		"name": "Hands from the Abyss",
		"effect_type": "damage",
		"target_type": "single_enemy",
		"attack_ratio": [0.2, 0.4],
		"description": "Summon abyssal hands to strike any rank and stun the victim",
		"use_positions": [2, 3, 4],
		"target_positions": [1, 2, 3, 4],
		"icon_num": 6,
		# 晕眩：轮到目标行动时跳过其一次行动，跳过之后立即解除
		"status_effects": [
			{"status_id": "stun", "stacks": 1, "duration": 1}
		]
	},
	"灵魂之触": {
		"name": "Soul Touch",
		"effect_type": "damage",
		"target_type": "single_enemy",
		"attack_ratio": [0.3, 0.4],
		"target_move_forward": 3, # 结算后强制目标位移：正数向排头方向拉前（此处将怪物拉前3位）
		"description": "Corrupting touch that drains mind and body, dragging the victim 3 ranks forward",
		"use_positions": [3, 4],
		"target_positions": [2, 3, 4],
		"icon_num": 7
	},
	
	# 训犬师技能
	"释放猎犬": {
		"name": "Hound's Rush",
		"effect_type": "damage",
		"target_type": "single_enemy",
		"attack_ratio": [0.9, 1.1],
		"description": "Release the hound to charge any rank",
		"use_positions": [2, 3, 4],
		"target_positions": [1, 2, 3, 4],
		"icon_num": 1
	},
	"标记弱点": {
		"name": "Mark Target",
		"effect_type": "damage",
		"target_type": "single_enemy",
		"attack_ratio": [0.1, 0.2],
		"description": "A sharp whistle marks the prey, making it take +30% damage",
		"use_positions": [1, 2, 3, 4],
		"target_positions": [1, 2, 3, 4],
		"icon_num": 2,
		# 标记：被标记者承受伤害提高 30%（不含持续伤害），持续到其行动 3 次后消退
		"status_effects": [
			{"status_id": "mark", "stacks": 1, "duration": 3}
		]
	},
	"振奋犬吠": {
		"name": "Cry Havoc",
		"effect_type": "composite_heal",
		"target_type": "single_ally",
		"description": "A rallying howl that relieves the party's stress",
		"use_positions": [1, 2, 3, 4],
		"target_positions": [1, 2, 3, 4],
		"icon_num": 3,
		"stage_one": {
			"stress_heal": [6, 8]
		},
		"stage_two": {
			"stress_heal": [2, 3]
		}
	},
	"守护队友": {
		"name": "Guard Dog",
		"effect_type": "guard",
		"target_type": "single_ally",
		"guard_duration": 3, # 守护状态持续到被守护者行动 3 次
		"description": "The hound guards an ally: enemy single-target attacks are redirected to the houndmaster",
		"use_positions": [1, 2, 3, 4],
		"target_positions": [1, 2, 3, 4],
		"icon_num": 4
	},
	
	# =========================================================
	# 怪物专用技能
	# 仅由怪物使用，通过 MonsterConfig.MONSTERS[*]["skills"] 绑定；
	# 同一怪物可持有多个技能，按各自 use_positions 决定当前站位可用哪一招。
	# =========================================================
	
	# === 强盗 Cutthroat（monster_id: "cutthroat"）技能 ===
	# 前中排近战 + 后半排精神骚扰的组合型怪物
	"cutthroat_strike": {
		"name": "Cutthroat Strike",
		"effect_type": "damage",
		"target_type": "single_enemy",
		"attack_ratio": [0.9, 1.1],
		"description": "Cutthroat's basic slash attack that causes Bleed",
		"use_positions": [1, 2, 3],
		"target_positions": [1, 2],
		"target_priority": "lowest_hp",
		# 流血：每回合扣除当前层数点生命值，共结算 3 回合
		"status_effects": [
			{"status_id": "bleed", "stacks": 2, "duration": 3}
		]
	},
	# 强盗后排技能：群体精神骚扰，对敌方全体造成微量伤害并叠加压力
	"temptation": {
		"name": "Temptation",
		"effect_type": "damage",
		"target_type": "all_enemies",
		"attack_ratio": [0.45, 0.55],
		"stress_damage": [15, 25], # 对每个命中目标造成 15~25 点压力值伤害
		"description": "Inflict minor damage and accumulate 15~25 stress on every enemy",
		"use_positions": [3, 4],
		"target_positions": [1, 2, 3, 4],
		"target_priority": "highest_stress"
	},
	
	# === 骷髅弩手 Bone Arbalist（monster_id: "skeleton_arbalist"）技能 ===
	# 后排远程：远距离可射任意站位，被逼到前排时改用刺刀戳击
	"arbalist_crossbow": {
		"name": "Crossbow Shot",
		"effect_type": "damage",
		"target_type": "single_enemy",
		"attack_ratio": [1.2, 1.4],
		"description": "Aimed bolt from afar, strikes any rank",
		"use_positions": [3, 4],
		"target_positions": [1, 2, 3, 4],
		"target_priority": "random"
	},
	# 备用近战：被拉到前排时使用，只能戳前两位且优先补刀
	"arbalist_bayonet": {
		"name": "Bayonet Jab",
		"effect_type": "damage",
		"target_type": "single_enemy",
		"attack_ratio": [0.6, 0.8],
		"description": "Desperate melee stab against front ranks",
		"use_positions": [1, 2],
		"target_positions": [1, 2],
		"target_priority": "random"
	},
	
	# === 骷髅酒杯 Bone Courtier（monster_id: "skeleton_courtier"）技能 ===
	# 后排远程骚扰：群体微量伤害 + 全体压力，被拉到前排时改用单体短刀
	"courtier_goblet": {
		"name": "Goblet Toss",
		"effect_type": "damage",
		"target_type": "all_enemies",
		"attack_ratio": [0.25, 0.35],
		"stress_damage": [35, 45],
		"description": "Fling foul liquid, stressing the entire party",
		"use_positions": [3, 4],
		"target_positions": [1, 2, 3, 4],
		"target_priority": "highest_stress"
	},
	# 备用近战：被拉到前排时使用，单体伤害 + 额外压力
	"courtier_dagger": {
		"name": "Poisoned Dagger",
		"effect_type": "damage",
		"target_type": "single_enemy",
		"attack_ratio": [0.5, 0.7],
		
		"description": "Insidious stab that chips away at sanity",
		"use_positions": [1, 2],
		"target_positions": [1, 2, 3],
		"target_priority": "highest_stress"
	},
	
	# === 骷髅勇士 Bone Soldier（monster_id: "skeleton_common"）技能 ===
	# 最基础的骷髅小兵，只有一招近战斩击
	"skeleton_melee": {
		"name": "Rusty Blade",
		"effect_type": "damage",
		"target_type": "single_enemy",
		"attack_ratio": [0.9, 1.1],
		"description": "Standard skeleton slash against front ranks",
		"use_positions": [1, 2, 3, 4],
		"target_positions": [1, 2],
		"target_priority": "random"
	},
	
	# === 骷髅盾卫 Bone Defender（monster_id: "skeleton_defender"）技能 ===
	# 高血量前排坦克，斧击主伤害，盾击低伤害但附带晕眩
	"defender_axe": {
		"name": "Axe Cleave",
		"effect_type": "damage",
		"target_type": "single_enemy",
		"attack_ratio": [0.7, 0.9],
		"description": "Heavy axe blow to the frontline",
		"use_positions": [1, 2],
		"target_positions": [1, 2],
		"target_priority": "random"
	},
	# 副手技能：低伤害盾击，附带晕眩
	"defender_shield": {
		"name": "Shield Bash",
		"effect_type": "damage",
		"target_type": "single_enemy",
		"attack_ratio": [0.35, 0.45],
		"description": "Bone-rattling shield slam that stuns the victim",
		"use_positions": [1, 2],
		"target_positions": [1, 2],
		"target_priority": "lowest_hp",
		# 晕眩：轮到目标行动时跳过其一次行动，跳过之后立即解除
		"status_effects": [
			{"status_id": "stun", "stacks": 1, "duration": 1}
		]
	},
	
	# === 骷髅剑士 Bone Militia（monster_id: "skeleton_militia"）技能 ===
	# 前排斩击（附带流血）+ 后排远程削弱的双技能剑兵
	"militia_slash": {
		"name": "Militia Slash",
		"effect_type": "damage",
		"target_type": "single_enemy",
		"attack_ratio": [0.9, 1.1],
		"description": "Trained sword strike against front ranks",
		"use_positions": [1, 2],
		"target_positions": [1, 2, 3],
		"target_priority": "random",
		# 附带流血：每回合扣除当前层数点生命值，共结算 3 回合
		"status_effects": [
			{"status_id": "bleed", "stacks": 3, "duration": 3}
		]
	},
	# 后排技能：远程削弱攻击，只能打到敌方前两位，优先补刀血量最低者
	"militia_ranged": {
		"name": "Militia Ranged",
		"effect_type": "damage",
		"target_type": "single_enemy",
		"attack_ratio": [0.5, 0.7],
		"description": "Ranged attack that weakens the enemy's defense",
		"use_positions": [3, 4],
		"target_positions": [1, 2],
		"target_priority": "lowest_hp"
	},
	# === 骷髅枪兵 Bone Spearman（monster_id: "skeleton_spear"）技能 ===
	# 长手近战：站在前中排也能打到敌方后排（单点穿刺 + 全体贯穿）
	"spear_thrust": {
		"name": "Spear Thrust",
		"effect_type": "damage",
		"target_type": "single_enemy",
		"attack_ratio": [0.9, 1.1],
		"description": "Long-reach spear that pierces deep into enemy lines",
		"use_positions": [1, 2, 3],
		"target_positions": [2, 3, 4],
		"target_priority": "lowest_hp"
	},
	# 贯穿：1~3 号位可用，攻击玩家全体（AoE 下 target_priority 不生效）
	"spear_pierce": {
		"name": "Spear Pierce",
		"effect_type": "damage",
		"target_type": "all_enemies",
		"attack_ratio": [0.8, 1.0],
		"description": "Piercing spear attack that hits all enemies",
		"use_positions": [2, 3, 4],
		"target_positions": [1, 2, 3, 4],
		"target_priority": "random"
	},

	# =========================================================
	# 门前恶狼 BOSS 战（Brigand 火器小队）
	# 首领 Brigand Vvulf（brigand_sapper）
	# =========================================================
	# 投弹：不造成直接伤害，只给英雄挂上"爆破标记"。
	# 标记的引信由 BattleController 的待引爆炸药队列管理：一回合后（下个回合开始时）引爆，
	# 引爆不属于任何人的行动（不计入行动次数），属于 debuff 结算行为；
	# 若引爆时弹药桶已被摧毁，则标记转为哑弹并被直接清除。
	"sapper_throw": {
		"name": "Bomb Toss",
		"effect_type": "apply_status",
		"target_type": "single_enemy",
		"description": "Lob a bomb that marks a hero: it detonates next round for massive damage (destroy the Barrel to disarm)",
		"use_positions": [1, 2, 3, 4],
		"target_positions": [1, 2, 3, 4],
		"target_priority": "random",
		# 仅当场上仍有存活的弹药桶时才具备投弹条件
		"requires_alive_ally": ["brigand_barrel"],
		"status_effects": [
			{"status_id": "bomb_mark", "stacks": 1, "duration": 1}
		]
	},
	# 召回弹药桶：弹药桶不在场时使用（与炮击二选一，由 AI 随机决定）
	"sapper_summon": {
		"name": "Haul in a Barrel",
		"effect_type": "summon",
		"target_type": "self",
		"summon_monster_id": "brigand_barrel",
		"description": "Call in a fresh powder barrel",
		"use_positions": [1, 2, 3, 4],
		"target_positions": [1, 2, 3, 4],
		"requires_absent_ally": ["brigand_barrel"]
	},
	# 炮击：弹药桶不在场时的替代手段，只能命中敌方前两位（对两位英雄各造成一次伤害）
	"sapper_barrage": {
		"name": "Barrage",
		"effect_type": "damage",
		"target_type": "all_enemies",
		"attack_ratio": [0.5, 0.7],
		"stress_damage": [3, 6],
		"description": "Rake the front two ranks with shrapnel",
		"use_positions": [1, 2, 3, 4],
		"target_positions": [1, 2],
		"requires_absent_ally": ["brigand_barrel"]
	},

	# === 大炮 Brigand Cannon（monster_id: "brigand_cannon"）技能 ===
	# 开火：仅在"装填完毕"（点火员点完引信）时可用，对全体英雄造成高额伤害与压力，开火后卸弹
	"cannon_fire": {
		"name": "Fire!",
		"effect_type": "damage",
		"target_type": "all_enemies",
		"attack_ratio": [0.9, 1.2],
		"stress_damage": [3, 5],
		"description": "Unleash the loaded shot upon the whole party",
		"use_positions": [1, 2, 3, 4],
		"target_positions": [1, 2, 3, 4],
		"requires_self_status": "cannon_loaded",
		"consume_self_status": "cannon_loaded"
	},
	# 召回点火员：点火员不在场时使用（保证大炮始终有人伺火）
	"cannon_summon": {
		"name": "Press Gang",
		"effect_type": "summon",
		"target_type": "self",
		"summon_monster_id": "brigand_fuseman",
		"description": "Drag a new fuseman to the gun",
		"use_positions": [1, 2, 3, 4],
		"target_positions": [1, 2, 3, 4],
		"requires_absent_ally": ["brigand_fuseman"]
	},
	# 散弹：未装填且点火员在场时的普通炮击（单体，威力有限）
	"cannon_blast": {
		"name": "Scattershot",
		"effect_type": "damage",
		"target_type": "single_enemy",
		"attack_ratio": [0.6, 0.8],
		"description": "A ragged shot loaded with scrap",
		"use_positions": [1, 2, 3, 4],
		"target_positions": [1, 2, 3, 4],
		"target_priority": "random",
		"requires_alive_ally": ["brigand_fuseman"],
		"requires_self_status_absent": "cannon_loaded"
	},

	# === 点火员 Brigand Fuseman（monster_id: "brigand_fuseman"）技能 ===
	# 装填引信：给存活且尚未装填的大炮挂上"装填完毕"，使大炮下次行动时开火
	"fuseman_light_fuse": {
		"name": "Light the Fuse",
		"effect_type": "apply_status",
		"target_type": "single_ally",
		"target_ally_id": "brigand_cannon",
		"target_ally_status_absent": "cannon_loaded",
		"description": "Load the cannon: it will fire at the whole party on its next turn",
		"use_positions": [1, 2, 3, 4],
		"target_positions": [1, 2, 3, 4],
		"requires_alive_ally": ["brigand_cannon"],
		"skill_priority": 1, # 只要大炮还需装填，点火员就不会改用备选攻击
		"status_effects": [
			{"status_id": "cannon_loaded", "stacks": 1, "duration": 3}
		]
	},
	# 灼热散弹：大炮已装填（无需再点火）时的备选攻击
	"fuseman_hot_shot": {
		"name": "Hot Shot",
		"effect_type": "damage",
		"target_type": "single_enemy",
		"attack_ratio": [0.7, 0.9],
		"description": "A red-hot ball of scrap hurled at the enemy line",
		"use_positions": [1, 2, 3, 4],
		"target_positions": [1, 2, 3],
		"target_priority": "random"
	},
}

static func get_skill(skill_id: String) -> Dictionary:
	if skill_id in SKILLS:
		return SKILLS[skill_id].duplicate()
	return {}

static func skill_exists(skill_id: String) -> bool:
	return skill_id in SKILLS
