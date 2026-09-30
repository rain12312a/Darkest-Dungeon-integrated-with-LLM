extends SceneTree

# 临时探针脚本（端到端验证用，非游戏运行时代码）
# 用途：验证背景音乐管理器（Autoload `Bgm`）
#   ① Autoload 存在、曲目表中的音频都能加载（ogg / 循环标志 / 时长）
#   ② play() 先播前奏 → 前奏结束自动接循环段
#   ③ 切曲目做交叉淡入淡出、同曲目重复调用不重头播
#   ④ 场景接入：Start.tscn → title；点 START 进地图 → map
# 运行：godot --headless --path <项目> --script res://tools/_probe_bgm.gd

const EXPECT_TITLES := {
	"mus_theme_intro_v2.ogg": 18.99,
	"mus_theme_loop.ogg": 12.16,
	"Explore_Vaults_Level_1_Loop.ogg": 128.0,
	"Combat_Level1_Intro.ogg": 3.20,
	"Combat_Level1_Loop1.ogg": 51.20,
}

var _bgm: Node = null
var _pass := 0
var _fail := 0
var _frame := 0

func _initialize() -> void:
	pass

func _process(_delta: float) -> bool:
	_frame += 1
	if _frame < 2:
		return false
	if _frame == 2:
		_test_autoload()
		if _bgm == null:
			print("[BGM] ===== PASS=%d FAIL=%d ====" % [_pass, _fail])
			quit(1)
			return true
		_test_cues()
		_test_play_flow()
		_test_switch()
		_test_scene_hookup_start()
		return false
	if _frame == 4:
		_test_scene_hookup_map()
		print("[BGM] ===== PASS=%d FAIL=%d ====" % [_pass, _fail])
		quit(0 if _fail == 0 else 1)
		return true
	return false

func _expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("[BGM]   PASS  ", label)
	else:
		_fail += 1
		print("[BGM]   FAIL  ", label)

func _test_autoload() -> void:
	print("[BGM] --- ① Autoload ---")
	_bgm = root.get_node_or_null("Bgm")
	_expect(_bgm != null, "project.godot 注册的 Bgm Autoload 已实例化")
	if _bgm == null:
		# 退路：某些 --script 环境不建 Autoload，手动实例化继续验证逻辑
		var script: GDScript = load("res://scripts/core/BgmManager.gd")
		_bgm = script.new()
		_bgm.name = "Bgm"
		root.add_child(_bgm)
		print("[BGM]   （Autoload 缺失，已手动实例化用于验证逻辑）")
	_expect(_bgm.has_method("play") and _bgm.has_method("stop"), "暴露 play()/stop() 接口")
	_expect(_bgm.get("_players").size() == 2, "内部有 2 个播放器用于交叉淡入淡出")

# ------------------------------------------------------------ 曲目资源

func _test_cues() -> void:
	print("[BGM] --- ② 曲目资源 ---")
	var cues: Dictionary = _bgm.get("CUES")
	_expect(cues.size() == 3, "曲目表有 3 个 cue（title/map/battle）")
	for cue_id in cues.keys():
		_expect(cues[cue_id].has("loop"), "%s 定义了 loop 段" % cue_id)
	var checked := 0
	for cue_id in cues.keys():
		var cue: Dictionary = cues[cue_id]
		for key in ["intro", "loop"]:
			var file_name := str(cue.get(key, ""))
			if file_name.is_empty():
				continue
			var path := "res://audio/bgm/" + file_name
			if not ResourceLoader.exists(path):
				_expect(false, "存在音频文件 %s" % file_name)
				continue
			var stream: AudioStream = _bgm.call("_load_stream", file_name, key == "loop")
			_expect(stream is AudioStreamOggVorbis, "%s 是 ogg 格式" % file_name)
			var want_loop: bool = key == "loop"
			_expect((stream as AudioStreamOggVorbis).loop == want_loop,
				"%s 经 _load_stream 加载后循环标志 = %s" % [file_name, want_loop])
			var dur: float = stream.get_length()
			var expect_dur: float = float(EXPECT_TITLES.get(file_name, -1.0))
			if expect_dur > 0.0:
				_expect(absf(dur - expect_dur) < 0.6, "%s 时长 %.2fs ≈ %.2fs" % [file_name, dur, expect_dur])
			checked += 1
	_expect(checked == 5, "曲目表共引用 5 个音频文件（实际 %d）" % checked)

