extends SceneTree

# 截图 + 布局自检：开始界面的「LLM 设置」面板（首次启动引导形态）
# 运行（**必须非 headless**）：godot --path <项目> --script res://tools/_shot_llm_panel.gd
# 产物：res://shot_llm_panel.png
# 关注点：面板内容是否超高（VBox 的 combined_minimum_size 必须 ≤ 面板可用高度）

const DESIGN := Vector2(1920.0, 1080.0)

var _start: Node = null
var _frame := 0
var _stage := 0


func _initialize() -> void:
	var packed := load("res://scenes/start/Start.tscn") as PackedScene
	_start = packed.instantiate()
	root.add_child(_start)
	root.size = Vector2i(1280, 720)


func _process(_delta: float) -> bool:
	_frame += 1
	if _start == null:
		quit(1)
		return true

	if _frame == 3:
		_start.call("_dismiss_splash")
		return false

	if _stage == 0 and _frame >= 8:
		_start.call("_open_llm_panel", true)
		_stage = 1
		return false

	if _stage == 1 and _frame >= 16:
		_stage = 2
		_report()
		_save("res://shot_llm_panel.png")
		quit(0)
		return true
	return false


func _report() -> void:
	var panel: Variant = _start.get("_llm_panel")
	if panel == null or not is_instance_valid(panel):
		print("[SHOT] _llm_panel 未创建！")
		return
	var mask := panel as Control
	print("[SHOT] mask rect=", str(mask.get_global_rect()))
	var frame := mask.get_node_or_null("LlmFrame") as Control
	if frame == null:
		print("[SHOT] LlmFrame MISSING")
		return
	print("[SHOT] frame pos=", str(frame.position), " size=", str(frame.size))
	if frame.position.x < 0.0 or frame.position.y < 0.0 or frame.position.x + frame.size.x > DESIGN.x or frame.position.y + frame.size.y > DESIGN.y:
		print("[SHOT] !! 面板超出设计页面")
	var box := frame.get_child(0) as Control
	if box == null:
		print("[SHOT] LlmFrame 无内容节点")
		return
	var need: Vector2 = box.get_combined_minimum_size()
	var slack: float = frame.size.y - 52.0 - need.y # 52 = StyleBoxFlat content margin 26×2
	print("[SHOT] 内容最小高度=", need.y, " 面板可用高度=", frame.size.y - 52.0, " 余量=", slack)
	if slack < 0.0:
		print("[SHOT] !! 内容超高，会溢出面板")
	print("[SHOT] 按钮数=", (box.get_child(box.get_child_count() - 1) as Control).get_child_count())
	var key_edit: Variant = _start.get("_llm_key_edit")
	if key_edit != null and is_instance_valid(key_edit):
		print("[SHOT] Key 输入框 secret=", (key_edit as LineEdit).secret)
	var status: Variant = _start.get("_llm_status")
	if status != null and is_instance_valid(status):
		print("[SHOT] 状态文字=", (status as Label).text)


func _save(path: String) -> void:
	var img := root.get_texture().get_image()
	if img == null:
		print("[SHOT] 无法取得视口图像")
		return
	img.save_png(path)
	print("[SHOT] saved ", path, " size=", img.get_size())
