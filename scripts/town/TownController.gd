extends Node

signal start_battle

@onready var start_button: Button = $TownUI/StartBattleButton

func _ready() -> void:
	if start_button:
		start_button.pressed.connect(request_start_battle)

func request_start_battle() -> void:
	emit_signal("start_battle")