# ------------------------------------------------------------ 播放流程

func _test_play_flow() -> void:
	print("[BGM] --- ③ 前奏 → 循环 ---")
	_bgm.call("play", "title", 0.05)
	_expect(str(_bgm.call("current_cue")) == "title", "current_cue() = title")
	var players: Array = _bgm.get("_players")
	var active: AudioStreamPlayer = players[int(_bgm.get("_active"))]
	_expect(active.playing, "前奏已开始播放")
	_expect(active.stream.resource_path.ends_with("mus_theme_intro_v2.ogg"), "先播的是前奏段")
	_expect(bool(_bgm.get("_awaiting_intro")), "标记为“等待前奏结束”")
	# 模拟前奏播完
	_bgm.call("_on_player_finished", int(_bgm.get("_active")))
	_expect(active.stream.resource_path.ends_with("mus_theme_loop.ogg"), "前奏结束后切到循环段")
	_expect(active.stream.loop, "循环段已开启 loop 标志")
	_expect(active.playing, "循环段继续播放")

func _test_switch() -> void:
	print("[BGM] --- ④ 切曲目 / 交叉淡入淡出 ---")
	var players: Array = _bgm.get("_players")
	var old_active: int = int(_bgm.get("_active"))
	_bgm.call("play", "map", 0.05)
	_expect(str(_bgm.call("current_cue")) == "map", "current_cue() 切到 map")
	_expect(int(_bgm.get("_active")) != old_active, "播放器换到另一个（交叉淡入淡出）")
	var new_player: AudioStreamPlayer = players[int(_bgm.get("_active"))]
	_expect(new_player.playing, "新曲目已开始播放")
	_expect(new_player.stream.resource_path.ends_with("Explore_Vaults_Level_1_Loop.ogg"), "新曲目是地图探索曲")
	_expect(not bool(_bgm.get("_awaiting_intro")), "map 没有前奏，直接循环")
	# 同曲目重复调用不应重头播
	var stream_before: AudioStream = new_player.stream
	_bgm.call("play", "map", 0.05)
	_expect(new_player.stream == stream_before and int(_bgm.get("_active")) == int(_bgm.get("_active")), "重复 play 同曲目不重头播")
	# stop
	_bgm.call("stop", 0.05)
	_expect(str(_bgm.call("current_cue")) == "", "stop() 后 current_cue 为空")

# ------------------------------------------------------------ 场景接入

func _test_scene_hookup_start() -> void:
	print("[BGM] --- ⑤ 场景接入 ---")
	var packed := load("res://scenes/start/Start.tscn") as PackedScene
	_expect(packed != null, "Start.tscn 可加载")
	if packed == null:
		return
	var start: Node = packed.instantiate()
	root.add_child(start) # _ready 同步执行 → 应自动切到 title 曲
	_expect(str(_bgm.call("current_cue")) == "title", "进入开始界面自动播放 title 曲")
	start.call("_dismiss_splash")
	start.call("_on_start_pressed") # 内部会 change_scene_to_file(Map)

func _test_scene_hookup_map() -> void:
	var scene: Node = current_scene
	_expect(scene != null and scene.name == "Map", "已切到地图场景（current_scene=%s）" % (scene.name if scene != null else "null"))
	_expect(str(_bgm.call("current_cue")) == "map", "进入地图后 BGM 切到 map 曲")
	_expect(bool(_bgm.call("is_playing")), "地图探索曲正在播放")
