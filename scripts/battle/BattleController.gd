extends Node

signal return_to_start

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
	
	# === 骷髅枪兵特效 ===
	"spear_thrust": {
		"caster_fx": "res://monsters/skeleton_spear/fx/skeleton_spear.sprite.spear_thrust",
		"caster_anim": "attack"
	}
}

# --- 节点引用 ---
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
@onready var back_button: Button = $BattleUI/VictoryPanel/BackToStartButton
@onready var reposition_button: TextureButton = $BattleUI/BattleContainer/LeftArea/BottomLeftPanel/BottomPanelsContainer/PanelHero/ReposButton
@onready var skip_button: TextureButton = $BattleUI/BattleContainer/LeftArea/BottomLeftPanel/BottomPanelsContainer/PanelHero/SkipButton

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

# --- 战斗状态 ---
var battle_over := false
var round_number := 0
var current_actor: Dictionary = {}
var hero_skill_selected := false
var hero_current_skill := ""
var reposition_mode := false
var _in_fx_pause := false
var _fx_zoom_multiplier := 1.0 # 特效缩放倍率，攻击放大时同步生效
var monster_current_skill_id := ""

# --- 浮字 / 压力图标系统 ---
var _floating_text_layer: CanvasLayer = null

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
var _is_requesting_llm := false

# ============================================================
# 生命周期
# ============================================================

