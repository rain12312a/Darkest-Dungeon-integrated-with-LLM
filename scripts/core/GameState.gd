extends Node

const START_SCENE_PATH := "res://scenes/start/Start.tscn"
const TOWN_SCENE_PATH := "res://scenes/town/Town.tscn"
const BATTLE_SCENE_PATH := "res://scenes/battle/Battle.tscn"

var current_scene: Node

func _ready() -> void:
	_goto_start()

func _goto_start() -> void:
	_change_scene(START_SCENE_PATH)

func _goto_town() -> void:
	_change_scene(TOWN_SCENE_PATH)

func _goto_battle() -> void:
	_change_scene(BATTLE_SCENE_PATH)

func _change_scene(scene_path: String) -> void:
	if current_scene:
		current_scene.queue_free()
		current_scene = null
	var packed := load(scene_path)
	if packed:
		current_scene = packed.instantiate()
		add_child(current_scene)
		_wire_scene_events(current_scene)

func _wire_scene_events(scene: Node) -> void:
	if scene.has_signal("start_battle"):
		scene.connect("start_battle", Callable(self, "_goto_battle"))
	if scene.has_signal("return_to_start"):
		scene.connect("return_to_start", Callable(self, "_goto_start"))
	if scene.has_signal("return_to_town"):
		scene.connect("return_to_town", Callable(self, "_goto_town"))
