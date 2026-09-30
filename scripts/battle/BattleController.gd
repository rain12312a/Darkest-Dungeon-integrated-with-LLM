extends Node

signal return_to_start
# 激励回应窗口被玩家点击“确定”后发出（_execute_llm_inspiration 等待它再推进回合）
signal reply_confirmed

# 英雄位置对应的每轮速度浮动值（位置 0 最快，3 最慢）
const SPEED_DELTA_RANGE := 4 # 速度浮动范围：每轮随机 [-4, +4]

# Spine 动画资源路径（每个动作对应独立的 skel/atlas 文件）
const CRUSADER_ANIM_BASE := "res://characters/crusader/anim/crusader.sprite."
const CRUSADER_PNG_DIR := "res://characters/crusader/crusader_A/anim"
const CRUSADER_ANIM_MAP := {
	"idle": "idle",
	"attack": "attack_sword",
	"heal": "attack_heal",
	"attack_charge": "attack_charge", # 十字军的圣矛动作
	"defend": "defend",
	"combat": "combat",
	"heroic": "heroic",
	"walk": "walk",
}

const HIGHWAYMAN_ANIM_BASE := "res://characters/highwayman/anim/highwayman.sprite."
const HIGHWAYMAN_PNG_DIR := "res://characters/highwayman/highwayman_A/anim"
const HIGHWAYMAN_ANIM_MAP := {
	"idle": "idle",
	"attack": "attack_pistol",
	"attack2": "attack_slice",
	"defend": "defend",
	"combat": "combat",
	"heroic": "heroic",
	"walk": "walk",
}

const OCCULTIST_ANIM_BASE := "res://characters/occultist/anim/occultist.sprite."
const OCCULTIST_PNG_DIR := "res://characters/occultist/occultist_A/anim"
const OCCULTIST_ANIM_MAP := {
	"idle": "idle",
	"attack": "attack_melee", # 祭祀切割
	"attack2": "attack_skull", # 深渊之手
	"attack3": "attack_ranged", # 灵魂之触
	"heal": "attack_heal", # 命运重构
	"defend": "defend",
	"combat": "combat",
	"heroic": "heroic",
	"walk": "walk",
}

const HOUNDMASTER_ANIM_BASE := "res://characters/houndmaster/anim/houndmaster.sprite."
const HOUNDMASTER_PNG_DIR := "res://characters/houndmaster/houndmaster_A/anim"
const HOUNDMASTER_ANIM_MAP := {
	"idle": "idle",
	"attack": "attack_rush", # 释放猎犬
	"attack2": "attack_point", # 标记弱点
	"attack3": "attack_howl", # 振奋犬吠
	"attack4": "attack_guard", # 守护队友
	"defend": "defend",
	"combat": "combat",
	"heroic": "heroic",
	"walk": "walk",
}

# 拥有 Spine 立绘资源的英雄 id（_setup_battle 据此为其创建 SpinePlayer）
const HERO_SPINE_IDS := ["crusader", "highwayman", "occultist", "houndmaster"]

# 共享死亡特效（death_medium），覆盖在死亡角色上
const DEATH_MEDIUM_BASE := "res://death_medium/death_medium.sprite"
const DEATH_MEDIUM_PNG_DIR := "res://death_medium"

const CUTTHROAT_ANIM_BASE := "res://monsters/brigand_cutthroat/anim/brigand_cutthroat.sprite."
const CUTTHROAT_PNG_DIR := "res://monsters/brigand_cutthroat/anim"
const CUTTHROAT_ANIM_MAP := {
	"idle": "combat",
	"attack": "attack_lunge",
	"attack2": "attack_uppercut",
	"defend": "defend",
	"combat": "combat",
	"heroic": "combat",
	"walk": "combat",
	"dead": "dead",
}

# === 骷髅弩手 ===
const SKELETON_ARBALIST_ANIM_BASE := "res://monsters/skeleton_arbalist/anim/skeleton_arbalist.sprite."
const SKELETON_ARBALIST_PNG_DIR := "res://monsters/skeleton_arbalist/anim"
const SKELETON_ARBALIST_ANIM_MAP := {
	"idle": "combat",
	"attack": "attack_crossbow",
	"attack2": "attack_bayonet",
	"defend": "defend",
	"combat": "combat",
	"heroic": "combat",
	"walk": "combat",
	"dead": "dead",
}

# === 骷髅酒杯 ===
const SKELETON_COURTIER_ANIM_BASE := "res://monsters/skeleton_courtier/anim/skeleton_courtier.sprite."
const SKELETON_COURTIER_PNG_DIR := "res://monsters/skeleton_courtier/anim"
const SKELETON_COURTIER_ANIM_MAP := {
	"idle": "combat",
	"attack": "attack_goblet",
	"attack2": "attack_dagger",
	"defend": "defend",
	"combat": "combat",
	"heroic": "combat",
	"walk": "combat",
	"dead": "dead",
}

# === 骷髅勇士 ===
const SKELETON_COMMON_ANIM_BASE := "res://monsters/skeleton_common/anim/skeleton_common.sprite."
const SKELETON_COMMON_PNG_DIR := "res://monsters/skeleton_common/anim"
const SKELETON_COMMON_ANIM_MAP := {
	"idle": "combat",
	"attack": "attack_melee",
	"defend": "defend",
	"combat": "combat",
	"heroic": "combat",
	"walk": "combat",
	"dead": "dead",
}

# === 骷髅盾卫 ===
const SKELETON_DEFENDER_ANIM_BASE := "res://monsters/skeleton_defender/anim/skeleton_defender.sprite."
const SKELETON_DEFENDER_PNG_DIR := "res://monsters/skeleton_defender/anim"
const SKELETON_DEFENDER_ANIM_MAP := {
	"idle": "combat",
	"attack": "attack_axe",
	"attack2": "attack_shield",
	"defend": "defend",
	"combat": "combat",
	"heroic": "combat",
	"walk": "combat",
	"dead": "dead",
}

# === 骷髅剑士 ===
const SKELETON_MILITIA_ANIM_BASE := "res://monsters/skeleton_militia/anim/skeleton_militia.sprite."
const SKELETON_MILITIA_PNG_DIR := "res://monsters/skeleton_militia/anim"
const SKELETON_MILITIA_ANIM_MAP := {
	"idle": "combat",
	"attack": "attack_melee",
	"defend": "defend",
	"combat": "combat",
	"heroic": "combat",
	"walk": "combat",
	"dead": "dead",
}

# === 骷髅枪兵 ===
const SKELETON_SPEAR_ANIM_BASE := "res://monsters/skeleton_spear/anim/skeleton_spear.sprite."
const SKELETON_SPEAR_PNG_DIR := "res://monsters/skeleton_spear/anim"
const SKELETON_SPEAR_ANIM_MAP := {
	"idle": "combat",
	"attack": "attack_spear",
	"defend": "defend",
	"combat": "combat",
	"heroic": "combat",
	"walk": "combat",
	"dead": "dead",
}

# === 门前恶狼 BOSS 战：首领 Brigand Vvulf ===
# 该资源没有独立的 idle/dead 动作，待机与尸体一律沿用 combat 姿态
const BRIGAND_SAPPER_ANIM_BASE := "res://monsters/brigand_sapper/anim/brigand_sapper.sprite."
const BRIGAND_SAPPER_PNG_DIR := "res://monsters/brigand_sapper/anim"
const BRIGAND_SAPPER_ANIM_MAP := {
	"idle": "combat",
	"attack": "attack_ranged", # 炸弹投掷 / 弹幕炮击
	"attack2": "attack_shout", # 召回弹药桶
	"defend": "defend",
	"combat": "combat",
	"heroic": "combat",
	"walk": "combat",
	"dead": "combat",
}

# === 大炮 Brigand Cannon ===
const BRIGAND_CANNON_ANIM_BASE := "res://monsters/brigand_cannon/anim/brigand_cannon.sprite."
const BRIGAND_CANNON_PNG_DIR := "res://monsters/brigand_cannon/anim"
const BRIGAND_CANNON_ANIM_MAP := {
	"idle": "combat",
	"attack": "attack_ranged", # 开火 / 散弹
	"attack2": "attack_summon", # 召回点火员
	"defend": "defend",
	"combat": "combat",
	"heroic": "combat",
	"walk": "combat",
	"dead": "combat",
}

# === 点火员 Brigand Fuseman ===
const BRIGAND_FUSEMAN_ANIM_BASE := "res://monsters/brigand_fuseman/anim/brigand_fuseman.sprite."
const BRIGAND_FUSEMAN_PNG_DIR := "res://monsters/brigand_fuseman/anim"
const BRIGAND_FUSEMAN_ANIM_MAP := {
	"idle": "combat",
	"attack": "attack_ignite", # 装填引信
	"attack2": "attack_burn", # 灼热散弹
	"defend": "defend",
	"combat": "combat",
	"heroic": "combat",
	"walk": "combat",
	"dead": "combat",
}

# === 弹药桶 Brigand Barrel（惰性单位，永不行动）===
const BRIGAND_BARREL_ANIM_BASE := "res://monsters/brigand_barrel/anim/brigand_barrel.sprite."
const BRIGAND_BARREL_PNG_DIR := "res://monsters/brigand_barrel/anim"
const BRIGAND_BARREL_ANIM_MAP := {
	"idle": "combat",
	"attack": "combat",
	"defend": "defend",
	"combat": "combat",
	"heroic": "combat",
	"walk": "combat",
	"dead": "combat",
}

# 怪物 Spine 资源索引表：monster_id → {base: 动画前缀, dir: PNG 目录, map: 状态→动画名}
# 新增怪物只需在此登记一条，_setup_battle 的渲染白名单与 _load_monster_anim 会自动生效
const MONSTER_ANIM_CONFIG := {
	"cutthroat": {"base": CUTTHROAT_ANIM_BASE, "dir": CUTTHROAT_PNG_DIR, "map": CUTTHROAT_ANIM_MAP},
	"skeleton_arbalist": {"base": SKELETON_ARBALIST_ANIM_BASE, "dir": SKELETON_ARBALIST_PNG_DIR, "map": SKELETON_ARBALIST_ANIM_MAP},
	"skeleton_courtier": {"base": SKELETON_COURTIER_ANIM_BASE, "dir": SKELETON_COURTIER_PNG_DIR, "map": SKELETON_COURTIER_ANIM_MAP},
	"skeleton_common": {"base": SKELETON_COMMON_ANIM_BASE, "dir": SKELETON_COMMON_PNG_DIR, "map": SKELETON_COMMON_ANIM_MAP},
	"skeleton_defender": {"base": SKELETON_DEFENDER_ANIM_BASE, "dir": SKELETON_DEFENDER_PNG_DIR, "map": SKELETON_DEFENDER_ANIM_MAP},
	"skeleton_militia": {"base": SKELETON_MILITIA_ANIM_BASE, "dir": SKELETON_MILITIA_PNG_DIR, "map": SKELETON_MILITIA_ANIM_MAP},
	"skeleton_spear": {"base": SKELETON_SPEAR_ANIM_BASE, "dir": SKELETON_SPEAR_PNG_DIR, "map": SKELETON_SPEAR_ANIM_MAP},
	"brigand_sapper": {"base": BRIGAND_SAPPER_ANIM_BASE, "dir": BRIGAND_SAPPER_PNG_DIR, "map": BRIGAND_SAPPER_ANIM_MAP},
	"brigand_cannon": {"base": BRIGAND_CANNON_ANIM_BASE, "dir": BRIGAND_CANNON_PNG_DIR, "map": BRIGAND_CANNON_ANIM_MAP},
	"brigand_fuseman": {"base": BRIGAND_FUSEMAN_ANIM_BASE, "dir": BRIGAND_FUSEMAN_PNG_DIR, "map": BRIGAND_FUSEMAN_ANIM_MAP},
	"brigand_barrel": {"base": BRIGAND_BARREL_ANIM_BASE, "dir": BRIGAND_BARREL_PNG_DIR, "map": BRIGAND_BARREL_ANIM_MAP},
}

# 残骸（尸体）资源：骨架没有独立 dead 动画的怪物（首领/大炮/点火员/弹药桶）阵亡时，
# 直接借用普通小怪的 dead 残骸资源，保证场上摆的是真正躺着的遗体（而不是站着的活体姿态）。
# 默认借用强盗（brigand_cutthroat），与 BOSS 同属强盗阵营；
# 需要单独指定时，可在 MONSTER_ANIM_CONFIG 条目里加一条
# "corpse": {"base": ..., "dir": ..., "anim": ...}
const CORPSE_REMAINS_DEFAULT := {
	"base": CUTTHROAT_ANIM_BASE,
	"dir": CUTTHROAT_PNG_DIR,
	"anim": "dead",
}

# 首领投弹标记使用的状态 id 与引爆特效资源（特效在引爆时手动播放）
const BOMB_MARK_STATUS := "bomb_mark"
const SAPPER_DETONATE_FX := "res://monsters/brigand_sapper/fx/brigand_sapper.sprite.detonate_target"

# 死门（Death's Door）相关图标：进入濒死 / 撑过死亡骰时在头顶弹出
const DEATHS_DOOR_ICON := "res://overlays/tray_deathsdoor.png"
const DEATH_AVOIDED_ICON := "res://overlays/poptext_death_avoided.png"

# 压力系统（折磨 / 美德）四种失控行为（状态 id 与数值概率见 StressConfig）
const BREAKDOWN_SKIP := "skip" # 失控：跳过行动
const BREAKDOWN_ATTACK_ALLY := "attack_ally" # 失控：攻击队友
const BREAKDOWN_STRESS_ALLY := "stress_ally" # 失控：增加队友压力
const BREAKDOWN_RANDOM_ACTION := "random_action" # 失控：自动随机行动
const BREAKDOWN_OUTCOMES := [BREAKDOWN_SKIP, BREAKDOWN_ATTACK_ALLY, BREAKDOWN_STRESS_ALLY, BREAKDOWN_RANDOM_ACTION]

# --- 战斗结算（战利品）配置 ---
# 每场战斗胜利后掷一次战利品：食物 1~4 个，绷带 0~1 个，狗粮 0~1 个
const BATTLE_LOOT_TABLE := [
	{"item_id": "food", "count": [1, 4]},
	{"item_id": "bandage", "count": [0, 1]},
	{"item_id": "dogfood", "count": [0, 1]},
]
const LOOT_LAYER := 110 # 战利品结算层（高于战斗 UI 与激励喊话层 100）
# 结算界面层：必须高于浮字层（50）与战斗 UI；同时低于战利品层（110），
# 因为胜利时两者会同时显示——左侧战绩、右侧战利品
const END_LAYER := 105

# --- 战斗结算界面（胜利 / 远征终结 / 战败）---
# 卡片固定 660 宽居中（x 310~970），与右侧战利品面板（x 980~1260）留出 10px 间隙
const END_CARD_SIZE := Vector2(660, 430)
const END_DECOR := "res://overlays/announcement_frame.png" # 标题底衬装饰条
# 三种结局各自的徽记 / 插画
const END_ART_BY_STATE := {
	"victory": "res://overlays/quest_complete.png", # 卷轴徽记：通道重新敞开
	"run_complete": "res://panels/quest_return_to_hamlet.png", # 归乡木刻：远征终结
	"defeat": "res://panels/seal.affliction.png", # 折磨烙印（运行时染成血红）
}
const END_GOLD := Color(1.0, 0.86, 0.45, 1)
const END_BLOOD := Color(0.85, 0.28, 0.24, 1)

# --- 技能特效映射配置 ---
const SKILL_FX_MAP := {
	# 十字军技能特效
	"slash": {
		"caster_fx": "res://characters/crusader/fx/crusader.sprite.smite",
		"caster_anim": "attack" # 对应 crusader.sprite.attack_sword
	},
	"heal": {
		"caster_fx": "res://characters/crusader/fx/crusader.sprite.battle_heal",
		"target_fx": "res://characters/crusader/fx/crusader.sprite.battle_heal_target",
		"caster_anim": "heal" # 对应 crusader.sprite.attack_heal
	},
	"holy spear": {
		"caster_fx": "res://characters/crusader/fx/crusader.sprite.holy_lance",
		"caster_anim": "attack_charge" # 对应 crusader.sprite.attack_charge
	},
	"battle_cry": {
		"caster_fx": "res://characters/crusader/fx/crusader.sprite.battle_heal",
		"target_fx": "res://characters/crusader/fx/crusader.sprite.battle_heal_target",
		"caster_anim": "heal" # 播放战吼激励动画（使用治疗动作）
	},
	
	# 强盗技能特效
	"shotgun": {
		"caster_fx": "res://characters/highwayman/fx/highwayman.sprite.grape_shot_blast",
		"target_fx": "res://characters/highwayman/fx/highwayman.sprite.grape_shot_blast_target",
		"caster_anim": "attack" # 对应 highwayman.sprite.attack_pistol
	},
	"cut": {
		"caster_fx": "res://characters/highwayman/fx/highwayman.sprite.wicked_slice",
		"target_fx": "res://characters/highwayman/fx/highwayman.sprite.opened_vein",
		"caster_anim": "attack2" # 对应 highwayman.sprite.attack_slice
	},
	"Close-range shooting": {
		"caster_fx": "res://characters/highwayman/fx/highwayman.sprite.point_blank_shot",
		"target_fx": "res://characters/highwayman/fx/highwayman.sprite.point_blank_shot_target",
		"caster_anim": "attack" # 对应 highwayman.sprite.attack_pistol
	},
	"pistol_shot": {
		"caster_fx": "res://characters/highwayman/fx/highwayman.sprite.pistol_shot",
		"target_fx": "res://characters/highwayman/fx/highwayman.sprite.pistol_shot_target",
		"caster_anim": "attack" # 对应 highwayman.sprite.attack_pistol
	},
	
	# 神秘学者技能特效
	"命运重构": {
		"caster_fx": "res://characters/occultist/fx/occultist.sprite.wyrd_reconstruction",
		"target_fx": "res://characters/occultist/fx/occultist.sprite.wyrd_reconstruction_target",
		"caster_anim": "heal" # 对应 occultist.sprite.attack_heal
	},
	"祭祀切割": {
		"caster_fx": "res://characters/occultist/fx/occultist.sprite.bloodlet",
		"caster_anim": "attack" # 对应 occultist.sprite.attack_melee
	},
	"深渊之手": {
		"target_fx": "res://characters/occultist/fx/occultist.sprite.hands_from_abyss_target",
		"caster_anim": "attack2" # 对应 occultist.sprite.attack_skull
	},
	"灵魂之触": {
		"caster_fx": "res://characters/occultist/fx/occultist.sprite.weakening_curse",
		"target_fx": "res://characters/occultist/fx/occultist.sprite.daemons_pull_target",
		"caster_anim": "attack3" # 对应 occultist.sprite.attack_ranged
	},
	
	# 训犬师技能特效
	"释放猎犬": {
		"caster_fx": "res://characters/houndmaster/fx/houndmaster.sprite.hounds_rush",
		"caster_anim": "attack" # 对应 houndmaster.sprite.attack_rush
	},
	"标记弱点": {
		"caster_fx": "res://characters/houndmaster/fx/houndmaster.sprite.whistle",
		"caster_anim": "attack2" # 对应 houndmaster.sprite.attack_point
	},
	"振奋犬吠": {
		"caster_fx": "res://characters/houndmaster/fx/houndmaster.sprite.baleful_howl",
		"caster_anim": "attack3" # 对应 houndmaster.sprite.attack_howl
	},
	"守护队友": {
		"caster_fx": "res://characters/houndmaster/fx/houndmaster.sprite.guard_dog",
		"caster_anim": "attack4" # 对应 houndmaster.sprite.attack_guard
	},
	
	# 怪物技能特效
	"cutthroat_strike": {
		"caster_fx": "res://characters/highwayman/fx/highwayman.sprite.wicked_slice",
		"target_fx": "res://characters/highwayman/fx/highwayman.sprite.opened_vein",
		"caster_anim": "attack"
	},
	"temptation": {
		"target_fx": "res://characters/crusader/fx/crusader.sprite.stunning_blow_target",
		"caster_anim": "attack2"
	},
	
	# === 骷髅弩手特效 ===
	"arbalist_crossbow": {
		"caster_fx": "res://monsters/skeleton_arbalist/fx/skeleton_arbalist.sprite.crossbow_shot",
		"target_fx": "res://monsters/skeleton_arbalist/fx/skeleton_arbalist.sprite.crossbow_shot_target",
		"caster_anim": "attack"
	},
	"arbalist_bayonet": {
		"caster_fx": "res://monsters/skeleton_arbalist/fx/skeleton_arbalist.sprite.bayonet_jab",
		"caster_anim": "attack2"
	},
	
	# === 骷髅酒杯特效 ===
	"courtier_goblet": {
		"caster_fx": "res://monsters/skeleton_courtier/fx/skeleton_courtier.sprite.tempting_goblet",
		"caster_anim": "attack"
	},
	"courtier_dagger": {
		"caster_fx": "res://monsters/skeleton_courtier/fx/skeleton_courtier.sprite.dagger_jab",
		"caster_anim": "attack2"
	},
	
	# === 骷髅勇士特效 ===
	"skeleton_melee": {
		"caster_fx": "res://monsters/skeleton_common/fx/skeleton_common.sprite.cudgel",
		"caster_anim": "attack"
	},
	
	# === 骷髅盾卫特效 ===
	"defender_axe": {
		"caster_fx": "res://monsters/skeleton_defender/fx/skeleton_defender.sprite.axe_strike",
		"caster_anim": "attack"
	},
	"defender_shield": {
		"caster_fx": "res://monsters/skeleton_defender/fx/skeleton_defender.sprite.shield_bash",
		"caster_anim": "attack2"
	},
	
	# === 骷髅剑士特效 ===
	"militia_slash": {
		"caster_fx": "res://monsters/skeleton_militia/fx/skeleton_militia.sprite.sword_strike",
		"caster_anim": "attack"
	},
	"militia_ranged": {
		# 该怪无专用远程动作/特效资源，复用自身挥砍特效并以 attack 动作出招
		"caster_fx": "res://monsters/skeleton_militia/fx/skeleton_militia.sprite.sword_strike",
		"caster_anim": "attack"
	},
	
	# === 骷髅枪兵特效 ===
	"spear_thrust": {
		"caster_fx": "res://monsters/skeleton_spear/fx/skeleton_spear.sprite.spear_thrust",
		"caster_anim": "attack"
	},
	"spear_pierce": {
		# 同样复用长枪刺击特效（无专用贯穿资源），AoE 由技能数据本身驱动
		"caster_fx": "res://monsters/skeleton_spear/fx/skeleton_spear.sprite.spear_thrust",
		"caster_anim": "attack"
	},
	
	# === 门前恶狼 BOSS 战：首领 Brigand Vvulf 特效 ===
	"sapper_throw": {
		# rank_target 是首领投出的炸药在目标身上留下的锁定标记
		"caster_fx": "res://monsters/brigand_sapper/fx/brigand_sapper.sprite.throw",
		"target_fx": "res://monsters/brigand_sapper/fx/brigand_sapper.sprite.rank_target",
		"caster_anim": "attack"
	},
	"sapper_summon": {
		"caster_fx": "res://monsters/brigand_sapper/fx/brigand_sapper.sprite.summon",
		"caster_anim": "attack2"
	},
	"sapper_barrage": {
		"caster_fx": "res://monsters/brigand_sapper/fx/brigand_sapper.sprite.throw",
		"target_fx": "res://monsters/brigand_sapper/fx/brigand_sapper.sprite.rank_target",
		"caster_anim": "attack"
	},
	
	# === 大炮 Brigand Cannon 特效 ===
	"cannon_fire": {
		# 施法者是炮身，target_fx 复用同一炮口爆炸作为每一名英雄身上的命中表现
		"caster_fx": "res://monsters/brigand_cannon/fx/brigand_cannon.sprite.boom",
		"target_fx": "res://monsters/brigand_cannon/fx/brigand_cannon.sprite.boom",
		"caster_anim": "attack"
	},
	"cannon_summon": {
		"caster_fx": "res://monsters/brigand_cannon/fx/brigand_cannon.sprite.summon",
		"caster_anim": "attack2"
	},
	"cannon_blast": {
		"caster_fx": "res://monsters/brigand_cannon/fx/brigand_cannon.sprite.misfire",
		"caster_anim": "attack"
	},
	
	# === 点火员 Brigand Fuseman 特效 ===
	"fuseman_light_fuse": {
		"caster_fx": "res://monsters/brigand_fuseman/fx/brigand_fuseman.sprite.light_fuse",
		"target_fx": "res://monsters/brigand_fuseman/fx/brigand_fuseman.sprite.light_fuse_target",
		"caster_anim": "attack"
	},
	"fuseman_hot_shot": {
		"caster_fx": "res://monsters/brigand_fuseman/fx/brigand_fuseman.sprite.hot_shot",
		"caster_anim": "attack2"
	}
}

# --- 节点引用 ---
@onready var battle_ui: Control = $BattleUI
@onready var hero_list: HBoxContainer = $BattleUI/BattleContainer/LeftArea/HeroArea
@onready var monster_list: HBoxContainer = $BattleUI/BattleContainer/RightArea/MonsterArea
@onready var selected_label: Label = $BattleUI/BattleContainer/RightArea/SelectedLabel
@onready var portrait_box: ColorRect = $BattleUI/BattleContainer/LeftArea/BottomLeftPanel/PanelBanner/BannerContent/CharacterPortrait
@onready var skill_icon_boxes: Array[ColorRect] = [
	$BattleUI/BattleContainer/LeftArea/BottomLeftPanel/PanelBanner/BannerContent/SkillContainer/SkillIconBox1,
	$BattleUI/BattleContainer/LeftArea/BottomLeftPanel/PanelBanner/BannerContent/SkillContainer/SkillIconBox2,
	$BattleUI/BattleContainer/LeftArea/BottomLeftPanel/PanelBanner/BannerContent/SkillContainer/SkillIconBox3,
	$BattleUI/BattleContainer/LeftArea/BottomLeftPanel/PanelBanner/BannerContent/SkillContainer/SkillIconBox4,
]
@onready var skill_container: HBoxContainer = $BattleUI/BattleContainer/LeftArea/BottomLeftPanel/PanelBanner/BannerContent/SkillContainer
@onready var victory_panel: Panel = $BattleUI/VictoryPanel
# 结算界面的标题与主按钮不再写在 tscn 里，改由 _create_end_battle_ui() 在代码中构建
# （旧版只是一个素面 Panel + Label + Button；现在是带徽记、战绩与入场动画的卡片）
var victory_label: Label = null
var back_button: Button = null
@onready var reposition_button: TextureButton = $BattleUI/BattleContainer/LeftArea/BottomLeftPanel/BottomPanelsContainer/PanelHero/ReposButton
@onready var skip_button: TextureButton = $BattleUI/BattleContainer/LeftArea/BottomLeftPanel/BottomPanelsContainer/PanelHero/SkipButton
@onready var panel_inventory: Control = $BattleUI/BattleContainer/LeftArea/BottomLeftPanel/BottomPanelsContainer/PanelInventory
@onready var panel_inventory_bg: TextureRect = $BattleUI/BattleContainer/LeftArea/BottomLeftPanel/BottomPanelsContainer/PanelInventory/PanelInventoryBg

# 预设位置节点引用
@onready var hero_slots: Array[Control] = [
	$BattleUI/BattleContainer/LeftArea/HeroArea/HeroSlot1,
	$BattleUI/BattleContainer/LeftArea/HeroArea/HeroSlot2,
	$BattleUI/BattleContainer/LeftArea/HeroArea/HeroSlot3,
	$BattleUI/BattleContainer/LeftArea/HeroArea/HeroSlot4,
]
@onready var monster_slots: Array[Control] = [
	$BattleUI/BattleContainer/RightArea/MonsterArea/MonsterSlot1,
	$BattleUI/BattleContainer/RightArea/MonsterArea/MonsterSlot2,
	$BattleUI/BattleContainer/RightArea/MonsterArea/MonsterSlot3,
	$BattleUI/BattleContainer/RightArea/MonsterArea/MonsterSlot4,
]

