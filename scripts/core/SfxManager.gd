extends Node

# ============================================================
# 音效管理器（Autoload 单例：Sfx）
#
# 素材来源：从游戏自带的 FMOD 音效库（res://audio/secondary_banks/hero_*.bank、
# en_crypts.bank、en_shared.bank）中提取出来的 .ogg。提取工具见
# tools/extract_fmod_bank.py（FSB5-Vorbis → Ogg 重封装，不重新编码）。
#
# 目录约定：
#   res://audio/sfx/        英雄技能音效 char_al_* + 通用命中层 char_share_imp_*
#   res://audio/sfx/enemy/  怪物技能音效 char_en_skl* / char_en_brig*
#
# 设计要点：
#   · 固定大小的 AudioStreamPlayer 池 —— 同一帧叠多个音效不会互相打断
#     （AoE 一次打 4 个目标、施法音与命中音重叠都需要这个）
#   · 声音表用「技能 id」索引，与 BattleController.SKILL_FX_MAP 的键一一对应，
#     新增技能时只需在 SKILL_FX_MAP 与本文件各加一条
#   · 每次播放带轻微随机音高，重复出招不会听起来像复读机
#   · 库文件缺失时静默跳过（返回 false），方便素材逐步补齐
#
# 用法：
#   Sfx.play_skill_cast("crusader", "slash")   # 施法音
#   Sfx.play_impact("sword")                   # 命中音（叠在施法音之后）
#   Sfx.play_skill_miss("pistol_shot")         # 挥空音
#   Sfx.play("char_al_hnd_howl", -6.0)         # 直接按文件名播放
# ============================================================

const SFX_DIR := "res://audio/sfx/"
const ENEMY_DIR := "res://audio/sfx/enemy/"
const UI_DIR := "res://audio/sfx/ui/"

# 文件名前缀 → 子目录（不带前缀的音效放在 audio/sfx/ 根目录）
const SUB_DIRS := {
	"enemy/": ENEMY_DIR,
	"ui/": UI_DIR,
}

const POOL_SIZE := 12 # 播放器池大小（同时发声上限）
const CAST_DB := -9.0 # 施法音默认音量
const IMPACT_DB := -12.0 # 命中音默认音量（压低，避免盖过施法音）
const PITCH_JITTER := 0.04 # 音高随机浮动 ±4%
const VOLUME_JITTER := 1.5 # 音量随机浮动 ±1.5dB

# 激励喊话音：四个英雄都能用喊话，但只有十字军有 battle_cry 素材，
# 因此统一用这声战吼代表“领主发出训示”（它本来就是喊话性质的声音）。
const INSPIRE_SFX := "char_al_cru_inspiringcry"

# --- 英雄技能 → 施法音效 ---
# hero_id → skill_id → 文件名（不带目录与扩展名）
const HERO_SKILL_SFX := {
	"crusader": {
		"slash": "char_al_cru_smite",
		"heal": "char_al_cru_battleheal",
		"holy spear": "char_al_cry_holylance",
		"battle_cry": "char_al_cru_inspiringcry",
	},
	"highwayman": {
		"cut": "char_al_hwy_wickedslice",
		"pistol_shot": "char_al_hwy_pistolshot",
		"Close-range shooting": "char_al_hwy_pointblank",
		"shotgun": "char_al_hwy_grapeshot",
	},
	"occultist": {
		"命运重构": "char_al_occ_wyrdrecon",
		"祭祀切割": "char_al_occ_bloodlet",
		"深渊之手": "char_al_occ_daemons",
		"灵魂之触": "char_al_occ_abyssalart",
	},
	"houndmaster": {
		"释放猎犬": "char_al_hnd_hounds_rush",
		"标记弱点": "char_al_hnd_whistle",
		"振奋犬吠": "char_al_hnd_howl",
		"守护队友": "char_al_hnd_guard_dog",
	},
}

# --- 英雄技能 → 挥空（_miss）音效：只登记实际存在该素材的技能 ---
const HERO_SKILL_MISS_SFX := {
	"slash": "char_al_cru_smite_miss",
	"battle_cry": "char_al_cru_inspiringcry_miss",
	"pistol_shot": "char_al_hwy_pistolshot_miss",
	"shotgun": "char_al_hwy_grapeshot_miss",
	"命运重构": "char_al_occ_wyrdrecon_miss",
	"深渊之手": "char_al_occ_daemons_miss",
	"灵魂之触": "char_al_occ_abyssalart_miss",
	"释放猎犬": "char_al_hnd_hounds_rush_miss",
	"标记弱点": "char_al_hnd_whistle_miss",
	"振奋犬吠": "char_al_hnd_howl_miss",
}