func _ready() -> void:
	_create_inspire_button_and_ui()
	
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
		var tpl := team[i]
		heroes.append({
			"id": tpl.get("id", ""),
			"name": tpl.get("name", "Hero %d" % (i + 1)),
			"hp": tpl.get("max_hp", 50),
			"max_hp": tpl.get("max_hp", 50),
			"attack": tpl.get("attack", 10),
			"speed": tpl.get("speed", 4),
			"speed_delta": 0,
			"actions_remaining": 1,
			"skills": tpl.get("skills", []),
			"index": i,
			"stress": 0,
			"max_stress": 200,
		})

	# 从 MonsterConfig 加载本场遭遇怪物
	var encounter := MonsterConfig.get_encounter_monsters()
	for i in range(encounter.size()):
		var tpl := encounter[i]
		monsters.append({
			"id": tpl.get("id", ""),
			"name": tpl.get("name", "Monster %d" % (i + 1)),
			"hp": tpl.get("max_hp", 40),
			"max_hp": tpl.get("max_hp", 40),
			"attack": tpl.get("attack", 10),
			"speed": tpl.get("speed", 4),
			"speed_delta": 0,
			"speed_delta_base": tpl.get("speed_delta_base", -1),
			"actions_remaining": 1,
			"index": i,
			"skills": tpl.get("skills", []),
		})

	battle_over = false
	hero_skill_selected = false
	hero_current_skill = ""
	reposition_mode = false
	current_actor = {}
	round_number = 0
	if victory_panel:
		victory_panel.visible = false

	# 初始化英雄和怪物 SpinePlayer
	_clear_spine_players()
	for i in range(heroes.size()):
		var hero_id: String = heroes[i].get("id", "")
		if hero_id == "crusader" or hero_id == "highwayman":
			_create_spine_player_for_hero(i)

	# 初始化怪物 SpinePlayer（cutthroat / 骷髅系等）
	var skeleton_ids := ["skeleton_arbalist", "skeleton_courtier", "skeleton_common", "skeleton_defender", "skeleton_militia", "skeleton_spear"]
	for i in range(monsters.size()):
		var monster_id: String = monsters[i].get("id", "")
		if monster_id == "cutthroat" or monster_id in skeleton_ids:
			_create_spine_player_for_monster(i)

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
			monster["actions_remaining"] = 1
			monster["speed_delta"] = randi_range(-SPEED_DELTA_RANGE, SPEED_DELTA_RANGE)
	turn_queue.build(heroes, monsters)

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

		if current_actor["unit_type"] == "hero":
			hero_skill_selected = false
			hero_current_skill = ""
			reposition_mode = false
			_in_fx_pause = false
			monster_current_skill_id = ""
			_update_ui()
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
	if not candidate_skills.is_empty():
		var recruited: Dictionary = candidate_skills[randi() % candidate_skills.size()]
		var skill_data: Dictionary = recruited["skill_data"]
		var valid_targets: Array[Dictionary] = recruited["targets"]
		var target_type: String = skill_data.get("target_type", "")
		
		# 4. 执行施法与效果分发
		_in_fx_pause = true
		monster_current_skill_id = recruited["skill_id"]
		
		match target_type:
			"single_enemy", "single_ally":
				var priority: String = skill_data.get("target_priority", "random")
				var chosen_target: Dictionary = _select_target_by_priority(valid_targets, priority)
				if not chosen_target.is_empty():
					var is_dmg: bool = skill_data.get("effect_type", "") == "damage"
					if is_dmg:
						chosen_target["is_defending"] = true
					_update_ui()
					
					_zoom_attack_scene(monsters[idx], [chosen_target], true)
					_play_skill_fx_v2(monsters[idx], recruited["skill_id"], [chosen_target])
					if chosen_target.get("is_defending", false):
						chosen_target["is_defending"] = false
					var snap_single := _snap_unit(chosen_target)
					ActionResolver.resolve_on_target(monsters[idx], skill_data, chosen_target)
					_emit_feedback([chosen_target], [snap_single])
					
					# 若目标为英雄则处理濒死/死亡骰
					var hero_killed := false
					if target_type == "single_enemy":
						var target_hero_idx := heroes.find(chosen_target)
						if target_hero_idx >= 0:
							hero_killed = _handle_hero_damage_aftermath(target_hero_idx)
					
					await get_tree().create_timer(ATTACK_ZOOM_DURATION).timeout
					
					# 英雄被击杀 → 仅缩放怪物回正常；否则正常缩放双方
					if hero_killed:
						_zoom_combatant(monsters[idx], false)
					else:
						_zoom_attack_scene(monsters[idx], [chosen_target], false)
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
				
				_zoom_attack_scene(monsters[idx], valid_targets, true)
				_play_skill_fx_v2(monsters[idx], recruited["skill_id"], valid_targets)
				for t in valid_targets:
					t["is_defending"] = false
				var snaps_all: Array[Dictionary] = []
				for t in valid_targets:
					snaps_all.append(_snap_unit(t))
				ActionResolver.resolve_on_all(monsters[idx], skill_data, valid_targets)
				_emit_feedback(valid_targets, snaps_all)
				
				# 若目标为英雄则逐个处理濒死/死亡骰；任一英雄死亡立即标记
				var any_hero_killed := false
				if target_type == "all_enemies":
					for t in valid_targets:
						var target_hero_idx := heroes.find(t)
						if target_hero_idx >= 0:
							if _handle_hero_damage_aftermath(target_hero_idx):
								any_hero_killed = true
				
				await get_tree().create_timer(ATTACK_ZOOM_DURATION).timeout
				
				# 缩放恢复：怪物始终恢复；存活的英雄逐个恢复
				_zoom_combatant(monsters[idx], false)
				for t in valid_targets:
					if heroes.find(t) >= 0:
						_zoom_combatant(t, false)
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
		for i in range(monsters.size()):
			if monsters[i]["hp"] > 0 and not monsters[i].get("is_corpse", false):
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
	battle_over = true
	current_actor = {}
	if victory_panel:
		victory_panel.visible = true
	_update_ui()

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
			print("[Corpse] ", m["name"], " fell, leaving a corpse with 10 HP")

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