# --- 战斗数据 ---
var heroes: Array[Dictionary] = []
var monsters: Array[Dictionary] = []
var turn_queue := TurnQueue.new()

# --- SpinePlayer 缓存：key = 英雄 index，value = SpinePlayer ---
var _spine_players: Dictionary = {}
var _spine_current_state: Dictionary = {} # key = hero_index, value = anim_state string
# portrait 锚点节点缓存：key = hero_index，value = Control（用于跟踪 SpinePlayer 位置）
var _spine_anchors: Dictionary = {}
var _focus_keys: Array = [] # 当前保持清晰的 SpinePlayer 缓存键
var _focus_bg_material: ShaderMaterial = null # 背景模糊材质（聚焦时应用）

# --- 战斗状态 ---
var battle_over := false
var round_number := 0
var current_actor: Dictionary = {}
var hero_skill_selected := false
var hero_current_skill := ""
var reposition_mode := false
var _in_fx_pause := false
# 标记本回合技能是否已对目标造成强制位移（数据重排已完成，待行动点扣除后重建队列）
var _target_reposition_applied := false
var monster_current_skill_id := ""
var _battle_won := false
var _run_complete := false

# --- 音效衔接：_play_skill_fx_v2 记下“本次出招”，_emit_feedback 结算出真实掉血后再播命中层 ---
var _pending_impact_skill := ""

# --- 结算界面（胜利 / 远征终结 / 战败）---
var _end_card: Panel = null # 卡片本体
var _end_decor: TextureRect = null # 标题底衬装饰条
var _end_art: TextureRect = null # 徽记 / 插画
var _end_subtitle: Label = null # 结局描述
var _end_stats: VBoxContainer = null # 战绩行容器
var _end_state := "" # victory / run_complete / defeat
var _end_tween: Tween = null

# --- 门前恶狼 BOSS 战：待引爆炸药队列 ---
# 首领投弹时登记一枚待引爆炸药；引爆在回合开始时结算，不占用任何单位的行动次数
# 元素格式：{"hero_slot": int, "due_round": int}
var _pending_bombs: Array[Dictionary] = []
# 生命链接（life_link）递归处理保护
var _processing_life_link := false

# --- 浮字 / 压力图标系统 ---
var _floating_text_layer: CanvasLayer = null

# --- 消耗品背包槽位容器 ---
var _inventory_slots_root: Control = null
var _inventory_initialized := false

# --- 战斗结算（战利品）UI ---
var loot_modal: ColorRect = null
var loot_panel: Panel = null
var loot_items_root: VBoxContainer = null
var loot_confirm_button: Button = null
var loot_title_label: Label = null
var loot_hint_label: Label = null
# 本场战斗待领取的战利品：[{"item_id": String, "count": int}]
var _pending_loot: Array[Dictionary] = []
var _loot_claimed := false

# --- LLM 激励喊话系统数据 ---
var llm_client := LLMClient.new()
var inspire_button: Button = null
var inspire_modal: ColorRect = null
var inspire_input: LineEdit = null
var inspire_label: Label = null
var reply_modal: ColorRect = null
var reply_title_lbl: Label = null
var reply_text_lbl: Label = null
var reply_status_lbl: Label = null
var reply_confirm_button: Button = null
# 本轮回应是否已被玩家点击“确定”（防止 await 注册前的点击被漏掉）
var _reply_confirm_clicked := false
var _is_requesting_llm := false

# ============================================================
# 生命周期
# ============================================================

func _ready() -> void:
	_create_inspire_button_and_ui()
	_create_loot_ui()
	_create_end_battle_ui()
	# 背景音乐：战斗曲（前奏 → 循环）
	Bgm.play("battle")
	
	# 浮字 / 压力图标专属 CanvasLayer（层 50，高于角色低于弹窗）
	_floating_text_layer = CanvasLayer.new()
	_floating_text_layer.name = "FloatingTextLayer"
	_floating_text_layer.layer = 50
	add_child(_floating_text_layer)
	
	_setup_battle()
	_start_new_round()
	_get_next_actor()
	if back_button:
		back_button.pressed.connect(_on_back_pressed)
	if reposition_button:
		reposition_button.pressed.connect(_on_reposition_pressed)
	if skip_button:
		skip_button.pressed.connect(_on_skip_pressed)
	
	# 延迟调用，等树完全布局后再更新UI
	call_deferred("_update_ui")

func _process(_delta: float) -> void:
	# 每帧同步 SpinePlayer 位置到 UI 锚点（英雄和怪物完全对称）
	for idx in _spine_anchors.keys():
		var anchor = _spine_anchors.get(idx)
		var sp: SpinePlayer = _spine_players.get(idx)
		if not is_instance_valid(anchor) or not is_instance_valid(sp):
			continue
			
		# 获得对应的 persistent Slot 容器作为稳定锚点后盾
		var slot: Control = null
		if typeof(idx) == TYPE_INT:
			if idx < hero_slots.size():
				slot = hero_slots[idx]
		elif typeof(idx) == TYPE_STRING and idx.begins_with("monster_"):
			var m_idx := int(idx.replace("monster_", ""))
			if m_idx < monster_slots.size():
				slot = monster_slots[m_idx]
				
		# 以锚点 ColorRect 中心下方为 SpinePlayer 原点
		var rect_global: Vector2 = anchor.global_position
		var rect_size: Vector2 = anchor.size
		
		# 避免在布局尚未生效、尺寸和坐标为零时，将角色错误瞬移到 (0,0) 造成闪烁或短暂丢失。直接使用 Slot 属性补偿首帧！
		if rect_size == Vector2.ZERO or rect_global == Vector2.ZERO:
			if is_instance_valid(slot):
				rect_global = slot.global_position
				rect_size = slot.size
			else:
				continue
				
		var target_pos = rect_global + Vector2(rect_size.x * 0.5, rect_size.y * 0.9)
		sp.global_position = target_pos
		sp.z_index = 10 # 确保在 UI 前面

	# 首帧（布局稳定后）构建消耗品背包槽位，确保命中区域与可见区域一致
	if not _inventory_initialized:
		if panel_inventory and panel_inventory_bg and battle_ui:
			_inventory_initialized = true
			_build_inventory_panel()

# ============================================================
# 初始化
# ============================================================

func _setup_battle() -> void:
	heroes.clear()
	monsters.clear()
	_spine_current_state.clear() # 清除所有动画状态，防止旧状态阻塞新的加载

	# 从 HeroConfig 加载编队英雄
	var team := HeroConfig.get_team_heroes()
	for i in range(team.size()):
		heroes.append(_build_hero_runtime(team[i], i))

	# 从 MonsterConfig 加载本场遭遇怪物
	var encounter := MonsterConfig.get_encounter_monsters()
	for i in range(encounter.size()):
		monsters.append(_build_monster_runtime(encounter[i], i))

	battle_over = false
	hero_skill_selected = false
	hero_current_skill = ""
	reposition_mode = false
	_target_reposition_applied = false
	current_actor = {}
	round_number = 0
	_pending_bombs.clear()
	_processing_life_link = false
	if victory_panel:
		victory_panel.visible = false
	if back_button:
		back_button.disabled = false
	# 结算（战利品）状态复位：本场尚未掷战利品、未领取
	_pending_loot.clear()
	_loot_claimed = false
	if loot_modal:
		loot_modal.visible = false

	# 初始化英雄和怪物 SpinePlayer
	_clear_spine_players()
	for i in range(heroes.size()):
		var hero_id: String = heroes[i].get("id", "")
		if hero_id in HERO_SPINE_IDS:
			_create_spine_player_for_hero(i)

	# 初始化怪物 SpinePlayer（凡在 MONSTER_ANIM_CONFIG 中登记过的怪物都会创建）
	for i in range(monsters.size()):
		if MONSTER_ANIM_CONFIG.has(str(monsters[i].get("id", ""))):
			_create_spine_player_for_monster(i)

# 用英雄模板构建运行时字典（编队初始化专用）
# 同时把跨战斗保留的"折磨 / 美德"还原成状态（由 HeroConfig.PARTY_STATES 持久化）
func _build_hero_runtime(tpl: Dictionary, index: int) -> Dictionary:
	var statuses: Dictionary = {}
	if bool(tpl.get("is_afflicted", false)):
		statuses[StressConfig.AFFLICTION_STATUS] = {"stacks": 1, "duration": 1}
	if bool(tpl.get("is_virtuous", false)):
		statuses[StressConfig.VIRTUE_STATUS] = {"stacks": 1, "duration": 1}
	return {
		"id": tpl.get("id", ""),
		"name": tpl.get("name", "Hero %d" % (index + 1)),
		"hp": tpl.get("hp", tpl.get("max_hp", 50)),
		"max_hp": tpl.get("max_hp", 50),
		"attack": tpl.get("attack", 10),
		"speed": tpl.get("speed", 4),
		"speed_delta": 0,
		"actions_remaining": 1,
		"skills": tpl.get("skills", []),
		"index": index,
		"slot": tpl.get("slot", index),
		"stress": tpl.get("stress", 0),
		"max_stress": StressConfig.MAX_STRESS,
		"is_death_door": tpl.get("is_death_door", false),
		# 死门死亡概率写在每个角色自己的配置里（HeroConfig.HEROES[*].death_blow_chance）
		"death_blow_chance": _death_blow_chance_of(tpl),
		"statuses": statuses,
	}

# 取该角色的死门死亡概率：优先用编队模板里的数值，缺失时回落到 HeroConfig 的按角色配置/默认值
func _death_blow_chance_of(tpl: Dictionary) -> float:
	if tpl.has("death_blow_chance"):
		return clampf(float(tpl["death_blow_chance"]), 0.0, 1.0)
	return HeroConfig.get_death_blow_chance(str(tpl.get("id", "")))

# 用怪物模板构建运行时字典（战斗初始化与战斗内召唤共用同一套字段，
# 避免召唤出来的单位缺少 inert / life_link 等字段导致机制失效）
func _build_monster_runtime(tpl: Dictionary, index: int) -> Dictionary:
	return {
		"id": str(tpl.get("id", "")),
		"name": str(tpl.get("name", "Monster %d" % (index + 1))),
		"hp": int(tpl.get("max_hp", 40)),
		"max_hp": int(tpl.get("max_hp", 40)),
		"attack": int(tpl.get("attack", 10)),
		"speed": int(tpl.get("speed", 4)),
		"speed_delta": 0,
		"speed_delta_base": int(tpl.get("speed_delta_base", -1)),
		"actions_remaining": 1,
		"index": index,
		"skills": tpl.get("skills", []),
		"statuses": {},
		"inert": bool(tpl.get("inert", false)),
		"life_link": str(tpl.get("life_link", "")),
	}

# ============================================================
# 回合管理
# ============================================================

func _start_new_round() -> void:
	round_number += 1
	for hero in heroes:
		# 存活英雄（含濒死状态）重置行动次数
		if hero["hp"] > 0 or hero.get("is_death_door", false):
			hero["actions_remaining"] = 1
			hero["speed_delta"] = randi_range(-SPEED_DELTA_RANGE, SPEED_DELTA_RANGE)
	for monster in monsters:
		# 存活怪物（排除尸体）重置行动次数
		if monster["hp"] > 0 and not monster.get("is_corpse", false):
			if monster.get("inert", false):
				# 惰性单位（如弹药桶）：永不行动，也不进入行动队列
				monster["actions_remaining"] = 0
				monster["speed_delta"] = 0
			else:
				monster["actions_remaining"] = 1
				monster["speed_delta"] = randi_range(-SPEED_DELTA_RANGE, SPEED_DELTA_RANGE)
	# 上一回合首领投出的炸药在本回合开始时引爆（debuff 结算行为，不占用任何人的行动）
	_resolve_pending_bombs()
	turn_queue.build(heroes, monsters)

# 角色行动开始时结算其身上的状态：持续伤害（流血/腐蚀等 DoT）+ 控制类状态（晕眩）
# 返回 true 表示该角色仍可行动；false 表示本回合行动应被跳过（死亡 / 尸体 / 晕眩）
func _tick_current_actor_statuses() -> bool:
	if current_actor.is_empty():
		return true
	var unit_type: String = current_actor.get("unit_type", "")
	var idx: int = current_actor.get("index", -1)
	
	if unit_type == "hero":
		if idx < 0 or idx >= heroes.size():
			return false
		var h := heroes[idx]
		if h.get("hp", 0) <= 0 and not h.get("is_death_door", false):
			return false
		# 晕眩判定：在单位行动时进行，判定后立即解除（先于 DoT 结算取出，避免状态被提前清掉）
		var stunned := ActionResolver.consume_skip_turn(h)
		var dmg := ActionResolver.tick_statuses(h)
		if dmg > 0:
			_show_floating_number(h, -dmg)
			_handle_hero_damage_aftermath(idx)
		# 英雄可能因死亡骰失败被移除
		if idx >= heroes.size():
			return false
		if stunned:
			_skip_turn_by_stun(h)
			return false
		return true
	elif unit_type == "monster":
		if idx < 0 or idx >= monsters.size():
			return false
		var m := monsters[idx]
		if m.get("hp", 0) <= 0 or m.get("is_corpse", false):
			return false
		# 晕眩判定：在单位行动时进行，判定后立即解除
		var stunned := ActionResolver.consume_skip_turn(m)
		var dmg := ActionResolver.tick_statuses(m)
		if dmg > 0:
			_show_floating_number(m, -dmg)
			_handle_monster_damage_aftermath(idx)
		# 怪物可能因 DoT 致死变为尸体（或被清除出场）
		if idx >= monsters.size():
			return false
		if monsters[idx].get("is_corpse", false) or monsters[idx].get("hp", 0) <= 0:
			return false
		if stunned:
			_skip_turn_by_stun(m)
			return false
		return true
	return true

# 晕眩等控制状态触发：消耗该单位本回合行动点（真正的"跳过一次行动"），
# 弹出提示图标并刷新 UI，使状态徽标在解除后同步消失
func _skip_turn_by_stun(unit: Dictionary) -> void:
	unit["actions_remaining"] = max(0, int(unit.get("actions_remaining", 1)) - 1)
	print("[Status] ", unit.get("name", "???"), " is stunned and skips this action.")
	_show_status_popup(unit, "res://overlays/tray_stun.png")
	_update_ui()

# 在单位头顶弹出一个状态图标提示（复用压力图标的上浮淡出效果）
func _show_status_popup(unit: Dictionary, icon_path: String) -> void:
	var sp_key = _get_spine_player_ref_info(unit).key
	if sp_key == null:
		return
	var sp: SpinePlayer = _spine_players.get(sp_key) as SpinePlayer
	if not is_instance_valid(sp):
		return
	if not ResourceLoader.exists(icon_path):
		return
	_show_stress_seal_delayed(sp.global_position, icon_path)

# 推进行动（英雄行动结束后调用）
func _advance_action() -> void:
	if current_actor.get("unit_type") == "hero":
		heroes[current_actor["index"]]["actions_remaining"] -= 1
	await _get_next_actor()

# 核心行动流转循环
func _get_next_actor() -> void:
	while true:
		if battle_over:
			return

		if turn_queue.is_empty():
			if turn_queue.has_remaining_actions(heroes, monsters):
				turn_queue.build(heroes, monsters)
				continue
			# 本轮全部行动完毕 → 开始下一轮
			current_actor = {}
			hero_skill_selected = false
			hero_current_skill = ""
			reposition_mode = false
			_start_new_round()
			continue

		current_actor = turn_queue.pop_next_alive(heroes, monsters)
		if current_actor.is_empty():
			continue

		# 角色行动开始时结算其身上的持续伤害（流血/腐蚀等 DoT）
		var can_act := _tick_current_actor_statuses()

		# DoT 可能直接造成胜负判定
		if _check_victory() or _check_defeat():
			return

		if not can_act:
			continue

		if current_actor["unit_type"] == "hero":
			hero_skill_selected = false
			hero_current_skill = ""
			reposition_mode = false
			_in_fx_pause = false
			monster_current_skill_id = ""
			_update_ui()
			# 折磨（Affliction）失控判定：行动开始即掷骰，命中则本回合改由失控行为接管
			var actor_idx: int = current_actor["index"]
			if actor_idx >= 0 and actor_idx < heroes.size() and _should_roll_breakdown(heroes[actor_idx]):
				var delegated: bool = await _execute_affliction_breakdown(actor_idx)
				if delegated:
					# 失控行为已走完正常技能流程（内部扣点并推进了队列），本层循环直接退出
					return
				continue
			return # 等待玩家输入
		else:
			await _execute_monster_action()
			continue

# ============================================================
# 战斗执行
# ============================================================

func _execute_monster_action() -> void:
	if current_actor.is_empty() or current_actor["unit_type"] != "monster":
		return
	var idx: int = current_actor["index"]
	if idx >= monsters.size():
		return
	var m := monsters[idx]
	# 安全守卫：尸体、已死或无剩余行动次数的怪物不执行
	if m["hp"] <= 0 or m.get("is_corpse", false) or m.get("actions_remaining", 0) <= 0:
		return
		
	# 立即更新 UI，使该主动行怪摆出 combat（备战待机姿态）并亮起行动指示器 ▲
	_update_ui()
	# 略作停顿，增加战斗的条理性，让怪物的准备阶段动作平滑过渡，不再仓促闪烁
	await get_tree().create_timer(0.3).timeout
	
	monsters[idx]["actions_remaining"] -= 1
	var monster_pos: int = idx + 1
	
	var m_skills: Array = monsters[idx].get("skills", [])
	var candidate_skills: Array[Dictionary] = []
	
	for skill_id_val in m_skills:
		var skill_id: String = str(skill_id_val)
		var skill_data: Dictionary = SkillConfig.get_skill(skill_id)
		if skill_data.is_empty():
			continue
			
		# 1. 检查释放者可用位置范围
		var use_positions: Array = skill_data.get("use_positions", [])
		if not use_positions.is_empty() and not (monster_pos in use_positions):
			continue
			
		# 1.5 检查技能使用条件（BOSS 联动技能：需弹药桶在场 / 需自身已被装填 等）
		if not _meets_skill_conditions(idx, skill_data):
			continue
			
		# 2. 检索符合条件的有效目标
		var valid_targets: Array[Dictionary] = _get_valid_targets_for_monster(idx, skill_data)
		if valid_targets.is_empty():
			continue
			
		candidate_skills.append({
			"skill_id": skill_id,
			"skill_data": skill_data,
			"targets": valid_targets
		})
		
	# 3. 决定最终释放的技能并选择目标
	#    技能可用时默认等概率随机（同一怪物多招轮换的手感）；
	#    配置了 "skill_priority" 的技能优先：只有最高档的候选参与随机，
	#    低档技能仅在它不可用时兜底（例：点火员能装填就一定装填，装不了才打灼热散弹）。
	if not candidate_skills.is_empty():
		var best_priority: int = -9999
		for cand in candidate_skills:
			best_priority = maxi(best_priority, int((cand["skill_data"] as Dictionary).get("skill_priority", 0)))
		var top_candidates: Array[Dictionary] = []
		for cand in candidate_skills:
			if int((cand["skill_data"] as Dictionary).get("skill_priority", 0)) >= best_priority:
				top_candidates.append(cand)
		var recruited: Dictionary = top_candidates[randi() % top_candidates.size()]
		var skill_data: Dictionary = recruited["skill_data"]
		var valid_targets: Array[Dictionary] = recruited["targets"]
		var target_type: String = skill_data.get("target_type", "")
		
		# 4. 执行施法与效果分发
		_in_fx_pause = true
		monster_current_skill_id = recruited["skill_id"]
		
		match target_type:
			"single_enemy", "single_ally", "self":
				var priority: String = skill_data.get("target_priority", "random")
				var chosen_target: Dictionary = _select_target_by_priority(valid_targets, priority)
				# 守护转移：单体攻击若选中了被守护者，则改为打该守护者
				if target_type == "single_enemy":
					chosen_target = _resolve_guard(chosen_target)
				if not chosen_target.is_empty():
					var is_dmg: bool = skill_data.get("effect_type", "") == "damage"
					if is_dmg:
						chosen_target["is_defending"] = true
					_update_ui()
					
					_apply_focus(monsters[idx], [chosen_target])
					_play_skill_fx_v2(monsters[idx], recruited["skill_id"], [chosen_target])
					if chosen_target.get("is_defending", false):
						chosen_target["is_defending"] = false
					var snap_single := _snap_unit(chosen_target)
					ActionResolver.resolve_on_target(monsters[idx], skill_data, chosen_target)
					_emit_feedback([chosen_target], [snap_single])
					
					# 首领投弹：为被标记的英雄登记一枚待引爆炸药（下个回合开始时结算）
					if target_type == "single_enemy":
						_register_pending_bomb(chosen_target, skill_data)
					
					# 技能附加效果（召唤新单位 / 消耗自身状态）
					_apply_monster_skill_post_effects(idx, skill_data)
					
					# 若目标为英雄则处理濒死/死亡骰
					if target_type == "single_enemy":
						var target_hero_idx := heroes.find(chosen_target)
						if target_hero_idx >= 0:
							_handle_hero_damage_aftermath(target_hero_idx, is_dmg)
					
					await get_tree().create_timer(ATTACK_ZOOM_DURATION).timeout
					
					# 取消聚焦，恢复所有角色与背景
					_clear_focus()
					_in_fx_pause = false
					monster_current_skill_id = ""
					_update_ui()
					
					if _check_defeat():
						return

			"all_enemies", "all_allies":
				var is_dmg: bool = skill_data.get("effect_type", "") == "damage"
				if is_dmg:
					for t in valid_targets:
						t["is_defending"] = true
				_update_ui()
				
				_apply_focus(monsters[idx], valid_targets)
				_play_skill_fx_v2(monsters[idx], recruited["skill_id"], valid_targets)
				for t in valid_targets:
					t["is_defending"] = false
				var snaps_all: Array[Dictionary] = []
				for t in valid_targets:
					snaps_all.append(_snap_unit(t))
				ActionResolver.resolve_on_all(monsters[idx], skill_data, valid_targets)
				_emit_feedback(valid_targets, snaps_all)
				
				# 技能附加效果（大炮开火后卸弹等）
				_apply_monster_skill_post_effects(idx, skill_data)
				
				# 若目标为英雄则逐个处理濒死/死亡骰
				if target_type == "all_enemies":
					for t in valid_targets:
						var target_hero_idx := heroes.find(t)
						if target_hero_idx >= 0:
							_handle_hero_damage_aftermath(target_hero_idx, is_dmg)
				
				await get_tree().create_timer(ATTACK_ZOOM_DURATION).timeout
				
				# 取消聚焦，恢复所有角色与背景
				_clear_focus()
				_in_fx_pause = false
				monster_current_skill_id = ""
				_update_ui()
				
				if _check_defeat():
					return
		
		# 刚才释放过技能，在数值落地后额外停顿 0.4 秒，免得画面切换过快产生“怪物没停顿”的生硬感
		await get_tree().create_timer(0.4).timeout
	else:
		# 无可用候选技能时走跳过回合退避方式
		pass
		
	_update_ui()

func _get_valid_targets_for_monster(idx: int, skill_data: Dictionary) -> Array[Dictionary]:
	var valid_targets: Array[Dictionary] = []
	var target_type: String = skill_data.get("target_type", "")
	var target_positions: Array = skill_data.get("target_positions", [])
	
	if target_type == "single_enemy" or target_type == "all_enemies":
		for i in range(heroes.size()):
			# 存活或濒死状态的英雄均为有效目标
			if heroes[i]["hp"] > 0 or heroes[i].get("is_death_door", false):
				if target_positions.is_empty() or ((i + 1) in target_positions):
					valid_targets.append(heroes[i])
	elif target_type == "single_ally" or target_type == "all_allies":
		# 友方目标的额外筛选：只服务指定 id 的友军（如点火员只给大炮装填），
		# 且身上已带有指定状态的友军不可再选（避免对已装填的大炮重复点火）
		var ally_id: String = str(skill_data.get("target_ally_id", ""))
		var ally_status_absent: String = str(skill_data.get("target_ally_status_absent", ""))
		for i in range(monsters.size()):
			if monsters[i]["hp"] > 0 and not monsters[i].get("is_corpse", false):
				if ally_id != "" and str(monsters[i].get("id", "")) != ally_id:
					continue
				if ally_status_absent != "" and ActionResolver.has_status(monsters[i], ally_status_absent):
					continue
				if target_positions.is_empty() or ((i + 1) in target_positions):
					valid_targets.append(monsters[i])
	elif target_type == "self":
		if monsters[idx]["hp"] > 0 and not monsters[idx].get("is_corpse", false):
			valid_targets.append(monsters[idx])
			
	return valid_targets

func _select_target_by_priority(targets: Array, priority: String) -> Dictionary:
	if targets.is_empty():
		return {}
	
	match priority:
		"lowest_hp":
			var best_target: Dictionary = targets[0]
			for t in targets:
				if t.get("hp", 0) < best_target.get("hp", 0):
					best_target = t
			return best_target
		"highest_stress":
			var best_target: Dictionary = targets[0]
			for t in targets:
				if t.get("stress", 0) > best_target.get("stress", 0):
					best_target = t
			return best_target
		"random", _:
			return targets[randi() % targets.size()]

# 守护转移：若目标身上带有 "guard" 状态且其守护者仍在场，则返回守护者；否则原样返回目标
# 守护者用 (id, slot) 定位——战斗中会因换位/阵亡改变 heroes 下标，但 id/slot 始终跟随本人
func _resolve_guard(unit: Dictionary) -> Dictionary:
	if unit.is_empty():
		return unit
	var statuses: Dictionary = unit.get("statuses", {})
	if not statuses.has("guard"):
		return unit
	var g: Dictionary = statuses["guard"]
	var g_id: String = str(g.get("guardian_id", ""))
	var g_slot: int = int(g.get("guardian_slot", -1))
	for h in heroes:
		if str(h.get("id", "")) == g_id and int(h.get("slot", -1)) == g_slot:
			# 守护者必须存活（含濒死）且不是被守护者本人
			if (h.get("hp", 0) > 0 or h.get("is_death_door", false)) and not is_same(h, unit):
				return h
	return unit

# ============================================================
# 门前恶狼 BOSS 战机制（首领投弹 / 弹药桶 / 大炮与点火员联动）
# ============================================================

# 是否仍有该 id 的怪物存活在场（尸体与已阵亡者不算）
func _has_alive_monster(monster_id: String) -> bool:
	if monster_id == "":
		return false
	for m in monsters:
		if str(m.get("id", "")) == monster_id and m.get("hp", 0) > 0 and not m.get("is_corpse", false):
			return true
	return false

# 技能数据是否附带指定状态（用于判断某技能是否属于"投弹标记"类）
func _skill_applies_status(skill_data: Dictionary, status_id: String) -> bool:
	for se in skill_data.get("status_effects", []):
		if str(se.get("status_id", "")) == status_id:
			return true
	return false

# 技能使用条件判定（数据驱动，字段说明见 SkillConfig 顶部注释）：
#   requires_alive_ally / requires_absent_ally / requires_self_status / requires_self_status_absent
func _meets_skill_conditions(idx: int, skill_data: Dictionary) -> bool:
	if idx < 0 or idx >= monsters.size():
		return false
	var caster := monsters[idx]
	for required in skill_data.get("requires_alive_ally", []):
		if not _has_alive_monster(str(required)):
			return false
	for absent in skill_data.get("requires_absent_ally", []):
		if _has_alive_monster(str(absent)):
			return false
	var need_self: String = str(skill_data.get("requires_self_status", ""))
	if need_self != "" and not ActionResolver.has_status(caster, need_self):
		return false
	var forbid_self: String = str(skill_data.get("requires_self_status_absent", ""))
	if forbid_self != "" and ActionResolver.has_status(caster, forbid_self):
		return false
	return true

