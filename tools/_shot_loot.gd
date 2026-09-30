extends SceneTree

# 临时截图脚本（人工核对战利品结算面板布局用，非游戏运行时代码）
# 运行：godot --path <项目> --script res://tools/_shot_loot.gd
# 产物：res://shot_loot.png（核对完即可删除）

var _battle: Node = null
var _frame := 0

func _initialize() -> void:
	HeroConfig.reset_party_state()
	ConsumableConfig.reset_inventory()
	MonsterConfig.CURRENT_ENCOUNTER = ["skeleton_common", "skeleton_defender"]
	var packed := load("res://scenes/battle/Battle.tscn") as PackedScene
	_battle = packed.instantiate()
	root.add_child(_battle)

func _process(_delta: float) -> bool:
	_frame += 1
	if _battle == null:
		quit(1)
		return true
	if _frame == 3:
		_battle.set("battle_over", true) # 冻结自动战斗
		var monsters: Array = _battle.get("monsters")
		monsters.clear() # 全歼 → 胜利结算
		_battle.set("battle_over", false)
		_battle.call("_end_battle")
		_battle.set("battle_over", true)
		return false
	if _frame >= 20:
		_report_rects()
		var img := root.get_texture().get_image()
		if img == null:
			print("[SHOT] 无法取得视口图像")
			quit(1)
			return true
		img.save_png("res://shot_loot.png")
		print("[SHOT] saved res://shot_loot.png size=", img.get_size())
		quit(0)
		return true
	return false

# 打印结算面板 / 胜利面板 / 战利品行的屏幕矩形，便于核对右侧布局与不重叠
func _report_rects() -> void:
	var panel: Panel = _battle.get("loot_panel")
	var modal: ColorRect = _battle.get("loot_modal")
	var victory: Panel = _battle.get("victory_panel")
	var items_root: VBoxContainer = _battle.get("loot_items_root")
	if modal:
		print("[SHOT] modal visible=%s rect=%s" % [str(modal.visible), str(modal.get_global_rect())])
	if panel:
		print("[SHOT] loot panel rect=", str(panel.get_global_rect()))
	if victory:
		print("[SHOT] victory panel rect=", str(victory.get_global_rect()))
	if items_root:
		print("[SHOT] loot rows=", items_root.get_child_count(), " rect=", str(items_root.get_global_rect()))