# --- 怪物技能 → 施法音效 ---
# 键为技能 id（与 SKILL_FX_MAP 一致）；"enemy/" 前缀表示去 audio/sfx/enemy/ 找
const MONSTER_SKILL_SFX := {
	# 强盗刀手
	"cutthroat_strike": "enemy/char_en_brigcut_banditstab",
	"temptation": "enemy/char_en_sklco_temptinggob",
	# 骷髅系
	"arbalist_crossbow": "enemy/char_en_sklar_crossbowshot",
	"arbalist_bayonet": "enemy/char_en_sklar_bayonet_jab",
	"courtier_goblet": "enemy/char_en_sklco_temptinggob",
	"courtier_dagger": "enemy/char_en_sklco_daggerjab",
	"skeleton_melee": "enemy/char_en_sklcom_cudgel",
	"defender_axe": "enemy/char_en_sklde_axestrike",
	"defender_shield": "enemy/char_en_sklde_shieldbash",
	"militia_slash": "enemy/char_en_sklmi_swordstrike",
	"militia_ranged": "enemy/char_en_sklmi_swordstrike", # 该怪无专用远程素材，复用挥砍
	"spear_thrust": "enemy/char_en_sklsp_spearthrust",
	"spear_pierce": "enemy/char_en_sklsp_impale",
	# 门前恶狼 BOSS 战（火器小队）
	# 投弹 / 炮击这类没有专用素材的技能，复用点火员的火器与哨声（近义素材，好过静音）
	"sapper_throw": "enemy/char_en_brigfus_pickpocket",
	"sapper_summon": "char_al_hnd_whistle",
	"sapper_barrage": "enemy/char_en_brigfus_blunderbuuss",
	"cannon_fire": "enemy/char_en_brigfus_blunderbuuss",
	"cannon_summon": "char_al_hnd_whistle",
	"cannon_blast": "enemy/char_en_brigfus_blunderbuuss",
	"fuseman_light_fuse": "enemy/char_en_brigfus_pickpocket",
	"fuseman_hot_shot": "enemy/char_en_brigfus_blunderbuuss",
}

# --- 怪物技能 → 挥空音效 ---
const MONSTER_SKILL_MISS_SFX := {
	"cutthroat_strike": "enemy/char_en_brigcut_doubleslice_miss",
	"arbalist_crossbow": "enemy/char_en_sklar_crossbowshot_miss",
	"courtier_goblet": "enemy/char_en_sklco_temptinggob_miss",
	"skeleton_melee": "enemy/char_en_sklcom_cudgel_miss",
	"defender_shield": "enemy/char_en_sklde_shieldbash_miss",
	"spear_pierce": "enemy/char_en_sklsp_impale_miss",
}

# --- 通用命中层：武器类型 → 打击反馈音 ---
# 这些是"打中了"的统一质感层，与施法音叠在一起播放
const IMPACT_SFX := {
	"sword": "char_share_imp_sword",
	"axe": "char_share_imp_axe",
	"hammer": "char_share_imp_hammer",
	"knife": "char_share_imp_knife",
	"shield": "char_share_imp_shield",
	"gun": "char_share_imp_gun",
	"arrow": "char_share_imp_arrow",
	"magic_light": "char_share_imp_magic_light",
	"magic_dark": "char_share_imp_magic_dark",
	"heavy": "sfx_org_imp_03_heavy_sweetener", # 通用重击甜化层（爆桶等大型打击）
}

# --- 技能 → 命中层类型（空串表示该技能没有打击环节，如治疗/增益） ---
const SKILL_IMPACT := {
	# 英雄
	"slash": "sword",
	"holy spear": "sword",
	"shotgun": "gun",
	"cut": "sword",
	"Close-range shooting": "gun",
	"pistol_shot": "gun",
	"命运重构": "magic_dark",
	"祭祀切割": "knife",
	"深渊之手": "magic_dark",
	"灵魂之触": "magic_dark",
	"释放猎犬": "knife",
	# 怪物
	"cutthroat_strike": "knife",
	"temptation": "magic_dark",
	"arbalist_crossbow": "arrow",
	"arbalist_bayonet": "knife",
	"courtier_goblet": "magic_dark",
	"courtier_dagger": "knife",
	"skeleton_melee": "hammer",
	"defender_axe": "axe",
	"defender_shield": "shield",
	"militia_slash": "sword",
	"militia_ranged": "arrow",
	"spear_thrust": "knife",
	"spear_pierce": "knife",
	"sapper_throw": "hammer",
	"sapper_barrage": "gun",
	"cannon_fire": "gun",
	"cannon_blast": "gun",
	"fuseman_hot_shot": "gun",
}

# --- UI 音效（弹窗 / 按钮） ---
const UI_SFX := {
	"victory": "ui/ui_dun_loot_popup_battle", # 战斗结算弹出（胜利仪式感）
	"reward": "ui/ui_dun_loot_popup_chest", # 战利品入手
	"window": "ui/ui_shr_window_popup", # 通用窗口弹出
	"continue": "ui/ui_dun_comnext", # 继续深入
	"click": "ui/ui_shr_button_click", # 普通按钮
}

# --- 内部状态 ---
var _players: Array[AudioStreamPlayer] = []
var _next := 0
var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	# 与 Bgm 一致：暂停游戏时音效照常播放
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rng.randomize()
	for i in range(POOL_SIZE):
		var p := AudioStreamPlayer.new()
		p.name = "SfxPlayer%d" % i
		p.bus = "Master"
		p.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(p)
		_players.append(p)

