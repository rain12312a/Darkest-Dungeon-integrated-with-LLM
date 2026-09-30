extends Node

# ============================================================
# 全局显示管理（Autoload 名：Display）
#
# 快捷键：
#   F11        —— 切换全屏 / 窗口
#   Alt+Enter  —— 同上（Windows 惯例）
#   Esc        —— 仅在全屏时退回窗口模式（被 GUI 消费的事件不会走到这里）
#
# 全屏适配方式：project.godot 中启用
#   window/stretch/mode   = "canvas_items"
#   window/stretch/aspect = "keep"
# 即「逻辑分辨率固定 1280×720，全屏时整幅等比放大并居中」。
# 因此所有既有布局（战场底图、地图视口、开始界面 DesignRoot 等）
# 在任意窗口尺寸下都保持与 1280×720 完全一致的相对位置，无需改动；
# 非 16:9 屏幕（如 16:10 / 21:9）多出的部分补黑边。
#
# 若想让程序启动即全屏，把 project.godot 的
#   [display] window/size/mode 设为 3（全屏）或 4（独占全屏）即可。
# ============================================================

func _ready() -> void:
	# 即使游戏被暂停，全屏切换也应可用
	process_mode = Node.PROCESS_MODE_ALWAYS


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return
	var key := event as InputEventKey
	if not key.pressed or key.echo:
		return
	if key.keycode == KEY_F11 or (key.alt_pressed and key.keycode == KEY_ENTER):
		toggle_fullscreen()
		get_viewport().set_input_as_handled()
	elif key.keycode == KEY_ESCAPE and is_fullscreen():
		set_fullscreen(false)
		get_viewport().set_input_as_handled()


func toggle_fullscreen() -> void:
	set_fullscreen(not is_fullscreen())


func is_fullscreen() -> bool:
	var mode := DisplayServer.window_get_mode()
	return mode == DisplayServer.WINDOW_MODE_FULLSCREEN \
		or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN


func set_fullscreen(enabled: bool) -> void:
	if enabled:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