# 按 slot 定位英雄（slot 是队伍槽位，换位/补位改变的只是 heroes 下标，slot 始终跟随本人）
func _find_hero_by_slot(slot: int) -> Dictionary:
	for h in heroes:
		if int(h.get("slot", -1)) == slot and (h.get("hp", 0) > 0 or h.get("is_death_door", false)):
			return h
	return {}

# 首领投弹：为被标记的英雄登记一枚待引爆炸药，下个回合开始时引爆
# 引爆不属于任何单位的行动（不计入行动次数），属于 debuff 结算行为
func _register_pending_bomb(hero: Dictionary, skill_data: Dictionary) -> void:
	if hero.is_empty() or not _skill_applies_status(skill_data, BOMB_MARK_STATUS):
		return
	var slot: int = int(hero.get("slot", -1))
	if slot < 0:
		return
	var due_round: int = round_number + 1
	for bomb in _pending_bombs:
		if int(bomb.get("hero_slot", -1)) == slot:
			bomb["due_round"] = due_round # 同一英雄重复标记：引信重燃
			print("[Bomb] Fuse re-lit on ", hero.get("name"), " (due round ", due_round, ")")
			return
	_pending_bombs.append({"hero_slot": slot, "due_round": due_round})
	print("[Bomb] Fuse lit on ", hero.get("name"), " (due round ", due_round, ")")

# 回合开始时结算到期的炸药：弹药桶仍在场则引爆，否则转为哑弹并解除标记
func _resolve_pending_bombs() -> void:
	if _pending_bombs.is_empty():
		return
	var due: Array[Dictionary] = []
	var remain: Array[Dictionary] = []
	for bomb in _pending_bombs:
		if int(bomb.get("due_round", 0)) <= round_number:
			due.append(bomb)
		else:
			remain.append(bomb)
	_pending_bombs = remain
	if due.is_empty():
		return
	for bomb in due:
		var hero := _find_hero_by_slot(int(bomb.get("hero_slot", -1)))
		if hero.is_empty():
			continue # 目标已阵亡/离场，炸药落空
		if not ActionResolver.has_status(hero, BOMB_MARK_STATUS):
			continue # 标记已被提前解除（弹药桶被摧毁时清空）
		if not _has_alive_monster("brigand_barrel"):
			ActionResolver.remove_status(hero, BOMB_MARK_STATUS)
			_show_toast("弹药桶已被摧毁 —— 落在 %s 身上的炸药成了哑弹" % str(hero.get("name", "英雄")))
			print("[Bomb] Disarmed (no barrel alive) on ", hero.get("name"))
			continue
		_detonate_bomb(hero)
	# 引爆可能直接把队伍炸进全灭，立即判定一次失败
	_check_defeat()

# 炸药引爆：在目标身上播放首领的引爆特效并造成大量伤害
func _detonate_bomb(hero: Dictionary) -> void:
	var cfg := StatusConfig.get_status(BOMB_MARK_STATUS)
	var dmg: int = ActionResolver.roll_range_int(cfg.get("detonate_damage", [14, 20]))
	var info := _get_spine_player_ref_info(hero)
	if info.get("key") != null:
		var sp: SpinePlayer = _spine_players.get(info["key"]) as SpinePlayer
		if is_instance_valid(sp):
			_play_fx_at_position(sp.global_position,
				SAPPER_DETONATE_FX + ".skel", SAPPER_DETONATE_FX + ".atlas",
				SAPPER_DETONATE_FX.get_base_dir(), false, 1.0, sp)
	# 引爆巨响：用通用重击甜化层 + 一发火器音叠加，做出“炸弹”的量感
	Sfx.play_impact("heavy", -5.0)
	Sfx.play_monster_cast("cannon_blast", -7.0)
	ActionResolver.remove_status(hero, BOMB_MARK_STATUS)
	var before: int = hero.get("hp", 0)
	ActionResolver.apply_damage(hero, dmg)
	var dealt: int = before - int(hero.get("hp", 0))
	if dealt > 0:
		_show_floating_number(hero, -dealt)
	print("[Bomb] Detonated on ", hero.get("name"), " for ", dealt, " damage")
	var hero_idx := heroes.find(hero)
	if hero_idx >= 0:
		# 炸药是货真价实的伤害 → 濒死目标要掷死亡骰
		_handle_hero_damage_aftermath(hero_idx, true)
	_update_ui()

# 弹药桶被摧毁 → 所有爆破标记立即解除（与暗黑地牢原版"桶毁弹消"一致）
func _disarm_pending_bombs() -> void:
	var cleared := 0
	for hero in heroes:
		if ActionResolver.remove_status(hero, BOMB_MARK_STATUS):
			cleared += 1
	_pending_bombs.clear()
	if cleared > 0:
		_show_toast("弹药桶被摧毁 —— 炸药标记已解除")
	print("[Bomb] Barrel destroyed, disarmed ", cleared, " bomb mark(s)")

# 怪物技能结算后的附加效果：消耗自身状态（大炮开火后卸弹）与召唤新单位
func _apply_monster_skill_post_effects(idx: int, skill_data: Dictionary) -> void:
	# 先处理状态消耗：召唤会改动 monsters 数组，放在后面更安全
	var consume: String = str(skill_data.get("consume_self_status", ""))
	if consume != "" and idx >= 0 and idx < monsters.size():
		ActionResolver.remove_status(monsters[idx], consume)
		_update_ui()
	if str(skill_data.get("effect_type", "")) == "summon":
		_summon_monster(str(skill_data.get("summon_monster_id", "")))

# 战斗内召唤怪物（首领召回弹药桶 / 大炮召回点火员）
# 优先占用尸体槽位（尸体让位，不改变其它单位的索引），否则追加到队尾；
# 新单位当回合不行动（actions_remaining = 0），下回合开始正常入队。
func _summon_monster(monster_id: String) -> int:
	if monster_id == "":
		return -1
	if _has_alive_monster(monster_id):
		return -1 # 同类单位仍在场，无需召唤
	var tpl := MonsterConfig.get_monster_template(monster_id)
	if tpl.is_empty():
		push_warning("[Summon] Unknown monster_id '%s'" % monster_id)
		return -1
	var slot := -1
	for i in range(monsters.size()):
		if monsters[i].get("is_corpse", false):
			slot = i
			break
	if slot < 0:
		if monsters.size() >= monster_slots.size():
			print("[Summon] No room for ", monster_id, " (all ", monster_slots.size(), " slots occupied)")
			return -1
		slot = monsters.size()
	var unit := _build_monster_runtime(tpl, slot)
	unit["actions_remaining"] = 0 # 登场当回合不行动
	if slot < monsters.size():
		monsters[slot] = unit
	else:
		monsters.append(unit)
	# 该槽位的 SpinePlayer 原本在播放尸体姿态，需要整体重建
	var key := "monster_%d" % slot
	if _spine_players.has(key):
		var old_sp = _spine_players[key]
		if is_instance_valid(old_sp):
			old_sp.queue_free()
		_spine_players.erase(key)
	_spine_current_state.erase(key)
	if MONSTER_ANIM_CONFIG.has(monster_id):
		_create_spine_player_for_monster(slot)
	turn_queue.build(heroes, monsters)
	_update_ui()
	print("[Summon] ", tpl.get("name", monster_id), " appears in slot ", slot + 1)
	return slot

# 生命链接（life_link）：源怪阵亡时，把 life_link 指向它的怪物一并带走
# （弹药桶随首领损毁、点火员随大炮倒下，与暗黑地牢原版一致）
func _apply_life_links(source_idx: int) -> void:
	if _processing_life_link:
		return
	if source_idx < 0 or source_idx >= monsters.size():
		return
	var source_id: String = str(monsters[source_idx].get("id", ""))
	if source_id == "":
		return
	var source_name: String = str(monsters[source_idx].get("name", source_id))
	_processing_life_link = true
	for i in range(monsters.size()):
		var m := monsters[i]
		if m.get("hp", 0) <= 0 or m.get("is_corpse", false):
			continue
		if str(m.get("life_link", "")) != source_id:
			continue
		print("[LifeLink] ", m.get("name", "?"), " collapses together with ", source_name)
		m["hp"] = 0
		m["statuses"] = {}
		_handle_monster_damage_aftermath(i)
	_processing_life_link = false

# ============================================================
# 压力系统（折磨 / 美德）
# 数值与概率集中在 scripts/data/StressConfig.gd
# ============================================================

# 该英雄本回合是否要掷"失控"（处于折磨状态 + 命中 BREAKDOWN_CHANCE）
func _should_roll_breakdown(hero: Dictionary) -> bool:
	if hero.is_empty() or not ActionResolver.has_status(hero, StressConfig.AFFLICTION_STATUS):
		return false
	return randf() < StressConfig.BREAKDOWN_CHANCE

# 结算一批单位中"压力越阈待判"的英雄（任何压力来源结算后都会调用，保证同一条结算链）
func _resolve_pending_stress_states(units: Array) -> void:
	for u in units:
		if typeof(u) != TYPE_DICTIONARY:
			continue
		var unit: Dictionary = u
		if bool(unit.get("stress_resolve_pending", false)):
			_resolve_stress_threshold(unit)

# 压力越过阈值后的掷骰结算：75% 折磨 / 25% 美德（概率见 StressConfig）
# 触发链路：ActionResolver.apply_stress 越阈时打上 stress_resolve_pending 标记 → 本函数结算
# 注意：是否掷骰由"当前是否已处于折磨/美德"决定（见 StressConfig），**不按战斗重置**——
#       折磨 / 美德与压力一起跨战斗保留（HeroConfig.PARTY_STATES）。
func _resolve_stress_threshold(hero: Dictionary) -> void:
	if hero.is_empty():
		return
	hero["stress_resolve_pending"] = false
	var hero_name: String = str(hero.get("name", "英雄"))
	var roll := randf()
	if roll < StressConfig.AFFLICTION_CHANCE:
		# ① 折磨：受到压力 +20%，每次行动有概率失控
		ActionResolver.apply_status(hero, StressConfig.AFFLICTION_STATUS, 1, 1)
		_show_stress_seal(hero, false)
		_show_status_popup(hero, str(StatusConfig.get_status(StressConfig.AFFLICTION_STATUS).get("icon", "")))
		_show_toast("%s 精神崩溃，陷入【折磨】：受到压力 +20%%，每次行动 %d%% 概率失控" % [
			hero_name, int(round(StressConfig.BREAKDOWN_CHANCE * 100.0))])
		print("[Stress] ", hero_name, " became AFFLICTED (stress=", hero.get("stress", 0), ")")
	elif roll < StressConfig.AFFLICTION_CHANCE + StressConfig.VIRTUE_CHANCE:
		# ② 美德：清空自身压力，全体英雄攻击力提升（持续若干回合）
		hero["stress"] = 0
		ActionResolver.apply_status(hero, StressConfig.VIRTUE_STATUS, 1, 1)
		var blessed := 0
		for h in heroes:
			if h.get("hp", 0) > 0 or h.get("is_death_door", false):
				ActionResolver.apply_status(h, StressConfig.VIRTUE_BUFF_STATUS, 1, StressConfig.VIRTUE_BUFF_ROUNDS)
				blessed += 1
		_show_stress_seal(hero, true)
		_show_status_popup(hero, str(StatusConfig.get_status(StressConfig.VIRTUE_STATUS).get("icon", "")))
		_show_toast("%s 展现出【美德】：压力清空，全体攻击力 +%d%%（%d 回合）" % [
			hero_name, int(round((StressConfig.VIRTUE_ATTACK_MULT - 1.0) * 100.0)), StressConfig.VIRTUE_BUFF_ROUNDS])
		print("[Stress] ", hero_name, " became VIRTUOUS (buffed ", blessed, " heroes)")
	else:
		# 两次概率均未命中（当前配置为 75% + 25% = 100%，不会走到这里）：仅保留钳制后的压力
		print("[Stress] ", hero_name, " passed threshold with no state change (stress=", hero.get("stress", 0), ")")
	_update_ui()

# 失控行为的中文名（用于提示文案）
func _breakdown_label(outcome: String) -> String:
	match outcome:
		BREAKDOWN_ATTACK_ALLY:
			return "攻击队友"
		BREAKDOWN_STRESS_ALLY:
			return "向队友倾泻压力"
		BREAKDOWN_RANDOM_ACTION:
			return "不受控地自行出手"
		_:
			return "呆立当场（跳过行动）"

# 折磨（Affliction）失控：接管该英雄本回合的行动
# 返回 true  = 失控行为走完了正常技能流程（内部已扣点并推进队列），调用方应直接 return
# 返回 false = 已在本函数内扣点并重建队列，调用方应 continue 回行动循环
# forced_outcome 仅用于探针脚本确定性地覆盖四种分支，正常玩法传空串
func _execute_affliction_breakdown(hero_idx: int, forced_outcome: String = "") -> bool:
	if hero_idx < 0 or hero_idx >= heroes.size():
		return false
	var hero := heroes[hero_idx]
	var hero_name: String = str(hero.get("name", "英雄"))
	var outcome := forced_outcome
	if outcome == "":
		outcome = str(BREAKDOWN_OUTCOMES[randi() % BREAKDOWN_OUTCOMES.size()])
	print("[Affliction] ", hero_name, " breakdown → ", outcome)
	_show_toast("%s 失控：%s" % [hero_name, _breakdown_label(outcome)])
	
	if outcome == BREAKDOWN_RANDOM_ACTION:
		if await _auto_perform_random_action(hero_idx):
			return true # 已交回正常技能流程（内部会扣点并推进队列）
		outcome = BREAKDOWN_SKIP # 找不到可用技能 → 退化为跳过行动
	
	if outcome == BREAKDOWN_ATTACK_ALLY:
		if _execute_breakdown_attack_ally(hero).is_empty():
			outcome = BREAKDOWN_SKIP # 没有可攻击的队友 → 退化为跳过行动
	elif outcome == BREAKDOWN_STRESS_ALLY:
		if not _execute_breakdown_stress_ally(hero):
			outcome = BREAKDOWN_SKIP # 没有可加压的队友 → 退化为跳过行动
	
	if outcome == BREAKDOWN_SKIP:
		_show_status_popup(hero, str(StatusConfig.get_status(StressConfig.AFFLICTION_STATUS).get("icon", "")))
	
	# 收尾：扣除本回合行动点并重建队列（与晕眩跳过、激励喊话保持一致的做法）
	# 队友可能因失控攻击而阵亡补位，因此按引用重新定位失控者
	var idx := heroes.find(hero)
	if idx >= 0:
		heroes[idx]["actions_remaining"] = max(0, int(heroes[idx].get("actions_remaining", 1)) - 1)
	turn_queue.build(heroes, monsters)
	_update_ui()
	return false

# 失控行为"攻击队友"：复用激励倒戈的结算（返回 {} 表示无人可攻）
func _execute_breakdown_attack_ally(actor: Dictionary) -> Dictionary:
	return _execute_inspire_betrayal(actor, StressConfig.BREAKDOWN_ATTACK_RATIO)

# 压力结算后收尾：把因"心脏骤停"（压力满上限的 999 伤害）而倒下但尚未处理的英雄
# 补上瀕死/死亡判定。仅用于"只有压力变动、没有其他伤害处理"的路径（激励喊话、失控加压）。
func _handle_stress_damage_aftermath() -> void:
	var i := 0
	while i < heroes.size():
		var h := heroes[i]
		if h.get("hp", 0) <= 0 and not h.get("is_death_door", false):
			var died: bool = _handle_hero_damage_aftermath(i, true)
			if died:
				continue # 阵亡补位：不推进下标，重新检查同一位置
		i += 1

# 失控行为"增加队友压力"：返回 false 表示无人可加压
func _execute_breakdown_stress_ally(actor: Dictionary) -> bool:
	var target := _pick_random_ally(actor)
	if target.is_empty():
		return false
	var snaps: Array[Dictionary] = [_snap_unit(target)]
	ActionResolver.apply_stress(target, ActionResolver.roll_range_int(StressConfig.BREAKDOWN_STRESS_AMOUNT))
	_emit_feedback([target], snaps) # 内部会顺带结算"压力越阈"的目标
	_handle_stress_damage_aftermath() # 压力满上限的"心脏骰停"可能直接把队友打倒
	print("[Affliction] ", actor.get("name", "?"), " dumps stress on ", target.get("name", "?"))
	return true

# 随机挑一名"除自己以外仍可行动"的队友（无则返回 {}）
func _pick_random_ally(actor: Dictionary) -> Dictionary:
	var candidates: Array[Dictionary] = []
	for h in heroes:
		if is_same(h, actor):
			continue
		if h.get("hp", 0) > 0 or h.get("is_death_door", false):
			candidates.append(h)
	if candidates.is_empty():
		return {}
	return candidates[randi() % candidates.size()]

# 失控行为"自动随机行动"：随机挑一个当前站位可用且目标合法的技能，
# 再走与玩家操作完全相同的结算流程（特效 / 聚焦 / 数值 / 扣点 / 推进队列）
# 返回 true 表示已成功接管；false 表示无可用技能（调用方退化为跳过行动）
func _auto_perform_random_action(hero_idx: int) -> bool:
	if hero_idx < 0 or hero_idx >= heroes.size():
		return false
	var hero := heroes[hero_idx]
	# 濒死（HP = 0）的英雄无法出招（与 _can_act() 的判定一致）→ 退化为跳过行动
	if hero.get("hp", 0) <= 0:
		return false
	var pool: Array[Dictionary] = []
	for skill_id_val in hero.get("skills", []):
		var skill_id := str(skill_id_val)
		var sd := SkillConfig.get_skill(skill_id)
		if sd.is_empty():
			continue
		var use_positions: Array = sd.get("use_positions", [])
		if not use_positions.is_empty() and not ((hero_idx + 1) in use_positions):
			continue
		var target_type: String = str(sd.get("target_type", "single_enemy"))
		match target_type:
			"all_enemies":
				if _valid_monster_targets(sd).is_empty():
					continue
				pool.append({"skill_id": skill_id, "target_type": target_type, "target_index": - 1})
			"single_ally", "self":
				var hero_t_idx := _pick_random_ally_target(sd)
				if hero_t_idx < 0:
					continue
				pool.append({"skill_id": skill_id, "target_type": target_type, "target_index": hero_t_idx})
			_:
				var monster_t_idx := _pick_random_monster_target(sd)
				if monster_t_idx < 0:
					continue
				pool.append({"skill_id": skill_id, "target_type": target_type, "target_index": monster_t_idx})
	if pool.is_empty():
		return false
	var pick: Dictionary = pool[randi() % pool.size()]
	print("[Affliction] auto action → ", pick["skill_id"], " target_index=", pick["target_index"])
	hero_skill_selected = true
	hero_current_skill = str(pick["skill_id"])
	_update_ui()
	match str(pick["target_type"]):
		"all_enemies":
			await _on_attack_all_enemies()
		"single_ally", "self":
			await _on_ally_pressed(int(pick["target_index"]))
		_:
			await _on_monster_pressed(int(pick["target_index"]))
	return true

# 技能可命中的存活怪物下标（按 target_positions 过滤）
func _valid_monster_targets(sd: Dictionary) -> Array[int]:
	var positions: Array = sd.get("target_positions", [])
	var result: Array[int] = []
	for i in range(monsters.size()):
		if monsters[i].get("hp", 0) > 0 and (positions.is_empty() or ((i + 1) in positions)):
			result.append(i)
	return result

func _pick_random_monster_target(sd: Dictionary) -> int:
	var valid := _valid_monster_targets(sd)
	if valid.is_empty():
		return -1
	return valid[randi() % valid.size()]

# 技能可作用的友方下标：治疗类只选未满血/濒死的友方（避免把行动白白浪费在满血目标上）
func _pick_random_ally_target(sd: Dictionary) -> int:
	var positions: Array = sd.get("target_positions", [])
	var is_heal: bool = str(sd.get("effect_type", "")) in ["heal", "composite_heal"]
	var valid: Array[int] = []
	for i in range(heroes.size()):
		var h := heroes[i]
		if not (h.get("hp", 0) > 0 or h.get("is_death_door", false)):
			continue
		if not positions.is_empty() and not ((i + 1) in positions):
			continue
		if is_heal and h.get("hp", 0) >= h.get("max_hp", 0):
			continue
		valid.append(i)
	if valid.is_empty():
		return -1
	return valid[randi() % valid.size()]

# ============================================================
# 胜负判定
# ============================================================

# 存活且可战斗的单位数（非尸体，非真死）
func _count_alive(units: Array[Dictionary]) -> int:
	var n := 0
	for u in units:
		if u["hp"] > 0 and not u.get("is_corpse", false):
			n += 1
	return n

# 英雄存活数（包括濒死状态 is_death_door）
func _count_heroes_alive() -> int:
	var n := 0
	for h in heroes:
		if h["hp"] > 0 or h.get("is_death_door", false):
			n += 1
	return n

# 可战斗怪物数（排除尸体）
func _count_fighting_monsters() -> int:
	var n := 0
	for m in monsters:
		if m["hp"] > 0 and not m.get("is_corpse", false):
			n += 1
	return n

func _first_alive(units: Array[Dictionary]) -> Dictionary:
	for u in units:
		if u["hp"] > 0:
			return u
	return {}

func _check_victory() -> bool:
	if _count_fighting_monsters() == 0:
		_end_battle()
		return true
	return false

func _check_defeat() -> bool:
	if _count_heroes_alive() == 0:
		_end_battle()
		return true
	return false

func _end_battle() -> void:
	if battle_over:
		return
	battle_over = true
	current_actor = {}
	_battle_won = _count_fighting_monsters() == 0
	_run_complete = _battle_won and DungeonMap.is_boss_room(DungeonMap.current_room)
	if _battle_won:
		DungeonMap.mark_cleared(DungeonMap.current_room)
	if victory_panel:
		victory_panel.visible = true
	_refresh_end_battle_content()
	if _battle_won:
		HeroConfig.persist_party_after_battle(heroes)
		# 胜利后进入结算步骤：右侧展示本场战利品，玩家点击确认后才可离开
		_begin_loot_step()
	else:
		# 失败没有战利品，直接放行（同时清空可能残留的待领战利品，避免跨状态污染）
		_pending_loot.clear()
		_loot_claimed = false
		_hide_loot_panel()
		if back_button:
			back_button.disabled = false
	_update_ui()

# ============================================================
# 战斗结算（战利品）
# ============================================================

# 掷出本场战斗的战利品（胜利时调用一次）
func _roll_battle_loot() -> Array[Dictionary]:
	var loot: Array[Dictionary] = []
	for spec in BATTLE_LOOT_TABLE:
		var item_id: String = str(spec.get("item_id", ""))
		if item_id == "" or not (item_id in ConsumableConfig.ITEMS):
			continue
		var count: int = ActionResolver.roll_range_int(spec.get("count", 0))
		if count > 0:
			loot.append({"item_id": item_id, "count": count})
	return loot

# 进入结算步骤：掷战利品并在右侧弹出面板，锁定返回按钮直到玩家确认
func _begin_loot_step() -> void:
	_pending_loot = _roll_battle_loot()
	_loot_claimed = false
	_show_loot_panel(_pending_loot)
	# 未确认前不能离开战斗（return to map / back to start）；仅当结算面板确实创建成功时才锁定，避免卡死
	if back_button and loot_modal:
		back_button.disabled = true

# 玩家点击确认：把面板上的战利品加入背包，收起面板并放行返回按钮
func _on_loot_confirm_pressed() -> void:
	if not loot_modal or not loot_modal.visible:
		return
	var gained := PackedStringArray()
	var full_slots := PackedStringArray()
	for entry in _pending_loot:
		var item_id: String = str(entry.get("item_id", ""))
		var count: int = int(entry.get("count", 0))
		if count <= 0:
			continue
		if ConsumableConfig.add_item(item_id, count):
			var item := ConsumableConfig.get_item(item_id)
			gained.append("%s x%d" % [str(item.get("name", item_id)), count])
		else:
			full_slots.append(item_id)
	print("[Loot] Claimed: ", " ".join(gained))
	_pending_loot.clear()
	_loot_claimed = true
	_hide_loot_panel()
	Sfx.play_ui("reward", -8.0)
	if back_button:
		back_button.disabled = false
	_build_inventory_panel()
	if not full_slots.is_empty():
		_show_toast("背包已满，无法放入：%s" % "、".join(full_slots))

func _hide_loot_panel() -> void:
	if loot_modal:
		loot_modal.visible = false

# 在右侧弹出战利品结算面板（物品行按本次掷出的战利品动态生成）
func _show_loot_panel(loot: Array[Dictionary]) -> void:
	if not loot_modal or not loot_items_root:
		return
	_clear_children(loot_items_root)
	for entry in loot:
		var item_id: String = str(entry.get("item_id", ""))
		var count: int = int(entry.get("count", 0))
		if count <= 0:
			continue
		var item := ConsumableConfig.get_item(item_id)
		if item.is_empty():
			continue
		loot_items_root.add_child(_make_loot_row(item, count))
	if loot_items_root.get_child_count() == 0:
		var empty_lbl := Label.new()
		empty_lbl.text = "（本次没有拾得任何补给）"
		empty_lbl.add_theme_color_override("font_color", Color(0.7, 0.66, 0.55, 1))
		empty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		loot_items_root.add_child(empty_lbl)
	loot_modal.visible = true

# 单条战利品行：图标 + 名称 + x数量
func _make_loot_row(item: Dictionary, count: int) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.custom_minimum_size = Vector2(0, 40)

	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(34, 34)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var icon_path: String = str(item.get("icon", ""))
	if icon_path != "" and ResourceLoader.exists(icon_path):
		icon.texture = load(icon_path)
	row.add_child(icon)

	var name_lbl := Label.new()
	name_lbl.text = str(item.get("name", ""))
	name_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_lbl.add_theme_font_size_override("font_size", 14)
	name_lbl.add_theme_color_override("font_color", Color(0.92, 0.87, 0.7, 1))
	row.add_child(name_lbl)

	var count_lbl := Label.new()
	count_lbl.text = "x%d" % count
	count_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	count_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	count_lbl.add_theme_font_size_override("font_size", 14)
	count_lbl.add_theme_color_override("font_color", Color(1.0, 0.86, 0.4, 1))
	row.add_child(count_lbl)

	var tooltip_lines := PackedStringArray()
	tooltip_lines.append(str(item.get("name", "")))
	var item_desc: String = str(item.get("description", ""))
	if item_desc != "":
		tooltip_lines.append(item_desc)
	row.tooltip_text = "\n".join(tooltip_lines)
	return row