# 英雄受到伤害后调用：处理濒死/死亡骰
# 返回 true 表示英雄已真死
func _handle_hero_damage_aftermath(hero_idx: int) -> bool:
	if hero_idx < 0 or hero_idx >= heroes.size():
		return false
	var h := heroes[hero_idx]
	if h["hp"] > 0:
		# 存活状态，检查是否脱离濒死
		if h.get("is_death_door", false):
			h["is_death_door"] = false
			print("[DeathDoor] ", h["name"], " recovered from death's door!")
		return false
	
	# HP ≤ 0
	if h.get("is_death_door", false):
		# 已在濒死状态 → 50% 死亡骰
		if randf() < 0.5:
			print("[DeathDoor] ", h["name"], " has died at death's door!")
			_kill_hero(hero_idx)
			return true
		else:
			h["hp"] = 0 # 保持在濒死
			print("[DeathDoor] ", h["name"], " survived the death blow at death's door!")
			return false
	else:
		# 首次降至 0 → 进入濒死状态
		h["hp"] = 0
		h["is_death_door"] = true
		print("[DeathDoor] ", h["name"], " has entered death's door!")
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
	
	# 放大攻击方和目标（暗黑地牢风格，所有技能通用）
	_zoom_attack_scene(heroes[current_actor["index"]], [monsters[index]], true)
	
	# 2. 生成特效后立即结算伤害并显示数字（与放大同步）
	_play_skill_fx_v2(heroes[current_actor["index"]], s_id, [monsters[index]])
	if monsters[index].get("is_defending", false):
		monsters[index]["is_defending"] = false
	var snap := _snap_unit(monsters[index])
	ActionResolver.resolve_on_target(heroes[current_actor["index"]], skill_data, monsters[index])
	_emit_feedback([monsters[index]], [snap])
	
	# 处理怪物尸体创建/清除（可能移除该怪物）
	var was_cleared: bool = monsters[index].get("is_corpse", false) and monsters[index]["hp"] <= 0
	_handle_monster_damage_aftermath(index)
	
	# 3. 放大 + 特效 + 数字持续 ATTACK_ZOOM_DURATION 秒
	await get_tree().create_timer(ATTACK_ZOOM_DURATION).timeout
	
	# 缩小回正常（若怪物已被清除则只缩放英雄）
	if was_cleared or index >= monsters.size():
		_zoom_combatant(heroes[current_actor["index"]], false)
	else:
		_zoom_attack_scene(heroes[current_actor["index"]], [monsters[index]], false)
	
	# 4. 特效演完，释放锁定并彻底清理已选技能
	_in_fx_pause = false
	hero_skill_selected = false
	var pre_current_skill := hero_current_skill
	hero_current_skill = ""
	_update_ui() # 刷新动画（回到正常状态）
	
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
	
	# 放大攻击方和所有目标（暗黑地牢风格，所有技能通用）
	_zoom_attack_scene(heroes[current_actor["index"]], final_targets, true)
	
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
	
	# 3. 放大 + 特效 + 数字持续 ATTACK_ZOOM_DURATION 秒
	await get_tree().create_timer(ATTACK_ZOOM_DURATION).timeout
	
	# 缩小回正常（过滤掉已被清除的尸体）
	var remaining: Array[Dictionary] = []
	for t in final_targets:
		if monsters.find(t) >= 0:
			remaining.append(t)
	if remaining.is_empty():
		_zoom_combatant(heroes[current_actor["index"]], false)
	else:
		_zoom_attack_scene(heroes[current_actor["index"]], remaining, false)
	
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
	
	# 放大施法者和目标（暗黑地牢风格）
	_zoom_attack_scene(heroes[current_actor["index"]], [heroes[index]], true)
	
	# 2. 生成特效后立即结算（battle_cry 等可能影响全体友方）
	_play_skill_fx_v2(heroes[current_actor["index"]], s_id, [heroes[index]])
	var ally_snaps: Array[Dictionary] = []
	for h in heroes:
		ally_snaps.append(_snap_unit(h))
	ActionResolver.resolve_on_target(heroes[current_actor["index"]], skill_data, heroes[index], heroes)
	_emit_feedback(heroes, ally_snaps)
	
	# 治疗可能让濒死英雄脱离死亡之门
	_handle_hero_damage_aftermath(index)
	for i in range(heroes.size()):
		if i != index:
			_handle_hero_damage_aftermath(i)
	
	# 3. 放大 + 特效 + 数字/图标持续 ATTACK_ZOOM_DURATION 秒
	await get_tree().create_timer(ATTACK_ZOOM_DURATION).timeout
	
	# 缩小回正常
	_zoom_attack_scene(heroes[current_actor["index"]], [heroes[index]], false)
	
	# 4. 特效演完，释放锁定并清理选定
	_in_fx_pause = false
	hero_skill_selected = false
	var pre_current_skill := hero_current_skill
	hero_current_skill = ""
	_update_ui()
	
	await _finish_hero_action(pre_current_skill)

func _on_back_pressed() -> void:
	emit_signal("return_to_start")

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

