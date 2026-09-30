extends Node

# ============================================================
# 地图场景控制器
# 渲染由正方形房间 + 走廊组成的随机生成地图。
# 玩家可点击与当前房间相连的其它房间进入，触发新的随机战斗。
# ============================================================

const BATTLE_SCENE_PATH := "res://scenes/battle/Battle.tscn"
const START_SCENE_PATH := "res://scenes/start/Start.tscn"

# 地图视口：地图内容全部生成在“地图坐标系”里，再整体平移，使当前房间落在视口正中，超出部分裁掉
const VIEW_TOP := 108.0 # 视口上沿（标题/状态文字之下）
const VIEW_BOTTOM := 600.0 # 视口下沿（提示文字与按钮之上）
const VIEW_WIDTH_FALLBACK := 1280.0 # 取不到视口宽度时的兜底
# 房间方块与格距：固定值（不再缩到“刚好装下整张图”），中/大地图会超出视口，靠平移查看
const ROOM_SIZE := 76.0
const STEP_X := 150.0
const STEP_Y := 126.0
const CENTER_TWEEN_TIME := 0.28 # 换房时平移的补间时长（秒）

var status_label: Label
var map_viewport: Control
var map_root: Node2D
var room_layer: Control
var _room_size: float = ROOM_SIZE
var _step_x: float = STEP_X
var _step_y: float = STEP_Y
var _center_tween: Tween

func _ready() -> void:
	_build_ui()
	# 背景音乐：地图探索曲
	Bgm.play("map")
	# 窗口尺寸变化时视口尺寸跟着变，并重新居中
	var vp := get_viewport()
	if vp != null and not vp.size_changed.is_connected(_on_viewport_resized):
		vp.size_changed.connect(_on_viewport_resized)

func _on_viewport_resized() -> void:
	if not is_instance_valid(map_viewport):
		return
	map_viewport.size = Vector2(_view_width(), VIEW_BOTTOM - VIEW_TOP)
	var view_bg := map_viewport.get_node_or_null("ViewportBg") as Control
	if view_bg != null:
		view_bg.size = map_viewport.size
	_center_on_current_room(false)

func _build_ui() -> void:
	var ui := Control.new()
	ui.name = "MapUI"
	ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(ui)

	var bg := ColorRect.new()
	bg.name = "Background"
	bg.color = Color(0.07, 0.05, 0.04, 1)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui.add_child(bg)

	var title := Label.new()
	title.name = "Title"
	title.text = "The Crypts"
	title.position = Vector2(40, 26)
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", Color(0.85, 0.78, 0.55, 1))
	ui.add_child(title)

	status_label = Label.new()
	status_label.name = "StatusLabel"
	status_label.position = Vector2(40, 72)
	status_label.add_theme_font_size_override("font_size", 16)
	status_label.add_theme_color_override("font_color", Color(0.9, 0.85, 0.7, 1))
	ui.add_child(status_label)

	map_viewport = Control.new()
	map_viewport.name = "MapViewport"
	map_viewport.position = Vector2(0.0, VIEW_TOP)
	map_viewport.size = Vector2(_view_width(), VIEW_BOTTOM - VIEW_TOP)
	map_viewport.clip_contents = true # 超出视口的部分不显示
	map_viewport.mouse_filter = Control.MOUSE_FILTER_IGNORE # 自己不吃事件，子节点照常可点
	ui.add_child(map_viewport)

	var view_bg := ColorRect.new()
	view_bg.name = "ViewportBg"
	view_bg.color = Color(0.1, 0.075, 0.06, 1)
	view_bg.size = map_viewport.size
	view_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	map_viewport.add_child(view_bg)

	# 地图内容根节点：只改它的 position 就能平移整张地图（房间 + 走廊）
	map_root = Node2D.new()
	map_root.name = "MapRoot"
	map_viewport.add_child(map_root)

	_room_size = ROOM_SIZE
	_step_x = STEP_X
	_step_y = STEP_Y

	_draw_corridors()
	_refresh_rooms(false)

	var hint := Label.new()
	hint.text = "橙色房间有敌（进入战斗）；蓝色（已清）房间可直接通行；视野始终以当前房间为中心"
	hint.position = Vector2(40, 620)
	hint.add_theme_font_size_override("font_size", 13)
	hint.add_theme_color_override("font_color", Color(0.6, 0.55, 0.45, 1))
	ui.add_child(hint)

	var back_btn := Button.new()
	back_btn.text = "Abandon Run"
	back_btn.position = Vector2(40, 650)
	back_btn.size = Vector2(150, 42)
	back_btn.pressed.connect(_on_abandon_pressed)
	ui.add_child(back_btn)

	_update_status()