# 创建战利品结算 UI（右侧面板 + 确认按钮），常驻但默认隐藏
func _create_loot_ui() -> void:
	var ui_root := get_node_or_null("BattleUI")
	if ui_root == null:
		return

	var loot_layer := CanvasLayer.new()
	loot_layer.name = "LootLayer"
	loot_layer.layer = LOOT_LAYER
	ui_root.add_child(loot_layer)

	# 半透明遮罩：结算期间屏蔽战斗界面的点击（含返回按钮）
	loot_modal = ColorRect.new()
	loot_modal.name = "LootModal"
	loot_modal.color = Color(0.05, 0.04, 0.03, 0.4)
	loot_modal.anchor_left = 0.0
	loot_modal.anchor_top = 0.0
	loot_modal.anchor_right = 1.0
	loot_modal.anchor_bottom = 1.0
	loot_modal.mouse_filter = Control.MOUSE_FILTER_STOP
	loot_modal.visible = false
	loot_layer.add_child(loot_modal)

	# 面板本体：贴屏幕右侧、垂直居中
	loot_panel = Panel.new()
	loot_panel.name = "LootPanel"
	loot_panel.anchor_left = 1.0
	loot_panel.anchor_top = 0.5
	loot_panel.anchor_right = 1.0
	loot_panel.anchor_bottom = 0.5
	loot_panel.offset_left = -300.0
	loot_panel.offset_top = -200.0
	loot_panel.offset_right = -20.0
	loot_panel.offset_bottom = 200.0

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.11, 0.09, 0.07, 0.96)
	panel_style.border_width_left = 2
	panel_style.border_width_top = 2
	panel_style.border_width_right = 2
	panel_style.border_width_bottom = 2
	panel_style.border_color = Color(0.62, 0.5, 0.24, 1)
	panel_style.corner_radius_top_left = 6
	panel_style.corner_radius_top_right = 6
	panel_style.corner_radius_bottom_left = 6
	panel_style.corner_radius_bottom_right = 6
	loot_panel.add_theme_stylebox_override("panel", panel_style)
	loot_modal.add_child(loot_panel)

	var vbox := VBoxContainer.new()
	vbox.anchor_left = 0.0
	vbox.anchor_top = 0.0
	vbox.anchor_right = 1.0
	vbox.anchor_bottom = 1.0
	vbox.offset_left = 18.0
	vbox.offset_top = 18.0
	vbox.offset_right = -18.0
	vbox.offset_bottom = -18.0
	vbox.add_theme_constant_override("separation", 10)
	loot_panel.add_child(vbox)

	loot_title_label = Label.new()
	loot_title_label.text = "战利品"
	loot_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	loot_title_label.add_theme_font_size_override("font_size", 20)
	loot_title_label.add_theme_color_override("font_color", Color(1.0, 0.86, 0.4, 1))
	vbox.add_child(loot_title_label)

	loot_hint_label = Label.new()
	loot_hint_label.text = "点击确认将战利品放入物品栏"
	loot_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	loot_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	loot_hint_label.add_theme_font_size_override("font_size", 12)
	loot_hint_label.add_theme_color_override("font_color", Color(0.78, 0.73, 0.6, 1))
	vbox.add_child(loot_hint_label)

	loot_items_root = VBoxContainer.new()
	loot_items_root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	loot_items_root.add_theme_constant_override("separation", 6)
	vbox.add_child(loot_items_root)

	loot_confirm_button = Button.new()
	loot_confirm_button.text = "确认"
	loot_confirm_button.custom_minimum_size = Vector2(0, 40)
	loot_confirm_button.add_theme_font_size_override("font_size", 16)
	loot_confirm_button.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	var btn_style := StyleBoxFlat.new()
	btn_style.bg_color = Color(0.3, 0.24, 0.1, 1)
	btn_style.border_width_left = 1
	btn_style.border_width_top = 1
	btn_style.border_width_right = 1
	btn_style.border_width_bottom = 1
	btn_style.border_color = Color(0.75, 0.62, 0.28, 1)
	btn_style.corner_radius_top_left = 4
	btn_style.corner_radius_top_right = 4
	btn_style.corner_radius_bottom_left = 4
	btn_style.corner_radius_bottom_right = 4
	var btn_hover := btn_style.duplicate()
	btn_hover.bg_color = Color(0.42, 0.34, 0.14, 1)
	loot_confirm_button.add_theme_stylebox_override("normal", btn_style)
	loot_confirm_button.add_theme_stylebox_override("hover", btn_hover)
	loot_confirm_button.add_theme_stylebox_override("pressed", btn_hover)
	vbox.add_child(loot_confirm_button)

	loot_confirm_button.pressed.connect(_on_loot_confirm_pressed)

# ============================================================
# 战斗结算界面（胜利 / 远征终结 / 战败）
#
# 三种结局共用一张卡片，只换标题、描述、徽记与按钮文案：
#   · victory      普通胜利 → 返回地图继续探索
#   · run_complete 击败 BOSS 房首领 → 远征终结，返回开始界面
#   · defeat       全员阵亡 / 濒死未起 → 返回开始界面
# 卡片固定 680 宽居中（x 300~980），与右侧战利品面板（x 980~1260）刚好错开。
# ============================================================

# 构建结算卡片骨架；具体文案与数值由 _refresh_end_battle_content() 在战斗结束时填充
func _create_end_battle_ui() -> void:
	if victory_panel == null or battle_ui == null:
		return

	# 角色 SpinePlayer 是挂在 Battle 根节点下的 Node2D，并且在 _process 里被设成
	# z_index = 10 —— 也就是说它们会画在 BattleUI 之上。所以结算面板必须搬进
	# 独立的 CanvasLayer，否则英雄会“站在”结算卡片前面（与战利品结算同一种做法）。
	var end_layer := CanvasLayer.new()
	end_layer.name = "EndLayer"
	end_layer.layer = END_LAYER
	battle_ui.add_child(end_layer)
	var old_parent := victory_panel.get_parent()
	if old_parent != null:
		old_parent.remove_child(victory_panel)
	end_layer.add_child(victory_panel)

	# 全屏暗幕：保留一点透明度，让玩家还能看见刚才厮杀的战场
	var backdrop := StyleBoxFlat.new()
	backdrop.bg_color = Color(0.02, 0.018, 0.015, 0.88)
	victory_panel.add_theme_stylebox_override("panel", backdrop)
	victory_panel.mouse_filter = Control.MOUSE_FILTER_STOP # 挡住底下的战斗 UI

	# 上下黑边：收尾的电影感
	for is_top in [true, false]:
		var bar := ColorRect.new()
		bar.color = Color(0, 0, 0, 0.9)
		bar.anchor_left = 0.0
		bar.anchor_right = 1.0
		if is_top:
			bar.anchor_top = 0.0
			bar.anchor_bottom = 0.0
			bar.offset_bottom = 52.0
		else:
			bar.anchor_top = 1.0
			bar.anchor_bottom = 1.0
			bar.offset_top = -52.0
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		victory_panel.add_child(bar)

	# 卡片本体：屏幕正中
	_end_card = Panel.new()
	_end_card.name = "EndCard"
	_end_card.anchor_left = 0.5
	_end_card.anchor_top = 0.5
	_end_card.anchor_right = 0.5
	_end_card.anchor_bottom = 0.5
	_end_card.offset_left = - END_CARD_SIZE.x * 0.5
	_end_card.offset_top = - END_CARD_SIZE.y * 0.5
	_end_card.offset_right = END_CARD_SIZE.x * 0.5
	_end_card.offset_bottom = END_CARD_SIZE.y * 0.5
	# 缩放动画的支点必须设在卡片中心，否则会从左上角“长出来”
	_end_card.pivot_offset = END_CARD_SIZE * 0.5
	_end_card.mouse_filter = Control.MOUSE_FILTER_STOP
	_end_card.add_theme_stylebox_override("panel", _end_card_style())
	victory_panel.add_child(_end_card)

	var margin := MarginContainer.new()
	margin.anchor_right = 1.0
	margin.anchor_bottom = 1.0
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	_end_card.add_child(margin)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	margin.add_child(column)

	# ① 标题行：装饰条作底衬 + 居中大标题（两者需重叠，所以用 Control 包一层）
	var title_row := Control.new()
	title_row.custom_minimum_size = Vector2(0, 46)
	title_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(title_row)

	_end_decor = TextureRect.new()
	_end_decor.texture = load(END_DECOR)
	_end_decor.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_end_decor.stretch_mode = TextureRect.STRETCH_SCALE
	_end_decor.anchor_right = 1.0
	_end_decor.anchor_bottom = 1.0
	_end_decor.modulate = Color(1, 1, 1, 0.9)
	_end_decor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_row.add_child(_end_decor)

	victory_label = Label.new()
	victory_label.name = "EndTitle"
	victory_label.text = "Victory"
	victory_label.anchor_right = 1.0
	victory_label.anchor_bottom = 1.0
	victory_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	victory_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	victory_label.add_theme_font_size_override("font_size", 34)
	victory_label.add_theme_color_override("font_color", END_GOLD)
	victory_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.95))
	victory_label.add_theme_constant_override("outline_size", 6)
	victory_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_row.add_child(victory_label)

	# ② 主体区：左侧徽记 + 右侧结局描述与战绩
	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 20)
	column.add_child(body)

	_end_art = TextureRect.new()
	_end_art.custom_minimum_size = Vector2(156, 156)
	_end_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_end_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_end_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_child(_end_art)

	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 12)
	body.add_child(right)

	_end_subtitle = Label.new()
	_end_subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_end_subtitle.add_theme_font_size_override("font_size", 14)
	_end_subtitle.add_theme_color_override("font_color", Color(0.82, 0.77, 0.65, 1))
	right.add_child(_end_subtitle)

	# 分隔线：用一根 1px 金色细线，比默认 HSeparator 更有“古旧卷宗”的味道
	var rule := ColorRect.new()
	rule.color = Color(0.62, 0.5, 0.24, 0.55)
	rule.custom_minimum_size = Vector2(0, 1)
	right.add_child(rule)

	_end_stats = VBoxContainer.new()
	_end_stats.add_theme_constant_override("separation", 5)
	right.add_child(_end_stats)

	# ③ 主按钮：返回地图 / 凯旋而归 / 重新开始
	back_button = Button.new()
	back_button.name = "EndButton"
	back_button.text = "Return to Map"
	back_button.custom_minimum_size = Vector2(0, 48)
	back_button.add_theme_font_size_override("font_size", 19)
	back_button.add_theme_color_override("font_color", Color(1, 0.96, 0.86, 1))
	back_button.add_theme_color_override("font_hover_color", Color(1, 1, 1, 1))
	back_button.add_theme_color_override("font_focus_color", Color(1, 1, 1, 1))
	back_button.add_theme_color_override("font_disabled_color", Color(0.6, 0.57, 0.5, 1))
	for key in ["normal", "hover", "pressed", "focus", "disabled"]:
		back_button.add_theme_stylebox_override(key, _end_button_style(key))
	column.add_child(back_button)
	# 注意：pressed 信号统一在 _ready() 里连接，这里不要重复连（否则处理器会跑两遍）

# 卡片底板：深棕 + 金色描边（与战利品面板、激励窗口同一套配色）
func _end_card_style() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.105, 0.086, 0.066, 0.97)
	s.border_width_left = 2
	s.border_width_top = 2
	s.border_width_right = 2
	s.border_width_bottom = 2
	s.border_color = Color(0.62, 0.5, 0.24, 1)
	s.corner_radius_top_left = 8
	s.corner_radius_top_right = 8
	s.corner_radius_bottom_left = 8
	s.corner_radius_bottom_right = 8
	return s

# 主按钮的 5 种状态（normal / hover / pressed / focus / disabled）
func _end_button_style(state: String) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	match state:
		"hover":
			s.bg_color = Color(0.42, 0.34, 0.14, 1)
		"pressed":
			s.bg_color = Color(0.24, 0.19, 0.08, 1)
		"focus":
			s.bg_color = Color(0.36, 0.29, 0.12, 1)
		"disabled":
			s.bg_color = Color(0.16, 0.14, 0.11, 1)
		_:
			s.bg_color = Color(0.3, 0.24, 0.1, 1)
	s.border_width_left = 1
	s.border_width_top = 1
	s.border_width_right = 1
	s.border_width_bottom = 1
	s.border_color = Color(0.35, 0.32, 0.26, 1) if state == "disabled" else Color(0.75, 0.62, 0.28, 1)
	s.corner_radius_top_left = 5
	s.corner_radius_top_right = 5
	s.corner_radius_bottom_left = 5
	s.corner_radius_bottom_right = 5
	s.content_margin_top = 8
	s.content_margin_bottom = 8
	return s

# 战斗结束时填充结算内容（由 _end_battle() 调用）
func _refresh_end_battle_content() -> void:
	if _end_card == null or victory_label == null or back_button == null:
		return # 骨架没建起来（例如探针没挂 BattleUI），保持旧行为即可

	if _battle_won and _run_complete:
		_end_state = "run_complete"
	elif _battle_won:
		_end_state = "victory"
	else:
		_end_state = "defeat"

	match _end_state:
		"run_complete":
			victory_label.text = "远 征 终 结"
			victory_label.add_theme_color_override("font_color", END_GOLD)
			_end_subtitle.text = "门前恶狼尽数伏诛，火药桶的硝烟终于散去。\n探险队带着满身血污与战利品，踏上归乡的路。"
			_end_art.modulate = Color(1, 1, 1, 1)
			back_button.text = "凯  旋  而  归"
		"victory":
			victory_label.text = "胜    利"
			victory_label.add_theme_color_override("font_color", END_GOLD)
			_end_subtitle.text = "敌人的抵抗已经停止。走廊尽头，还有更深的黑暗在等着他们。"
			_end_art.modulate = Color(1, 1, 1, 1)
			back_button.text = "返  回  地  图"
		_:
			victory_label.text = "败    北"
			victory_label.add_theme_color_override("font_color", END_BLOOD)
			_end_subtitle.text = "烛火熄灭，最后一声呻吟也被黑暗吞没。\n这具躯壳，将永远留在这座地窖里。"
			# 折磨烙印原本是黑色剪影，在暗底上完全看不见 → 染成血色才算“烙印”
			_end_art.modulate = END_BLOOD
			back_button.text = "重  新  开  始"

	_end_art.texture = load(str(END_ART_BY_STATE.get(_end_state, "")))
	_fill_end_stats()
	_play_end_battle_intro()

# 战绩：让玩家知道这一场到底打成了什么样
func _fill_end_stats() -> void:
	if _end_stats == null:
		return
	for child in _end_stats.get_children():
		# 必须先 remove_child 再 queue_free：queue_free 要到帧末才真正删除，
		# 这一帧里旧行仍留在容器中会被重复绘制，也会让"行数"统计出错
		_end_stats.remove_child(child)
		child.queue_free()

	var total := heroes.size()
	var alive := _count_heroes_alive()
	var hp_now := 0
	var hp_max := 0
	var stress_sum := 0
	for h in heroes:
		hp_now += maxi(int(h.get("hp", 0)), 0)
		hp_max += int(h.get("max_hp", 0))
		stress_sum += int(h.get("stress", 0))
	var avg_stress := int(round(float(stress_sum) / float(maxi(total, 1))))

	_add_end_stat_row("战斗回合", "%d" % round_number, END_GOLD)
	_add_end_stat_row("存活英雄", "%d / %d" % [alive, total], END_GOLD if alive > 0 else END_BLOOD)
	_add_end_stat_row("队伍剩余生命", "%d / %d" % [hp_now, hp_max], END_GOLD if hp_now > 0 else END_BLOOD)
	# 压力是本作的核心资源：过半就标红，提醒玩家该回城减压了
	_add_end_stat_row("队伍平均压力", "%d" % avg_stress, END_BLOOD if avg_stress >= 50 else END_GOLD)

func _add_end_stat_row(name_text: String, value_text: String, value_color: Color) -> void:
	var row := HBoxContainer.new()
	var name_lbl := Label.new()
	name_lbl.text = name_text
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_lbl.add_theme_font_size_override("font_size", 14)
	name_lbl.add_theme_color_override("font_color", Color(0.72, 0.67, 0.55, 1))
	row.add_child(name_lbl)
	var value_lbl := Label.new()
	value_lbl.text = value_text
	value_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value_lbl.add_theme_font_size_override("font_size", 15)
	value_lbl.add_theme_color_override("font_color", value_color)
	row.add_child(value_lbl)
	_end_stats.add_child(row)

# 入场：整屏淡入 + 卡片微缩放；同时播一声音效
func _play_end_battle_intro() -> void:
	if _end_tween != null and _end_tween.is_valid():
		_end_tween.kill()
	victory_panel.modulate = Color(1, 1, 1, 0)
	_end_card.modulate = Color(1, 1, 1, 0)
	_end_card.scale = Vector2(0.94, 0.94)
	_end_tween = create_tween().set_parallel(true)
	_end_tween.tween_property(victory_panel, "modulate:a", 1.0, 0.35)
	_end_tween.tween_property(_end_card, "modulate:a", 1.0, 0.4).set_delay(0.08)
	_end_tween.tween_property(_end_card, "scale", Vector2.ONE, 0.45).set_delay(0.08).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	# 战败用同一个音源压低音高，听感上更沉闷，避免和胜利撞音色
	match _end_state:
		"defeat":
			Sfx.play_ui("window", -6.0, 0.72)
		"run_complete":
			Sfx.play_ui("victory", -6.0, 1.06)
		_:
			Sfx.play_ui("victory", -6.0)

# ============================================================
# 死亡 / 尸体 / 补位 处理
# ============================================================

# 怪物受到伤害后调用：HP≤0 时创建尸体或清除尸体
func _handle_monster_damage_aftermath(monster_idx: int) -> void:
	if monster_idx < 0 or monster_idx >= monsters.size():
		return
	var m := monsters[monster_idx]
	if m.get("is_corpse", false):
		# 尸体被击杀 → 清除尸体，后方怪物补位
		if m["hp"] <= 0:
			_clear_monster_corpse(monster_idx)
	else:
		# 正常怪物 HP 降为 0 → 留尸体
		if m["hp"] <= 0:
			m["is_corpse"] = true
			m["hp"] = 10 # 尸体血量
			m["actions_remaining"] = 0
			m["statuses"] = {} # 尸体不再承受流血/腐蚀等持续伤害
			print("[Corpse] ", m["name"], " fell, leaving a corpse with 10 HP")
			# 弹药桶被摧毁 → 立即解除首领留下的所有炸药标记
			if str(m.get("id", "")) == "brigand_barrel":
				_disarm_pending_bombs()
			# 生命链接：被链接者（弹药桶 / 点火员）随之一同倒下
			_apply_life_links(monster_idx)

# 清除怪物尸体并让后方怪物向前补位
func _clear_monster_corpse(corpse_idx: int) -> void:
	if corpse_idx < 0 or corpse_idx >= monsters.size():
		return
	
	var key := "monster_%d" % corpse_idx
	# 播放 death_medium 死亡特效覆盖层（尸体保持 dead 动画）
	if _spine_players.has(key):
		var sp = _spine_players[key]
		if is_instance_valid(sp):
			_play_death_fx_at(sp.global_position)
			sp.queue_free()
	_spine_players.erase(key)
	_spine_current_state.erase(key)
	
	print("[Corpse] Clearing corpse at index ", corpse_idx)
	monsters.remove_at(corpse_idx)
	
	# 重建怪物 SpinePlayer 键值映射（后方怪物向前补位）
	var new_spine: Dictionary = {}
	var new_state: Dictionary = {}
	for i in range(monsters.size()):
		# 原索引：如果 i >= corpse_idx，则原单位在 i+1 位置
		var old_key := "monster_%d" % (i + 1 if i >= corpse_idx else i)
		var new_key := "monster_%d" % i
		if _spine_players.has(old_key):
			new_spine[new_key] = _spine_players[old_key]
		if _spine_current_state.has(old_key):
			new_state[new_key] = _spine_current_state[old_key]
	
	# 合并：保留英雄键（int），替换怪物键（string）
	var merged_spine: Dictionary = {}
	var merged_state: Dictionary = {}
	for k in _spine_players:
		if not (k is String and k.begins_with("monster_")):
			merged_spine[k] = _spine_players[k]
	for k in _spine_current_state:
		if not (k is String and k.begins_with("monster_")):
			merged_state[k] = _spine_current_state[k]
	for k in new_spine:
		merged_spine[k] = new_spine[k]
	for k in new_state:
		merged_state[k] = new_state[k]
	_spine_players = merged_spine
	_spine_current_state = merged_state
	
	# 重建行动队列
	turn_queue.build(heroes, monsters)
	_update_ui()

# 英雄受到伤害 / 治疗后的收尾：处理死门（Death's Door / 濒死）与死亡骰
# 返回 true 表示英雄已真死
#
# 规则（与暗黑地牢一致）：
#   ① 生命值首次降至 0 → 不立刻死亡，而是进入濒死状态（is_death_door = true），仍可正常行动/被治疗；
#   ② 已在濒死状态时【受到任何伤害】→ 按该角色自己的 death_blow_chance 掷一次死亡骰，
#      命中则当场阵亡，否则继续苦苦支撑（弹出"死里逃生"图标）；
#   ③ 治疗等非伤害结算（took_damage = false）不掷骰——只要生命值回复到 0 以上就自动脱离濒死。
# 概率写在 HeroConfig.HEROES[hero_id]["death_blow_chance"]（见 HeroConfig 顶部说明）。
func _handle_hero_damage_aftermath(hero_idx: int, took_damage: bool = true) -> bool:
	if hero_idx < 0 or hero_idx >= heroes.size():
		return false
	var h := heroes[hero_idx]
	# 压力满上限的"心脏骤停 + 折磨 + 瀕死"：无视死门死扛，直接处决（见 ActionResolver.apply_stress）
	if ActionResolver.consume_instant_death(h):
		print("[Stress] ", h.get("name", "?"), " is struck down by a heart attack at death's door (afflicted)")
		_kill_hero(hero_idx)
		return true
	if h["hp"] > 0:
		# 存活状态，检查是否脱离濒死
		if h.get("is_death_door", false):
			h["is_death_door"] = false
			print("[DeathDoor] ", h["name"], " recovered from death's door!")
		return false
	
	# HP ≤ 0
	if not h.get("is_death_door", false):
		# 首次降至 0 → 进入死门（濒死），不会立刻死亡
		h["hp"] = 0
		h["is_death_door"] = true
		_show_status_popup(h, DEATHS_DOOR_ICON)
		print("[DeathDoor] ", h["name"], " has entered death's door!")
		return false
	
	# 已在死门：只有确实承受了伤害才进行死亡判定（治疗/净化等空结算一律不掷骰）
	h["hp"] = 0
	if not took_damage:
		return false
	var chance: float = clampf(float(h.get("death_blow_chance", HeroConfig.DEFAULT_DEATH_BLOW_CHANCE)), 0.0, 1.0)
	if randf() < chance:
		print("[DeathDoor] ", h["name"], " has died at death's door! (死亡概率 %.0f%%)" % (chance * 100.0))
		_kill_hero(hero_idx)
		return true
	# 撑过这一击：弹出"死里逃生"反馈，让玩家看到这次死亡骰的结果
	_show_status_popup(h, DEATH_AVOIDED_ICON)
	print("[DeathDoor] ", h["name"], " survived the death blow at death's door! (死亡概率 %.0f%%)" % (chance * 100.0))
	return false

# 英雄真死：播放共享死亡特效后移除并补位
func _kill_hero(hero_idx: int) -> void:
	if hero_idx < 0 or hero_idx >= heroes.size():
		return
	
	var hero_name = heroes[hero_idx].get("name", "???")
	print("[Death] Hero ", hero_name, " has been slain!")
	
	# 播放共享 death_medium 死亡特效覆盖层（角色保持受击动画）
	var sp: SpinePlayer = _spine_players.get(hero_idx) as SpinePlayer
	if is_instance_valid(sp):
		_play_death_fx_at(sp.global_position)
	
	# 清理 SpinePlayer
	if _spine_players.has(hero_idx):
		if is_instance_valid(sp):
			sp.queue_free()
		_spine_players.erase(hero_idx)
	_spine_current_state.erase(hero_idx)
	
	heroes.remove_at(hero_idx)
	
	# 重建英雄 SpinePlayer 索引映射
	var new_spine: Dictionary = {}
	var new_state: Dictionary = {}
	for i in range(heroes.size()):
		var old_idx := i + 1 if i >= hero_idx else i
		if _spine_players.has(old_idx):
			new_spine[i] = _spine_players[old_idx]
		if _spine_current_state.has(old_idx):
			new_state[i] = _spine_current_state[old_idx]
	_spine_players = new_spine
	_spine_current_state = new_state
	
	# 重建队列
	turn_queue.build(heroes, monsters)
	_update_ui()

# ============================================================
# 输入处理
# ============================================================

func _on_skill_pressed(skill_id: String) -> void:
	if battle_over or current_actor.is_empty() or current_actor["unit_type"] != "hero":
		return
	var sd := SkillConfig.get_skill(skill_id)
	if not sd.is_empty():
		var use_positions: Array = sd.get("use_positions", [])
		var hero_pos: int = current_actor["index"] + 1
		if not use_positions.is_empty() and not (hero_pos in use_positions):
			print("[Skill] %s unavailable at position %d (requires %s)" % [skill_id, hero_pos, use_positions])
			return
	hero_current_skill = skill_id
	hero_skill_selected = true
	_in_fx_pause = false
	_update_ui()

func _on_skip_pressed() -> void:
	if battle_over or current_actor.is_empty() or current_actor["unit_type"] != "hero":
		return
	hero_skill_selected = false
	hero_current_skill = ""
	reposition_mode = false
	_advance_action()

func _on_reposition_pressed() -> void:
	if battle_over or current_actor.is_empty() or current_actor["unit_type"] != "hero":
		return
	# 换位模式与技能选择互斥
	hero_skill_selected = false
	hero_current_skill = ""
	reposition_mode = not reposition_mode
	_update_ui()

func _on_hero_reposition_target(target_idx: int) -> void:
	if not reposition_mode:
		return
	reposition_mode = false
	var src_idx: int = current_actor["index"]
	if target_idx == src_idx:
		_update_ui()
		return
	
	# 执行换位 logic
	_apply_hero_reposition_position(src_idx, target_idx)
	
	# 主动换位扣除行动点
	heroes[current_actor["index"]]["actions_remaining"] -= 1
	hero_skill_selected = false
	hero_current_skill = ""
	turn_queue.build(heroes, monsters)
	_get_next_actor()
	_update_ui()

func _on_cancel_skill() -> void:
	if battle_over or current_actor.is_empty() or current_actor["unit_type"] != "hero":
		return
	hero_skill_selected = false
	hero_current_skill = ""
	_update_ui()

func _on_monster_pressed(index: int) -> void:
	if not _can_act():
		return
	if index < 0 or index >= monsters.size() or monsters[index]["hp"] <= 0:
		return
	var skill_data := SkillConfig.get_skill(hero_current_skill)
	if skill_data.is_empty():
		return
	
	# 1. 锁定行动，暂存技能 ID，触发 _update_ui 以切换出招方动画
	_in_fx_pause = true
	var s_id := hero_current_skill
	var is_damage: bool = skill_data.get("effect_type", "") == "damage"
	if is_damage:
		monsters[index]["is_defending"] = true
	_update_ui()
	
	# 聚焦：除攻击方与目标外，其余角色与背景虚化
	_apply_focus(heroes[current_actor["index"]], [monsters[index]])
	
	# 2. 生成特效后立即结算伤害并显示数字
	_play_skill_fx_v2(heroes[current_actor["index"]], s_id, [monsters[index]])
	if monsters[index].get("is_defending", false):
		monsters[index]["is_defending"] = false
	var snap := _snap_unit(monsters[index])
	ActionResolver.resolve_on_target(heroes[current_actor["index"]], skill_data, monsters[index])
	_emit_feedback([monsters[index]], [snap])
	
	# 处理怪物尸体创建/清除（可能移除该怪物）
	var was_cleared: bool = monsters[index].get("is_corpse", false) and monsters[index]["hp"] <= 0
	_handle_monster_damage_aftermath(index)
	
	# 3. 特效 + 数字持续 ATTACK_ZOOM_DURATION 秒
	await get_tree().create_timer(ATTACK_ZOOM_DURATION).timeout
	
	# 取消聚焦，恢复所有角色与背景
	_clear_focus()
	
	# 4. 特效演完，释放锁定并彻底清理已选技能
	_in_fx_pause = false
	hero_skill_selected = false
	var pre_current_skill := hero_current_skill
	hero_current_skill = ""
	_update_ui() # 刷新动画（回到正常状态）
	
	# 4.5 技能附带的“目标强制位移”（如灵魂之触将怪物拉前3位）
	#     打击动画结束后才结算，避免目标在出招途中发生视觉瞬移；
	#     was_cleared 为真说明尸体被清除、数组索引已整体前移，此时不再定位目标。
	if not was_cleared:
		_apply_skill_target_reposition(index, skill_data)
	
	if _check_victory():
		return
	await _finish_hero_action(pre_current_skill)

