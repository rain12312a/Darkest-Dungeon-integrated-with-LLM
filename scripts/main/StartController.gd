extends Node

@onready var start_button: Button = $StartUI/StartButton

func _ready() -> void:
	if start_button:
		start_button.pressed.connect(_on_start_pressed)

func _on_start_pressed() -> void:
	# 前往编队选择场景
	get_tree().change_scene_to_file("res://scenes/main/TeamSelect.tscn")