func _finish_hero_action(used_skill_id: String = "") -> void:
	var move_applied: bool = false
	var skill_to_check := hero_current_skill if used_skill_id == "" else used_skill_id
	if skill_to_check != "":
		var skill_data: Dictionary = SkillConfig.get_skill(skill_to_check)
		if not skill_data.is_empty():
			var move_f: int = int(skill_data.get("move_forward", 0))
			if move_f != 0 and current_actor.get("unit_type") == "hero":
				var src_idx: int = current_actor["index"]
				var target_idx: int = int(clamp(src_idx - move_f, 0, heroes.size() - 1))
				if target_idx != src_idx:
					# 1. 先扣除本回合行动点
					heroes[src_idx]["actions_remaining"] -= 1
					# 2. 执行位移 (支持前进 > 0 和后退 < 0)
					_apply_hero_reposition_position(src_idx, target_idx)
					# 3. 重建队列
					turn_queue.build(heroes, monsters)
					move_applied = true
				
	hero_skill_selected = false
	hero_current_skill = ""
	
	if move_applied:
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
	
	var hero = heroes[current_actor["index"]]
	var hero_name: String = hero.get("name", "Unknown")
	
	# 获取英雄对应的头像路径
	var portrait_path: String = "res://characters/%s/%s_guild_header.png" % [hero_name.to_lower(), hero_name.to_lower()]
	
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
	var hero := heroes[current_actor["index"]]
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

# 创建怪物内容（用于填充预设位置）
func _make_monster_content(monster: Dictionary, idx: int, target_type: String, target_positions: Array = []) -> VBoxContainer:
	return _make_monster_slot(monster, idx, target_type, target_positions)

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
	var vbox := VBoxContainer.new()
	vbox.anchors_preset = 15
	vbox.anchor_right = 1.0
	vbox.anchor_bottom = 1.0
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	slot.add_child(vbox)

	var is_current: bool = (current_actor.get("unit_type") == "hero" and current_actor.get("index") == idx)
	var is_death_door: bool = hero.get("is_death_door", false)
	var is_dead: bool = hero["hp"] <= 0 and not is_death_door
	var is_target: bool = (hero_skill_selected and target_type == "single_ally" and not is_dead and not battle_over
		and (target_positions.is_empty() or (idx + 1) in target_positions))
	var is_repos_target: bool = (reposition_mode and not is_current and not is_dead and not battle_over)

	# 速度标签（顶部）
	var spd_lbl := Label.new()
	spd_lbl.text = "SPD %d" % (hero["speed"] + hero["speed_delta"])
	spd_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	spd_lbl.add_theme_color_override("font_color", Color(0.75, 0.75, 0.45, 1))
	spd_lbl.add_theme_font_size_override("font_size", 13)
	vbox.add_child(spd_lbl)

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

	# 血条
	var hp_bar := ProgressBar.new()
	hp_bar.custom_minimum_size = Vector2(100.0, 14.0)
	hp_bar.min_value = 0
	hp_bar.max_value = hero["max_hp"]
	hp_bar.value = hero["hp"]
	hp_bar.show_percentage = false
	vbox.add_child(hp_bar)

	# HP 数值
	var hp_lbl := Label.new()
	hp_lbl.text = "%d/%d" % [hero["hp"], hero["max_hp"]]
	hp_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hp_lbl.add_theme_font_size_override("font_size", 11)
	vbox.add_child(hp_lbl)

	# 压力条
	var stress_bar := ProgressBar.new()
	stress_bar.custom_minimum_size = Vector2(100.0, 14.0)
	stress_bar.min_value = 0
	stress_bar.max_value = 200
	stress_bar.value = hero.get("stress", 0)
	stress_bar.show_percentage = false
	
	# 自定义 StyleBox 将填充色改为神秘而庄重的暗黑色調紫色
	var sb_fill := StyleBoxFlat.new()
	sb_fill.bg_color = Color(0.6, 0.2, 0.7, 1.0)
	stress_bar.add_theme_stylebox_override("fill", sb_fill)
	vbox.add_child(stress_bar)

	# 压力数值
	var stress_lbl := Label.new()
	stress_lbl.text = "Stress: %d/200" % hero.get("stress", 0)
	stress_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stress_lbl.add_theme_font_size_override("font_size", 11)
	stress_lbl.add_theme_color_override("font_color", Color(0.9, 0.4, 0.9, 1))
	vbox.add_child(stress_lbl)

	# 濒死状态指示器
	if is_death_door:
		var dd_lbl := Label.new()
		dd_lbl.text = "☠ DEATH'S DOOR ☠"
		dd_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		dd_lbl.add_theme_font_size_override("font_size", 10)
		dd_lbl.add_theme_color_override("font_color", Color(1.0, 0.2, 0.2, 1))
		vbox.add_child(dd_lbl)

	# 选中指示器
	var sel_lbl := Label.new()
	sel_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sel_lbl.add_theme_color_override("font_color", Color(1.0, 0.9, 0.2, 1))
	sel_lbl.text = "▲" if is_current else ""
	vbox.add_child(sel_lbl)

	return slot

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
	var vbox := VBoxContainer.new()
	vbox.anchors_preset = 15
	vbox.anchor_right = 1.0
	vbox.anchor_bottom = 1.0
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	slot.add_child(vbox)

	var is_current: bool = (current_actor.get("unit_type") == "monster" and current_actor.get("index") == idx)
	var is_corpse: bool = monster.get("is_corpse", false)
	var is_dead: bool = monster["hp"] <= 0 and not is_corpse
	var is_target: bool = (hero_skill_selected and target_type == "single_enemy" and not is_dead and not battle_over
		and (target_positions.is_empty() or (idx + 1) in target_positions))

	# 速度标签（顶部）
	var spd_lbl := Label.new()
	spd_lbl.text = "SPD %d" % (monster["speed"] + monster["speed_delta"])
	spd_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	spd_lbl.add_theme_color_override("font_color", Color(0.75, 0.45, 0.40, 1))
	spd_lbl.add_theme_font_size_override("font_size", 13)
	vbox.add_child(spd_lbl)

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

	# 血条（尸体显示10点生命上限）
	var hp_bar := ProgressBar.new()
	hp_bar.custom_minimum_size = Vector2(100.0, 14.0)
	hp_bar.min_value = 0
	hp_bar.max_value = 10 if is_corpse else monster["max_hp"]
	hp_bar.value = monster["hp"]
	hp_bar.show_percentage = false
	vbox.add_child(hp_bar)

	# HP 数值
	var hp_lbl := Label.new()
	if is_corpse:
		hp_lbl.text = "Corpse: %d/10" % monster["hp"]
	else:
		hp_lbl.text = "%d/%d" % [monster["hp"], monster["max_hp"]]
	hp_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hp_lbl.add_theme_font_size_override("font_size", 11)
	vbox.add_child(hp_lbl)

	# 尸体状态指示器
	if is_corpse:
		var corpse_lbl := Label.new()
		corpse_lbl.text = "☠ CORPSE ☠"
		corpse_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		corpse_lbl.add_theme_font_size_override("font_size", 10)
		corpse_lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6, 1))
		vbox.add_child(corpse_lbl)

	# 选中指示器
	var sel_lbl := Label.new()
	sel_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sel_lbl.add_theme_color_override("font_color", Color(1.0, 0.4, 0.2, 1))
	sel_lbl.text = "▲" if is_current else ""
	vbox.add_child(sel_lbl)

	return slot

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
	_spine_anchors.clear()
	for i in range(heroes.size()):
		if i < hero_slots.size():
			# 使用queue_free删除旧节点（安全，不会在信号处理中导致崩溃）
			_clear_children(hero_slots[i])
			
			# 添加新的内容
			var content := _make_hero_content(heroes[i], i, target_type, target_positions)
			hero_slots[i].add_child(content)

	# 怪物区：从左到右排列 1234（对应 index 0,1,2,3）
	for i in range(monsters.size()):
		if i < monster_slots.size():
			# 使用queue_free删除旧节点（安全，不会在信号处理中导致崩溃）
			_clear_children(monster_slots[i])
			
			# 添加新的内容
			var content := _make_monster_content(monsters[i], i, target_type, target_positions)
			monster_slots[i].add_child(content)

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
		var hero := heroes[current_actor["index"]]
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
		selected_label.text = "Round %d - %s attacking..." % [round_number, monsters[current_actor["index"]]["name"]]