func _on_attack_all_enemies() -> void:
	if not _can_act():
		return
	var skill_data := SkillConfig.get_skill(hero_current_skill)
	if skill_data.is_empty():
		return
	var target_positions: Array = skill_data.get("target_positions", [])
	var final_targets: Array[Dictionary] = []
	if target_positions.is_empty():
		for m in monsters:
			if m["hp"] > 0:
				final_targets.append(m)
	else:
		for i in range(monsters.size()):
			if (i + 1) in target_positions and monsters[i]["hp"] > 0:
				final_targets.append(monsters[i])
				
	# 1. 锁定行动，暂存技能 ID，并刷新 UI 切换出招方动作
	_in_fx_pause = true
	var s_id := hero_current_skill
	var is_damage: bool = skill_data.get("effect_type", "") == "damage"
	if is_damage:
		for t in final_targets:
			t["is_defending"] = true
	_update_ui()
	
	# 聚焦：除攻击方与目标外，其余角色与背景虚化
	_apply_focus(heroes[current_actor["index"]], final_targets)
	
	# 2. 生成特效后立即结算伤害并显示数字
	_play_skill_fx_v2(heroes[current_actor["index"]], s_id, final_targets)
	for t in final_targets:
		t["is_defending"] = false
	var snaps: Array[Dictionary] = []
	for t in final_targets:
		snaps.append(_snap_unit(t))
	ActionResolver.resolve_on_all(heroes[current_actor["index"]], skill_data, final_targets)
	_emit_feedback(final_targets, snaps)
	
	# 处理所有怪物目标的尸体创建/清除
	for t in final_targets:
		var m_idx := monsters.find(t)
		if m_idx >= 0:
			_handle_monster_damage_aftermath(m_idx)
	
	# 3. 特效 + 数字持续 ATTACK_ZOOM_DURATION 秒
	await get_tree().create_timer(ATTACK_ZOOM_DURATION).timeout
	
	# 取消聚焦，恢复所有角色与背景
	_clear_focus()
	
	# 4. 特效演完，释放锁定并清理已选技能
	_in_fx_pause = false
	hero_skill_selected = false
	var pre_current_skill := hero_current_skill
	hero_current_skill = ""
	_update_ui()
	
	if _check_victory():
		return
	await _finish_hero_action(pre_current_skill)

func _on_ally_pressed(index: int) -> void:
	if not _can_act():
		return
	if index < 0 or index >= heroes.size():
		return
	var skill_data := SkillConfig.get_skill(hero_current_skill)
	if skill_data.is_empty():
		return
		
	# 1. 锁定行动，暂存技能 ID并刷新 UI 切换出招方动作
	_in_fx_pause = true
	var s_id := hero_current_skill
	_update_ui()
	
	# 聚焦：除施法者与目标外，其余角色与背景虚化
	_apply_focus(heroes[current_actor["index"]], [heroes[index]])
	
	# 2. 生成特效后立即结算（battle_cry 等可能影响全体友方）
	_play_skill_fx_v2(heroes[current_actor["index"]], s_id, [heroes[index]])
	var ally_snaps: Array[Dictionary] = []
	for h in heroes:
		ally_snaps.append(_snap_unit(h))
	ActionResolver.resolve_on_target(heroes[current_actor["index"]], skill_data, heroes[index], heroes)
	_emit_feedback(heroes, ally_snaps)
	
	# 治疗让英雄脱离濒死（治疗不是伤害，took_damage = false → 处于死门的队友不会因此被判死）
	_handle_hero_damage_aftermath(index, false)
	for i in range(heroes.size()):
		if i != index:
			_handle_hero_damage_aftermath(i, false)
	
	# 3. 特效 + 数字/图标持续 ATTACK_ZOOM_DURATION 秒
	await get_tree().create_timer(ATTACK_ZOOM_DURATION).timeout
	
	# 取消聚焦，恢复所有角色与背景
	_clear_focus()
	
	# 4. 特效演完，释放锁定并清理选定
	_in_fx_pause = false
	hero_skill_selected = false
	var pre_current_skill := hero_current_skill
	hero_current_skill = ""
	_update_ui()
	
	await _finish_hero_action(pre_current_skill)

func _on_back_pressed() -> void:
	Sfx.play_ui("click", -9.0)
	if _run_complete or not _battle_won:
		# 通关或失败：返回开始画面
		get_tree().change_scene_to_file("res://scenes/start/Start.tscn")
	else:
		# 普通胜利：返回地图继续探索
		get_tree().change_scene_to_file("res://scenes/map/Map.tscn")

# --- 辅助 ---

func _can_act() -> bool:
	return (not battle_over
		and not _in_fx_pause
		and not current_actor.is_empty()
		and current_actor["unit_type"] == "hero"
		and hero_skill_selected
		and heroes[current_actor["index"]]["hp"] > 0)

func _apply_hero_reposition_position(src_idx: int, target_idx: int) -> void:
	if target_idx == src_idx:
		return
	
	# 保存旧映射
	var src_spine: Variant = _spine_players.get(src_idx)
	var src_state: Variant = _spine_current_state.get(src_idx, "")
	
	# 循环位移
	var hero_to_move: Dictionary = heroes[src_idx]
	heroes.remove_at(src_idx)
	var insert_at: int = target_idx
	heroes.insert(insert_at, hero_to_move)
	
	# 更新 heroes index
	for i in range(heroes.size()):
		heroes[i]["index"] = i
		
	# 重建 _spine_players 和 _spine_current_state
	var new_spine_players: Dictionary = {}
	var new_spine_current_state: Dictionary = {}
	
	if src_idx < target_idx:
		# 向右移动
		for i in range(heroes.size()):
			if i < src_idx:
				if _spine_players.has(i):
					new_spine_players[i] = _spine_players[i]
					new_spine_current_state[i] = _spine_current_state.get(i, "")
			elif i < insert_at:
				if _spine_players.has(i + 1):
					new_spine_players[i] = _spine_players[i + 1]
					new_spine_current_state[i] = _spine_current_state.get(i + 1, "")
			elif i == insert_at:
				if src_spine:
					new_spine_players[i] = src_spine
					new_spine_current_state[i] = src_state
			else:
				if _spine_players.has(i):
					new_spine_players[i] = _spine_players[i]
					new_spine_current_state[i] = _spine_current_state.get(i, "")
	else:
		# 向左移动
		for i in range(heroes.size()):
			if i < insert_at:
				if i < target_idx and _spine_players.has(i):
					new_spine_players[i] = _spine_players[i]
					new_spine_current_state[i] = _spine_current_state.get(i, "")
			elif i == insert_at:
				if src_spine:
					new_spine_players[i] = src_spine
					new_spine_current_state[i] = src_state
			elif i <= src_idx:
				if _spine_players.has(i - 1):
					new_spine_players[i] = _spine_players[i - 1]
					new_spine_current_state[i] = _spine_current_state.get(i - 1, "")
			else:
				if _spine_players.has(i):
					new_spine_players[i] = _spine_players[i]
					new_spine_current_state[i] = _spine_current_state.get(i, "")
				
	# 保留所有的怪物 SpinePlayer 和动画状态，防止因为英雄位移重建字典而丢失
	for key in _spine_players.keys():
		if typeof(key) != TYPE_INT:
			new_spine_players[key] = _spine_players[key]
			new_spine_current_state[key] = _spine_current_state.get(key, "")
				
	_spine_players = new_spine_players
	_spine_current_state = new_spine_current_state
	
	current_actor["index"] = insert_at

# 强制重定位怪物在 monsters 数组中的站位（用于将目标拉前/推后）
# 与 _apply_hero_reposition_position 对称：同步重排怪物数据与 SpinePlayer 映射；
# 注意：行动队列的重建不在此处进行，需由 _finish_hero_action 在扣除行动点后调用，避免重复行动
func _apply_monster_reposition_position(src_idx: int, target_idx: int) -> void:
	if src_idx < 0 or src_idx >= monsters.size():
		return
	target_idx = int(clamp(target_idx, 0, monsters.size() - 1))
	if target_idx == src_idx:
		return
	
	# 1. 按索引顺序缓存旧的 SpinePlayer / 动画状态槽位
	var spine_slots: Array = []
	var state_slots: Array = []
	for i in range(monsters.size()):
		var old_key := "monster_%d" % i
		spine_slots.append(_spine_players.get(old_key))
		state_slots.append(_spine_current_state.get(old_key, ""))
	
	# 2. 物理重排 monsters 数组并刷新 index
	var monster_to_move: Dictionary = monsters[src_idx]
	monsters.remove_at(src_idx)
	monsters.insert(target_idx, monster_to_move)
	for i in range(monsters.size()):
		monsters[i]["index"] = i
	
	# 3. 以同样的位移规则重排 Spine 槽位，保证视觉效果与数据一致
	var moved_spine = spine_slots[src_idx]
	var moved_state = state_slots[src_idx]
	spine_slots.remove_at(src_idx)
	spine_slots.insert(target_idx, moved_spine)
	state_slots.remove_at(src_idx)
	state_slots.insert(target_idx, moved_state)
	
	# 4. 清除旧的怪物键（"monster_*"），保留英雄键（int）后写入新键
	for k in _spine_players.keys():
		if k is String and k.begins_with("monster_"):
			_spine_players.erase(k)
	for k in _spine_current_state.keys():
		if k is String and k.begins_with("monster_"):
			_spine_current_state.erase(k)
	for i in range(monsters.size()):
		var new_key := "monster_%d" % i
		if spine_slots[i] != null:
			_spine_players[new_key] = spine_slots[i]
		if state_slots[i] != null:
			_spine_current_state[new_key] = state_slots[i]
	
	# 5. 仅刷新 UI（锚点/站位重建）；行动队列的重建必须延后到本回合行动点扣除之后，
	#    否则施法者会带着 actions_remaining=1 被重新入队，导致同一回合重复行动（见 _finish_hero_action）
	_update_ui()

# 技能附带的“目标强制位移”：将指定怪物按 target_move_forward 拉前/推后
# 正数向排头方向（索引减小）拉前，负数向排尾方向（索引增大）推后
func _apply_skill_target_reposition(target_idx: int, skill_data: Dictionary) -> void:
	if target_idx < 0 or target_idx >= monsters.size():
		return
	var pull: int = int(skill_data.get("target_move_forward", 0))
	if pull == 0:
		return
	# 已死亡/尸体不参与拉前，避免把尸体拖到排头
	var m := monsters[target_idx]
	if m.get("hp", 0) <= 0 or m.get("is_corpse", false):
		return
	var dst: int = int(clamp(target_idx - pull, 0, monsters.size() - 1))
	if dst == target_idx:
		return
	_apply_monster_reposition_position(target_idx, dst)
	_target_reposition_applied = true

func _finish_hero_action(used_skill_id: String = "") -> void:
	# 本回合“是否已扣除行动点并重建队列”的统一标记，避免重复扣点或重复入队
	var action_consumed: bool = false
	var is_hero_actor: bool = current_actor.get("unit_type") == "hero"
	var skill_to_check := hero_current_skill if used_skill_id == "" else used_skill_id
	if skill_to_check != "":
		var skill_data: Dictionary = SkillConfig.get_skill(skill_to_check)
		if not skill_data.is_empty():
			# A. 施法者自身位移 (move_forward)
			var move_f: int = int(skill_data.get("move_forward", 0))
			if move_f != 0 and is_hero_actor:
				var src_idx: int = current_actor["index"]
				var target_idx: int = int(clamp(src_idx - move_f, 0, heroes.size() - 1))
				if target_idx != src_idx:
					# 1. 先扣除本回合行动点
					heroes[src_idx]["actions_remaining"] -= 1
					# 2. 执行位移 (支持前进 > 0 和后退 < 0)
					_apply_hero_reposition_position(src_idx, target_idx)
					# 3. 重建队列
					turn_queue.build(heroes, monsters)
					action_consumed = true
			# B. 目标强制位移 (target_move_forward，如灵魂之触将怪物拉前3)
			#    monsters 数组与 Spine 映射已在打击动画结束时重排，此处仅需在扣除行动点后重建队列，
			#    否则施法者会带着 actions_remaining=1 被重新入队而重复行动。
			if _target_reposition_applied and not action_consumed and is_hero_actor:
				heroes[current_actor["index"]]["actions_remaining"] -= 1
				turn_queue.build(heroes, monsters)
				action_consumed = true
	_target_reposition_applied = false
	
	hero_skill_selected = false
	hero_current_skill = ""
	
	if action_consumed:
		await _get_next_actor()
	else:
		await _advance_action()

# ============================================================
# UI 更新
# ============================================================

func _update_ui() -> void:
	_update_crusader_animations()
	_update_monster_animations()
	_update_list_ui()
	_update_selected_text()
	_update_character_portrait()
	_update_skill_buttons()

func _update_character_portrait() -> void:
	if not portrait_box or current_actor.get("unit_type") != "hero":
		return
	# 防守：英雄阵亡补位后 current_actor 可能短暂指向已不存在的下标（与 _update_selected_text 同一套防护），
	# 直接索引会抛 "Invalid access of index ... on Array[Dictionary]"
	var h_idx: int = int(current_actor.get("index", -1))
	if h_idx < 0 or h_idx >= heroes.size():
		_clear_children(portrait_box)
		return
	
	var hero = heroes[h_idx]
	var hero_name: String = hero.get("name", "Unknown")
	
	# 获取英雄对应的头像路径
	var portrait_path: String = "res://characters/%s/%s_A/%s_portrait_roster.png" % [hero_name.to_lower(), hero_name.to_lower(), hero_name.to_lower()]
	
	# 清空旧内容
	_clear_children(portrait_box)
	
	# 尝试加载头像
	if ResourceLoader.exists(portrait_path):
		var texture = load(portrait_path)
		if texture:
			var portrait_img = TextureRect.new()
			portrait_img.texture = texture
			portrait_img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			portrait_img.layout_mode = 1
			portrait_img.anchors_preset = 15
			portrait_img.anchor_left = 0.0
			portrait_img.anchor_top = 0.0
			portrait_img.anchor_right = 1.0
			portrait_img.anchor_bottom = 1.0
			portrait_box.add_child(portrait_img)
	# 文件不存在时不显示任何内容


func _update_skill_buttons() -> void:
	if not skill_container or current_actor.get("unit_type") != "hero":
		# 清空技能框
		for icon_box in skill_icon_boxes:
			_clear_children(icon_box)
		# 禁用换位按钮和跳过按钮
		if reposition_button:
			reposition_button.disabled = true
		if skip_button:
			skip_button.disabled = true
		if inspire_button:
			inspire_button.disabled = true
		return
	
	# 启用换位按钮和跳过按钮
	if reposition_button:
		reposition_button.disabled = false
	if skip_button:
		skip_button.disabled = false
	if inspire_button:
		inspire_button.disabled = _is_requesting_llm
	
	# 清空旧内容
	for icon_box in skill_icon_boxes:
		_clear_children(icon_box)

	# 换位模式下显示提示
	if reposition_mode:
		return

	# 已选技能 — 根据目标类型显示提示或操作按钮
	if hero_skill_selected:
		var sd := SkillConfig.get_skill(hero_current_skill)
		if not sd.is_empty():
			var target_type: String = sd.get("target_type", "single_enemy")
			var target_pos: Array = sd.get("target_positions", [])
			
			match target_type:
				"all_enemies":
					# 显示攻击所有敌人按钮
					if skill_icon_boxes.size() > 0:
						var btn = Button.new()
						btn.custom_minimum_size = Vector2(50, 50)
						if target_pos.is_empty():
							btn.text = "Attack\nAll"
						else:
							var pos_parts := PackedStringArray()
							for p in target_pos:
								pos_parts.append(str(p))
							btn.text = "Attack\n(%s)" % ", ".join(pos_parts)
						btn.pressed.connect(_on_attack_all_enemies, CONNECT_DEFERRED)
						skill_icon_boxes[0].add_child(btn)
				"single_ally":
					# 显示选择友方提示
					if skill_icon_boxes.size() > 0:
						var lbl = Label.new()
						lbl.text = "Select\nAlly"
						lbl.custom_minimum_size = Vector2(50, 50)
						lbl.add_theme_color_override("font_color", Color(1.0, 0.9, 0.2, 1))
						lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
						lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
						lbl.add_theme_font_size_override("font_size", 10)
						skill_icon_boxes[0].add_child(lbl)
				"single_enemy":
					# 显示选择敌人提示
					if skill_icon_boxes.size() > 0:
						var lbl = Label.new()
						lbl.text = "Select\nEnemy"
						lbl.custom_minimum_size = Vector2(50, 50)
						lbl.add_theme_color_override("font_color", Color(0.8, 0.3, 0.3, 1))
						lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
						lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
						lbl.add_theme_font_size_override("font_size", 10)
						skill_icon_boxes[0].add_child(lbl)
		
		# 显示取消按钮
		if skill_icon_boxes.size() > 1:
			var cancel_btn = Button.new()
			cancel_btn.text = "X"
			cancel_btn.custom_minimum_size = Vector2(50, 50)
			cancel_btn.add_theme_font_size_override("font_size", 12)
			cancel_btn.pressed.connect(_on_cancel_skill, CONNECT_DEFERRED)
			skill_icon_boxes[1].add_child(cancel_btn)
		return

	# 未选技能 — 显示英雄技能图标
	# 防守：与 _update_character_portrait 同理，补位瞬间 current_actor 可能是失效下标
	var skill_h_idx: int = int(current_actor.get("index", -1))
	if skill_h_idx < 0 or skill_h_idx >= heroes.size():
		return
	var hero := heroes[skill_h_idx]
	var hero_name: String = hero.get("name", "").to_lower()
	for skill_idx in range(hero.get("skills", []).size()):
		if skill_idx >= skill_icon_boxes.size():
			break
		
		var skill_id = hero.get("skills", [])[skill_idx]
		var sd := SkillConfig.get_skill(skill_id)
		if sd.is_empty():
			continue
		
		# 尝试加载技能图标
		var skill_num: int = sd.get("icon_num", skill_idx + 1)
		var icon_path: String = "res://characters/%s/%s.ability.%s.png" % [hero_name, hero_name, _number_to_word(skill_num)]
		
		var icon_box = skill_icon_boxes[skill_idx]
		if ResourceLoader.exists(icon_path):
			var icon_texture = load(icon_path)
			if icon_texture:
				# 创建可点击的 Button - 完全填满 icon_box
				var btn = Button.new()
				btn.layout_mode = 1
				btn.anchors_preset = 15 # 全填充
				btn.anchor_left = 0.0
				btn.anchor_top = 0.0
				btn.anchor_right = 1.0
				btn.anchor_bottom = 1.0
				btn.icon = icon_texture
				btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
				btn.tooltip_text = _build_skill_tooltip(sd)
				btn.pressed.connect(_on_skill_pressed.bind(skill_id), CONNECT_DEFERRED)
				icon_box.add_child(btn)


# 创建英雄内容（用于填充预设位置）
func _make_hero_content(hero: Dictionary, idx: int, target_type: String, target_positions: Array = []) -> VBoxContainer:
	return _make_hero_slot(hero, idx, target_type, target_positions)

# 数字转单词（用于技能图标路径）
func _number_to_word(num: int) -> String:
	match num:
		1: return "one"
		2: return "two"
		3: return "three"
		4: return "four"
		5: return "five"
		6: return "six"
		7: return "seven"
		8: return "eight"
		_: return str(num)

# 技能悬浮提示：名称 + 描述 + 可用/目标位置 + 效果数值
func _build_skill_tooltip(sd: Dictionary) -> String:
	var lines := PackedStringArray()
	lines.append(str(sd.get("name", "")))
	var desc: String = str(sd.get("description", ""))
	if desc != "":
		lines.append(desc)
	var has_pos := false
	var use_pos: Array = sd.get("use_positions", [])
	if not use_pos.is_empty():
		lines.append("使用位置：%s" % _format_positions(use_pos))
		has_pos = true
	var target_pos: Array = sd.get("target_positions", [])
	if not target_pos.is_empty():
		lines.append("目标位置：%s" % _format_positions(target_pos))
		has_pos = true
	if has_pos:
		lines.append("（1=最前，4=最后）")
	var move_f: int = int(sd.get("move_forward", 0))
	if move_f != 0:
		lines.append("位移：%s" % ("前进 %d" % move_f if move_f > 0 else "后退 %d" % -move_f))
	var target_move_f: int = int(sd.get("target_move_forward", 0))
	if target_move_f != 0:
		lines.append("目标位移：%s" % ("拉前 %d 位" % target_move_f if target_move_f > 0 else "推后 %d 位" % -target_move_f))
	match str(sd.get("effect_type", "")):
		"damage":
			var ar := _to_range(sd.get("attack_ratio", 0.0))
			if ar.size() == 2:
				lines.append("伤害：%.0f%%~%.0f%% 攻击力" % [float(ar[0]) * 100.0, float(ar[1]) * 100.0])
			else:
				lines.append("伤害：%.0f%% 攻击力" % (float(ar[0]) * 100.0))
		"heal":
			lines.append("治疗：%s 点生命" % _format_value(sd.get("heal_amount", 0)))
		"composite_heal":
			var st1: Dictionary = sd.get("stage_one", {})
			var st2: Dictionary = sd.get("stage_two", {})
			var parts := PackedStringArray()
			if st1.has("heal_amount") and _has_positive_value(st1["heal_amount"]):
				parts.append("回复 %s 生命" % _format_value(st1["heal_amount"]))
			if st1.has("stress_heal") and _has_positive_value(st1["stress_heal"]):
				parts.append("-%s 压力" % _format_value(st1["stress_heal"]))
			lines.append("效果：%s" % "、".join(parts))
			if st2.has("heal_amount") and _has_positive_value(st2["heal_amount"]):
				lines.append("其他队友：+%s 生命" % _format_value(st2["heal_amount"]))
			if st2.has("stress_heal") and _has_positive_value(st2["stress_heal"]):
				lines.append("其他队友：-%s 压力" % _format_value(st2["stress_heal"]))
		"guard":
			lines.append("效果：守护目标，敌人单体攻击转移给施法者（持续 %d 回合）" % int(sd.get("guard_duration", 3)))
	# 状态异常附加效果
	var status_effects: Array = sd.get("status_effects", [])
	for se in status_effects:
		var se_status_id: String = str(se.get("status_id", ""))
		var status_cfg := StatusConfig.get_status(se_status_id)
		if status_cfg.is_empty():
			continue
		if status_cfg.get("skip_turn", false):
			# 控制类状态（如晕眩）：不按层数/回合描述，直接说明会跳过下一次行动
			lines.append("%s：跳过下一次行动（跳过即解除）" % status_cfg.get("name", ""))
		else:
			lines.append("%s：%d 层 / 持续 %d 回合" % [status_cfg.get("name", ""), int(se.get("stacks", 1)), int(se.get("duration", 3))])
	return "\n".join(lines)

# 将数值规范为区间数组：区间 [min, max] 原样返回，单个数值包装为单元素数组
func _to_range(value) -> Array:
	if value is Array and (value as Array).size() == 2:
		return value
	return [value]

# 将数值格式化为显示文本：区间 [min, max] 显示为 "min~max"
func _format_value(value) -> String:
	var arr := _to_range(value)
	if arr.size() == 2:
		return "%s~%s" % [arr[0], arr[1]]
	return str(arr[0])

# 判断数值/区间是否包含正值（用于悬浮提示中省略为 0 的效果段落）
func _has_positive_value(value) -> bool:
	var arr := _to_range(value)
	for v in arr:
		if float(v) > 0.0:
			return true
	return false

# 将站位数组格式化为 "1, 2, 3" 的文本
func _format_positions(positions: Array) -> String:
	var parts := PackedStringArray()
	for p in positions:
		parts.append(str(int(p)))
	return ", ".join(parts)

# 创建怪物内容（用于填充预设位置）
func _make_monster_content(monster: Dictionary, idx: int, target_type: String, target_positions: Array = []) -> VBoxContainer:
	return _make_monster_slot(monster, idx, target_type, target_positions)

# 卡槽顶部悬浮区高度：状态行(22) + 间隔(2) + 死门行(18) = 42px
# 悬浮区底边贴在卡槽内容（速度标签）上方，向上占用卡槽顶部 0~70 的空闲带：
# 既不会被下方的 BottomLeftPanel 遮住，也不会压在角色肖像上
const TOP_OVERLAY_HEIGHT := 42.0

# 创建英雄角色槽
func _make_hero_slot(hero: Dictionary, idx: int, target_type: String, target_positions: Array = []) -> Control:
	# 使用Control作为容器，用anchors定位（复制HeroLabel的位置配置）
	var slot := Control.new()
	slot.name = "HeroContent%d" % (idx + 1)
	slot.anchors_preset = 8 # 中心锚点
	slot.anchor_left = 0.5
	slot.anchor_top = 0.5
	slot.anchor_right = 0.5
	slot.anchor_bottom = 0.5
	slot.custom_minimum_size = Vector2(110.0, 200.0)
	
	# 使用HeroLabel的offset定位
	match idx:
		0: # HeroLabel1
			slot.offset_left = -57.0
			slot.offset_top = -30.0
			slot.offset_right = -15.0
			slot.offset_bottom = 111.0
		1: # HeroLabel2
			slot.offset_left = -55.0
			slot.offset_top = -30.0
			slot.offset_right = -13.0
			slot.offset_bottom = 111.0
		2: # HeroLabel3
			slot.offset_left = -55.0
			slot.offset_top = -30.0
			slot.offset_right = -13.0
			slot.offset_bottom = 111.0
		3: # HeroLabel4
			slot.offset_left = -55.0
			slot.offset_top = -30.0
			slot.offset_right = -13.0
			slot.offset_bottom = 111.0
	
	# 内部用VBox排列内容
	# alignment 必须为 BEGIN：卡槽内容高度是固定的，居中会把角色整体下移、扎进下方面板
	var vbox := VBoxContainer.new()
	vbox.anchors_preset = 15
	vbox.anchor_right = 1.0
	vbox.anchor_bottom = 1.0
	vbox.alignment = BoxContainer.ALIGNMENT_BEGIN
	vbox.add_theme_constant_override("separation", 2)
	slot.add_child(vbox)

	var is_current: bool = (current_actor.get("unit_type") == "hero" and current_actor.get("index") == idx)
	var is_death_door: bool = hero.get("is_death_door", false)
	var is_dead: bool = hero["hp"] <= 0 and not is_death_door
	var is_target: bool = (hero_skill_selected and target_type == "single_ally" and not is_dead and not battle_over
		and (target_positions.is_empty() or (idx + 1) in target_positions))
	var is_repos_target: bool = (reposition_mode and not is_current and not is_dead and not battle_over)

	# 速度标签（顶部，兼作当前行动者指示：▲ 前缀，省掉一整行"▲"占位）
	var spd_lbl := Label.new()
	spd_lbl.text = "%sSPD %d" % ["▲ " if is_current else "", hero["speed"] + hero["speed_delta"]]
	spd_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	spd_lbl.add_theme_color_override("font_color", Color(1.0, 0.9, 0.2, 1) if is_current else Color(0.75, 0.75, 0.45, 1))
	spd_lbl.add_theme_font_size_override("font_size", 12)
	vbox.add_child(spd_lbl)

	# 顶部悬浮区（不参与 VBox 竖排，绝对定位在卡槽上方的空白带 y 26~66）：
	# 死门提示与状态异常图标放在这里，既不会被下方 BottomLeftPanel 遮挡，
	# 也不会把角色肖像向下挤出（肖像/血条的纵向位置必须保持稳定，角色脚底始终落在卡槽底部）
	var top_overlay := VBoxContainer.new()
	top_overlay.name = "HeroTopOverlay"
	top_overlay.mouse_filter = Control.MOUSE_FILTER_PASS
	top_overlay.add_theme_constant_override("separation", 2)
	top_overlay.alignment = BoxContainer.ALIGNMENT_END
	top_overlay.anchor_left = 0.0
	top_overlay.anchor_right = 1.0
	top_overlay.anchor_top = 0.0
	top_overlay.anchor_bottom = 0.0
	top_overlay.offset_left = 0.0
	top_overlay.offset_right = 0.0
	top_overlay.offset_top = - TOP_OVERLAY_HEIGHT
	top_overlay.offset_bottom = 0.0
	slot.add_child(top_overlay)

	# 状态异常图标（压力条下方 → 改为顶部悬浮，避免被下方 UI 遮挡）
	if not hero.get("statuses", {}).is_empty():
		top_overlay.add_child(_make_status_row(hero))

	# 死门（濒死）指示器：图标 + 该角色自己的死亡概率，悬浮提示说明机制
	if is_death_door:
		top_overlay.add_child(_make_deaths_door_row(hero))

	# 肖像（可点击则用 Button，否则用 ColorRect 或 SpinePlayer 锚点）
	if is_target or is_repos_target:
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(100.0, 120.0)
		btn.text = hero["name"]
		if is_target:
			btn.pressed.connect(_on_ally_pressed.bind(idx), CONNECT_DEFERRED)
		else:
			btn.pressed.connect(_on_hero_reposition_target.bind(idx), CONNECT_DEFERRED)
			btn.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2, 1))
		vbox.add_child(btn)
		
		# 极度重要：作为目标可点击按钮时，它也必须充当位置锚点以防位置不更新或短暂闪烁！
		if _spine_players.has(idx):
			_spine_anchors[idx] = btn
	elif _spine_players.has(idx):
		# 有 SpinePlayer 的英雄（crusader / highwayman）：使用 ColorRect 作为位置锚点，SpinePlayer 渲染在其上
		var portrait := ColorRect.new()
		portrait.custom_minimum_size = Vector2(100.0, 120.0)
		portrait.color = Color(0, 0, 0, 0) # 透明背景
		_spine_anchors[idx] = portrait # 缓存锚点以供 _process 使用
		vbox.add_child(portrait)
	else:
		# 直接显示英雄名称，不需要背景框
		var name_lbl := Label.new()
		name_lbl.text = hero["name"]
		name_lbl.custom_minimum_size = Vector2(100.0, 120.0)
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		vbox.add_child(name_lbl)

	# 血条（数值内嵌在条上，省掉一整行文本高度，为状态栏腾出空间）
	var hp_bar := ProgressBar.new()
	hp_bar.custom_minimum_size = Vector2(100.0, 12.0)
	hp_bar.min_value = 0
	hp_bar.max_value = hero["max_hp"]
	hp_bar.value = hero["hp"]
	hp_bar.show_percentage = false
	hp_bar.add_child(_make_bar_value_label("%d/%d" % [hero["hp"], hero["max_hp"]], Color(1, 1, 1, 1)))
	vbox.add_child(hp_bar)

	# 压力条（同样内嵌数值）
	var stress_bar := ProgressBar.new()
	stress_bar.custom_minimum_size = Vector2(100.0, 12.0)
	stress_bar.min_value = 0
	stress_bar.max_value = 200
	stress_bar.value = hero.get("stress", 0)
	stress_bar.show_percentage = false
	
	# 自定义 StyleBox 将填充色改为神秘而庄重的暗黑色調紫色
	# 折磨（Affliction）状态下转为暗红，作为"随时可能失控"的视觉警示
	var sb_fill := StyleBoxFlat.new()
	sb_fill.bg_color = Color(0.75, 0.12, 0.12, 1.0) if ActionResolver.has_status(hero, StressConfig.AFFLICTION_STATUS) else Color(0.6, 0.2, 0.7, 1.0)
	stress_bar.add_theme_stylebox_override("fill", sb_fill)
	stress_bar.add_child(_make_bar_value_label("Stress %d/200" % hero.get("stress", 0), Color(1, 0.85, 1, 1)))
	vbox.add_child(stress_bar)

	return slot