# 视口宽度（跟随实际窗口，取不到时用兜底）
func _view_width() -> float:
	var vp := get_viewport()
	if vp != null:
		var w: float = vp.get_visible_rect().size.x
		if w > 1.0:
			return w
	return VIEW_WIDTH_FALLBACK

func _room_center(room: Dictionary) -> Vector2:
	var col: int = room.get("col", 0)
	var row: int = room.get("row", 0)
	return Vector2(col * _step_x + _room_size * 0.5, row * _step_y + _room_size * 0.5)

# 把当前房间平移到视口正中：整张地图作为整体平移，超出视口的部分被裁掉
func _center_on_current_room(animate: bool = true) -> void:
	if not is_instance_valid(map_root) or not is_instance_valid(map_viewport):
		return
	var room: Dictionary = DungeonMap.get_room(DungeonMap.current_room)
	if room.is_empty():
		return
	var target: Vector2 = map_viewport.size * 0.5 - _room_center(room)
	if not animate:
		map_root.position = target
		return
	# 上一段补间还在跑时要先停掉，否则两个补间会互相抢同一个 position
	if _center_tween != null and _center_tween.is_valid():
		_center_tween.kill()
	_center_tween = create_tween()
	_center_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_center_tween.tween_property(map_root, "position", target, CENTER_TWEEN_TIME)

func _draw_corridors() -> void:
	var drawn: Dictionary = {}
	for room_id in DungeonMap.get_all_room_ids():
		var room: Dictionary = DungeonMap.get_room(room_id)
		for other_id in room.get("connections", []):
			var a: String = room_id if room_id < other_id else other_id
			var b: String = other_id if room_id < other_id else room_id
			var edge_key := a + "|" + b
			if drawn.has(edge_key):
				continue
			drawn[edge_key] = true
			var from := _room_center(DungeonMap.get_room(a))
			var to := _room_center(DungeonMap.get_room(b))
			var line := Line2D.new()
			line.points = PackedVector2Array([from, to])
			line.width = 8.0
			line.default_color = Color(0.35, 0.25, 0.16, 0.95)
			map_root.add_child(line)

func _refresh_rooms(animate: bool = true) -> void:
	if is_instance_valid(room_layer):
		room_layer.queue_free()
	room_layer = Control.new()
	room_layer.name = "RoomLayer"
	room_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	map_root.add_child(room_layer)
	for room_id in DungeonMap.get_all_room_ids():
		var room: Dictionary = DungeonMap.get_room(room_id)
		var center := _room_center(room)
		_create_room_button(room_layer, room_id, room, center)
	# 换房后重新居中（整张地图平移，当前房间永远落在视口中心）
	_center_on_current_room(animate)

