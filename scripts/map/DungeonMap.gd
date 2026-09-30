class_name DungeonMap
extends Node

# ============================================================
# 暗黑地牢风格地图系统（静态单例，小/中/大三级随机生成）
# "start"=起始房，"normal"=普通战斗房，"boss"=Boss房，""=无房间。
# 房间与走廊由二维数组自动生成（上下左右相邻即为走廊相连）。
# ============================================================

static var MAP_SIZE := "small" # "small" | "medium" | "large"
static var MAP_GRID: Array = []

# 扩散倾向：0=一条路径（线性），1=四通八达（分支），可调节
static var BRANCHINESS := 0.5

# 由 MAP_GRID 自动生成的房间表（key=房间id，value=房间字典）
static var _rooms: Dictionary = {}

static var START_ROOM := ""
static var BOSS_ROOM := ""
static var current_room := ""
# 已清除怪物的房间（含出生点），已清除房间不会再次刷新怪物
static var cleared_rooms: Array[String] = []

# 随机遭遇池（每种为一个怪物 id 数组）
static var ENCOUNTER_POOL := [
	["skeleton_common", "skeleton_common", "skeleton_militia", "skeleton_arbalist"],
	["skeleton_common", "skeleton_defender", "skeleton_courtier", "skeleton_spear"],
	["skeleton_militia", "skeleton_militia", "skeleton_defender", "skeleton_arbalist"],
	["skeleton_common", "skeleton_courtier", "skeleton_arbalist", "skeleton_spear"],
	["cutthroat", "cutthroat", "skeleton_common", "skeleton_common"],
	["skeleton_defender", "skeleton_defender", "skeleton_militia", "skeleton_courtier"],
]

# Boss 房使用固定的"门前恶狼"首领遭遇（队伍顺序即 1~4 号站位）：
#   1号 首领 Brigand Vvulf / 2号 弹药桶 / 3号 点火员 / 4号 大炮
static var BOSS_ENCOUNTER := ["brigand_sapper", "brigand_barrel", "brigand_fuseman", "brigand_cannon"]

# ------------------------------------------------------------
# 尺寸配置
# ------------------------------------------------------------

static func set_size(size_key: String) -> void:
	MAP_SIZE = size_key

static func set_branchiness(value: float) -> void:
	BRANCHINESS = clampf(value, 0.0, 1.0)

static func _grid_side() -> int:
	match MAP_SIZE:
		"medium":
			return 7
		"large":
			return 9
		_:
			return 5

static func _target_room_count() -> int:
	match MAP_SIZE:
		"medium":
			return 15
		"large":
			return 20
		_:
			return 10

static func get_grid_cols() -> int:
	_ensure_built()
	if MAP_GRID.is_empty():
		return 1
	var row: Array = MAP_GRID[0]
	return row.size()

static func get_grid_rows() -> int:
	_ensure_built()
	return MAP_GRID.size()

# ------------------------------------------------------------
# 内部构建
# ------------------------------------------------------------

static func _ensure_built() -> void:
	if MAP_GRID.is_empty() or _rooms.is_empty():
		_generate_map()

# 随机生成一张当前尺寸的地图，并据此重建房间表
static func _generate_map() -> void:
	var side := _grid_side()
	var target := _target_room_count()
	MAP_GRID = []
	for r in range(side):
		var row := []
		for c in range(side):
			row.append("")
		MAP_GRID.append(row)

	# 1. 全图随机挑选一个格子作为起点
	var start := Vector2i(randi_range(0, side - 1), randi_range(0, side - 1))
	_set_cell(start.y, start.x, "start")
	var head := start
	var room_count := 1

	# 2. 从已有房间向四周扩散，直到达到目标房间数
	while room_count < target:
		var candidates: Array = []
		if randf() >= BRANCHINESS:
			# 一条路径倾向：优先从当前“链头”继续扩散
			candidates = _empty_neighbors(head)
		if candidates.is_empty():
			# 四通八达倾向（或链头被围死时）：从所有前沿格子中随机选
			candidates = _frontier_cells()
		if candidates.is_empty():
			break
		var cell: Vector2i = candidates[randi() % candidates.size()]
		_set_cell(cell.y, cell.x, "normal")
		head = cell
		room_count += 1

	_build_rooms()

	# 3. 挑选距离起点最远（BFS 行走房间数最多）的房间作为 Boss
	_assign_boss()

static func _empty_neighbors(cell: Vector2i) -> Array:
	var result: Array = []
	for offset in [[-1, 0], [1, 0], [0, -1], [0, 1]]:
		var nr: int = cell.y + offset[0]
		var nc: int = cell.x + offset[1]
		# 必须显式检查边界：_cell_kind 对越界和空格都返回 ""，
		# 若不先判边界，会把地图外的格子当成可用空格，导致 _set_cell 越界
		if nr < 0 or nr >= MAP_GRID.size():
			continue
		var row: Array = MAP_GRID[nr]
		if nc < 0 or nc >= row.size():
			continue
		if _cell_kind(nr, nc) == "":
			result.append(Vector2i(nc, nr))
	return result

static func _frontier_cells() -> Array:
	var result: Array = []
	for r in range(MAP_GRID.size()):
		var row: Array = MAP_GRID[r]
		for c in range(row.size()):
			if _cell_kind(r, c) == "" and _has_room_neighbor(r, c):
				result.append(Vector2i(c, r))
	return result