# ------------------------------------------------------------ 对外接口

# 按文件名播放（name 可带 "enemy/" / "ui/" 前缀指定子目录）
# 返回是否真的播出去了（文件缺失 / 流加载失败 → false）
func play(file_name: String, volume_db: float = CAST_DB, pitch_scale: float = 1.0) -> bool:
	if file_name.is_empty():
		return false
	var dir := SFX_DIR
	var file := file_name
	for prefix in SUB_DIRS.keys():
		var p := str(prefix)
		if file_name.begins_with(p):
			dir = str(SUB_DIRS[p])
			file = file_name.substr(p.length())
			break
	var stream: AudioStream = _load_stream(dir, file)
	if stream == null:
		return false
	var p := _take_player()
	p.stream = stream
	p.volume_db = volume_db + _rng.randf_range(-VOLUME_JITTER, VOLUME_JITTER)
	p.pitch_scale = clampf(pitch_scale * _rng.randf_range(1.0 - PITCH_JITTER, 1.0 + PITCH_JITTER), 0.1, 4.0)
	p.play()
	return true

# 播放 UI 音效（key 见 UI_SFX）
func play_ui(key: String, volume_db: float = -8.0, pitch_scale: float = 1.0) -> bool:
	return play(str(UI_SFX.get(key, "")), volume_db, pitch_scale)

# 播放英雄技能施法音；caster_id 为英雄 id（crusader / highwayman / …）
func play_hero_cast(hero_id: String, skill_id: String, volume_db: float = CAST_DB) -> bool:
	var table: Dictionary = HERO_SKILL_SFX.get(hero_id, {})
	return play(str(table.get(skill_id, "")), volume_db)

# 播放怪物技能施法音（按技能 id 索引，与怪物无关）
func play_monster_cast(skill_id: String, volume_db: float = CAST_DB) -> bool:
	return play(str(MONSTER_SKILL_SFX.get(skill_id, "")), volume_db)

# 统一入口：按技能 id 找施法音，先查英雄表（需要 hero_id），再查怪物表
func play_skill_cast(skill_id: String, hero_id: String = "", volume_db: float = CAST_DB) -> bool:
	if not hero_id.is_empty() and play_hero_cast(hero_id, skill_id, volume_db):
		return true
	return play_monster_cast(skill_id, volume_db)

# 播放挥空音；返回 false 表示该技能没有挥空素材
# 技能 id 在整个项目里唯一（英雄技能与怪物技能不重名），因此无需再按英雄二次定位
func play_skill_miss(skill_id: String) -> bool:
	var file := str(HERO_SKILL_MISS_SFX.get(skill_id, ""))
	if file.is_empty():
		file = str(MONSTER_SKILL_MISS_SFX.get(skill_id, ""))
	return play(file, IMPACT_DB - 1.0)

# 播放命中层（kind 见 IMPACT_SFX）
func play_impact(kind: String, volume_db: float = IMPACT_DB) -> bool:
	return play(str(IMPACT_SFX.get(kind, "")), volume_db)

# 按技能 id 播放命中层；无打击环节的技能不发声
func play_skill_impact(skill_id: String, volume_db: float = IMPACT_DB) -> bool:
	var kind := str(SKILL_IMPACT.get(skill_id, ""))
	if kind.is_empty():
		return false
	return play_impact(kind, volume_db)

# 该技能是否配了挥空素材
func has_miss_sound(skill_id: String) -> bool:
	if HERO_SKILL_MISS_SFX.has(skill_id):
		return true
	return MONSTER_SKILL_MISS_SFX.has(skill_id)

# 该技能是否配了施法音（hero_id 留空 → 只查怪物表）
func has_cast_sound(skill_id: String, hero_id: String = "") -> bool:
	if not hero_id.is_empty() and (HERO_SKILL_SFX.get(hero_id, {}) as Dictionary).has(skill_id):
		return true
	return MONSTER_SKILL_SFX.has(skill_id)

# 该技能是否有打击环节（无打击环节 = 治疗/增益类）
func has_impact_sound(skill_id: String) -> bool:
	return not str(SKILL_IMPACT.get(skill_id, "")).is_empty()

func stop_all() -> void:
	for p in _players:
		if p.playing:
			p.stop()

# ------------------------------------------------------------ 内部

# 轮转取播放器：池满时覆盖最旧的一个（旧音自然被打断，好过排队延迟）
func _take_player() -> AudioStreamPlayer:
	var p := _players[_next]
	_next = (_next + 1) % _players.size()
	return p

func _load_stream(dir: String, file: String) -> AudioStream:
	var path := dir + file + ".ogg"
	if not ResourceLoader.exists(path):
		return null
	var stream: AudioStream = load(path)
	if stream is AudioStreamOggVorbis:
		# 音效一律不循环（BGM 才循环）
		(stream as AudioStreamOggVorbis).loop = false
	return stream
