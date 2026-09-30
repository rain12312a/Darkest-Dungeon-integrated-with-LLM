extends SceneTree

# 临时探针脚本（端到端验证用，非游戏运行时代码）
# 用途：验证地图显示改造——地图内容放在裁剪视口（MapViewport）里，
#      并且当前房间永远被平移到视口正中（换房/改尺寸后依然成立）。
# 运行：godot --headless --path <项目> --script res://tools/_probe_map_center.gd

const MAP_SCENE := "res://scenes/map/Map.tscn"

var _map: Node = null
var _frame := 0
var _pass := 0
var _fail := 0
var _wait := 0.0
var _phase := 0

func _initialize() -> void:
	# headless 下窗口默认可视尺寸很小（视口宽度会算错），先摆成真实 1280x720
	root.size = Vector2i(1280, 720)
	# 用大地图（9x9）验证：网格明显大于视口，必须靠平移才能看全
	DungeonMap.set_size("large")
	DungeonMap.BRANCHINESS = 0.5
	DungeonMap.reset_run()
	var packed := load(MAP_SCENE) as PackedScene
	if packed == null:
		print("[MC] FAILED: cannot load Map.tscn")
		quit(1)
		return
	_map = packed.instantiate()
	root.add_child(_map)

func _process(delta: float) -> bool:
	_frame += 1
	if _map == null:
		quit(1)
		return true

	if _phase == 1:
		_wait += delta
		if _wait < 0.45: # 等补间跑完
			return false
		_check_centered("换房后（补间结束）")
		print("[MC] ===== PASS=%d FAIL=%d =====" % [_pass, _fail])
		quit(0 if _fail == 0 else 1)
		return true

	if _frame >= 3:
		_check_viewport()
		_check_centered("开局")
		_check_map_bigger_than_view()
		_move_to_neighbor()
		_phase = 1
		_wait = 0.0
	return false

# ------------------------------------------------------------ 检查项

func _check_viewport() -> void:
	var vp := _find_by_name(_map, "MapViewport") as Control
	_expect(vp != null, "存在地图视口 MapViewport")
	if vp == null:
		return
	_expect(vp.clip_contents, "视口开启 clip_contents（超出部分裁掉）")
	_expect(vp.size.y > 200.0, "视口高度合理（%.0f px）" % vp.size.y)
	_expect(absf(vp.size.x - float(root.size.x)) <= 1.0, "视口宽度跟随窗口（%.0f vs %d）" % [vp.size.x, root.size.x])
	_expect(vp.global_position.y > 0.0, "视口不与顶部标题/状态文字重叠（top=%.0f）" % vp.global_position.y)
	_expect(vp.get_global_rect().end.y < 720.0 - 100.0, "视口不与底部提示/按钮重叠（bottom=%.0f）" % vp.get_global_rect().end.y)
	var root_node := _find_by_name(_map, "MapRoot")
	_expect(root_node != null and root_node is Node2D, "地图内容挂在可平移的 MapRoot(Node2D) 下")

func _check_centered(label: String) -> void:
	var vp := _find_by_name(_map, "MapViewport") as Control
	var btn := _find_by_name(_map, "Room_" + DungeonMap.current_room) as Control
	if vp == null or btn == null:
		_expect(false, "%s：找不到视口或当前房间按钮" % label)
		return
	var vp_center: Vector2 = vp.get_global_rect().position + vp.get_global_rect().size * 0.5
	var btn_center: Vector2 = btn.get_global_rect().position + btn.get_global_rect().size * 0.5
	var diff: float = (btn_center - vp_center).length()
	print("[MC] %s：当前房间 %s 中心=%s，视口中心=%s，偏差 %.2f px" % [
		label, DungeonMap.current_room, str(btn_center), str(vp_center), diff])
	_expect(diff <= 1.5, "%s：当前房间位于视口正中（偏差 %.2f px）" % [label, diff])

# 大地图内容应明显大于视口（否则“居中/平移”没有意义，说明尺寸又被缩回刚好装下）
func _check_map_bigger_than_view() -> void:
	var vp := _find_by_name(_map, "MapViewport") as Control
	var layer := _find_by_name(_map, "RoomLayer") as Control
	if vp == null or layer == null:
		return
	var content := Rect2()
	var first := true
	for c in layer.get_children():
		if not (c is Control):
			continue
		var r: Rect2 = (c as Control).get_rect()
		if first:
			content = r
			first = false
		else:
			content = content.merge(r)
	print("[MC] 地图内容尺寸=%.0fx%.0f，视口=%.0fx%.0f" % [
		content.size.x, content.size.y, vp.size.x, vp.size.y])
	_expect(content.size.y > vp.size.y or content.size.x > vp.size.x,
		"大地图内容超出视口（可平移查看）")

func _move_to_neighbor() -> void:
	# 沿真实交互路径移动到相邻房间（已清除的邻居可直接移动，不跳场景）
	var from := DungeonMap.current_room
	var neighbors := DungeonMap.get_connected_rooms(from)
	if neighbors.is_empty():
		_expect(false, "当前房间没有相邻房间")
		return
	var target := str(neighbors[0])
	DungeonMap.mark_cleared(target)
	_map.call("_on_room_clicked", target)
	_expect(DungeonMap.current_room == target, "点击相邻已清房间后移动到 %s（现在 %s）" % [target, DungeonMap.current_room])
	_expect(DungeonMap.current_room != from, "当前房间确实变了")

# ------------------------------------------------------------ 工具

func _find_by_name(node: Node, target: String) -> Node:
	if node.name == target:
		return node
	for c in node.get_children():
		var found := _find_by_name(c, target)
		if found != null:
			return found
	return null

func _expect(condition: bool, label: String) -> void:
	if condition:
		_pass += 1
		print("[MC] PASS  ", label)
	else:
		_fail += 1
		print("[MC] FAIL  ", label)