func _clear_children(node: Node) -> void:
	for child in node.get_children():
		child.queue_free()

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
			var offset: Vector2 = fx_config.get("caster_offset", Vector2.ZERO) * _fx_zoom_multiplier
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
					# 受击特效默认偏移至人物躯干中央（Y=-100），而非脚底；自定义 target_offset 可覆盖
					var offset: Vector2 = fx_config.get("target_offset", Vector2(0, -100)) * _fx_zoom_multiplier
					if flip:
						offset.x = - offset.x
					var target_pos = target_sp.global_position + offset
					var scale_mult: float = fx_config.get("target_scale", 1.0)
					
					print("[FX] Playing target_fx at pos=", target_pos, " file=", fx_base, " flip=", flip, " scale_mult=", scale_mult)
					_play_fx_at_position(target_pos, skel, atlas, png_dir, flip, scale_mult)
				else:
					print("[FX] Target SpinePlayer is invalid!")

# 核心底层：在指定屏幕全局坐标处生成并播放 1s 左右的 Spine 特效，随后自行销毁
func _play_fx_at_position(global_pos: Vector2, skel_path: String, atlas_path: String, png_dir: String, flip: bool, scale_multiplier: float = 1.0) -> void:
	print("[FX] _play_fx_at_position: pos=", global_pos, " skel=", skel_path, " atlas=", atlas_path, " png=", png_dir)
	if not FileAccess.file_exists(skel_path) or not FileAccess.file_exists(atlas_path):
		push_warning("[FX] Assets not found: %s or %s" % [skel_path, atlas_path])
		return
		
	var fx_sp := SpinePlayer.new()
	# 特效添加到当前节点
	add_child(fx_sp)
	fx_sp.global_position = global_pos
	fx_sp.z_index = 20 # 盖在普通角色之上
	
	# 保持特效正确的缩放（含攻击放大同步）
	var base_scale: float = 0.5 * scale_multiplier * _fx_zoom_multiplier
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

	# 计算播放时长：放大时与骨骼同步持续 ATTACK_ZOOM_DURATION，否则取动画自然时长（保底 1.0 秒）
	var duration: float = 1.0
	if _fx_zoom_multiplier > 1.0:
		duration = ATTACK_ZOOM_DURATION
	elif fx_sp.current_anim and fx_sp.current_anim.duration > 0.1:
		duration = fx_sp.current_anim.duration
	print("[FX] Duration set to: ", duration)
	
	# 倒计时结束后优雅地删除特效节点
	get_tree().create_timer(duration).timeout.connect(func():
		if is_instance_valid(fx_sp):
			fx_sp.queue_free()
	)

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
# 攻击特效 - 暗黑地牢风格镜头放大效果
# ============================================================

