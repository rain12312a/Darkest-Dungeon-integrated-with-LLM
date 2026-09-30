extends SceneTree

# 临时探针脚本（测量用，非游戏运行时代码）
# 用途：打印 Spine 角色与特效"绘制内容包围盒"（节点本地单位，未乘 scale）
# 运行：godot --headless --path <项目> --script res://tools/_probe_spine_bounds.gd

# [标签, skel_base, png_dir]
const TARGETS := [
	# ── 参考：角色实体（本地单位为骨架单位，节点 scale=0.5） ──
	["CHAR crusader idle", "res://characters/crusader/anim/crusader.sprite.idle", "res://characters/crusader/crusader_A/anim"],
	["CHAR crusader combat", "res://characters/crusader/anim/crusader.sprite.combat", "res://characters/crusader/crusader_A/anim"],
	["CHAR highwayman idle", "res://characters/highwayman/anim/highwayman.sprite.idle", "res://characters/highwayman/highwayman_A/anim"],
	["CHAR houndmaster idle", "res://characters/houndmaster/anim/houndmaster.sprite.idle", "res://characters/houndmaster/houndmaster_A/anim"],
	["CHAR skeleton_common combat", "res://monsters/skeleton_common/anim/skeleton_common.sprite.combat", "res://monsters/skeleton_common/anim"],
	["CHAR skeleton_defender combat", "res://monsters/skeleton_defender/anim/skeleton_defender.sprite.combat", "res://monsters/skeleton_defender/anim"],
	["CHAR cutthroat combat", "res://monsters/brigand_cutthroat/anim/brigand_cutthroat.sprite.combat", "res://monsters/brigand_cutthroat/anim"],

	# ── 残骸（怪物尸体，BOSS 关借用普通小怪的 dead）──
	["CORPSE cutthroat dead", "res://monsters/brigand_cutthroat/anim/brigand_cutthroat.sprite.dead", "res://monsters/brigand_cutthroat/anim"],
	["CORPSE skeleton_common dead", "res://monsters/skeleton_common/anim/skeleton_common.sprite.dead", "res://monsters/skeleton_common/anim"],
	["CORPSE skeleton_arbalist dead", "res://monsters/skeleton_arbalist/anim/skeleton_arbalist.sprite.dead", "res://monsters/skeleton_arbalist/anim"],

	# ── 受击（target）特效 ──
	["FX opened_vein (cut)", "res://characters/highwayman/fx/highwayman.sprite.opened_vein", "res://characters/highwayman/fx"],
	["FX grape_shot_blast_target", "res://characters/highwayman/fx/highwayman.sprite.grape_shot_blast_target", "res://characters/highwayman/fx"],
	["FX point_blank_shot_target", "res://characters/highwayman/fx/highwayman.sprite.point_blank_shot_target", "res://characters/highwayman/fx"],
	["FX pistol_shot_target", "res://characters/highwayman/fx/highwayman.sprite.pistol_shot_target", "res://characters/highwayman/fx"],
	["FX stunning_blow_target", "res://characters/crusader/fx/crusader.sprite.stunning_blow_target", "res://characters/crusader/fx"],
	["FX battle_heal_target", "res://characters/crusader/fx/crusader.sprite.battle_heal_target", "res://characters/crusader/fx"],
	["FX hands_from_abyss_target", "res://characters/occultist/fx/occultist.sprite.hands_from_abyss_target", "res://characters/occultist/fx"],
	["FX daemons_pull_target", "res://characters/occultist/fx/occultist.sprite.daemons_pull_target", "res://characters/occultist/fx"],
	["FX wyrd_reconstruction_target", "res://characters/occultist/fx/occultist.sprite.wyrd_reconstruction_target", "res://characters/occultist/fx"],
	["FX crossbow_shot_target", "res://monsters/skeleton_arbalist/fx/skeleton_arbalist.sprite.crossbow_shot_target", "res://monsters/skeleton_arbalist/fx"],

	# ── 施法（caster）特效 ──
	["FX smite (slash)", "res://characters/crusader/fx/crusader.sprite.smite", "res://characters/crusader/fx"],
	["FX wicked_slice (cut)", "res://characters/highwayman/fx/highwayman.sprite.wicked_slice", "res://characters/highwayman/fx"],
	["FX cudgel (skeleton_melee)", "res://monsters/skeleton_common/fx/skeleton_common.sprite.cudgel", "res://monsters/skeleton_common/fx"],
	["FX sword_strike (militia)", "res://monsters/skeleton_militia/fx/skeleton_militia.sprite.sword_strike", "res://monsters/skeleton_militia/fx"],
	["FX axe_strike (defender)", "res://monsters/skeleton_defender/fx/skeleton_defender.sprite.axe_strike", "res://monsters/skeleton_defender/fx"],
]

func _initialize() -> void:
	print("=== Spine content bounds probe (local units, node scale = 0.5) ===")
	print("%-34s %10s %10s %10s %10s %8s %6s" % ["label", "y_min", "y_max", "x_min", "x_max", "height", "slots"])
	for t in TARGETS:
		var label: String = str(t[0])
		var base: String = str(t[1])
		var png_dir: String = str(t[2])
		var skel_path: String = base + ".skel"
		var atlas_path: String = base + ".atlas"
		if not FileAccess.file_exists(skel_path) or not FileAccess.file_exists(atlas_path):
			print("%-34s  [MISSING]" % label)
			continue
		var sp := SpinePlayer.new()
		root.add_child(sp)
		sp.load_character(skel_path, atlas_path, png_dir)
		var anims: Array = sp.skel_data.get("animations", [])
		if not anims.is_empty():
			sp.play(anims[0].name, false)
			sp._update_pose()
		var r := _content_bounds(sp)
		if r.size == Vector2.ZERO:
			print("%-34s  [NO GEOMETRY]" % label)
		else:
			print("%-34s %10.1f %10.1f %10.1f %10.1f %8.1f %6d" % [
				label,
				r.position.y, r.end.y, r.position.x, r.end.x, r.size.y, sp.get_child_count()
			])
		sp.free()
	print("=== done ===")
	quit()

# 计算节点本地空间中"所有已绘制几何"的包围盒
func _content_bounds(sp: Node2D) -> Rect2:
	var minv := Vector2(INF, INF)
	var maxv := Vector2(-INF, -INF)
	for c in sp.get_children():
		if c is Polygon2D:
			var poly := c as Polygon2D
			for p in poly.polygon:
				minv = minv.min(p)
				maxv = maxv.max(p)
		elif c is Sprite2D:
			var spr := c as Sprite2D
			var rect: Rect2 = spr.get_rect()
			var corners: Array[Vector2] = [
				rect.position,
				Vector2(rect.end.x, rect.position.y),
				Vector2(rect.position.x, rect.end.y),
				rect.end,
			]
			for corner in corners:
				var p: Vector2 = spr.transform * corner
				minv = minv.min(p)
				maxv = maxv.max(p)
	if minv.x == INF:
		return Rect2()
	return Rect2(minv, maxv - minv)
