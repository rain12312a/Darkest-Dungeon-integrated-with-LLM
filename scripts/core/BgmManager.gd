extends Node

# ============================================================
# 背景音乐管理器（Autoload 单例：Bgm）
#
# 曲目来源：从游戏自带的 FMOD 音效库 res://audio/secondary_banks/music.bank
# 中提取的 .ogg（提取工具见 tools/extract_fmod_bank.py，FADPCM 解码）。
#
# 设计：
#   · 两个 AudioStreamPlayer 做交叉淡入淡出（避免切场景时音乐硬切）
#   · 支持“前奏 + 循环”两段式编排（暗黑地牢原版战斗/标题音乐就是 intro→loop）
#   · Autoload 挂在场景树根上，因此 `change_scene_to_file` 换场景不会中断音乐
#
# 用法：Bgm.play("title") / Bgm.play("map") / Bgm.play("battle") / Bgm.stop()
# ============================================================

const BGM_DIR := "res://audio/bgm/"

# 曲目表：intro 只播一次，loop 循环播放（intro 为空则直接循环 loop）
const CUES := {
	"title": {
		"intro": "mus_theme_intro_v2.ogg",
		"loop": "mus_theme_loop.ogg",
		"volume_db": - 8.0,
	},
	"map": {
		"intro": "",
		"loop": "Explore_Vaults_Level_1_Loop.ogg",
		"volume_db": - 10.0,
	},
	"battle": {
		"intro": "Combat_Level1_Intro.ogg",
		"loop": "Combat_Level1_Loop1.ogg",
		"volume_db": - 9.0,
	},
}

const FADE_TIME := 0.8 # 交叉淡入淡出时长（秒）

var _players: Array[AudioStreamPlayer] = []
var _active := 0
var _current_cue := ""
var _fade_tween: Tween = null
var _awaiting_intro := false

func _ready() -> void:
	# 作为 Autoload 常驻；暂停游戏（get_tree().paused）时音乐照常播放
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in range(2):
		var p := AudioStreamPlayer.new()
		p.name = "BgmPlayer%d" % i
		p.bus = "Master"
		p.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(p)
		p.finished.connect(_on_player_finished.bind(i))
		_players.append(p)
	# 允许通过 --headless / 单元测试环境静默运行
	set_process(false)

# ------------------------------------------------------------ 播放控制

# 切换曲目；同曲目重复调用不会重头播放
func play(cue_id: String, fade_time: float = FADE_TIME) -> void:
	if not CUES.has(cue_id):
		push_warning("[Bgm] 未知曲目：%s" % cue_id)
		return
	if cue_id == _current_cue:
		return
	_current_cue = cue_id
	_awaiting_intro = false

	var cue: Dictionary = CUES[cue_id]
	var loop_stream: AudioStream = _load_stream(str(cue.get("loop", "")), true)
	var intro_stream: AudioStream = _load_stream(str(cue.get("intro", "")), false)
	if loop_stream == null and intro_stream == null:
		push_warning("[Bgm] 曲目 %s 没有可用音频文件" % cue_id)
		return

	var next := 1 - _active
	var player: AudioStreamPlayer = _players[next]
	player.volume_db = float(cue.get("volume_db", 0.0))

	if intro_stream != null:
		# 先播前奏，播完由 _on_player_finished 接到循环段
		_awaiting_intro = true
		player.stream = intro_stream
	else:
		player.stream = loop_stream
	player.play()

	# 交叉淡入淡出：新曲目淡入、旧曲目淡出后停掉
	if _fade_tween != null and _fade_tween.is_valid():
		_fade_tween.kill()
	var old: AudioStreamPlayer = _players[_active]
	var target_fade: float = maxf(fade_time, 0.01)
	player.volume_db = float(cue.get("volume_db", 0.0)) - 40.0
	_fade_tween = create_tween().set_parallel(true)
	_fade_tween.tween_property(player, "volume_db", float(cue.get("volume_db", 0.0)), target_fade)
	if old.playing:
		_fade_tween.tween_property(old, "volume_db", -60.0, target_fade)
		_fade_tween.chain().tween_callback(old.stop)
	_active = next

func stop(fade_time: float = FADE_TIME) -> void:
	_current_cue = ""
	_awaiting_intro = false
	var cur: AudioStreamPlayer = _players[_active]
	if not cur.playing:
		return
	if _fade_tween != null and _fade_tween.is_valid():
		_fade_tween.kill()
	var target_fade: float = maxf(fade_time, 0.01)
	_fade_tween = create_tween()
	_fade_tween.tween_property(cur, "volume_db", -60.0, target_fade)
	_fade_tween.tween_callback(cur.stop)

func current_cue() -> String:
	return _current_cue

func is_playing() -> bool:
	for p in _players:
		if p.playing:
			return true
	return false

# ------------------------------------------------------------ 内部

# 前奏播完 → 无缝接到循环段
func _on_player_finished(index: int) -> void:
	if not _awaiting_intro or index != _active:
		return
	var cue: Dictionary = CUES.get(_current_cue, {})
	var loop_stream: AudioStream = _load_stream(str(cue.get("loop", "")), true)
	if loop_stream == null:
		_awaiting_intro = false
		return
	_awaiting_intro = false
	var player: AudioStreamPlayer = _players[index]
	player.stream = loop_stream
	player.play()

func _load_stream(file_name: String, looping: bool) -> AudioStream:
	if file_name.is_empty():
		return null
	var path := BGM_DIR + file_name
	if not ResourceLoader.exists(path):
		push_warning("[Bgm] 找不到音频：%s" % path)
		return null
	var stream: AudioStream = load(path)
	if stream == null:
		return null
	# OGG 的循环开关可以在运行时设置，无需改导入参数
	if stream is AudioStreamOggVorbis:
		var ogg := stream as AudioStreamOggVorbis
		ogg.loop = looping
	elif stream is AudioStreamWAV:
		var wav := stream as AudioStreamWAV
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD if looping else AudioStreamWAV.LOOP_DISABLED
	return stream