func _create_room_button(parent: Control, room_id: String, room: Dictionary, center: Vector2) -> void:
	var is_current := room_id == DungeonMap.current_room
	var is_linked := DungeonMap.are_connected(DungeonMap.current_room, room_id)
	var is_cleared := DungeonMap.is_cleared(room_id)
	var is_adjacent := is_current or is_linked

	var btn := Button.new()
	btn.name = "Room_" + room_id
	btn.position = center - Vector2(_room_size * 0.5, _room_size * 0.5)
	btn.size = Vector2(_room_size, _room_size)
	btn.disabled = not is_adjacent
	btn.clip_text = true
	btn.add_theme_font_size_override("font_size", 13 if _room_size >= 48.0 else (11 if _room_size >= 34.0 else 9))

	var label_text: String = room.get("name", room_id)
	if is_current:
		label_text = "▶ " + label_text
	elif is_cleared:
		label_text = label_text + " ✓"
	btn.text = label_text

	var sb_normal := StyleBoxFlat.new()
	sb_normal.bg_color = Color(0.16, 0.12, 0.09, 1)
	sb_normal.border_width_left = 2
	sb_normal.border_width_top = 2
	sb_normal.border_width_right = 2
	sb_normal.border_width_bottom = 2
	sb_normal.border_color = Color(0.55, 0.45, 0.3, 1)

	var sb_hover := sb_normal.duplicate()
	sb_hover.bg_color = Color(0.22, 0.16, 0.11, 1)

	var sb_adjacent := sb_normal.duplicate()
	sb_adjacent.border_color = Color(0.85, 0.6, 0.2, 1)

	var sb_cleared := sb_normal.duplicate()
	sb_cleared.border_color = Color(0.3, 0.65, 0.75, 1)

	var sb_current := sb_normal.duplicate()
	sb_current.bg_color = Color(0.13, 0.2, 0.12, 1)
	sb_current.border_color = Color(0.35, 0.8, 0.35, 1)

	var sb_disabled := sb_normal.duplicate()
	sb_disabled.bg_color = Color(0.1, 0.1, 0.1, 0.7)
	sb_disabled.border_color = Color(0.3, 0.3, 0.3, 0.5)

	var normal_style := sb_normal
	if is_current:
		normal_style = sb_current
	elif is_adjacent:
		normal_style = sb_cleared if is_cleared else sb_adjacent

	btn.add_theme_stylebox_override("normal", normal_style)
	btn.add_theme_stylebox_override("hover", sb_hover)
	btn.add_theme_stylebox_override("pressed", sb_hover)
	btn.add_theme_stylebox_override("disabled", sb_disabled)

	btn.pressed.connect(_on_room_clicked.bind(room_id))
	parent.add_child(btn)

func _update_status() -> void:
	if not status_label:
		return
	var current: Dictionary = DungeonMap.get_room(DungeonMap.current_room)
	var exits := DungeonMap.get_connected_rooms(DungeonMap.current_room)
	var enemy_count := 0
	var cleared_count := 0
	for r in exits:
		if DungeonMap.is_cleared(r):
			cleared_count += 1
		else:
			enemy_count += 1
	var parts := PackedStringArray()
	if enemy_count > 0:
		parts.append("战斗房 ×%d（有敌）" % enemy_count)
	if cleared_count > 0:
		parts.append("已清 ×%d" % cleared_count)
	var exit_text := "、".join(parts) if not parts.is_empty() else "无"
	status_label.text = "当前房间：%s    |    相邻：%s" % [current.get("name", DungeonMap.current_room), exit_text]

func _on_room_clicked(room_id: String) -> void:
	if room_id == DungeonMap.current_room:
		return
	if not DungeonMap.are_connected(DungeonMap.current_room, room_id):
		return
	if DungeonMap.is_cleared(room_id):
		# 已清除的房间：直接移动，不刷新怪物
		DungeonMap.move_to(room_id)
		_refresh_rooms()
		_update_status()
		return
	var encounter := DungeonMap.roll_encounter(room_id)
	MonsterConfig.CURRENT_ENCOUNTER = encounter
	DungeonMap.move_to(room_id)
	get_tree().change_scene_to_file(BATTLE_SCENE_PATH)

func _on_abandon_pressed() -> void:
	get_tree().change_scene_to_file(START_SCENE_PATH)