# 在进度条上叠加数值文本（PRESET_FULL_RECT + 居中），省下一整行文本高度
func _make_bar_value_label(text: String, color: Color) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 10)
	lbl.add_theme_color_override("font_color", color)
	lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	lbl.add_theme_constant_override("outline_size", 2)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return lbl

# 死门（濒死）指示行：图标 + 该角色自己的死亡概率，悬浮提示说明机制
func _make_deaths_door_row(hero: Dictionary) -> HBoxContainer:
	var dd_row := HBoxContainer.new()
	dd_row.alignment = BoxContainer.ALIGNMENT_CENTER
	dd_row.add_theme_constant_override("separation", 4)
	var dd_chance: float = clampf(float(hero.get("death_blow_chance", HeroConfig.DEFAULT_DEATH_BLOW_CHANCE)), 0.0, 1.0)
	var dd_tip: String = "死门（濒死）：生命值已归零，仍可行动与受治疗；\n在此期间受到任何伤害时有 %d%% 概率当场死亡。" % int(round(dd_chance * 100.0))
	if ResourceLoader.exists(DEATHS_DOOR_ICON):
		var dd_icon := TextureRect.new()
		dd_icon.texture = load(DEATHS_DOOR_ICON)
		dd_icon.custom_minimum_size = Vector2(18, 18)
		dd_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		dd_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		dd_icon.mouse_filter = Control.MOUSE_FILTER_STOP
		dd_icon.tooltip_text = dd_tip
		dd_row.add_child(dd_icon)
	var dd_lbl := Label.new()
	dd_lbl.text = "DEATH'S DOOR %d%%" % int(round(dd_chance * 100.0))
	dd_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dd_lbl.add_theme_font_size_override("font_size", 10)
	dd_lbl.add_theme_color_override("font_color", Color(1.0, 0.2, 0.2, 1))
	dd_lbl.tooltip_text = dd_tip
	dd_row.add_child(dd_lbl)
	return dd_row


# 创建怪物角色槽
func _make_monster_slot(monster: Dictionary, idx: int, target_type: String, target_positions: Array = []) -> Control:
	# 使用Control作为容器，用anchors定位
	var slot := Control.new()
	slot.name = "MonsterContent%d" % (idx + 1)
	slot.anchors_preset = 8 # 中心锚点
	slot.anchor_left = 0.5
	slot.anchor_top = 0.5
	slot.anchor_right = 0.5
	slot.anchor_bottom = 0.5
	slot.custom_minimum_size = Vector2(110.0, 200.0)
	
	# 使用对称英雄位置的offset（镜像）
	match idx:
		0: # MonsterSlot1（对称 HeroLabel1）
			slot.offset_left = 15.0
			slot.offset_top = -55.0
			slot.offset_right = 57.0
			slot.offset_bottom = 111.0
		1: # MonsterSlot2（对称 HeroLabel2）
			slot.offset_left = 13.0
			slot.offset_top = -55.0
			slot.offset_right = 55.0
			slot.offset_bottom = 111.0
		2: # MonsterSlot3（对称 HeroLabel3）
			slot.offset_left = 13.0
			slot.offset_top = -55.0
			slot.offset_right = 55.0
			slot.offset_bottom = 111.0
		3: # MonsterSlot4（对称 HeroLabel4）
			slot.offset_left = 13.0
			slot.offset_top = -55.0
			slot.offset_right = 55.0
			slot.offset_bottom = 111.0
	
	# 内部用VBox排列内容
	# alignment 必须为 BEGIN：内容高度固定，居中会把怪物整体下移、扎进下方面板
	var vbox := VBoxContainer.new()
	vbox.anchors_preset = 15
	vbox.anchor_right = 1.0
	vbox.anchor_bottom = 1.0
	vbox.alignment = BoxContainer.ALIGNMENT_BEGIN
	vbox.add_theme_constant_override("separation", 2)
	slot.add_child(vbox)

	var is_current: bool = (current_actor.get("unit_type") == "monster" and current_actor.get("index") == idx)
	var is_corpse: bool = monster.get("is_corpse", false)
	var is_dead: bool = monster["hp"] <= 0 and not is_corpse
	var is_target: bool = (hero_skill_selected and target_type == "single_enemy" and not is_dead and not battle_over
		and (target_positions.is_empty() or (idx + 1) in target_positions))

	# 速度标签（顶部，兼作当前行动者指示：▲ 前缀）
	var spd_lbl := Label.new()
	spd_lbl.text = "%sSPD %d" % ["▲ " if is_current else "", monster["speed"] + monster["speed_delta"]]
	spd_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	spd_lbl.add_theme_color_override("font_color", Color(1.0, 0.4, 0.2, 1) if is_current else Color(0.75, 0.45, 0.40, 1))
	spd_lbl.add_theme_font_size_override("font_size", 12)
	vbox.add_child(spd_lbl)

	# 顶部悬浮区（不参与 VBox 竖排）：尸体指示与状态异常图标放这里，避免被下方 UI 遮挡
	var top_overlay := VBoxContainer.new()
	top_overlay.name = "MonsterTopOverlay"
	top_overlay.mouse_filter = Control.MOUSE_FILTER_PASS
	top_overlay.add_theme_constant_override("separation", 2)
	top_overlay.alignment = BoxContainer.ALIGNMENT_END
	top_overlay.anchor_left = 0.0
	top_overlay.anchor_right = 1.0
	top_overlay.anchor_top = 0.0
	top_overlay.anchor_bottom = 0.0
	top_overlay.offset_left = 0.0
	top_overlay.offset_right = 0.0
	top_overlay.offset_top = - TOP_OVERLAY_HEIGHT
	top_overlay.offset_bottom = 0.0
	slot.add_child(top_overlay)

	# 状态异常图标（顶部悬浮）
	if not monster.get("statuses", {}).is_empty():
		top_overlay.add_child(_make_status_row(monster))

	# 尸体状态指示器（顶部悬浮）
	if is_corpse:
		var corpse_lbl := Label.new()
		corpse_lbl.text = "☠ CORPSE ☠"
		corpse_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		corpse_lbl.add_theme_font_size_override("font_size", 10)
		corpse_lbl.add_theme_color_override("font_color", Color(0.75, 0.75, 0.75, 1))
		top_overlay.add_child(corpse_lbl)

	# 肖像
	if is_target:
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(100.0, 120.0)
		btn.text = monster["name"]
		btn.pressed.connect(_on_monster_pressed.bind(idx), CONNECT_DEFERRED)
		vbox.add_child(btn)
		
		# 极度重要：作为目标可点击按钮时，它也必须充当位置锚点以防位置不更新或短暂闪烁！
		if _spine_players.has("monster_%d" % idx):
			_spine_anchors["monster_%d" % idx] = btn
	elif _spine_players.has("monster_%d" % idx):
		# 有 SpinePlayer 的怪物（cutthroat 等）：使用 ColorRect 作为位置锚点
		var portrait := ColorRect.new()
		portrait.custom_minimum_size = Vector2(100.0, 120.0)
		portrait.color = Color(0, 0, 0, 0) # 透明背景
		_spine_anchors["monster_%d" % idx] = portrait # 缓存锚点以供 _process 使用
		vbox.add_child(portrait)
	else:
		# 直接显示怪物名称，不需要背景框
		var name_lbl := Label.new()
		name_lbl.text = monster["name"]
		name_lbl.custom_minimum_size = Vector2(100.0, 120.0)
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		vbox.add_child(name_lbl)

	# 血条（尸体显示10点生命上限；数值内嵌在条上，省下一整行文本高度）
	var hp_bar := ProgressBar.new()
	hp_bar.custom_minimum_size = Vector2(100.0, 12.0)
	hp_bar.min_value = 0
	hp_bar.max_value = 10 if is_corpse else monster["max_hp"]
	hp_bar.value = monster["hp"]
	hp_bar.show_percentage = false
	if is_corpse:
		hp_bar.add_child(_make_bar_value_label("☠ %d/10" % monster["hp"], Color(0.85, 0.85, 0.85, 1)))
	else:
		hp_bar.add_child(_make_bar_value_label("%d/%d" % [monster["hp"], monster["max_hp"]], Color(1, 1, 1, 1)))
	vbox.add_child(hp_bar)

	return slot

# 构建状态异常图标行（血条/压力条下方），悬浮显示描述
func _make_status_row(unit: Dictionary) -> HBoxContainer:
	# 左对齐：槽位实际宽度较窄，居中会因 VBox 溢出而把靠后的图标推到不可悬停区域
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_BEGIN
	row.add_theme_constant_override("separation", 3)
	row.custom_minimum_size = Vector2(0, 22)
	
	var statuses: Dictionary = unit.get("statuses", {})
	for status_id in statuses.keys():
		var cfg := StatusConfig.get_status(str(status_id))
		if cfg.is_empty():
			continue
		var s: Dictionary = statuses[status_id]
		var stacks: int = int(s.get("stacks", 0))
		var duration: int = int(s.get("duration", 0))
		var tip: String = _build_status_tooltip(cfg, stacks, duration)
		
		var icon := TextureRect.new()
		icon.custom_minimum_size = Vector2(18, 18)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_STOP
		icon.tooltip_text = tip
		var icon_path: String = str(cfg.get("icon", ""))
		if icon_path != "" and ResourceLoader.exists(icon_path):
			icon.texture = load(icon_path)
		row.add_child(icon)
		
		# 层数角标叠加在图标上，避免额外宽度把后面的图标挤出可悬停区域
		# 只有按层数结算的 DoT（流血/腐蚀）才显示角标；晕眩/标记/守护等不显示
		if not cfg.get("dot", false):
			continue
		var lbl := Label.new()
		lbl.text = "%d" % stacks
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		lbl.add_theme_font_size_override("font_size", 10)
		lbl.add_theme_color_override("font_color", Color(1, 1, 1, 1))
		lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
		lbl.add_theme_constant_override("outline_size", 2)
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		icon.add_child(lbl)
	
	return row

# 状态异常悬浮提示：名称 + 描述（+ 层数/剩余回合）
# 控制类状态（skip_turn）只显示名称 + 描述；层数只在按层数结算的 DoT 上显示；
# 事件驱动状态（manual_duration，如爆破标记）的存续由战斗逻辑掌握，不显示"剩余回合"
func _build_status_tooltip(cfg: Dictionary, stacks: int, duration: int) -> String:
	var lines := PackedStringArray()
	lines.append(str(cfg.get("name", "")))
	var desc: String = str(cfg.get("description", ""))
	if desc != "":
		lines.append(desc)
	if not cfg.get("skip_turn", false) and not cfg.get("manual_duration", false):
		if cfg.get("dot", false):
			lines.append("层数：%d" % stacks)
		lines.append("剩余回合：%d" % duration)
	return "\n".join(lines)

func _update_list_ui() -> void:
	# 确定当前技能的目标类型与有效目标位置
	var target_type := ""
	var target_positions: Array = []
	if hero_skill_selected:
		var sd := SkillConfig.get_skill(hero_current_skill)
		if not sd.is_empty():
			target_type = sd.get("target_type", "single_enemy")
			target_positions = sd.get("target_positions", [])

	# 英雄区：从左到右排列 1234（对应 index 0,1,2,3）
	# 注意：必须遍历全部槽位并清空，不能只遍历 heroes.size()，
	# 否则英雄阵亡/队伍变短后，尾部槽位会残留上一帧的内容（补位错位）
	_spine_anchors.clear()
	for i in range(hero_slots.size()):
		# 使用queue_free删除旧节点（安全，不会在信号处理中导致崩溃）
		_clear_children(hero_slots[i])
		if i < heroes.size():
			hero_slots[i].add_child(_make_hero_content(heroes[i], i, target_type, target_positions))

	# 怪物区：从左到右排列 1234（对应 index 0,1,2,3）
	# 同上：清空全部槽位，避免尸体被清掉/怪物死亡后尾位残留旧的血条与图标
	for i in range(monster_slots.size()):
		_clear_children(monster_slots[i])
		if i < monsters.size():
			monster_slots[i].add_child(_make_monster_content(monsters[i], i, target_type, target_positions))

func _update_selected_text() -> void:
	if not selected_label:
		return
	if battle_over:
		selected_label.text = "Victory" if _count_alive(monsters) == 0 else "Defeat"
		return
	if current_actor.is_empty():
		selected_label.text = "Round %d - Loading..." % round_number
		return
	if current_actor["unit_type"] == "hero":
		var h_idx: int = current_actor["index"]
		if h_idx < 0 or h_idx >= heroes.size():
			return
		var hero := heroes[h_idx]
		if hero_skill_selected:
			var sd := SkillConfig.get_skill(hero_current_skill)
			var sname: String = sd.get("name", hero_current_skill) if not sd.is_empty() else hero_current_skill
			match sd.get("target_type", "single_enemy"):
				"all_enemies":
					selected_label.text = "Round %d - %s: using %s on all enemies" % [round_number, hero["name"], sname]
				"single_ally":
					selected_label.text = "Round %d - %s: select ally for %s" % [round_number, hero["name"], sname]
				"_":
					selected_label.text = "Round %d - %s: select target for %s" % [round_number, hero["name"], sname]
		else:
			selected_label.text = "Round %d - %s: choose skill (or Skip)" % [round_number, hero["name"]]
	else:
		var m_idx: int = current_actor["index"]
		if m_idx < 0 or m_idx >= monsters.size():
			return
		selected_label.text = "Round %d - %s attacking..." % [round_number, monsters[m_idx]["name"]]

func _clear_children(node: Node) -> void:
	for child in node.get_children():
		child.queue_free()

# ============================================================
# 消耗品背包（16 格）渲染与使用
# ============================================================

# 重建消耗品格子：保留场景中原有的 PanelInventoryBg 背景不动，在其可见区域上铺设 16 个格子
func _build_inventory_panel() -> void:
	if not panel_inventory or not panel_inventory_bg or not battle_ui:
		return
	# 只移除上一次生成的槽位容器，不触碰背景
	if is_instance_valid(_inventory_slots_root):
		_inventory_slots_root.queue_free()
	_inventory_slots_root = null

	# 关键修复：PanelInventory 控件本身只有 280×130，而背景贴图通过偏移
	# （offset_left=370）实际绘制在父控件范围之外。若把槽位作为 PanelInventory
	# 的子节点，按钮会落在父控件矩形外，Godot 的 GUI 命中测试（has_point）会
	# 在父控件处直接失败、不再向下递归，导致“能看到却左/右键都点不到”。
	# 因此改为把槽位挂到全屏的 BattleUI 下，并按背景贴图的全局矩形定位，
	# 使按钮的命中区域与可见区域完全一致。
	var bg_rect: Rect2 = panel_inventory_bg.get_global_rect()

	var slots_root := Control.new()
	slots_root.name = "InventorySlots"
	slots_root.mouse_filter = Control.MOUSE_FILTER_PASS
	slots_root.anchor_left = 0.0
	slots_root.anchor_top = 0.0
	slots_root.anchor_right = 0.0
	slots_root.anchor_bottom = 0.0
	# BattleUI 是全屏控件且位于 (0,0)，其本地坐标即全局坐标，直接使用 bg_rect.position
	slots_root.offset_left = bg_rect.position.x
	slots_root.offset_top = bg_rect.position.y
	slots_root.offset_right = bg_rect.position.x + bg_rect.size.x
	slots_root.offset_bottom = bg_rect.position.y + bg_rect.size.y
	battle_ui.add_child(slots_root)
	_inventory_slots_root = slots_root

	# 16 格几何（以背景区域的比例表示，可微调）
	# 主网格 7×2（左侧）
	var main_x0 := 0.02
	var main_x1 := 0.80
	var main_y0 := 0.10
	var main_y1 := 0.90
	var cell_w := (main_x1 - main_x0) / 7.0
	var cell_h := (main_y1 - main_y0) / 2.0

	# 右侧独立列 2 格
	var side_x0 := 0.87
	var side_x1 := 0.97
	var side_y0 := 0.20
	var side_y1 := 0.80
	var side_cell_h := (side_y1 - side_y0) / 2.0

	var slot_index := 0
	for r in range(2):
		for c in range(7):
			_add_inventory_slot(slots_root, slot_index,
				main_x0 + c * cell_w, main_y0 + r * cell_h,
				main_x0 + (c + 1) * cell_w, main_y0 + (r + 1) * cell_h)
			slot_index += 1
	for s in range(2):
		_add_inventory_slot(slots_root, slot_index,
			side_x0, side_y0 + s * side_cell_h,
			side_x1, side_y0 + (s + 1) * side_cell_h)
		slot_index += 1

# 在指定锚点区域创建单个消耗品格子（Button，左键点击触发使用）
func _add_inventory_slot(root: Control, slot_index: int, ax0: float, ay0: float, ax1: float, ay1: float) -> void:
	var item_id: String = _get_inventory_item_at(slot_index)

	var slot := Button.new()
	slot.name = "InvSlot%d" % slot_index
	slot.anchor_left = ax0
	slot.anchor_top = ay0
	slot.anchor_right = ax1
	slot.anchor_bottom = ay1
	slot.flat = true
	slot.button_mask = MOUSE_BUTTON_MASK_LEFT
	slot.focus_mode = Control.FOCUS_NONE

	if item_id == "":
		slot.disabled = true
		root.add_child(slot)
		return

	var item := ConsumableConfig.get_item(item_id)
	var count := ConsumableConfig.get_count(item_id)

	var icon_path: String = item.get("icon", "")
	if icon_path != "" and ResourceLoader.exists(icon_path):
		slot.icon = load(icon_path)
		slot.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		slot.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
		slot.expand_icon = true

	# 数量角标
	var count_lbl := Label.new()
	count_lbl.text = "x%d" % count
	count_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	count_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	count_lbl.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	count_lbl.add_theme_font_size_override("font_size", 10)
	count_lbl.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	count_lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	count_lbl.add_theme_constant_override("outline_size", 2)
	count_lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	slot.add_child(count_lbl)

	# 悬浮提示：名称 + 描述 + 可用位置 + 效果
	var tooltip_lines := PackedStringArray()
	tooltip_lines.append(str(item.get("name", item_id)))
	var item_desc: String = str(item.get("description", ""))
	if item_desc != "":
		tooltip_lines.append(item_desc)
	tooltip_lines.append("可用位置：无限制（对当前行动英雄使用）")
	# 效果行由配置驱动，兼容回复类（heal）/治愈类（cure_status）/增益类（buff_status）
	var effect_parts := PackedStringArray()
	var tip_heal: int = int(item.get("heal", 0))
	if tip_heal > 0:
		effect_parts.append("回复 %d 点生命" % tip_heal)
	for sid in item.get("cure_status", []):
		var cfg := StatusConfig.get_status(str(sid))
		effect_parts.append("治愈%s" % str(cfg.get("name", sid)))
	var tip_buff: String = str(item.get("buff_status", ""))
	if tip_buff != "":
		var bcfg := StatusConfig.get_status(tip_buff)
		effect_parts.append("附加%s（%d 回合）" % [str(bcfg.get("name", tip_buff)), int(item.get("buff_duration", 1))])
	if not effect_parts.is_empty():
		tooltip_lines.append("效果：" + "、".join(effect_parts))
	slot.tooltip_text = "\n".join(tooltip_lines)
	slot.pressed.connect(_try_use_consumable.bind(slot_index), CONNECT_DEFERRED)
	root.add_child(slot)

func _get_inventory_item_at(slot_index: int) -> String:
	if slot_index < 0 or slot_index >= ConsumableConfig.INVENTORY.size():
		return ""
	return str(ConsumableConfig.INVENTORY[slot_index].get("item_id", ""))

# 点击使用消耗品：对当前行动的英雄生效（恢复生命 / 治愈负面状态）
func _try_use_consumable(slot_index: int) -> void:
	if battle_over or _in_fx_pause:
		return
	if current_actor.is_empty() or current_actor["unit_type"] != "hero":
		_show_toast("当前不是英雄行动回合，无法使用消耗品")
		return
	var hero_idx: int = current_actor["index"]
	if hero_idx < 0 or hero_idx >= heroes.size():
		return
	var hero := heroes[hero_idx]

	var item_id: String = _get_inventory_item_at(slot_index)
	if item_id == "":
		return
	var item := ConsumableConfig.get_item(item_id)
	if item.is_empty():
		return

	# ① 治愈类消耗品（如绷带）：身上确实带有对应状态时才可用，避免白白消耗
	var cure_statuses: Array = item.get("cure_status", [])
	if not cure_statuses.is_empty():
		_use_cure_consumable(hero, item, item_id, cure_statuses)
		return

	# ② 增益类消耗品（如狗粮）：为当前行动的英雄附加增益状态（攻击力 +20%，1 回合）
	var buff_status: String = str(item.get("buff_status", ""))
	if buff_status != "":
		_use_buff_consumable(hero, item, item_id, buff_status)
		return

	# ③ 恢复类消耗品（如食物）
	var heal_amt: int = int(item.get("heal", 0))
	if heal_amt <= 0:
		return
	if hero["hp"] >= hero["max_hp"]:
		_show_toast("%s 生命已满，无需使用" % hero.get("name", "英雄"))
		return # 满血时不消耗

	if not ConsumableConfig.consume_item(item_id):
		return

	var actual: int = mini(heal_amt, hero["max_hp"] - hero["hp"])
	ActionResolver.apply_heal(hero, heal_amt)
	# 消耗品治疗同样不掷死亡骰
	_handle_hero_damage_aftermath(hero_idx, false)
	_show_floating_number(hero, actual)
	_update_ui()
	_build_inventory_panel()

# 治愈类消耗品：移除目标身上的指定状态（如绷带治流血），并给出图标 + 文字反馈
func _use_cure_consumable(hero: Dictionary, item: Dictionary, item_id: String, cure_statuses: Array) -> void:
	var cured_ids: Array[String] = []
	var cured_names := PackedStringArray()
	for sid in cure_statuses:
		var status_id := str(sid)
		if not ActionResolver.has_status(hero, status_id):
			continue
		cured_ids.append(status_id)
		var cfg := StatusConfig.get_status(status_id)
		cured_names.append(str(cfg.get("name", status_id)))

	if cured_ids.is_empty():
		_show_toast("%s 没有可被%s治愈的状态" % [hero.get("name", "英雄"), str(item.get("name", item_id))])
		return
	if not ConsumableConfig.consume_item(item_id):
		return

	for status_id in cured_ids:
		ActionResolver.remove_status(hero, status_id)
		_show_status_popup(hero, str(StatusConfig.get_status(status_id).get("icon", "")))

	_show_toast("%s 的%s已被治愈" % [hero.get("name", "英雄"), "、".join(cured_names)])
	_update_ui()
	_build_inventory_panel()

# 增益类消耗品：为当前行动的英雄附加攻击力增益状态（如狗粮的 dogfood_buff）
func _use_buff_consumable(hero: Dictionary, item: Dictionary, item_id: String, buff_status: String) -> void:
	var cfg := StatusConfig.get_status(buff_status)
	if cfg.is_empty():
		return
	var duration: int = max(1, int(item.get("buff_duration", 1)))
	if not ConsumableConfig.consume_item(item_id):
		return

	ActionResolver.apply_status(hero, buff_status, 1, duration)
	_show_status_popup(hero, str(cfg.get("icon", "")))
	_show_toast("%s 获得了%s" % [hero.get("name", "英雄"), str(cfg.get("name", buff_status))])
	_update_ui()
	_build_inventory_panel()

# 在视口上部居中显示一条短暂的提示文字（用于消耗品使用失败等反馈）
func _show_toast(text: String) -> void:
	if _floating_text_layer == null:
		return
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.35, 1.0))
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	label.add_theme_constant_override("outline_size", 4)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_floating_text_layer.add_child(label)
	label.size = Vector2(640, 30)
	var vp := get_viewport().get_visible_rect()
	label.global_position = Vector2(vp.size.x / 2.0 - 320.0, vp.size.y * 0.22)
	var tween := create_tween()
	tween.tween_interval(1.2)
	tween.tween_property(label, "modulate:a", 0.0, 0.4)
	tween.tween_callback(label.queue_free)

# ============================================================
# 技能特效（FX）机制实现
# ============================================================