const ATTACK_ZOOM_FACTOR := 2.0 # 攻击时放大倍数
const ATTACK_ZOOM_DURATION := 1.0 # 放大/特效/数字统一持续时间（秒）

# 将指定单位（攻击方或受击方）的 SpinePlayer 放大/恢复
func _zoom_combatant(unit: Dictionary, zoom_in: bool) -> void:
	var info := _get_spine_player_ref_info(unit)
	if info.key == null:
		return
	var sp: SpinePlayer = _spine_players.get(info.key) as SpinePlayer
	if not is_instance_valid(sp):
		return
	
	if zoom_in:
		# 保存原始缩放（保留 x 符号以维持镜像方向）
		unit["_orig_scale_x"] = sp.scale.x
		unit["_orig_scale_y"] = sp.scale.y
		sp.scale = Vector2(sp.scale.x * ATTACK_ZOOM_FACTOR, sp.scale.y * ATTACK_ZOOM_FACTOR)
		# 放大时 z_index 提升以保证不被其他角色遮挡
		unit["_orig_z_index"] = sp.z_index
		sp.z_index = 25
	else:
		if unit.has("_orig_scale_x"):
			sp.scale = Vector2(unit["_orig_scale_x"], unit["_orig_scale_y"])
			unit.erase("_orig_scale_x")
			unit.erase("_orig_scale_y")
		if unit.has("_orig_z_index"):
			sp.z_index = unit["_orig_z_index"]
			unit.erase("_orig_z_index")

