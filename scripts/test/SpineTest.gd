# SpineTest.gd — 调试脚本：加载并展示 crusader.sprite.idle 的拼接状态
# 挂载到任意 Node2D 场景节点即可运行
extends Node2D

const SKEL_PATH  := "res://crusader/anim/crusader.sprite.idle.skel"
const ATLAS_PATH := "res://crusader/anim/crusader.sprite.idle.atlas"
const PNG_DIR    := "res://crusader/crusader_A/anim"

var _sp: SpinePlayer = null

func _ready() -> void:
	# 居中显示
	var viewport_size = get_viewport_rect().size
	position = Vector2(viewport_size.x * 0.5, viewport_size.y * 0.7)

	# ── 1. 先解析 skel，打印诊断信息 ──────────────────────────────
	var skel = SpineSkel.parse(SKEL_PATH)
	if skel.is_empty():
		push_error("[SpineTest] skel 解析失败")
		return

	var bones: Array       = skel.get("bones", [])
	var slots: Array       = skel.get("slots", [])
	var attachments: Dictionary = skel.get("attachments", {})
	var animations: Array  = skel.get("animations", [])

	print("=== SpineTest 诊断 ===")
	print("骨骼数: %d" % bones.size())
	print("槽位数: %d" % slots.size())
	print("Region 附件数: %d" % attachments.size())
	print("动画数: %d" % animations.size())

	for i in attachments.keys():
		var ra: SpineSkel.RegionAttachment = attachments[i]
		print("  slot[%02d] %-20s  path=%s  rotate=%s  x=%.1f y=%.1f sx=%.3f sy=%.3f rot=%.2f" % [
			i, ra.name, ra.path if ra.path != "" else "(same as name)",
			str(ra.rotate), ra.x, ra.y, ra.scale_x, ra.scale_y, ra.rotation
		])

	# ── 2. 解析 atlas，打印找到的 region ─────────────────────────
	var atlas_file = FileAccess.open(ATLAS_PATH, FileAccess.READ)
	if atlas_file == null:
		push_error("[SpineTest] 无法打开 atlas: " + ATLAS_PATH)
		return
	var atlas_text = atlas_file.get_as_text()
	atlas_file.close()
	var atlas_regions: Dictionary = SpineAtlas.parse(atlas_text, PNG_DIR)

	print("\natlas region 数: %d" % atlas_regions.size())
	for rname in atlas_regions.keys():
		var r: SpineAtlas.Region = atlas_regions[rname]
		print("  %-22s  rot=%-5s  xy=(%d,%d)  size=%dx%d  tex=%s" % [
			rname, str(r.rotate), r.x, r.y, r.width, r.height,
			r.texture_path.get_file()
		])

	# ── 3. 检查每个 attachment 能否在 atlas 找到对应 region ──────
	print("\n附件与 atlas 匹配检查:")
	for i in attachments.keys():
		var ra: SpineSkel.RegionAttachment = attachments[i]
		var key = ra.path if ra.path != "" else ra.name
		var found: bool = atlas_regions.has(key) or atlas_regions.has(ra.name)
		print("  slot[%02d] %-20s  → %s" % [i, ra.name, "OK" if found else "MISSING in atlas!"])

	# ── 4. 创建 SpinePlayer 展示 ──────────────────────────────────
	_sp = SpinePlayer.new()
	_sp.scale = Vector2(0.5, 0.5)
	add_child(_sp)
	_sp.load_character(SKEL_PATH, ATLAS_PATH, PNG_DIR)
	# 不播放动画，只显示 t=0 的默认姿势
	_sp.set_time(0.0)

	print("\n[SpineTest] SpinePlayer 子节点数: %d" % _sp.get_child_count())
	var visible_count := 0
	for child in _sp.get_children():
		if child is Sprite2D and child.visible:
			visible_count += 1
	print("[SpineTest] 可见 Sprite2D 数: %d" % visible_count)
	print("=== 诊断完毕 ===")

func _input(event: InputEvent) -> void:
	# 按空格切换动画播放/暂停
	if event is InputEventKey and event.pressed and event.keycode == KEY_SPACE:
		if _sp == null:
			return
		if _sp.current_anim == null:
			_sp.play("idle")
			print("[SpineTest] 开始播放 idle 动画")
		else:
			_sp.current_anim = null
			print("[SpineTest] 暂停动画")
