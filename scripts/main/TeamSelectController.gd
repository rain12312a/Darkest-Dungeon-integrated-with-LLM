extends Node

signal team_selected

var hero_slots: Array[HBoxContainer]
var confirm_button: Button
var available_heroes_container: VBoxContainer
var confirm_panel: Panel
var team_summary_label: Label
var start_button: Button
var back_button: Button

var current_team: Array[String] = ["crusader", "highwayman", "crusader", "highwayman"]
var selected_slot: int = -1

func _ready() -> void:
	# 手动获取节点
	hero_slots = [
		get_node("TeamUI/Content/Slot1") as HBoxContainer,
		get_node("TeamUI/Content/Slot2") as HBoxContainer,
		get_node("TeamUI/Content/Slot3") as HBoxContainer,
		get_node("TeamUI/Content/Slot4") as HBoxContainer
	]
	confirm_button = get_node("TeamUI/ConfirmButton") as Button
	available_heroes_container = get_node("TeamUI/AvailableHeroes/HeroList") as VBoxContainer
	confirm_panel = get_node("TeamUI/ConfirmPanel") as Panel
	team_summary_label = get_node("TeamUI/ConfirmPanel/VBoxContainer/TeamSummary") as Label
	start_button = get_node("TeamUI/ConfirmPanel/VBoxContainer/ButtonContainer/StartButton") as Button
	back_button = get_node("TeamUI/ConfirmPanel/VBoxContainer/ButtonContainer/BackButton") as Button
	
	_setup_ui()
	
	if confirm_button:
		confirm_button.pressed.connect(_on_confirm_pressed)
	
	if start_button:
		start_button.pressed.connect(_on_start_battle_pressed)
	
	if back_button:
		back_button.pressed.connect(_on_confirm_back_pressed)

func _setup_ui() -> void:
	# 显示可用英雄
	_update_available_heroes()
	# 显示当前编队
	_update_team_display()

func _update_available_heroes() -> void:
	if not available_heroes_container:
		return
	
	for child in available_heroes_container.get_children():
		child.queue_free()
	
	for hero_id in HeroConfig.get_all_hero_ids():
		var hero_template = HeroConfig.get_hero_template(hero_id)
		if hero_template.is_empty():
			continue
		
		var button = Button.new()
		button.text = "%s (HP:%d ATK:%d)" % [hero_template["name"], hero_template["max_hp"], hero_template["attack"]]
		button.custom_minimum_size = Vector2(300, 40)
		button.pressed.connect(_on_hero_selected.bind(hero_id))
		available_heroes_container.add_child(button)

func _update_team_display() -> void:
	for i in range(hero_slots.size()):
		var slot = hero_slots[i]
		
		# 清空旧内容
		for child in slot.get_children():
			child.queue_free()
		
		# 显示英雄和选择按钮
		if i < current_team.size() and current_team[i] != "":
			var hero_id = current_team[i]
			var hero_template = HeroConfig.get_hero_template(hero_id)
			
			var label = Label.new()
			label.text = "%d. %s" % [i + 1, hero_template["name"]]
			label.custom_minimum_size = Vector2(150, 40)
			slot.add_child(label)
			
			var remove_button = Button.new()
			remove_button.text = "Remove"
			remove_button.custom_minimum_size = Vector2(80, 40)
			remove_button.pressed.connect(_on_slot_remove.bind(i))
			slot.add_child(remove_button)
		else:
			var label = Label.new()
			if selected_slot == i:
				label.text = "%d. [SELECT HERO] <" % (i + 1)
				label.modulate = Color.YELLOW
			else:
				label.text = "%d. Empty" % (i + 1)
			label.custom_minimum_size = Vector2(150, 40)
			slot.add_child(label)
			
			var select_button = Button.new()
			select_button.text = "Select"
			select_button.custom_minimum_size = Vector2(80, 40)
			select_button.pressed.connect(_on_slot_select.bind(i))
			slot.add_child(select_button)

func _on_hero_selected(hero_id: String) -> void:
	if selected_slot >= 0 and selected_slot < current_team.size():
		current_team[selected_slot] = hero_id
		selected_slot = -1
		_update_team_display()

func _on_slot_select(slot_index: int) -> void:
	selected_slot = slot_index
	_update_available_heroes()
	_update_team_display()

func _on_slot_remove(slot_index: int) -> void:
	if slot_index >= 0 and slot_index < current_team.size():
		current_team[slot_index] = ""
		_update_available_heroes()
		_update_team_display()

func _on_confirm_pressed() -> void:
	# 检查编队是否有效（至少有一个英雄）
	var has_hero = false
	for hero_id in current_team:
		if hero_id != "":
			has_hero = true
			break
	
	if not has_hero:
		return
	
	# 显示确认面板
	_show_confirm_panel()

func _show_confirm_panel() -> void:
	if not confirm_panel or not team_summary_label:
		return
	
	# 构建编队摘要
	var summary = ""
	for i in range(current_team.size()):
		if i < current_team.size() and current_team[i] != "":
			var hero_template = HeroConfig.get_hero_template(current_team[i])
			summary += "%d. %s\n" % [i + 1, hero_template["name"]]
		else:
			summary += "%d. Empty\n" % (i + 1)
	
	team_summary_label.text = summary
	confirm_panel.visible = true

func _on_start_battle_pressed() -> void:
	HeroConfig.set_team(current_team)
	get_tree().change_scene_to_file("res://scenes/battle/Battle.tscn")

func _on_confirm_back_pressed() -> void:
	confirm_panel.visible = false