# 批量放大/恢复攻击方和所有防御方（含特效同步），自动去重防止自指技能双倍缩放
func _zoom_attack_scene(attacker: Dictionary, defenders: Array[Dictionary], zoom_in: bool) -> void:
	_fx_zoom_multiplier = ATTACK_ZOOM_FACTOR if zoom_in else 1.0
	_zoom_combatant(attacker, zoom_in)
	for d in defenders:
		if not is_same(d, attacker):
			_zoom_combatant(d, zoom_in)

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
	var zoomed := _fx_zoom_multiplier > 1.0
	label.text = "%d" % amount if is_dmg else "+%d" % amount
	label.add_theme_color_override("font_color", Color(1.0, 0.1, 0.1, 1) if is_dmg else Color(0.1, 1.0, 0.2, 1))
	label.add_theme_font_size_override("font_size", 28 if zoomed else 18)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	label.add_theme_constant_override("outline_size", 4)
	
	_floating_text_layer.add_child(label)
	label.global_position = sp.global_position + Vector2(0, -70)
	label.scale = Vector2(1.6, 1.6) if zoomed else Vector2.ONE
	label.pivot_offset = Vector2.ZERO
	
	var end_scale := Vector2(0.8, 0.8) if zoomed else Vector2(0.5, 0.5)
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
	for i in range(targets.size()):
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
	if hero_id == "highwayman":
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
func _load_monster_anim(monster_index: int, state: String) -> void:
	var key = "monster_%d" % monster_index
	if not _spine_players.has(key):
		return
	if _spine_current_state.get(key, "") == state:
		return # 已经是该动画，不需要重新加载
	var sp: SpinePlayer = _spine_players[key]
	var monster_id: String = monsters[monster_index].get("id", "")
	
	var anim_file: String
	var skel_path: String
	var atlas_path: String
	if monster_id == "skeleton_arbalist":
		anim_file = SKELETON_ARBALIST_ANIM_MAP.get(state, "combat")
		skel_path = SKELETON_ARBALIST_ANIM_BASE + anim_file + ".skel"
		atlas_path = SKELETON_ARBALIST_ANIM_BASE + anim_file + ".atlas"
		sp.load_character(skel_path, atlas_path, SKELETON_ARBALIST_PNG_DIR)
		sp.play(anim_file)
	elif monster_id == "skeleton_courtier":
		anim_file = SKELETON_COURTIER_ANIM_MAP.get(state, "combat")
		skel_path = SKELETON_COURTIER_ANIM_BASE + anim_file + ".skel"
		atlas_path = SKELETON_COURTIER_ANIM_BASE + anim_file + ".atlas"
		sp.load_character(skel_path, atlas_path, SKELETON_COURTIER_PNG_DIR)
		sp.play(anim_file)
	elif monster_id == "skeleton_common":
		anim_file = SKELETON_COMMON_ANIM_MAP.get(state, "combat")
		skel_path = SKELETON_COMMON_ANIM_BASE + anim_file + ".skel"
		atlas_path = SKELETON_COMMON_ANIM_BASE + anim_file + ".atlas"
		sp.load_character(skel_path, atlas_path, SKELETON_COMMON_PNG_DIR)
		sp.play(anim_file)
	elif monster_id == "skeleton_defender":
		anim_file = SKELETON_DEFENDER_ANIM_MAP.get(state, "combat")
		skel_path = SKELETON_DEFENDER_ANIM_BASE + anim_file + ".skel"
		atlas_path = SKELETON_DEFENDER_ANIM_BASE + anim_file + ".atlas"
		sp.load_character(skel_path, atlas_path, SKELETON_DEFENDER_PNG_DIR)
		sp.play(anim_file)
	elif monster_id == "skeleton_militia":
		anim_file = SKELETON_MILITIA_ANIM_MAP.get(state, "combat")
		skel_path = SKELETON_MILITIA_ANIM_BASE + anim_file + ".skel"
		atlas_path = SKELETON_MILITIA_ANIM_BASE + anim_file + ".atlas"
		sp.load_character(skel_path, atlas_path, SKELETON_MILITIA_PNG_DIR)
		sp.play(anim_file)
	elif monster_id == "skeleton_spear":
		anim_file = SKELETON_SPEAR_ANIM_MAP.get(state, "combat")
		skel_path = SKELETON_SPEAR_ANIM_BASE + anim_file + ".skel"
		atlas_path = SKELETON_SPEAR_ANIM_BASE + anim_file + ".atlas"
		sp.load_character(skel_path, atlas_path, SKELETON_SPEAR_PNG_DIR)
		sp.play(anim_file)
	elif monster_id == "cutthroat":
		anim_file = CUTTHROAT_ANIM_MAP.get(state, "combat")
		skel_path = CUTTHROAT_ANIM_BASE + anim_file + ".skel"
		atlas_path = CUTTHROAT_ANIM_BASE + anim_file + ".atlas"
		sp.load_character(skel_path, atlas_path, CUTTHROAT_PNG_DIR)
		sp.play(anim_file)
	else:
		push_warning("[Monster] Unknown monster_id '%s'" % monster_id)
		return
	_spine_current_state[key] = state


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
			_load_monster_anim(i, "dead") # 尸体播放 dead 动画
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