# 通过引用匹配，获取某一角色在 _spine_players 里的缓存 key 与类型信息
func _get_spine_player_ref_info(unit: Dictionary) -> Dictionary:
	# 优先通过 exact dictionary reference 匹配，避免同名/同类型角色匹配错误
	for i in range(heroes.size()):
		if is_same(heroes[i], unit):
			return {"key": i, "is_hero": true}
	for i in range(monsters.size()):
		if is_same(monsters[i], unit):
			return {"key": "monster_%d" % i, "is_hero": false}
			
	# 后备方案：根据 name 和 id 字段匹配
	for i in range(heroes.size()):
		if heroes[i].get("name") == unit.get("name") and heroes[i].get("id") == unit.get("id"):
			return {"key": i, "is_hero": true}
	for i in range(monsters.size()):
		if monsters[i].get("name") == unit.get("name") and monsters[i].get("id") == unit.get("id"):
			return {"key": "monster_%d" % i, "is_hero": false}
	return {"key": null, "is_hero": false}

# 为角色播放指定技能的施法和受击特效（展示约 1 秒左右，加载独立的骨骼特效文件并自动销毁）
func _play_skill_fx_v2(caster: Dictionary, skill_id: String, targets: Array) -> void:
	print("[FX] _play_skill_fx_v2: skill_id=", skill_id, " caster=", caster.get("name"), " targets_count=", targets.size())

	# 0. 音效：施法音先响，再出特效，听感与画面几乎同步。
	#    注意放在特效表校验之前 —— 没配 Spine 特效的技能依然要有声音。
	#    英雄按 hero_id + skill_id 两层查表（每个英雄有自己的音色），
	#    怪物只按 skill_id 查（同一种怪的攻击音是共用的）。
	var caster_info_v := _get_spine_player_ref_info(caster)
	var caster_hero_id := str(caster.get("id", "")) if caster_info_v.is_hero else ""
	Sfx.play_skill_cast(skill_id, caster_hero_id)
	# 记下本招，等 _emit_feedback 算出真实掉血后再决定播命中音还是挥空音
	_pending_impact_skill = skill_id

	if not SKILL_FX_MAP.has(skill_id):
		print("[FX] skill_id not in SKILL_FX_MAP: ", skill_id)
		return # 该技能未配置特效，不进行播放
	
	var fx_config: Dictionary = SKILL_FX_MAP[skill_id]
	var caster_info := _get_spine_player_ref_info(caster)
	print("[FX] caster_info key=", caster_info.key, " is_hero=", caster_info.is_hero)
	
	# 1. 播放施法者自身的特效 (Caster FX)
	if fx_config.has("caster_fx") and caster_info.key != null:
		var caster_sp: SpinePlayer = _spine_players.get(caster_info.key)
		if is_instance_valid(caster_sp):
			var fx_base: String = fx_config["caster_fx"]
			var skel = fx_base + ".skel"
			var atlas = fx_base + ".atlas"
			var png_dir = fx_base.get_base_dir()
			
			# 朝向根据施法者进行垂直同步
			var flip = caster_sp.scale.x < 0
			var offset: Vector2 = fx_config.get("caster_offset", Vector2.ZERO)
			if flip:
				offset.x = - offset.x
			var target_pos = caster_sp.global_position + offset
			var scale_mult: float = fx_config.get("caster_scale", 1.0)
			
			print("[FX] Playing caster_fx at pos=", target_pos, " file=", fx_base, " flip=", flip, " scale_mult=", scale_mult)
			_play_fx_at_position(target_pos, skel, atlas, png_dir, flip, scale_mult)
		else:
			print("[FX] Caster SpinePlayer is invalid!")
			
	# 2. 播放目标角色身上的受击/辅助特效 (Target FX)
	if fx_config.has("target_fx"):
		var fx_base: String = fx_config["target_fx"]
		var skel = fx_base + ".skel"
		var atlas = fx_base + ".atlas"
		var png_dir = fx_base.get_base_dir()
		
		for target in targets:
			var target_info := _get_spine_player_ref_info(target)
			print("[FX] target=", target.get("name"), " info key=", target_info.key)
			if target_info.key != null:
				var target_sp: SpinePlayer = _spine_players.get(target_info.key)
				if is_instance_valid(target_sp):
					var flip = target_sp.scale.x < 0
					var scale_mult: float = fx_config.get("target_scale", 1.0)
					# 受击特效定位：
					#   · 显式配置 target_offset 时，按配置的屏幕像素偏移播放；
					#   · 未配置时交给 _play_fx_at_position 依据“双方实际绘制内容范围”自动对齐到目标躯干。
					# 不能写死一个全局 Y 偏移：各特效资源的原点位置并不统一——
					# 斩击/血花类（opened_vein）原点在脚底，弹着/闪光类（pistol_shot_target）原点在特效自身中心，
					# 统一抬升会让前者飞到人物头顶上方。
					var target_pos: Vector2 = target_sp.global_position
					var align_to: Variant = null
					var explicit_offset: Variant = fx_config.get("target_offset", null)
					if explicit_offset != null:
						var offset: Vector2 = explicit_offset
						if flip:
							offset.x = - offset.x
						target_pos = target_sp.global_position + offset
					else:
						align_to = target_sp
					
					print("[FX] Playing target_fx at pos=", target_pos, " file=", fx_base, " flip=", flip, " scale_mult=", scale_mult, " auto_align=", align_to != null)
					_play_fx_at_position(target_pos, skel, atlas, png_dir, flip, scale_mult, align_to)
				else:
					print("[FX] Target SpinePlayer is invalid!")

# 核心底层：在指定屏幕全局坐标处生成并播放 1s 左右的 Spine 特效，随后自行销毁
# align_body_to：非空且为有效 SpinePlayer 时，加载完成后把“特效内容中心”纵向对齐到该角色的躯干高度
func _play_fx_at_position(global_pos: Vector2, skel_path: String, atlas_path: String, png_dir: String, flip: bool, scale_multiplier: float = 1.0, align_body_to: Variant = null) -> void:
	print("[FX] _play_fx_at_position: pos=", global_pos, " skel=", skel_path, " atlas=", atlas_path, " png=", png_dir)
	if not FileAccess.file_exists(skel_path) or not FileAccess.file_exists(atlas_path):
		push_warning("[FX] Assets not found: %s or %s" % [skel_path, atlas_path])
		return
		
	var fx_sp := SpinePlayer.new()
	# 特效添加到当前节点
	add_child(fx_sp)
	fx_sp.global_position = global_pos
	fx_sp.z_index = 20 # 盖在普通角色之上
	
	# 保持特效正确的缩放
	var base_scale: float = 0.5 * scale_multiplier
	if flip:
		fx_sp.scale = Vector2(-base_scale, base_scale)
	else:
		fx_sp.scale = Vector2(base_scale, base_scale)
		
	# 加载特效骨骼和图集
	fx_sp.load_character(skel_path, atlas_path, png_dir)
	
	# 自动搜寻骨骼内部的默认动画并播放（不需要循环）
	var anims: Array = fx_sp.skel_data.get("animations", [])
	if not anims.is_empty():
		print("[FX] Playing anim: ", anims[0].name)
		fx_sp.play(anims[0].name, false) # looping = false, 播放一次
		fx_sp.set_time(0.0) # 强制立即计算当前姿姿姿势，避免首帧不绘制/不可见！
	else:
		print("[FX] No anims found in FX skeleton!")
	
	# 自动纵向对齐（受击特效使用）：几何已就绪，按内容范围把特效对到目标躯干
	_align_fx_to_body(fx_sp, align_body_to)

	# 取动画自然时长作为播放时长（保底 1.0 秒）
	var duration: float = 1.0
	if fx_sp.current_anim and fx_sp.current_anim.duration > 0.1:
		duration = fx_sp.current_anim.duration
	print("[FX] Duration set to: ", duration)
	
	# 倒计时结束后优雅地删除特效节点
	get_tree().create_timer(duration).timeout.connect(func():
		if is_instance_valid(fx_sp):
			fx_sp.queue_free()
	)

# 受击特效纵向锚点：目标身体自上而下的比例（0 = 头顶，1 = 脚底）
const BODY_FX_ANCHOR_RATIO := 0.45

# 把特效节点纵向对齐到目标角色的躯干：使“特效内容中心”落在身体 BODY_FX_ANCHOR_RATIO 处。
# 按实际内容范围计算的原因：各特效资源的原点并不统一——
#   · 斩击/血花类（opened_vein）原点在脚底，内容整体向上展开；
#   · 弹着/闪光类（pistol_shot_target）原点在特效自身中心。
# 同时目标也分英雄（高约 300~400 骨架单位）与怪物（约 300 单位），固定像素偏移无法兼顾。
func _align_fx_to_body(fx_sp: SpinePlayer, body: Variant) -> void:
	if body == null or not is_instance_valid(fx_sp):
		return
	var body_sp := body as SpinePlayer
	if not is_instance_valid(body_sp):
		return
	var fx_rect := _spine_content_bounds(fx_sp)
	var body_rect := _spine_content_bounds(body_sp)
	if fx_rect.size.y < 1.0 or body_rect.size.y < 1.0:
		return
	# 均为“未乘节点 scale”的骨架单位，但两节点 scale 已各自乘入，故下方分别换算成屏幕像素
	var anchor_local: float = body_rect.position.y + body_rect.size.y * BODY_FX_ANCHOR_RATIO
	var fx_center_local: float = fx_rect.position.y + fx_rect.size.y * 0.5
	var anchor_screen_y: float = body_sp.global_position.y + anchor_local * body_sp.scale.y
	var fx_center_screen_y: float = fx_center_local * fx_sp.scale.y
	fx_sp.global_position.y = anchor_screen_y - fx_center_screen_y

# 计算 SpinePlayer 当前姿势下“实际绘制几何”的本地包围盒（骨架单位，未乘节点 scale）
# 网格槽（Polygon2D）的顶点已在本地空间；区域槽（Sprite2D）需用自身 transform 映射四个角点。
func _spine_content_bounds(sp: SpinePlayer) -> Rect2:
	if not is_instance_valid(sp):
		return Rect2()
	var min_v := Vector2(INF, INF)
	var max_v := Vector2(-INF, -INF)
	for child in sp.get_children():
		if child is Polygon2D:
			var poly := child as Polygon2D
			for p: Vector2 in poly.polygon:
				min_v = min_v.min(p)
				max_v = max_v.max(p)
		elif child is Sprite2D:
			var spr := child as Sprite2D
			var rect: Rect2 = spr.get_rect()
			var corners: Array[Vector2] = [
				rect.position,
				Vector2(rect.end.x, rect.position.y),
				Vector2(rect.position.x, rect.end.y),
				rect.end,
			]
			for corner: Vector2 in corners:
				var p: Vector2 = spr.transform * corner
				min_v = min_v.min(p)
				max_v = max_v.max(p)
	if min_v.x == INF:
		return Rect2()
	return Rect2(min_v, max_v - min_v)

# 在指定位置播放共享 death_medium 死亡特效（覆盖在角色之上，不改变角色自身动画）
func _play_death_fx_at(pos: Vector2) -> void:
	var skel_path := DEATH_MEDIUM_BASE + ".skel"
	var atlas_path := DEATH_MEDIUM_BASE + ".atlas"
	if not FileAccess.file_exists(skel_path) or not FileAccess.file_exists(atlas_path):
		push_warning("[DeathFX] death_medium files not found")
		return
	
	var fx_sp := SpinePlayer.new()
	add_child(fx_sp)
	fx_sp.global_position = pos
	fx_sp.z_index = 30 # 高于角色和普通特效
	fx_sp.scale = Vector2(0.6, 0.6)
	fx_sp.load_character(skel_path, atlas_path, DEATH_MEDIUM_PNG_DIR)
	
	var anims: Array = fx_sp.skel_data.get("animations", [])
	if not anims.is_empty():
		fx_sp.play(anims[0].name, false)
	
	var duration: float = fx_sp.current_anim.duration if (fx_sp.current_anim and fx_sp.current_anim.duration > 0.1) else 1.0
	get_tree().create_timer(duration).timeout.connect(func():
		if is_instance_valid(fx_sp):
			fx_sp.queue_free()
	)

# ============================================================
# 技能聚焦效果 - 除释放者与目标外，其余角色与背景虚化/模糊
# ============================================================

const ATTACK_ZOOM_DURATION := 1.0 # 技能特效/聚焦统一持续时间（秒）
const FOCUS_DIM := Color(0.55, 0.55, 0.58, 0.65) # 非聚焦角色的暗淡程度

# 聚焦：仅保留攻击方与目标清晰，其余角色暗淡、背景模糊
func _apply_focus(attacker: Dictionary, defenders: Array[Dictionary]) -> void:
	_focus_keys = []
	var akey = _get_spine_player_ref_info(attacker).key
	if akey != null:
		_focus_keys.append(akey)
	for d in defenders:
		var dkey = _get_spine_player_ref_info(d).key
		if dkey != null and not (dkey in _focus_keys):
			_focus_keys.append(dkey)
	
	for key in _spine_players.keys():
		var sp: SpinePlayer = _spine_players[key]
		if is_instance_valid(sp):
			sp.modulate = Color.WHITE if (key in _focus_keys) else FOCUS_DIM
	
	_blur_background(true)

# 取消聚焦，恢复所有角色与背景
func _clear_focus() -> void:
	_focus_keys = []
	for key in _spine_players.keys():
		var sp: SpinePlayer = _spine_players[key]
		if is_instance_valid(sp):
			sp.modulate = Color.WHITE
	_blur_background(false)

# 聚焦时对背景贴图应用模糊+压暗；取消时移除
func _blur_background(active: bool) -> void:
	var decor := get_node_or_null("BattleUI/Crypts_roomWall_barrels") as Sprite2D
	if not decor:
		return
	if active:
		if _focus_bg_material == null:
			var shader := Shader.new()
			shader.code = "shader_type canvas_item;\nuniform float blur_amount : hint_range(0.0, 16.0) = 4.0;\nvoid fragment() {\n\tvec2 ps = TEXTURE_PIXEL_SIZE;\n\tvec3 rgb = vec3(0.0);\n\tfloat wsum = 0.0;\n\tfor (int x = -3; x <= 3; x++) {\n\t\tfor (int y = -3; y <= 3; y++) {\n\t\t\tvec2 off = vec2(float(x), float(y)) * ps * blur_amount;\n\t\t\tvec4 s = texture(TEXTURE, UV + off);\n\t\t\tfloat w = s.a;\n\t\t\trgb += s.rgb * w;\n\t\t\twsum += w;\n\t\t}\n\t}\n\trgb = (wsum > 0.0001) ? (rgb / wsum) : rgb;\n\tfloat alpha = wsum / 49.0;\n\tCOLOR = vec4(rgb, alpha) * COLOR;\n}"
			_focus_bg_material = ShaderMaterial.new()
			_focus_bg_material.shader = shader
		decor.material = _focus_bg_material
	else:
		decor.material = null

# ============================================================
# 浮字伤害/治疗 & 压力图标系统
# ============================================================

# 记录单位 hp/stress 快照，用于结算后计算差值
func _snap_unit(unit: Dictionary) -> Dictionary:
	return {"hp": unit.get("hp", 0), "stress": unit.get("stress", 0)}

# 在单位头顶显示浮字（红=伤害，绿=治疗），渐隐上升，持续 ATTACK_ZOOM_DURATION
func _show_floating_number(unit: Dictionary, amount: int) -> void:
	var sp_key = _get_spine_player_ref_info(unit).key
	if sp_key == null:
		return
	var sp: SpinePlayer = _spine_players.get(sp_key) as SpinePlayer
	if not is_instance_valid(sp):
		return
	
	var label := Label.new()
	var is_dmg := amount < 0
	label.text = "%d" % amount if is_dmg else "+%d" % amount
	label.add_theme_color_override("font_color", Color(1.0, 0.1, 0.1, 1) if is_dmg else Color(0.1, 1.0, 0.2, 1))
	label.add_theme_font_size_override("font_size", 22)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	label.add_theme_constant_override("outline_size", 4)
	
	_floating_text_layer.add_child(label)
	label.global_position = sp.global_position + Vector2(0, -70)
	label.scale = Vector2.ONE
	label.pivot_offset = Vector2.ZERO
	
	var end_scale := Vector2(0.6, 0.6)
	var tween := create_tween().set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y - 60, ATTACK_ZOOM_DURATION)
	tween.tween_property(label, "modulate:a", 0.0, ATTACK_ZOOM_DURATION).set_ease(Tween.EASE_IN)
	tween.tween_property(label, "scale", end_scale, ATTACK_ZOOM_DURATION)
	tween.chain().tween_callback(label.queue_free)

# 在单位头顶显示压力图标，延迟至放大特效结束后出现
func _show_stress_seal(unit: Dictionary, is_heroic: bool) -> void:
	var sp_key = _get_spine_player_ref_info(unit).key
	if sp_key == null:
		return
	var sp: SpinePlayer = _spine_players.get(sp_key) as SpinePlayer
	if not is_instance_valid(sp):
		return
	
	var icon_path := "res://panels/seal.heroic.png" if is_heroic else "res://panels/seal.affliction.png"
	if not ResourceLoader.exists(icon_path):
		return
	
	# 延迟至放大结束后再显示压力图标
	get_tree().create_timer(ATTACK_ZOOM_DURATION).timeout.connect(_show_stress_seal_delayed.bind(
		sp.global_position, icon_path
	))

func _show_stress_seal_delayed(at_pos: Vector2, icon_path: String) -> void:
	var base_s := 40.0
	var rect := TextureRect.new()
	rect.texture = load(icon_path)
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.custom_minimum_size = Vector2(base_s, base_s)
	rect.pivot_offset = Vector2(base_s * 0.5, base_s * 0.5)
	
	_floating_text_layer.add_child(rect)
	rect.global_position = at_pos + Vector2(-base_s * 0.5, -160)
	rect.scale = Vector2.ONE
	rect.modulate = Color(1, 1, 1, 1)
	
	var tween := create_tween().set_parallel(true)
	tween.tween_property(rect, "position:y", rect.position.y - 15, 1.0)
	tween.tween_property(rect, "modulate:a", 0.0, 1.0).set_ease(Tween.EASE_IN)
	tween.tween_property(rect, "scale", Vector2(0.5, 0.5), 1.0)
	tween.chain().tween_callback(rect.queue_free)

# 快照 → 结算 → 比对差值 → 自动生成浮字+压力图标
func _emit_feedback(targets: Array[Dictionary], snapshots: Array[Dictionary]) -> void:
	# 音效：只有真打出掉血才播“命中层”；一点血都没掉（完全被抵消/免疫）改播“挥空音”。
	# 治疗/增益类技能在 SKILL_IMPACT 里没有条目，has_impact_sound 为 false，自然静音。
	var skill_sfx := _pending_impact_skill
	_pending_impact_skill = ""
	if not skill_sfx.is_empty() and Sfx.has_impact_sound(skill_sfx):
		var hurt := 0
		for i in range(mini(targets.size(), snapshots.size())):
			if int(targets[i].get("hp", 0)) - int(snapshots[i].get("hp", 0)) < 0:
				hurt += 1
		if hurt > 0:
			# AoE 一次打多人只播一次命中音，命中数量越多略微抬高音量（更“重”）
			Sfx.play_skill_impact(skill_sfx, -12.0 + minf(float(hurt - 1) * 1.5, 4.5))
		else:
			Sfx.play_skill_miss(skill_sfx)

	for i in range(targets.size()):
		if i >= snapshots.size():
			break
		var t := targets[i]
		var snap := snapshots[i]
		var hp_delta: int = t.get("hp", 0) - snap["hp"]
		var stress_delta: int = t.get("stress", 0) - snap["stress"]
		
		if hp_delta != 0:
			_show_floating_number(t, hp_delta)
		if stress_delta > 0:
			_show_stress_seal(t, false) # 压力上升 → affliction
		elif stress_delta < 0:
			_show_stress_seal(t, true) # 压力下降 → heroic
	
	# 压力结算收尾：把本批目标中"压力越阈待判"的英雄结算为折磨 / 美德
	_resolve_pending_stress_states(targets)

# ============================================================
# SpinePlayer 管理
# ============================================================

func _clear_spine_players() -> void:
	for key in _spine_players.keys():
		var sp = _spine_players[key]
		if is_instance_valid(sp):
			sp.queue_free()
	_spine_players.clear()
	_spine_current_state.clear()
	_spine_anchors.clear()

func _create_spine_player_for_hero(hero_index: int) -> void:
	var sp := SpinePlayer.new()
	sp.name = "SpinePlayer_%d" % hero_index
	# 有效缩放 = node scale × attachment scaleX(0.5) = 0.5×0.5=0.25
	# 角色高度约 265 Spine units × 0.25 ≈ 66px，适合 120px 槽位
	sp.scale = Vector2(0.5, 0.5)
	add_child(sp)
	_spine_players[hero_index] = sp
	_spine_current_state[hero_index] = ""
	_load_hero_anim(hero_index, "idle")

func _load_hero_anim(hero_index: int, state: String) -> void:
	if not _spine_players.has(hero_index):
		return
	if _spine_current_state.get(hero_index, "") == state:
		return # 已经是该动画，不需要重新加载
	var sp: SpinePlayer = _spine_players[hero_index]
	var hero_id: String = heroes[hero_index].get("id", "")
	var anim_file: String
	var skel_path: String
	var atlas_path: String
	if hero_id == "occultist":
		anim_file = OCCULTIST_ANIM_MAP.get(state, "idle")
		skel_path = OCCULTIST_ANIM_BASE + anim_file + ".skel"
		atlas_path = OCCULTIST_ANIM_BASE + anim_file + ".atlas"
		sp.load_character(skel_path, atlas_path, OCCULTIST_PNG_DIR)
	elif hero_id == "houndmaster":
		anim_file = HOUNDMASTER_ANIM_MAP.get(state, "idle")
		skel_path = HOUNDMASTER_ANIM_BASE + anim_file + ".skel"
		atlas_path = HOUNDMASTER_ANIM_BASE + anim_file + ".atlas"
		sp.load_character(skel_path, atlas_path, HOUNDMASTER_PNG_DIR)
	elif hero_id == "highwayman":
		anim_file = HIGHWAYMAN_ANIM_MAP.get(state, "idle")
		skel_path = HIGHWAYMAN_ANIM_BASE + anim_file + ".skel"
		atlas_path = HIGHWAYMAN_ANIM_BASE + anim_file + ".atlas"
		sp.load_character(skel_path, atlas_path, HIGHWAYMAN_PNG_DIR)
	elif hero_id == "cutthroat":
		anim_file = CUTTHROAT_ANIM_MAP.get(state, "combat")
		skel_path = CUTTHROAT_ANIM_BASE + anim_file + ".skel"
		atlas_path = CUTTHROAT_ANIM_BASE + anim_file + ".atlas"
		sp.load_character(skel_path, atlas_path, CUTTHROAT_PNG_DIR)
	else:
		anim_file = CRUSADER_ANIM_MAP.get(state, "idle")
		skel_path = CRUSADER_ANIM_BASE + anim_file + ".skel"
		atlas_path = CRUSADER_ANIM_BASE + anim_file + ".atlas"
		sp.load_character(skel_path, atlas_path, CRUSADER_PNG_DIR)
	sp.play(anim_file)
	_spine_current_state[hero_index] = state

# 保留兼容性别名
func _load_crusader_anim(hero_index: int, state: String) -> void:
	_load_hero_anim(hero_index, state)

# 为怪物创建 SpinePlayer
func _create_spine_player_for_monster(monster_index: int) -> void:
	var sp := SpinePlayer.new()
	sp.name = "MonsterSpinePlayer_%d" % monster_index
	sp.scale = Vector2(-0.5, 0.5) # 面向左（水平镜像）
	sp.z_index = 10 # 确保在 UI 前面
	sp.visible = true
	add_child(sp)
	var key = "monster_%d" % monster_index
	_spine_players[key] = sp
	_spine_current_state[key] = ""
	_load_monster_anim(monster_index, "idle")

# 为怪物加载动画
# 资源索引由 MONSTER_ANIM_CONFIG 提供（monster_id → base/dir/状态映射表），
# 新增怪物只需在表中登记一条，无需再改动本函数
func _load_monster_anim(monster_index: int, state: String) -> void:
	var key = "monster_%d" % monster_index
	if not _spine_players.has(key):
		return
	if _spine_current_state.get(key, "") == state:
		return # 已经是该动画，不需要重新加载
	var sp: SpinePlayer = _spine_players[key]
	var monster_id: String = str(monsters[monster_index].get("id", ""))
	if not MONSTER_ANIM_CONFIG.has(monster_id):
		push_warning("[Monster] Unknown monster_id '%s'" % monster_id)
		return
	var cfg: Dictionary = MONSTER_ANIM_CONFIG[monster_id]
	var anim_map: Dictionary = cfg["map"]
	# 未登记的状态一律回落到 combat（与旧版 if/elif 链的默认值一致）
	var anim_file: String = str(anim_map.get(state, anim_map.get("combat", "combat")))
	var anim_base: String = str(cfg["base"])
	var png_dir: String = str(cfg["dir"])
	# 尸体：骨架没有独立 dead 动画的怪物（首领/大炮/点火员/弹药桶）直接改用
	# 普通小怪的"残骸"资源，因此场上摆的是真正躺着的遗体，而不是站着的活体姿态
	if state == "dead" and not _monster_has_real_dead_anim(monster_id):
		var remains: Dictionary = cfg.get("corpse", CORPSE_REMAINS_DEFAULT)
		anim_base = str(remains.get("base", CORPSE_REMAINS_DEFAULT["base"]))
		png_dir = str(remains.get("dir", CORPSE_REMAINS_DEFAULT["dir"]))
		anim_file = str(remains.get("anim", CORPSE_REMAINS_DEFAULT["anim"]))
	var skel_path: String = anim_base + anim_file + ".skel"
	var atlas_path: String = anim_base + anim_file + ".atlas"
	sp.load_character(skel_path, atlas_path, png_dir)
	sp.play(anim_file)
	_spine_current_state[key] = state

# 该怪物骨架是否自带真实的倒地动画（map["dead"] 与兜底动画不同）
func _monster_has_real_dead_anim(monster_id: String) -> bool:
	if not MONSTER_ANIM_CONFIG.has(monster_id):
		return false
	var amap: Dictionary = MONSTER_ANIM_CONFIG[monster_id]["map"]
	return amap.has("dead") and str(amap["dead"]) != str(amap.get("combat", "combat"))


# 根据英雄行动状态切换动画
func _update_crusader_animations() -> void:
	for i in range(heroes.size()):
		if not _spine_players.has(i):
			continue
		var hero := heroes[i]
		var is_current: bool = (current_actor.get("unit_type") == "hero" and current_actor.get("index") == i)
		if hero.get("is_death_door", false):
			_load_hero_anim(i, "combat") # 濒死状态用 combat（痛苦挣扎姿态）
		elif hero["hp"] <= 0:
			# 理论上英雄 HP<=0 且非濒死代表已真死移除，但保留此分支为安全兜底
			_load_hero_anim(i, "combat")
		elif hero.get("is_defending", false):
			_load_hero_anim(i, "defend")
		elif is_current and _in_fx_pause:
			var next_state := "attack"
			if hero_current_skill != "" and SKILL_FX_MAP.has(hero_current_skill):
				var fx_cfg = SKILL_FX_MAP[hero_current_skill]
				if fx_cfg.has("caster_anim"):
					next_state = fx_cfg["caster_anim"]
			_load_hero_anim(i, next_state)
		elif is_current:
			_load_hero_anim(i, "combat")
		else:
			_load_hero_anim(i, "idle")

