extends SceneTree

# ============================================================
# 全屏适配验证探针（非 headless，需要真实窗口）
# 运行：godot --path <项目> --script res://tools/_probe_fullscreen.gd
#
# 校验内容：
#   1) 多种窗口尺寸下「逻辑可见区」恒为 1280×720
#      （canvas_items + keep：全屏时整幅等比放大、非 16:9 补黑边）
#   2) 1920×1080 下 BattleUI / BattleContainer 仍完整覆盖逻辑画布
#   3) 开始界面 DesignRoot 仍按 min(宽,高) 比例居中缩放
#   4) 真实全屏可通过 F11 切换，且全屏后逻辑区不变
#   5) 产出截图 shot_fullscreen_*.png 供人工核对（核对完即可删除，不入库）
# ============================================================

const BASE_SIZE := Vector2(1280.0, 720.0)
const SHOT_SIZE := Vector2i(1920, 1080)
const WINDOW_SIZES: Array[Vector2i] = [
	Vector2i(1280, 720),
	Vector2i(1920, 1080),
	Vector2i(1280, 800), # 16:10：应上下补黑边，逻辑区仍 1280×720
	Vector2i(1600, 900),
]

var _checks := 0
var _fails := 0
var _frame := 0
var _idx := 0
var _settle := 0
var _phase := "resize"
var _wait := 0
var _battle: Node = null
var _start: Node = null


func _initialize() -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	print("[FULLSCREEN] stretch mode=", ProjectSettings.get_setting("display/window/stretch/mode"),
		" aspect=", ProjectSettings.get_setting("display/window/stretch/aspect"))
	var screen := DisplayServer.screen_get_size()
	print("[FULLSCREEN] 屏幕尺寸=", screen, " 起始窗口=", DisplayServer.window_get_size(),
		" 逻辑可见区=", root.get_visible_rect().size)


func _process(_delta: float) -> bool:
	_frame += 1
	if _frame < 6:
		return false
	match _phase:
		"resize":
			_resize_phase()
		"battle":
			_battle_phase()
		"start":
			_start_phase()
		"fullscreen":
			_fullscreen_phase()
		"done":
			return _finish()
	return false


# ------------------------------------------------------------ 阶段 1：多尺寸逻辑区校验
func _resize_phase() -> void:
	if _settle > 0:
		_settle -= 1
		if _settle == 0:
			_measure()
		return
	if _idx < WINDOW_SIZES.size():
		var want: Vector2i = WINDOW_SIZES[_idx]
		var screen := DisplayServer.screen_get_size()
		# 不超过屏幕，避免窗口被系统裁切后尺寸对不上
		want.x = mini(want.x, maxi(screen.x - 40, 320))
		want.y = mini(want.y, maxi(screen.y - 80, 240))
		DisplayServer.window_set_size(want)
		_idx += 1
		_settle = 4
		return
	_phase = "battle"
	_wait = 0


func _measure() -> void:
	var win := DisplayServer.window_get_size()
	var visible := root.get_visible_rect()
	print("[FULLSCREEN] 窗口=", win, " → 逻辑可见区=", visible.size)
	_check("逻辑可见区恒为 1280×720（窗口 " + str(win) + "）",
		visible.size.is_equal_approx(BASE_SIZE))
	_check("逻辑区原点在 (0,0)（窗口 " + str(win) + "）",
		visible.position.is_equal_approx(Vector2.ZERO))


# ------------------------------------------------------------ 阶段 2：战斗场景（最敏感）
func _battle_phase() -> void:
	if _battle == null:
		DisplayServer.window_set_size(SHOT_SIZE)
		MonsterConfig.CURRENT_ENCOUNTER = ["brigand_sapper", "brigand_barrel", "brigand_fuseman", "brigand_cannon"]
		HeroConfig.reset_party_state()
		var packed := load("res://scenes/battle/Battle.tscn") as PackedScene
		_battle = packed.instantiate()
		root.add_child(_battle)
		_wait = 0
		return
	_wait += 1
	if _wait == 3:
		_battle.set("battle_over", true) # 冻结自动战斗，避免截图时数值变化
		return
	if _wait < 30:
		return

	var ui := _battle.get_node_or_null("BattleUI") as Control
	_check("BattleUI 存在", ui != null)
	if ui != null:
		var rect := ui.get_global_rect()
		print("[FULLSCREEN] BattleUI rect=", rect)
		_check("BattleUI 覆盖逻辑画布", rect.position.is_equal_approx(Vector2.ZERO)
			and rect.size.is_equal_approx(BASE_SIZE))
	_save("res://shot_fullscreen_battle.png")
	_battle.queue_free()
	_battle = null
	_phase = "start"
	_wait = 0