func _create_inspire_button_and_ui() -> void:
	# 1. 在 PanelHero 动态追加 Inspire 按钮
	var panel_hero = get_node_or_null("BattleUI/BattleContainer/LeftArea/BottomLeftPanel/BottomPanelsContainer/PanelHero")
	if panel_hero:
		inspire_button = Button.new()
		inspire_button.text = "Inspire"
		inspire_button.tooltip_text = "用语言激励当前行动英雄，减少其30压力（消耗本轮行动）"
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
		reply_panel.custom_minimum_size = Vector2(580, 180)
		reply_panel.anchors_preset = 5 # 顶部居中
		reply_panel.anchor_left = 0.5
		reply_panel.anchor_top = 0.15 # 偏上
		reply_panel.anchor_right = 0.5
		reply_panel.anchor_bottom = 0.15
		reply_panel.offset_left = -290
		reply_panel.offset_top = 0
		reply_panel.offset_right = 290
		reply_panel.offset_bottom = 180
		
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

func _on_inspire_pressed() -> void:
	if battle_over or current_actor.is_empty() or current_actor["unit_type"] != "hero":
		return
	
	var hero = heroes[current_actor["index"]]
	if hero["hp"] <= 0:
		return
		
	# 唤醒 Modal 遮罩
	if inspire_modal and inspire_label and inspire_input:
		inspire_label.text = "对 【%s】 喊些什么来激励他吧（可消除其30点精神压力）：" % hero["name"]
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
		
	# 2. 播放战吼激励动画（播施法特效，播角色 battle_cry 的，也就是 heal 治疗姿态，代表神圣震撼）
	_load_hero_anim(hero_idx, "heal")
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
	var sentiment: int = result.get("sentiment", LLMClient.Sentiment.NEUTRAL)
	print("[LLM] Received reply: ", reply_str, " sentiment: ", sentiment)
	
	# 根据情感极性施加不同的精神压力效果
	var stress_delta: int
	var status_text: String
	match sentiment:
		LLMClient.Sentiment.POSITIVE:
			stress_delta = -35
			status_text = "★ 振奋鼓舞：精神压力从 %d 降至 %d！（正面回应）★"
		LLMClient.Sentiment.NEUTRAL:
			stress_delta = -15
			status_text = "◇ 平淡接受：精神压力从 %d 降至 %d（中性回应）◇"
		LLMClient.Sentiment.NEGATIVE:
			stress_delta = 15
			status_text = "☠ 动摇恐惧：精神压力从 %d 升至 %d！（负面回应）☠"
		_:
			stress_delta = -15
			status_text = "◇ 精神压力从 %d 调整为 %d ◇"
	
	hero["stress"] = clamp(old_stress + stress_delta, 0, 200)
	
	# 根据情感极性显示对应的压力光环图标
	if sentiment == LLMClient.Sentiment.POSITIVE:
		_show_stress_seal(hero, true) # heroic 图标
	elif sentiment == LLMClient.Sentiment.NEGATIVE:
		_show_stress_seal(hero, false) # affliction 图标
	
	# 播放 target_fx 特效（正面/中性播放神光，负面播放暗影）
	if SKILL_FX_MAP.has("battle_cry") and SKILL_FX_MAP["battle_cry"].has("target_fx"):
		var target_fx_base = SKILL_FX_MAP["battle_cry"]["target_fx"]
		var target_skel = target_fx_base + ".skel"
		var target_atlas = target_fx_base + ".atlas"
		var target_png_dir = target_fx_base.get_base_dir()
		var sp = _spine_players.get(hero_idx)
		if is_instance_valid(sp):
			var flip = sp.scale.x < 0
			var target_pos = sp.global_position + Vector2(0, -80)
			_play_fx_at_position(target_pos, target_skel, target_atlas, target_png_dir, flip, 0.8)
			
	# 6. 将终极台词在全屏顶部大字面板显示，持续停留 2.5s 
	if reply_modal and reply_title_lbl and reply_text_lbl and reply_status_lbl:
		reply_title_lbl.text = "【%s】回应了领主的指引：" % hero["name"]
		reply_text_lbl.text = reply_str
		reply_status_lbl.text = status_text % [old_stress, hero["stress"]]
		
	# 刷新血量及压力条本身，让效果落地
	_update_ui()
	
	# 停留 2.5 秒后自行散去，恢复角色正常 idle
	await get_tree().create_timer(2.5).timeout
	
	if reply_modal:
		reply_modal.visible = false
		
	_is_requesting_llm = false
	_in_fx_pause = false
	_load_hero_anim(hero_idx, "idle")
	_update_ui()
	
	# 8. 消耗当前角色的行动阶段，并推进到下一阶段
	heroes[hero_idx]["actions_remaining"] -= 1
	await _get_next_actor()