# 根据怪物行动状态切换动画
func _update_monster_animations() -> void:
	for i in range(monsters.size()):
		var key = "monster_%d" % i
		if not _spine_players.has(key):
			continue
		var monster := monsters[i]
		var is_current: bool = (current_actor.get("unit_type") == "monster" and current_actor.get("index") == i)
		if monster.get("is_corpse", false):
			_load_monster_anim(i, "dead") # 尸体：有 dead 动画的播 dead，没有的自动换成普通小怪残骸
		elif monster["hp"] <= 0:
			_load_monster_anim(i, "combat") # 安全兜底
		elif monster.get("is_defending", false):
			_load_monster_anim(i, "defend")
		elif is_current and _in_fx_pause:
			var next_state := "attack"
			if monster_current_skill_id != "" and SKILL_FX_MAP.has(monster_current_skill_id):
				var fx_cfg = SKILL_FX_MAP[monster_current_skill_id]
				if fx_cfg.has("caster_anim"):
					next_state = fx_cfg["caster_anim"]
			_load_monster_anim(i, next_state)
		elif is_current:
			# 行动前/后的待机备战阶段，保持 combat/备战待机姿态
			_load_monster_anim(i, "combat")
		else:
			_load_monster_anim(i, "idle")

# ============================================================
# LLM 激励喊话系统底座逻辑
# ============================================================

# 激励喊话的四种结果数值配置
const INSPIRE_STRESS_RELIEVE := -35 # ① 减压：压力下降值
const INSPIRE_STRESS_STRESS := 20 # ③ 加压：压力上升值
const INSPIRE_BETRAY_DAMAGE_RATIO := 0.5 # ④ 攻击队友：伤害 = 施动者攻击力 × 该系数
const INSPIRE_BUFF_STATUS := "inspired" # ② 增益：附加的状态 id（攻击力倍率见 StatusConfig.inspired.attack_mult）
const INSPIRE_BUFF_ROUNDS := 3 # ② 增益：持续回合数

func _create_inspire_button_and_ui() -> void:
	# 1. 在 PanelHero 动态追加 Inspire 按钮
	var panel_hero = get_node_or_null("BattleUI/BattleContainer/LeftArea/BottomLeftPanel/BottomPanelsContainer/PanelHero")
	if panel_hero:
		inspire_button = Button.new()
		inspire_button.text = "Inspire"
		inspire_button.tooltip_text = "用语言激励当前行动英雄（消耗该英雄本回合行动）。\n结果不定：①减压 ②获得增益 ③加压 ④精神崩溃倒戈攻击队友"
		# 摆在 ReposButton 左边 (ReposButton 在 575.0, SkipButton 在 620.0)
		inspire_button.offset_left = 510.0
		inspire_button.offset_top = -126.0
		inspire_button.offset_right = 570.0
		inspire_button.offset_bottom = -88.0
		
		# 美化按钮：加上暗紫色调（代表精神和解压力），让它极为精巧
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.35, 0.15, 0.45, 0.9)
		style.border_width_left = 1
		style.border_width_top = 1
		style.border_width_right = 1
		style.border_width_bottom = 1
		style.border_color = Color(0.6, 0.3, 0.7, 1)
		style.corner_radius_top_left = 3
		style.corner_radius_top_right = 3
		style.corner_radius_bottom_left = 3
		style.corner_radius_bottom_right = 3
		
		var style_hover := style.duplicate()
		style_hover.bg_color = Color(0.45, 0.2, 0.55, 1)
		
		var style_disabled := style.duplicate()
		style_disabled.bg_color = Color(0.2, 0.2, 0.2, 0.5)
		style_disabled.border_color = Color(0.4, 0.4, 0.4, 0.5)
		
		inspire_button.add_theme_stylebox_override("normal", style)
		inspire_button.add_theme_stylebox_override("hover", style_hover)
		inspire_button.add_theme_stylebox_override("pressed", style_hover)
		inspire_button.add_theme_stylebox_override("disabled", style_disabled)
		
		# 稍微调小一下字号
		inspire_button.add_theme_font_size_override("font_size", 10)
		inspire_button.add_theme_color_override("font_color", Color(1.0, 0.8, 1.0, 1))
		
		panel_hero.add_child(inspire_button)
		inspire_button.pressed.connect(_on_inspire_pressed)
		
	# 2. 动态创建全屏的模态输入框（使用 CanvasLayer 确保其永久渲染在所有游戏实体 Z 轴最顶层）
	var battle_ui = get_node_or_null("BattleUI")
	if battle_ui:
		var inspire_layer := CanvasLayer.new()
		inspire_layer.name = "InspireLayer"
		inspire_layer.layer = 100 # 超高层级，绝对防遮挡
		battle_ui.add_child(inspire_layer)
		
		# 输入面板 Modal
		inspire_modal = ColorRect.new()
		inspire_modal.name = "InspireModal"
		inspire_modal.color = Color(0.08, 0.08, 0.1, 0.8)
		inspire_modal.anchors_preset = 15
		inspire_modal.anchor_left = 0.0
		inspire_modal.anchor_top = 0.0
		inspire_modal.anchor_right = 1.0
		inspire_modal.anchor_bottom = 1.0
		inspire_modal.visible = false
		inspire_layer.add_child(inspire_modal)
		
		var panel := Panel.new()
		panel.custom_minimum_size = Vector2(440, 220)
		panel.anchors_preset = 8
		panel.anchor_left = 0.5
		panel.anchor_top = 0.5
		panel.anchor_right = 0.5
		panel.anchor_bottom = 0.5
		panel.offset_left = -220
		panel.offset_top = -110
		panel.offset_right = 220
		panel.offset_bottom = 110
		
		# 美化 panel
		var panel_style := StyleBoxFlat.new()
		panel_style.bg_color = Color(0.12, 0.1, 0.15, 0.95)
		panel_style.border_width_left = 2
		panel_style.border_width_top = 2
		panel_style.border_width_right = 2
		panel_style.border_width_bottom = 2
		panel_style.border_color = Color(0.5, 0.25, 0.6, 1)
		panel_style.corner_radius_top_left = 6
		panel_style.corner_radius_top_right = 6
		panel_style.corner_radius_bottom_left = 6
		panel_style.corner_radius_bottom_right = 6
		panel.add_theme_stylebox_override("panel", panel_style)
		inspire_modal.add_child(panel)
		
		var vbox := VBoxContainer.new()
		vbox.anchors_preset = 15
		vbox.offset_left = 20
		vbox.offset_top = 20
		vbox.offset_right = -20
		vbox.offset_bottom = -20
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		panel.add_child(vbox)
		
		inspire_label = Label.new()
		inspire_label.text = "对英雄喊点什么来激励他吧："
		inspire_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		inspire_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3, 1))
		inspire_label.add_theme_font_size_override("font_size", 14)
		inspire_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		vbox.add_child(inspire_label)
		
		# 换行间距
		var space1 := Control.new()
		space1.custom_minimum_size = Vector2(0, 10)
		vbox.add_child(space1)
		
		inspire_input = LineEdit.new()
		inspire_input.placeholder_text = "例如：圣光保佑！我们绝不会在此折戟！"
		inspire_input.custom_minimum_size = Vector2(380, 36)
		inspire_input.alignment = HORIZONTAL_ALIGNMENT_CENTER
		inspire_input.max_length = 60
		vbox.add_child(inspire_input)
		# 监听 Enter 键一键发送
		inspire_input.text_submitted.connect(_on_inspire_input_submitted)
		
		var space2 := Control.new()
		space2.custom_minimum_size = Vector2(0, 15)
		vbox.add_child(space2)
		
		var hbox := HBoxContainer.new()
		hbox.alignment = BoxContainer.ALIGNMENT_CENTER
		vbox.add_child(hbox)
		
		var send_btn := Button.new()
		send_btn.text = "大声喊话激励"
		send_btn.custom_minimum_size = Vector2(130, 36)
		var btn_style := StyleBoxFlat.new()
		btn_style.bg_color = Color(0.4, 0.2, 0.5, 1)
		btn_style.corner_radius_top_left = 4
		btn_style.corner_radius_top_right = 4
		btn_style.corner_radius_bottom_left = 4
		btn_style.corner_radius_bottom_right = 4
		send_btn.add_theme_stylebox_override("normal", btn_style)
		send_btn.add_theme_color_override("font_color", Color.WHITE)
		hbox.add_child(send_btn)
		send_btn.pressed.connect(_on_send_inspire_pressed)
		
		var space_h := Control.new()
		space_h.custom_minimum_size = Vector2(25, 0)
		hbox.add_child(space_h)
		
		var cancel_btn := Button.new()
		cancel_btn.text = "算了"
		cancel_btn.custom_minimum_size = Vector2(100, 36)
		var cancel_btn_style := StyleBoxFlat.new()
		cancel_btn_style.bg_color = Color(0.25, 0.25, 0.25, 1)
		cancel_btn_style.corner_radius_top_left = 4
		cancel_btn_style.corner_radius_top_right = 4
		cancel_btn_style.corner_radius_bottom_left = 4
		cancel_btn_style.corner_radius_bottom_right = 4
		cancel_btn.add_theme_stylebox_override("normal", cancel_btn_style)
		cancel_btn.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8, 1))
		hbox.add_child(cancel_btn)
		cancel_btn.pressed.connect(_on_cancel_inspire_pressed)
		
		# ----------------------------------------------------
		# 3. 动态创建全屏居中偏上的回复展示 Modal（同样置于高层 CanvasLayer）
		var reply_layer := CanvasLayer.new()
		reply_layer.name = "ReplyLayer"
		reply_layer.layer = 101 # 略高一等，覆盖一切
		battle_ui.add_child(reply_layer)
		
		reply_modal = ColorRect.new()
		reply_modal.name = "ReplyModal"
		reply_modal.color = Color(0.04, 0.04, 0.05, 0.85)
		reply_modal.anchors_preset = 15
		reply_modal.anchor_left = 0.0
		reply_modal.anchor_top = 0.0
		reply_modal.anchor_right = 1.0
		reply_modal.anchor_bottom = 1.0
		reply_modal.visible = false
		reply_layer.add_child(reply_modal)
		
		var reply_panel := Panel.new()
		reply_panel.custom_minimum_size = Vector2(580, 240)
		reply_panel.anchors_preset = 5 # 顶部居中
		reply_panel.anchor_left = 0.5
		reply_panel.anchor_top = 0.15 # 偏上
		reply_panel.anchor_right = 0.5
		reply_panel.anchor_bottom = 0.15
		reply_panel.offset_left = -290
		reply_panel.offset_top = 0
		reply_panel.offset_right = 290
		reply_panel.offset_bottom = 240
		
		var reply_panel_style := StyleBoxFlat.new()
		reply_panel_style.bg_color = Color(0.08, 0.08, 0.1, 0.98)
		reply_panel_style.border_width_left = 3
		reply_panel_style.border_width_top = 3
		reply_panel_style.border_width_right = 3
		reply_panel_style.border_width_bottom = 3
		reply_panel_style.border_color = Color(0.7, 0.5, 0.2, 1) # 尊贵金黄色边框
		reply_panel_style.corner_radius_top_left = 8
		reply_panel_style.corner_radius_top_right = 8
		reply_panel_style.corner_radius_bottom_left = 8
		reply_panel_style.corner_radius_bottom_right = 8
		reply_panel.add_theme_stylebox_override("panel", reply_panel_style)
		reply_modal.add_child(reply_panel)
		
		var reply_vbox := VBoxContainer.new()
		reply_vbox.anchors_preset = 15
		reply_vbox.offset_left = 25
		reply_vbox.offset_top = 15
		reply_vbox.offset_right = -25
		reply_vbox.offset_bottom = -15
		reply_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		reply_panel.add_child(reply_vbox)
		
		reply_title_lbl = Label.new()
		reply_title_lbl.text = "【英雄被振奋了】"
		reply_title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		reply_title_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2, 1)) # 金黄
		reply_title_lbl.add_theme_font_size_override("font_size", 13)
		reply_vbox.add_child(reply_title_lbl)
		
		var reply_space1 := Control.new()
		reply_space1.custom_minimum_size = Vector2(0, 10)
		reply_vbox.add_child(reply_space1)
		
		reply_text_lbl = Label.new()
		reply_text_lbl.text = "“......”"
		reply_text_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		reply_text_lbl.add_theme_color_override("font_color", Color(0.9, 0.9, 0.95, 1)) # 白灰色
		reply_text_lbl.add_theme_font_size_override("font_size", 16)
		reply_text_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		reply_vbox.add_child(reply_text_lbl)
		
		var reply_space2 := Control.new()
		reply_space2.custom_minimum_size = Vector2(0, 15)
		reply_vbox.add_child(reply_space2)
		
		reply_status_lbl = Label.new()
		reply_status_lbl.text = "★ 压力抚慰：精神压力降低了 30 点！行动已终了 ★"
		reply_status_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		reply_status_lbl.add_theme_color_override("font_color", Color(0.4, 1.0, 0.4, 1)) # 圣洁青绿
		reply_status_lbl.add_theme_font_size_override("font_size", 12)
		reply_vbox.add_child(reply_status_lbl)
		
		var reply_space3 := Control.new()
		reply_space3.custom_minimum_size = Vector2(0, 14)
		reply_vbox.add_child(reply_space3)
		
		# 确定按钮：回应内容展示后由玩家点击，才收起窗口并推进回合
		reply_confirm_button = Button.new()
		reply_confirm_button.name = "ReplyConfirmButton"
		reply_confirm_button.text = "确定"
		reply_confirm_button.custom_minimum_size = Vector2(150, 36)
		reply_confirm_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		reply_confirm_button.focus_mode = Control.FOCUS_ALL
		reply_confirm_button.visible = false
		reply_confirm_button.add_theme_font_size_override("font_size", 15)
		reply_confirm_button.add_theme_color_override("font_color", Color(0.95, 0.88, 0.66, 1))
		var reply_btn_style := StyleBoxFlat.new()
		reply_btn_style.bg_color = Color(0.22, 0.17, 0.08, 1)
		reply_btn_style.border_width_left = 1
		reply_btn_style.border_width_top = 1
		reply_btn_style.border_width_right = 1
		reply_btn_style.border_width_bottom = 1
		reply_btn_style.border_color = Color(0.7, 0.5, 0.2, 1)
		reply_btn_style.corner_radius_top_left = 4
		reply_btn_style.corner_radius_top_right = 4
		reply_btn_style.corner_radius_bottom_left = 4
		reply_btn_style.corner_radius_bottom_right = 4
		var reply_btn_hover := reply_btn_style.duplicate() as StyleBoxFlat
		reply_btn_hover.bg_color = Color(0.32, 0.24, 0.11, 1)
		reply_confirm_button.add_theme_stylebox_override("normal", reply_btn_style)
		reply_confirm_button.add_theme_stylebox_override("hover", reply_btn_hover)
		reply_confirm_button.add_theme_stylebox_override("pressed", reply_btn_hover)
		reply_confirm_button.add_theme_stylebox_override("focus", reply_btn_hover)
		reply_vbox.add_child(reply_confirm_button)
		reply_confirm_button.pressed.connect(_on_reply_confirm_pressed)

# 玩家点击“确定” → 释放回应窗口给 _execute_llm_inspiration 继续
func _on_reply_confirm_pressed() -> void:
	if _reply_confirm_clicked:
		return
	_reply_confirm_clicked = true
	if reply_confirm_button:
		reply_confirm_button.disabled = true
	reply_confirmed.emit()

func _on_inspire_pressed() -> void:
	if battle_over or current_actor.is_empty() or current_actor["unit_type"] != "hero":
		return
	
	var hero = heroes[current_actor["index"]]
	if hero["hp"] <= 0:
		return
		
	# 唤醒 Modal 遮罩
	if inspire_modal and inspire_label and inspire_input:
		inspire_label.text = "对 【%s】 喊些什么来激励他吧（将消耗其本回合行动）：" % hero["name"]
		inspire_input.text = ""
		inspire_modal.visible = true
		inspire_input.grab_focus()

func _on_inspire_input_submitted(_txt: String) -> void:
	_on_send_inspire_pressed()

func _on_cancel_inspire_pressed() -> void:
	if inspire_modal:
		inspire_modal.visible = false

func _on_send_inspire_pressed() -> void:
	if not inspire_input or inspire_input.text.strip_edges().is_empty():
		return
		
	var input_text = inspire_input.text.strip_edges()
	# 关闭输入面板
	if inspire_modal:
		inspire_modal.visible = false
		
	# 启动 LLM 业务逻辑
	_execute_llm_inspiration(input_text)

func _execute_llm_inspiration(input_text: String) -> void:
	if battle_over or current_actor.is_empty() or current_actor["unit_type"] != "hero":
		return
		
	var hero_idx = current_actor["index"]
	var hero = heroes[hero_idx]
	if hero["hp"] <= 0:
		return
		
	# 1. 锁防多次触发、并打开全屏回复遮罩提示“聆听唤醒中...”
	_is_requesting_llm = true
	_in_fx_pause = true
	_update_ui()
	
	if reply_modal and reply_title_lbl and reply_text_lbl and reply_status_lbl:
		reply_title_lbl.text = "【%s】在战场上聆听着您的训示......" % hero["name"]
		reply_text_lbl.text = "“（大口喘着粗气，似乎被深深触动）”"
		reply_status_lbl.text = "正在调协领主的精神意志..."
		reply_modal.visible = true
	# 聆听阶段不给“确定”：等模型回复落地后再亮出按钮
	_reply_confirm_clicked = false
	if reply_confirm_button:
		reply_confirm_button.visible = false
		reply_confirm_button.disabled = true
		
	# 2. 播放战吼激励动画（播施法特效，播角色 battle_cry 的，也就是 heal 治疗姿态，代表神圣震撼）
	_load_hero_anim(hero_idx, "heal")
	# 战吼声：喊话阶段的听觉开场，任何英雄都能用
	Sfx.play(Sfx.INSPIRE_SFX, -8.0)
	if SKILL_FX_MAP.has("battle_cry"):
		var fx_base = SKILL_FX_MAP["battle_cry"]["caster_fx"]
		var skel = fx_base + ".skel"
		var atlas = fx_base + ".atlas"
		var png_dir = fx_base.get_base_dir()
		var sp = _spine_players.get(hero_idx)
		if is_instance_valid(sp):
			var flip = sp.scale.x < 0
			var target_pos = sp.global_position + Vector2(0, -90)
			_play_fx_at_position(target_pos, skel, atlas, png_dir, flip, 1.0)
			
	# 获取性格
	var hero_tpl = HeroConfig.HEROES.get(hero["id"].to_lower(), {})
	var personality = hero_tpl.get("personality", "无畏而冷俊的誓约探险家")
	
	# 面临的敌人总数
	var enemy_count = _count_alive(monsters)
	
	# 记录激励前的压力值（用于后续显示）
	var old_stress = hero.get("stress", 0)
	
	# 异步向模型发出请求（返回 {"reply": String, "sentiment": int}）
	print("[LLM] Requesting reply for hero: ", hero["name"], " personality: ", personality)
	var result = await llm_client.get_hero_reply(
		hero["name"],
		personality,
		input_text,
		hero["hp"],
		hero["max_hp"],
		old_stress,
		enemy_count,
		self
	)
	
	var reply_str: String = result.get("reply", "\u201c......\u201d")
	var outcome: int = result.get("outcome", LLMClient.Outcome.RELIEVE)
	print("[LLM] Received reply: ", reply_str, " outcome: ", outcome)
	
	# ---- 依据英雄的四种反应分别结算 ----
	var status_text: String
	var status_args: Array = [old_stress, hero["stress"]]
	var heroic_icon := true
	var betray_info: Dictionary = {}
	
	match outcome:
		LLMClient.Outcome.RELIEVE: # ① 减压
			ActionResolver.apply_stress(hero, INSPIRE_STRESS_RELIEVE)
			status_args = [old_stress, hero["stress"]]
			status_text = "★ 振奋鼓舞：精神压力从 %d 降至 %d！（减压）★"
			heroic_icon = true
		LLMClient.Outcome.BUFF: # ② 增益：战意高涨，附加攻击力增益状态
			ActionResolver.apply_status(hero, INSPIRE_BUFF_STATUS, 1, INSPIRE_BUFF_ROUNDS)
			var buff_cfg := StatusConfig.get_status(INSPIRE_BUFF_STATUS)
			status_args = [int(round((float(buff_cfg.get("attack_mult", 1.0)) - 1.0) * 100.0)), INSPIRE_BUFF_ROUNDS]
			# 注意：%% 转义 —— 本段文字之后还会统一做一次 status_text % status_args
			status_text = "◆ 战意高涨：攻击力提高 %d%%（持续 %d 回合）◆"
			heroic_icon = true
		LLMClient.Outcome.STRESS: # ③ 加压
			ActionResolver.apply_stress(hero, INSPIRE_STRESS_STRESS)
			status_args = [old_stress, hero["stress"]]
			status_text = "☠ 动摇恐惧：精神压力从 %d 升至 %d！（加压）☠"
			heroic_icon = false
		LLMClient.Outcome.BETRAY: # ④ 攻击队友
			betray_info = _execute_inspire_betrayal(hero)
			if betray_info.is_empty():
				# 场上没有可攻击的队友（例如只剩自己一人）→ 退化为单纯加压
				ActionResolver.apply_stress(hero, INSPIRE_STRESS_STRESS)
				status_args = [old_stress, hero["stress"]]
				status_text = "☠ 精神崩溃却无人可攻：精神压力从 %d 升至 %d ☠"
			else:
				status_args = [hero["name"], betray_info["target_name"], betray_info["damage"]]
				status_text = "⚔ 精神崩溃：%s 挥刀砍向 %s，造成 %d 点伤害！（攻击队友）⚔"
			heroic_icon = false
		_:
			status_text = "◇ 精神压力从 %d 调整为 %d ◇"
	
	# 激励造成的压力变动同样要过"越阈（折磨 / 美德）"结算
	_resolve_pending_stress_states([hero])
	# 压力满上限的"心脏骰停"会直接造成 999 伤害 → 补上瀕死/死亡判定
	_handle_stress_damage_aftermath()
	
	# 倒戈可能击杀队友导致数组补位 → 施动者索引（含 current_actor）需按引用重新对齐
	if not betray_info.is_empty():
		var idx_after: int = heroes.find(hero)
		if idx_after >= 0:
			hero_idx = idx_after
			current_actor["index"] = idx_after
		# 从"聆听"姿态切换为挥刀姿态
		_load_hero_anim(hero_idx, "attack")
	
	# 压力光环图标：正向结果给 heroic，负向结果给 affliction
	_show_stress_seal(hero, heroic_icon)
	
	# 播放施法者身上的 target_fx 特效（倒戈时改播"命中队友"特效，已在结算中处理）
	if betray_info.is_empty() and SKILL_FX_MAP.has("battle_cry") and SKILL_FX_MAP["battle_cry"].has("target_fx"):
		var target_fx_base = SKILL_FX_MAP["battle_cry"]["target_fx"]
		var target_skel = target_fx_base + ".skel"
		var target_atlas = target_fx_base + ".atlas"
		var target_png_dir = target_fx_base.get_base_dir()
		var sp = _spine_players.get(hero_idx)
		if is_instance_valid(sp):
			var flip = sp.scale.x < 0
			var target_pos = sp.global_position + Vector2(0, -80)
			_play_fx_at_position(target_pos, target_skel, target_atlas, target_png_dir, flip, 0.8)
			
	# 6. 将终极台词在全屏顶部大字面板显示，等待玩家点击“确定”后再继续
	if reply_modal and reply_title_lbl and reply_text_lbl and reply_status_lbl:
		reply_title_lbl.text = "【%s】回应了领主的指引：" % hero["name"]
		reply_text_lbl.text = reply_str
		reply_status_lbl.text = status_text % status_args
	if reply_confirm_button:
		reply_confirm_button.disabled = false
		reply_confirm_button.visible = true
		reply_confirm_button.grab_focus()
	
	# 刷新血量及压力条本身，让效果落地
	_update_ui()
	
	# 不再定时自动散去：由玩家点击“确定”决定何时收起窗口并推进回合
	if not _reply_confirm_clicked:
		await reply_confirmed
	_reply_confirm_clicked = false
	if reply_confirm_button:
		reply_confirm_button.visible = false
		reply_confirm_button.disabled = true
	
	if reply_modal:
		reply_modal.visible = false
		
	_is_requesting_llm = false
	_in_fx_pause = false
	_load_hero_anim(hero_idx, "idle")
	_update_ui()
	
	# 8. 激励喊话占用该角色的行动点并推进回合
	#    队友可能因倒戈阵亡补位，因此按引用重新定位施动者，绝不使用过期下标
	var final_idx: int = heroes.find(hero)
	if final_idx < 0:
		await _get_next_actor()
		return
	hero_idx = final_idx
	current_actor["index"] = final_idx
	heroes[final_idx]["actions_remaining"] = max(0, int(heroes[final_idx].get("actions_remaining", 1)) - 1)
	# 若倒戈过程中队友阵亡，_kill_hero 已重建过队列（彼时施动者仍有行动点、会被重新入队），
	# 故此处扣点后再重建一次队列，确保该角色本回合不会重复行动
	turn_queue.build(heroes, monsters)
	await _get_next_actor()

# ④ 攻击队友：随机选中一名存活队友并造成伤害
# damage_ratio 默认取激励倒戈的系数；折磨失控会传入 StressConfig.BREAKDOWN_ATTACK_RATIO
# 返回 {"target_name": String, "damage": int}；若场上没有可攻击的队友则返回 {}
func _execute_inspire_betrayal(actor: Dictionary, damage_ratio: float = INSPIRE_BETRAY_DAMAGE_RATIO) -> Dictionary:
	var candidates: Array[Dictionary] = []
	for h in heroes:
		if is_same(h, actor):
			continue
		if h.get("hp", 0) > 0 or h.get("is_death_door", false):
			candidates.append(h)
	if candidates.is_empty():
		return {}
	
	var target: Dictionary = candidates[randi() % candidates.size()]
	var dmg: int = max(1, int(round(float(actor.get("attack", 0)) * damage_ratio)))
	var snap := _snap_unit(target)
	ActionResolver.apply_damage(target, dmg)
	_emit_feedback([target], [snap])
	_play_attack_hit_fx(actor, target)
	# 倒戈一击是实打实的肉体伤害 → 叠一层刀剑命中音（施法音里没有“打自己人”的音色）
	Sfx.play_impact("sword")
	
	# 处理濒死/死亡（可能造成 heroes 补位，调用方需重新定位施动者）
	var target_idx: int = heroes.find(target)
	if target_idx >= 0:
		# 倒戈一击是真实伤害 → 濒死队友要掷死亡骰
		_handle_hero_damage_aftermath(target_idx, true)
	
	print("[Inspire] ", actor.get("name", "???"), " betrayed and struck ", target.get("name", "???"), " for ", dmg)
	return {"target_name": str(target.get("name", "队友")), "damage": dmg}

# 在受击队友身上播放"普通攻击命中"特效：取施动者第一个带 target_fx 技能的特效
func _play_attack_hit_fx(attacker: Dictionary, target: Dictionary) -> void:
	var target_info := _get_spine_player_ref_info(target)
	if target_info.key == null:
		return
	var target_sp: SpinePlayer = _spine_players.get(target_info.key)
	if not is_instance_valid(target_sp):
		return
	for sid in attacker.get("skills", []):
		var s_id := str(sid)
		if not SKILL_FX_MAP.has(s_id):
			continue
		var cfg: Dictionary = SKILL_FX_MAP[s_id]
		if not cfg.has("target_fx"):
			continue
		var fx_base: String = cfg["target_fx"]
		var flip: bool = target_sp.scale.x < 0
		var scale_mult: float = float(cfg.get("target_scale", 1.0))
		# 与 _play_skill_fx_v2 一致：显式 target_offset 优先，否则自动对齐到目标躯干
		var pos: Vector2 = target_sp.global_position
		var align_to: Variant = null
		var explicit_offset: Variant = cfg.get("target_offset", null)
		if explicit_offset != null:
			var offset: Vector2 = explicit_offset
			if flip:
				offset.x = - offset.x
			pos = target_sp.global_position + offset
		else:
			align_to = target_sp
		_play_fx_at_position(
			pos,
			fx_base + ".skel",
			fx_base + ".atlas",
			fx_base.get_base_dir(),
			flip,
			scale_mult,
			align_to
		)
		return