static func _assign_boss() -> void:
	if START_ROOM == "" or _rooms.is_empty():
		return
	# BFS：计算每个房间到起点的行走步数
	var depth: Dictionary = {START_ROOM: 0}
	var queue: Array = [START_ROOM]
	var qi := 0
	while qi < queue.size():
		var cur: String = queue[qi]
		qi += 1
		var room: Dictionary = _rooms[cur]
		for nid in room.get("connections", []):
			if not depth.has(nid):
				depth[nid] = depth[cur] + 1
				queue.append(nid)

	var start_room: Dictionary = _rooms[START_ROOM]
	var start_cell := Vector2i(int(start_room["col"]), int(start_room["row"]))
	var best_id := ""
	var best_depth := -1
	var best_dist := -1
	for rid in _rooms.keys():
		if rid == START_ROOM:
			continue
		var d: int = depth.get(rid, -1)
		var room: Dictionary = _rooms[rid]
		var cell := Vector2i(int(room["col"]), int(room["row"]))
		var md := absi(cell.x - start_cell.x) + absi(cell.y - start_cell.y)
		if d > best_depth or (d == best_depth and md > best_dist):
			best_id = rid
			best_depth = d
			best_dist = md
	if best_id == "":
		return
	var boss_room: Dictionary = _rooms[best_id]
	var r: int = boss_room["row"]
	var c: int = boss_room["col"]
	_set_cell(r, c, "boss")
	boss_room["kind"] = "boss"
	boss_room["name"] = _kind_name("boss")
	BOSS_ROOM = best_id

static func _build_rooms() -> void:
	_rooms = {}
	START_ROOM = ""
	BOSS_ROOM = ""
	for r in range(MAP_GRID.size()):
		var row: Array = MAP_GRID[r]
		for c in range(row.size()):
			var kind: String = row[c]
			if kind == "":
				continue
			var room_id := _make_id(r, c)
			_rooms[room_id] = {
				"name": _kind_name(kind),
				"kind": kind,
				"col": c,
				"row": r,
				"connections": [],
			}
			if kind == "start":
				START_ROOM = room_id
			elif kind == "boss":
				BOSS_ROOM = room_id
	# 上下左右相邻的非空房间即为走廊相连
	for room_id in _rooms.keys():
		var room: Dictionary = _rooms[room_id]
		var r: int = room["row"]
		var c: int = room["col"]
		var conns: Array = []
		for offset in [[-1, 0], [1, 0], [0, -1], [0, 1]]:
			var nid := _id_at(r + offset[0], c + offset[1])
			if nid != "":
				conns.append(nid)
		room["connections"] = conns
	current_room = START_ROOM
	cleared_rooms = [START_ROOM]

static func _set_cell(r: int, c: int, kind: String) -> void:
	var row: Array = MAP_GRID[r]
	row[c] = kind

static func _cell_kind(r: int, c: int) -> String:
	if r < 0 or r >= MAP_GRID.size():
		return ""
	var row: Array = MAP_GRID[r]
	if c < 0 or c >= row.size():
		return ""
	return row[c]

static func _has_room_neighbor(r: int, c: int) -> bool:
	for offset in [[-1, 0], [1, 0], [0, -1], [0, 1]]:
		if _cell_kind(r + offset[0], c + offset[1]) != "":
			return true
	return false

static func _make_id(r: int, c: int) -> String:
	return "r%d_c%d" % [r, c]

static func _id_at(r: int, c: int) -> String:
	if _cell_kind(r, c) == "":
		return ""
	return _make_id(r, c)

static func _kind_name(kind: String) -> String:
	match kind:
		"start":
			return "起始"
		"boss":
			return "Boss"
		_:
			return "战斗"

# ------------------------------------------------------------
# 对外接口
# ------------------------------------------------------------

static func get_all_room_ids() -> Array[String]:
	_ensure_built()
	var result: Array[String] = []
	for id in _rooms.keys():
		result.append(str(id))
	return result

static func get_room(room_id: String) -> Dictionary:
	_ensure_built()
	if _rooms.has(room_id):
		return _rooms[room_id]
	return {}

static func are_connected(from_id: String, to_id: String) -> bool:
	var room := get_room(from_id)
	if room.is_empty():
		return false
	return to_id in room.get("connections", [])

static func get_connected_rooms(room_id: String) -> Array[String]:
	var result: Array[String] = []
	var room := get_room(room_id)
	if not room.is_empty():
		for other in room.get("connections", []):
			result.append(str(other))
	return result

static func is_cleared(room_id: String) -> bool:
	return room_id in cleared_rooms

static func mark_cleared(room_id: String) -> void:
	_ensure_built()
	if _rooms.has(room_id) and not (room_id in cleared_rooms):
		cleared_rooms.append(room_id)

static func is_boss_room(room_id: String) -> bool:
	_ensure_built()
	return room_id == BOSS_ROOM

static func move_to(room_id: String) -> void:
	_ensure_built()
	if _rooms.has(room_id):
		current_room = room_id

static func reset_run() -> void:
	# 重新随机生成一张当前尺寸的地图
	MAP_GRID = []
	_rooms = {}
	_generate_map()

# 为指定房间随机掷出一场遭遇（返回怪物 id 数组）
static func roll_encounter(room_id: String) -> Array[String]:
	var result: Array[String] = []
	var source: Array
	if is_boss_room(room_id):
		source = BOSS_ENCOUNTER
	else:
		source = ENCOUNTER_POOL[randi() % ENCOUNTER_POOL.size()]
	for monster_id in source:
		result.append(str(monster_id))
	return result