# ------------------------------------------------------------ 阶段 3：开始界面
func _start_phase() -> void:
	if _start == null:
		var packed := load("res://scenes/start/Start.tscn") as PackedScene
		_start = packed.instantiate()
		root.add_child(_start)
		_wait = 0
		return
	_wait += 1
	if _wait == 3:
		_start.call("_dismiss_splash")
		return
	if _wait < 40:
		return

	var design := _start.get("_design_root") as Control
	_check("DesignRoot 存在", design != null)
	if design != null:
		var expect := minf(BASE_SIZE.x / 1920.0, BASE_SIZE.y / 1080.0)
		print("[FULLSCREEN] DesignRoot scale=", design.scale, " 期望=", expect,
			" position=", design.position)
		_check("DesignRoot 按逻辑区等比缩放",
			absf(design.scale.x - expect) < 0.01 and absf(design.scale.y - expect) < 0.01)
		_check("DesignRoot 在逻辑区内居中",
			design.position.is_equal_approx((BASE_SIZE - Vector2(1920.0, 1080.0) * expect) * 0.5))
	_save("res://shot_fullscreen_start.png")
	_phase = "fullscreen"
	_wait = 0


# ------------------------------------------------------------ 阶段 4：真实全屏 + F11 快捷键
func _fullscreen_phase() -> void:
	_wait += 1
	if _wait == 1:
		var disp := root.get_node_or_null("/root/Display")
		_check("全屏 Autoload(Display) 已注册", disp != null)
		_check("起始为窗口模式", not DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN)
		_press_f11() # 走真实输入链路，验证 F11 绑定
		return
	if _wait < 30:
		return
	if _wait == 30:
		print("[FULLSCREEN] 按下 F11 后窗口模式=", DisplayServer.window_get_mode(),
			" 窗口=", DisplayServer.window_get_size())
		_check("F11 已切换到全屏", DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN)
		_check("全屏下逻辑可见区仍为 1280×720",
			root.get_visible_rect().size.is_equal_approx(BASE_SIZE))
		_save("res://shot_fullscreen_native.png")
		var disp2 := root.get_node_or_null("/root/Display")
		if disp2 != null:
			_check("is_fullscreen() 返回 true", bool(disp2.call("is_fullscreen")))
			disp2.call("set_fullscreen", false)
		return
	if _wait < 45:
		return
	_check("已退回窗口模式", DisplayServer.window_get_mode() != DisplayServer.WINDOW_MODE_FULLSCREEN)
	if _start != null:
		_start.queue_free() # 全屏截图已保存，现在释放开始界面
		_start = null
	_phase = "done"


func _press_f11() -> void:
	var ev := InputEventKey.new()
	ev.keycode = KEY_F11
	ev.physical_keycode = KEY_F11
	ev.pressed = true
	Input.parse_input_event(ev)


# ------------------------------------------------------------ 收尾
func _finish() -> bool:
	DisplayServer.window_set_size(Vector2i(1280, 720))
	print("[FULLSCREEN] ===== PASS=", _checks - _fails, " FAIL=", _fails, " (共 ", _checks, " 条) =====")
	quit(0 if _fails == 0 else 1)
	return true


func _check(label: String, ok: bool) -> void:
	_checks += 1
	if not ok:
		_fails += 1
	print("[FULLSCREEN] ", "PASS " if ok else "FAIL ", label)


func _save(path: String) -> void:
	var img := root.get_texture().get_image()
	if img == null:
		print("[FULLSCREEN] 无法取得视口图像")
		return
	img.save_png(path)
	print("[FULLSCREEN] saved ", path, " size=", img.get_size())
