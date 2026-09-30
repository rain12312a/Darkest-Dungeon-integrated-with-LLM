extends SceneTree

# 临时探针脚本（端到端验证用，非游戏运行时代码）
# 用途：真实实例化 Battle.tscn，直接调用 BattleController._play_skill_fx_v2() 播放各类受击特效，
#       然后测量特效节点在屏幕上的实际纵向落点，与目标身体范围对比，验证"自动对齐到躯干"是否按预期生效。
# 运行：godot --headless --path <项目> --script res://tools/_probe_fx_runtime.gd

const ANCHOR_RATIO := 0.45

var _battle: Node = null
var _frame := 0

func _initialize() -> void:
	# 换成包含剑士/枪兵的遭遇，以便同时验证新接线的 militia_ranged / spear_pierce
	var encounter: Array[String] = ["skeleton_militia", "skeleton_spear", "skeleton_common", "skeleton_defender"]
	MonsterConfig.CURRENT_ENCOUNTER = encounter
	var packed := load("res://scenes/battle/Battle.tscn") as PackedScene
	if packed == null:
		print("[RT] FAILED: cannot load Battle.tscn")
		quit(1)
		return
	_battle = packed.instantiate()
	root.add_child(_battle)

func _process(_delta: float) -> bool:
	_frame += 1
	if _frame < 3:
		return false # 等 _ready 与首帧 UI/Spine 初始化完成
	if _battle == null:
		quit(1)
		return true

	var heroes: Array = _battle.get("heroes")
	var monsters: Array = _battle.get("monsters")
	print("[RT] heroes=%d monsters=%d" % [heroes.size(), monsters.size()])
	if heroes.size() < 4 or monsters.size() < 4:
		print("[RT] FAILED: 编队/遭遇数量不足，无法测试")
		quit(1)
		return true

	print("[RT] ===== 受击特效运行期落点验证（屏幕像素，相对目标脚底；负=上方）=====")
	_test_skill(heroes[0], "cut", monsters[0])
	_test_skill(heroes[1], "pistol_shot", monsters[1])
	_test_skill(heroes[1], "shotgun", monsters[2])
	_test_skill(heroes[0], "heal", heroes[2])
	_test_skill(heroes[2], "深渊之手", monsters[3])
	_test_skill(heroes[2], "灵魂之触", monsters[0])
	_test_skill(monsters[0], "temptation", heroes[3])
	_test_skill(monsters[1], "arbalist_crossbow", heroes[1])
	_test_skill(monsters[0], "militia_slash", heroes[0])
	_test_skill(monsters[0], "militia_ranged", heroes[0])
	_test_skill(monsters[1], "spear_thrust", heroes[1])
	_test_skill(monsters[1], "spear_pierce", heroes[1])
	print("[RT] ===== done =====")
	quit(0)
	return true

func _test_skill(caster: Dictionary, skill_id: String, target: Dictionary) -> void:
	var before: int = _battle.get_child_count()
	_battle.call("_play_skill_fx_v2", caster, skill_id, [target])
	var added: Array = []
	for i in range(before, _battle.get_child_count()):
		var c := _battle.get_child(i)
		if c is SpinePlayer:
			added.append(c)
	if added.is_empty():
		print("[RT] %-20s 未生成特效节点" % skill_id)
		return

	var target_sp := _get_spine_player(target)
	var head_screen := 0.0
	var feet_screen := 0.0
	if target_sp != null:
		var body_rect := _content_bounds(target_sp)
		feet_screen = target_sp.global_position.y
		head_screen = feet_screen + body_rect.position.y * target_sp.scale.y

	for fx in added:
		var sp := fx as SpinePlayer
		var r := _content_bounds(sp)
		var top: float = sp.global_position.y + r.position.y * sp.scale.y
		var bottom: float = sp.global_position.y + r.end.y * sp.scale.y
		var overflow: float = 0.0
		if target_sp != null and head_screen != 0.0:
			overflow = head_screen - top
		var verdict := "OK"
		if overflow > 1.0:
			verdict = "超出头顶 %.0fpx" % overflow
		print("[RT] %-18s %-38s 头顶=%7.1f 特效=[%7.1f,%7.1f]  %s" % [
			skill_id, sp.current_skel_path.get_file(), head_screen, top, bottom, verdict
		])

func _get_spine_player(unit: Dictionary) -> SpinePlayer:
	var info: Dictionary = _battle.call("_get_spine_player_ref_info", unit)
	if info.get("key") == null:
		return null
	var players: Dictionary = _battle.get("_spine_players")
	return players.get(info["key"]) as SpinePlayer

# 与 BattleController._spine_content_bounds 相同的算法
func _content_bounds(sp: Node2D) -> Rect2:
	var min_v := Vector2(INF, INF)
	var max_v := Vector2(-INF, -INF)
	for child in sp.get_children():
		if child is Polygon2D:
			var poly := child as Polygon2D
			for p: Vector2 in poly.polygon:
				min_v = min_v.min(p)
				max_v = max_v.max(p)
		elif child is Sprite2D:
			var spr := child as Sprite2D
			var rect: Rect2 = spr.get_rect()
			var corners: Array[Vector2] = [
				rect.position,
				Vector2(rect.end.x, rect.position.y),
				Vector2(rect.position.x, rect.end.y),
				rect.end,
			]
			for corner: Vector2 in corners:
				var p2: Vector2 = spr.transform * corner
				min_v = min_v.min(p2)
				max_v = max_v.max(p2)
	if min_v.x == INF:
		return Rect2()
	return Rect2(min_v, max_v - min_v)
