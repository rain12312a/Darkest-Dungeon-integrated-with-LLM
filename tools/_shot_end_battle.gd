extends SceneTree

# 临时截图脚本（人工核对战斗结算界面布局用，非游戏运行时代码）
# 运行：godot --path <项目> --script res://tools/_shot_end_battle.gd
# 产物：res://shot_end_victory.png / shot_end_complete.png / shot_end_defeat.png（核对完即可删除）

const WAIT_FRAMES := 40 # 等入场动画播完再截图

var _battle: Node = null
var _frame := 0
var _plan: Array = []
var _step := 0

func _initialize() -> void:
	HeroConfig.reset_party_state()
	ConsumableConfig.reset_inventory()
	MonsterConfig.CURRENT_ENCOUNTER = ["skeleton_common", "skeleton_defender"]
	var packed := load("res://scenes/battle/Battle.tscn") as PackedScene
	_battle = packed.instantiate()
	root.add_child(_battle)
	_plan = [
		{"state": "victory", "won": true, "complete": false, "loot": true, "file": "shot_end_victory.png"},
		{"state": "run_complete", "won": true, "complete": true, "loot": false, "file": "shot_end_complete.png"},
		{"state": "defeat", "won": false, "complete": false, "loot": false, "file": "shot_end_defeat.png"},
	]

func _process(_delta: float) -> bool:
	_frame += 1
	if _battle == null:
		quit(1)
		return true
	# 冻结自动战斗循环，否则怪物会自己行动把画面搅乱
	_battle.set("battle_over", true)
	if _step >= _plan.size():
		return false
	# 第 3 帧进入某个状态，再等 WAIT_FRAMES 帧截图
	var entry: Dictionary = _plan[_step]
	var start := 3 + _step * (WAIT_FRAMES + 2)
	if _frame == start:
		_apply_state(entry)
		return false
	if _frame >= start + WAIT_FRAMES:
		_shoot(str(entry["file"]), bool(entry["loot"]))
		_step += 1
		if _step >= _plan.size():
			quit(0)
			return true
	return false

func _apply_state(entry: Dictionary) -> void:
	_battle.set("_battle_won", bool(entry["won"]))
	_battle.set("_run_complete", bool(entry["complete"]))
	var panel: Panel = _battle.get("victory_panel")
	panel.visible = true
	_battle.call("_refresh_end_battle_content")
	# 胜利状态顺带把右侧战利品面板也摊开，用于核对两者是否重叠
	var modal: ColorRect = _battle.get("loot_modal")
	if bool(entry["loot"]):
		_battle.call("_show_loot_panel", _battle.call("_roll_battle_loot"))
	else:
		modal.visible = false
	print("[SHOT] --- %s ---" % str(entry["state"]))

func _shoot(file_name: String, with_loot: bool) -> void:
	var card: Panel = _battle.get("_end_card")
	if card == null:
		print("[SHOT] FAIL: _end_card is null")
		return
	var card_rect: Rect2 = card.get_global_rect()
	print("[SHOT] card rect = ", card_rect)
	print("[SHOT] panel rect = ", (_battle.get("victory_panel") as Panel).get_global_rect())
	var loot_panel: Panel = _battle.get("loot_panel")
	if with_loot and loot_panel != null:
		var loot_rect: Rect2 = loot_panel.get_global_rect()
		print("[SHOT] loot rect = ", loot_rect)
		print("[SHOT] 与战利品面板重叠 = ", card_rect.intersects(loot_rect))
	print("[SHOT] 标题 = %s" % str((_battle.get("victory_label") as Label).text))
	print("[SHOT] 按钮 = %s (disabled=%s)" % [
		str((_battle.get("back_button") as Button).text),
		str((_battle.get("back_button") as Button).disabled)])
	var stats: VBoxContainer = _battle.get("_end_stats")
	if stats != null:
		var lines := PackedStringArray()
		for row in stats.get_children():
			var parts := PackedStringArray()
			for c in row.get_children():
				parts.append((c as Label).text)
			lines.append(" / ".join(parts))
		print("[SHOT] 战绩 = ", " | ".join(lines))
	print("[SHOT] BattleUI layout=", (_battle.get_node("BattleUI") as Control).size)
	var img := root.get_texture().get_image()
	if img == null:
		print("[SHOT] 无法取得视口图像")
		return
	img.save_png("res://" + file_name)
	print("[SHOT] saved res://%s size=%s" % [file_name, str(img.get_size())])
