extends SceneTree

# 临时截图脚本（人工核对 UI 遮挡 / 尸体姿态用，非游戏运行时代码）
# 运行：godot --path <项目> --script res://tools/_shot_check.gd
# 产物：res://shot_check.png（核对完即可删除）

var _battle: Node = null
var _frame := 0

func _initialize() -> void:
	MonsterConfig.CURRENT_ENCOUNTER = ["brigand_sapper", "brigand_barrel", "brigand_fuseman", "brigand_cannon"]
	HeroConfig.reset_party_state()
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
		# 1) 打死弹药桶与点火员 → 两个尸体（含无 dead 动画的骨架）
		for idx in [1, 2]:
			var monsters: Array = _battle.get("monsters")
			monsters[idx]["hp"] = 0
			_battle.call("_handle_monster_damage_aftermath", idx)
		# 2) 让 1 号英雄处于"折磨 + 流血 + 濒死"，检查状态栏 / 死门行是否被遮挡
		var h: Dictionary = _battle.get("heroes")[0]
		ActionResolver.apply_status(h, StressConfig.AFFLICTION_STATUS, 1, 1)
		ActionResolver.apply_status(h, "bleed", 3, 3)
		ActionResolver.apply_status(h, "blight", 2, 2)
		h["hp"] = 0
		h["is_death_door"] = true
		_battle.set("current_actor", {"unit_type": "hero", "index": 0})
		_battle.call("_update_ui")
		return false
	if _frame >= 20:
		_report_corpse_rects()
		var img := root.get_texture().get_image()
		if img == null:
			print("[SHOT] 无法取得视口图像")
			quit(1)
			return true
		img.save_png("res://shot_check.png")
		print("[SHOT] saved res://shot_check.png size=", img.get_size())
		quit(0)
		return true
	return false

# 打印每只怪物（含尸体）在屏幕上的绘制矩形，便于精确裁剪核对
func _report_corpse_rects() -> void:
	var players: Dictionary = _battle.get("_spine_players")
	var monsters: Array = _battle.get("monsters")
	for i in range(monsters.size()):
		var key := "monster_%d" % i
		if not players.has(key):
			continue
		var sp: SpinePlayer = players[key]
		if not is_instance_valid(sp):
			continue
		var bounds: Rect2 = _battle.call("_spine_content_bounds", sp)
		var tl: Vector2 = sp.global_position + bounds.position * sp.scale
		var br: Vector2 = sp.global_position + (bounds.position + bounds.size) * sp.scale
		print("[SHOT] slot%d %s corpse=%s pos=%s skel=%s 绘制矩形=(%.0f,%.0f)-(%.0f,%.0f)" % [
			i + 1, str(monsters[i].get("id", "")), str(monsters[i].get("is_corpse", false)),
			str(sp.global_position), str(sp.current_skel_path).get_file(),
			minf(tl.x, br.x), minf(tl.y, br.y), maxf(tl.x, br.x), maxf(tl.y, br.y)])
