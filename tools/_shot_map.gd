extends SceneTree

# 临时截图脚本（人工核对地图显示用，非游戏运行时代码）
# 运行：godot --path <项目> --script res://tools/_shot_map.gd
# 产物：res://shot_map_a.png（开局）、res://shot_map_b.png（移动到另一间房后）

const MAP_SCENE := "res://scenes/map/Map.tscn"

var _map: Node = null
var _frame := 0

func _initialize() -> void:
	DungeonMap.set_size("large")
	DungeonMap.BRANCHINESS = 0.5
	DungeonMap.reset_run()
	var packed := load(MAP_SCENE) as PackedScene
	_map = packed.instantiate()
	root.add_child(_map)

func _process(_delta: float) -> bool:
	_frame += 1
	if _map == null:
		quit(1)
		return true
	if _frame == 25:
		_save("res://shot_map_a.png")
		# 直接跳到离起点最远的房间（模拟换房后的重新居中）
		var far := _farthest_room()
		print("[SHOTMAP] 从 %s 移动到 %s" % [DungeonMap.current_room, far])
		DungeonMap.move_to(far)
		_map.call("_refresh_rooms", false)
		return false
	if _frame == 45:
		_save("res://shot_map_b.png")
		quit(0)
		return true
	return false

func _save(path: String) -> void:
	var img := root.get_texture().get_image()
	if img == null:
		print("[SHOTMAP] 无法取得视口图像")
		return
	img.save_png(path)
	print("[SHOTMAP] saved ", path, " size=", img.get_size())

func _farthest_room() -> String:
	var start := DungeonMap.get_room(DungeonMap.START_ROOM)
	var best := DungeonMap.START_ROOM
	var best_d := -1.0
	for room_id in DungeonMap.get_all_room_ids():
		var r := DungeonMap.get_room(room_id)
		var d: float = absf(float(r.get("col", 0) - start.get("col", 0))) + absf(float(r.get("row", 0) - start.get("row", 0)))
		if d > best_d:
			best_d = d
			best = room_id
	return best
