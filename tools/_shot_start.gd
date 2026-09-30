extends SceneTree

# 临时截图脚本（人工核对开始界面用，非游戏运行时代码）
# 运行：godot --path <项目> --script res://tools/_shot_start.gd
# 产物：res://shot_start_splash.png（闪屏） / res://shot_start_menu.png（主菜单）

var _start: Node = null
var _frame := 0
var _stage := 0

func _initialize() -> void:
	var packed := load("res://scenes/start/Start.tscn") as PackedScene
	_start = packed.instantiate()
	root.add_child(_start)

func _process(_delta: float) -> bool:
	_frame += 1
	if _start == null:
		quit(1)
		return true
	if _frame == 3:
		_save("res://shot_start_splash.png")
		_start.call("_dismiss_splash")
		_stage = 1
		return false
	if _stage == 1:
		var splash: Variant = _start.get("_splash_layer")
		if splash != null and is_instance_valid(splash):
			return false
		_stage = 2
		return false
	if _stage == 2:
		# 多等几帧让布局/补间稳定后再截图
		if _frame < 12:
			return false
		_report()
		_save("res://shot_start_menu.png")
		quit(0)
		return true
	return false

func _save(path: String) -> void:
	var img := root.get_texture().get_image()
	if img == null:
		print("[SHOT] 无法取得视口图像")
		return
	img.save_png(path)
	print("[SHOT] saved ", path, " size=", img.get_size())

func _report() -> void:
	var design: Control = _start.get("_design_root")
	if design == null:
		return
	for name in ["TitleGlow", "TitleHouse", "SkyFar", "SkyNear", "TitleLogo", "StartButton"]:
		var node := design.get_node_or_null(name) as Control
		if node == null:
			print("[SHOT] ", name, " MISSING")
		else:
			print("[SHOT] ", name, " rect=", str(node.get_global_rect()), " visible=", str(node.visible))
	var hint: Label = _start.get("_size_hint_label")
	if hint != null:
		print("[SHOT] size hint = ", hint.text)
	print("[SHOT] design scale=", str(design.scale), " pos=", str(design.position))
