# SpinePlayer.gd — 渲染 Spine 2.1.27 骨骼动画角色
# 使用 SpineSkel + SpineAtlas 解析数据，以 Sprite2D 子节点渲染每个身体部位
extends Node2D
class_name SpinePlayer

# ─── 公共属性 ─────────────────────────────────────────────────────────────────
var skel_data: Dictionary = {} # SpineSkel.parse() 结果
var atlas_regions: Dictionary = {} # SpineAtlas.parse() 结果

# 当前动画状态
var current_anim: SpineSkel.SpineAnimation = null
var anim_time: float = 0.0
var looping: bool = true
var current_skel_path: String = ""

# ─── 内部状态 ─────────────────────────────────────────────────────────────────
var _sprites: Array = [] # 按槽序排列的 Sprite2D 或 Polygon2D
var _bone_world: Array = [] # 每根骨骼的世界变换 Transform2D
var _atlas_rot_corrections: Array = [] # atlas region.rotate=true 时需 +90° CW 补偿
var _slot_is_mesh: Array = [] # 该槽是否为网格（Mesh/SkinnedMesh），用 Polygon2D 渲染
var _slot_region: Array = [] # 网格槽对应的图集 Region（用于 UV 映射），否则 null
var _loaded: bool = false

# Spine Y 轴与 Godot Y 轴方向相反，需翻转
const SPINE_TO_GODOT_SCALE := Vector2(1.0, -1.0)

# ─── 加载接口 ─────────────────────────────────────────────────────────────────

# skel_path: res://characters/crusader/anim/crusader.sprite.idle.skel
# atlas_path: res://characters/crusader/anim/crusader.sprite.idle.atlas
# png_dir:   res://characters/crusader/crusader_A/anim  (含 PNG 的目录)
func load_character(skel_path: String, atlas_path: String, png_dir: String) -> void:
	if current_skel_path == skel_path and _loaded:
		return
	current_skel_path = skel_path
	_clear_sprites()
	_loaded = false

	# 1. 解析骨骼文件
	skel_data = SpineSkel.parse(skel_path)
	if skel_data.is_empty():
		push_error("SpinePlayer: 无法解析 " + skel_path)
		return

	# 2. 解析图集文件
	var atlas_file = FileAccess.open(atlas_path, FileAccess.READ)
	if atlas_file == null:
		push_error("SpinePlayer: 无法打开 " + atlas_path)
		return
	var atlas_text = atlas_file.get_as_text()
	atlas_file.close()
	atlas_regions = SpineAtlas.parse(atlas_text, png_dir)

	# 3. 创建 Sprite2D 节点
	_build_sprites()
	_loaded = true

# 切换动画
func play(anim_name: String, loop: bool = true) -> void:
	if not _loaded:
		return
	var anims: Array = skel_data.get("animations", [])
	for a in anims:
		if a.name == anim_name:
			current_anim = a
			anim_time = 0.0
			looping = loop
			_update_pose() # 强制立即计算首帧姿势，防止白白闪烁或一帧的零位移
			return
	# 找不到动画则只显示默认姿势
	current_anim = null
	anim_time = 0.0
	_update_pose() # 强制更新到默认姿势

# 跳转到指定时间（秒）
func set_time(t: float) -> void:
	anim_time = t
	_update_pose()

# ─── 帧更新 ──────────────────────────────────────────────────────────────────

# ─── 调试绘制 ─────────────────────────────────────────────────────────────────

func _process(delta: float) -> void:
	if not _loaded:
		return

	anim_time += delta
	if looping and current_anim and anim_time >= current_anim.duration:
		anim_time = fmod(anim_time, current_anim.duration)

	_update_pose()

# ─── 姿势计算 ─────────────────────────────────────────────────────────────────

func _update_pose() -> void:
	var bones: Array = skel_data.get("bones", [])
	var slots: Array = skel_data.get("slots", [])
	var attachments: Dictionary = skel_data.get("attachments", {})

	# 1. 计算每根骨骼的局部变换（含动画偏移）
	var local_transforms: Array = []
	for i in range(bones.size()):
		var bd: SpineSkel.BoneData = bones[i]
		var local_rot = deg_to_rad(bd.rotation)
		var local_x = bd.x
		var local_y = - bd.y # Spine Y 轴向上，Godot Y 轴向下

		# 应用动画时间线
		if current_anim != null:
			for bt in current_anim.bone_timelines:
				if bt.bone_index != i:
					continue
				if bt.timeline_type == 0: # 旋转
					var angle = _sample_rotate(bt, anim_time)
					local_rot += deg_to_rad(angle)
				elif bt.timeline_type == 1: # 平移
					var tv = _sample_translate(bt, anim_time)
					local_x += tv.x
					local_y += -tv.y
				elif bt.timeline_type == 2: # 缩放（暂不处理复杂情形）
					pass

		# 构建局部 Transform2D（Godot Y-down 等价于 T_godot = F·T_spine·F）
		# 正确矩阵: x_axis=(cosθ, -sinθ)·sx, y_axis=(sinθ, cosθ)·sy
		var sx = bd.scale_x if bd.scale_x != 0.0 else 1.0
		var sy = bd.scale_y if bd.scale_y != 0.0 else 1.0
		var cos_r = cos(local_rot)
		var sin_r = sin(local_rot)
		var t2d = Transform2D(
			Vector2(cos_r * sx, -sin_r * sx), # x 轴
			Vector2(sin_r * sy, cos_r * sy), # y 轴
			Vector2(local_x, local_y)
		)
		local_transforms.append(t2d)

	# 2. 累积世界变换
	_bone_world.resize(bones.size())
	for i in range(bones.size()):
		var bd: SpineSkel.BoneData = bones[i]
		if bd.parent_index < 0 or bd.parent_index >= _bone_world.size():
			_bone_world[i] = local_transforms[i]
		else:
			var parent_t: Transform2D = _bone_world[bd.parent_index]
			_bone_world[i] = parent_t * local_transforms[i]

	# 3. 更新每个 Sprite2D / Polygon2D 的变换
	for si in range(slots.size()):
		if si >= _sprites.size():
			break
		var node = _sprites[si]
		if node == null:
			continue

		var sd: SpineSkel.SlotData = slots[si]
		var ra: SpineSkel.RegionAttachment = attachments.get(si)
		if ra == null:
			node.visible = false
			continue

		# ── 网格槽：用 Polygon2D 计算每个顶点世界位置 ──
		if si < _slot_is_mesh.size() and _slot_is_mesh[si]:
			_update_mesh_poly(si, node, sd, ra)
			continue

		var sprite: Sprite2D = node
		sprite.visible = true

		# 骨骼世界变换
		var bone_t: Transform2D = _bone_world[sd.bone_index] if (sd.bone_index >= 0 and sd.bone_index < _bone_world.size()) else Transform2D.IDENTITY

		# 附件变换（与骨骼使用相同的 Godot Y-down 公式）
		var att_x = ra.x
		var att_y = - ra.y # Spine Y-up → Godot Y-down
		var att_sx = ra.scale_x if ra.scale_x != 0.0 else 1.0
		var att_sy = ra.scale_y if ra.scale_y != 0.0 else 1.0
		var att_r = deg_to_rad(ra.rotation) # 不取反，公式本身已处理 Y 翻转
		var cos_a = cos(att_r)
		var sin_a = sin(att_r)
		var att_t = Transform2D(
			Vector2(cos_a * att_sx, -sin_a * att_sx),
			Vector2(sin_a * att_sy, cos_a * att_sy),
			Vector2(att_x, att_y)
		)

		var world_t = bone_t * att_t
		# atlas rotate:true 补偿：+90° CW 恢复打包时的顺时针旋转
		if si < _atlas_rot_corrections.size() and _atlas_rot_corrections[si]:
			# +90° CW: Godot Transform2D(rot=π/2) → x=(0,1) y=(-1,0)
			world_t = world_t * Transform2D(Vector2(0, 1), Vector2(-1, 0), Vector2.ZERO)
		
		sprite.transform = world_t

# ─── 网格姿势计算 ─────────────────────────────────────────────────────────────

# 计算网格附件每个顶点的世界位置，更新 Polygon2D
func _update_mesh_poly(si: int, poly: Polygon2D, sd: SpineSkel.SlotData, ra: SpineSkel.RegionAttachment) -> void:
	var region: SpineAtlas.Region = _slot_region[si] if si < _slot_region.size() else null
	if region == null or poly.texture == null:
		poly.visible = false
		return

	var pts := PackedVector2Array()

	if ra.att_type == 2:
		# Mesh：顶点在插槽骨骼局部空间（Spine Y-up）
		var bone_t: Transform2D = _bone_world[sd.bone_index] if (sd.bone_index >= 0 and sd.bone_index < _bone_world.size()) else Transform2D.IDENTITY
		var verts: PackedFloat32Array = ra.mesh_vertices
		var n: int = verts.size() / 2
		for i in range(n):
			var vx := verts[i * 2]
			var vy := verts[i * 2 + 1]
			# Spine Y-up 局部点 → Godot Y-down 局部 → 经骨骼世界变换
			pts.append(bone_t * Vector2(vx, -vy))
	else:
		# SkinnedMesh：每顶点由多根骨骼按权重混合
		var mbones: Array = ra.mesh_bones
		for vbinds in mbones:
			var wpos := Vector2.ZERO
			for b in vbinds:
				var bi: int = b[0]
				var bx: float = b[1]
				var by: float = b[2]
				var bw: float = b[3]
				if bi < 0 or bi >= _bone_world.size():
					continue
				var bt: Transform2D = _bone_world[bi]
				wpos += (bt * Vector2(bx, -by)) * bw
			pts.append(wpos)

	if pts.size() < 3:
		poly.visible = false
		return

	# UV：区域归一化 UV（0..1）映射到图集页像素坐标
	var uvs := PackedVector2Array()
	var src: PackedFloat32Array = ra.mesh_uvs
	var rx := float(region.x)
	var ry := float(region.y)
	var rw := float(region.width)
	var rh := float(region.height)
	var uvn: int = src.size() / 2
	for i in range(uvn):
		var u := src[i * 2]
		var v := src[i * 2 + 1]
		var px: float
		var py: float
		if region.rotate:
			# 旋转区域：页面占位框是 height 宽 × width 高
			# u 沿原图宽(width) → 页面竖直方向；v 沿原图高(height) → 页面水平方向
			px = rx + v * rh
			py = ry + (1.0 - u) * rw
		else:
			px = rx + u * rw
			py = ry + v * rh
		uvs.append(Vector2(px, py))

	# 三角形索引拆为 Polygon2D 的子多边形数组
	var tris: PackedInt32Array = ra.mesh_triangles
	var poly_indices: Array = []
	var t: int = 0
	while t + 2 < tris.size():
		poly_indices.append(PackedInt32Array([tris[t], tris[t + 1], tris[t + 2]]))
		t += 3

	poly.visible = true
	poly.polygon = pts
	poly.uv = uvs
	poly.polygons = poly_indices

# ─── Sprite 构建 ─────────────────────────────────────────────────────────────

func _build_sprites() -> void:
	_clear_sprites()
	var slots: Array = skel_data.get("slots", [])
	var attachments: Dictionary = skel_data.get("attachments", {})

	for si in range(slots.size()):
		var ra: SpineSkel.RegionAttachment = attachments.get(si)

		# ── 网格附件（Mesh/SkinnedMesh）用 Polygon2D 渲染 ──
		if ra != null and (ra.att_type == 2 or ra.att_type == 3):
			var poly = Polygon2D.new()
			poly.name = "slot_%d" % si
			var mregion: SpineAtlas.Region = atlas_regions.get(ra.name)
			if mregion == null:
				mregion = atlas_regions.get(ra.path)
			if mregion != null:
				var page_tex: Texture2D = load(mregion.texture_path)
				if page_tex != null:
					poly.texture = page_tex
			add_child(poly)
			_sprites.append(poly)
			_slot_is_mesh.append(true)
			_slot_region.append(mregion)
			_atlas_rot_corrections.append(false)
			continue

		var sprite = Sprite2D.new()
		sprite.name = "slot_%d" % si

		# 检测路径含 NUL 字节（Godot 会将其替换为 U+FFFD）
		# 这表示 Mesh 附件被误读为 Region（数据损坏），放弃解析值
		if ra != null and ra.path.length() > 0 and (ra.path.unicode_at(0) == 0xFFFD or ra.path.unicode_at(0) == 0):
			ra = null

		# 若 skin 解析未能提供 RegionAttachment（Mesh/SkinnedMesh 类型无法解析），
		# 用 SlotData.attachment 名从 atlas 创建 fallback，以骨骼中心为原点显示
		if ra == null:
			var sd: SpineSkel.SlotData = slots[si]
			if sd.attachment != "":
				var region: SpineAtlas.Region = atlas_regions.get(sd.attachment)
				if region != null:
					var fallback := SpineSkel.RegionAttachment.new()
					fallback.slot_index = si
					fallback.name = sd.attachment
					fallback.path = sd.attachment
					fallback.x = 0.0
					fallback.y = 0.0
					fallback.scale_x = 0.5
					fallback.scale_y = 0.5
					# rotation=0: 对 rotate=false 部件显示于骨骼方向；
					# 对 rotate=true 部件，atlas校正(+90°CW)将 atlas 旋转纠正，仍显示于骨骼方向
					fallback.rotation = 0.0
					fallback.rotate = region.rotate
					attachments[si] = fallback
					ra = fallback
					#print("[SpinePlayer]   slot_%d: fallback created for '%s' (rotate=%s)" % [si, sd.attachment, region.rotate])
				else:
					pass # print("[SpinePlayer]   slot_%d: region not found for '%s'" % [si, sd.attachment])

		if ra != null:
			var needs_rot = _apply_region_texture(sprite, ra)
			_atlas_rot_corrections.append(needs_rot)
			#print("[SpinePlayer]   slot_%d: loaded '%s', rot_needed=%s" % [si, ra.name, needs_rot])
		else:
			sprite.visible = false
			_atlas_rot_corrections.append(false)
			#print("[SpinePlayer]   slot_%d: no attachment, hidden" % si)

		add_child(sprite)
		_sprites.append(sprite)
		_slot_is_mesh.append(false)
		_slot_region.append(null)


func _apply_region_texture(sprite: Sprite2D, ra: SpineSkel.RegionAttachment) -> bool:
	# 查找图集区域
	var region_name = ra.path if ra.path != "" else ra.name
	var region: SpineAtlas.Region = atlas_regions.get(region_name)
	if region == null:
		region = atlas_regions.get(ra.name)
	if region == null:
		# BoundingBox 或其他无纹理 attachment，标记为不可见
		sprite.visible = false
		sprite.texture = null
		return false

	# 加载 PNG 纹理
	var tex: Texture2D = load(region.texture_path)
	if tex == null:
		sprite.visible = false
		return false

	# 创建 AtlasTexture（从大图中裁剪出这个区域）
	# rotate:true 时，atlas 内存储的是原始尺寸旋转 90° CW 后的像素区域
	# 因此 Rect2 需要交换 width/height 才能采样到正确像素
	var atlas_tex = AtlasTexture.new()
	atlas_tex.atlas = tex
	if region.rotate:
		atlas_tex.region = Rect2(region.x, region.y, region.height, region.width)
		#print("[SpinePlayer]     -> AtlasTexture region (rotated): xy=(%d,%d), size=(%d,%d)" % [region.x, region.y, region.height, region.width])
	else:
		atlas_tex.region = Rect2(region.x, region.y, region.width, region.height)
		#print("[SpinePlayer]     -> AtlasTexture region: xy=(%d,%d), size=(%d,%d)" % [region.x, region.y, region.width, region.height])
	
	sprite.texture = atlas_tex
	sprite.centered = true # Spine 附件偏移以区域中心为原点
	#print("[SpinePlayer]     -> Sprite configured: name=%s, tex_size=%s, centered=true" % [ra.name, atlas_tex.get_size()])
	return region.rotate

func _clear_sprites() -> void:
	for child in get_children():
		child.queue_free()
	_sprites.clear()
	_bone_world.clear()
	_atlas_rot_corrections.clear()
	_slot_is_mesh.clear()
	_slot_region.clear()

# ─── 动画采样 ─────────────────────────────────────────────────────────────────

# 采样旋转时间线，返回度数
func _sample_rotate(bt: SpineSkel.BoneTimeline, t: float) -> float:
	var kfs: Array = bt.keyframes
	if kfs.is_empty():
		return 0.0
	if t <= kfs[0].time:
		return kfs[0].value
	if t >= kfs[kfs.size() - 1].time:
		return kfs[kfs.size() - 1].value

	for i in range(kfs.size() - 1):
		var a: SpineSkel.RotateKeyframe = kfs[i]
		var b: SpineSkel.RotateKeyframe = kfs[i + 1]
		if t >= a.time and t < b.time:
			if a.curve == 1: # stepped
				return a.value
			var pct = (t - a.time) / (b.time - a.time)
			# 归一化角度差到 [-180, 180]，避免跨越 ±180° 时绕远路旋转
			var diff = fmod(b.value - a.value + 540.0, 360.0) - 180.0
			return a.value + diff * pct
	return kfs[kfs.size() - 1].value

# 采样平移时间线，返回 Vector2
func _sample_translate(bt: SpineSkel.BoneTimeline, t: float) -> Vector2:
	var kfs: Array = bt.keyframes
	if kfs.is_empty():
		return Vector2.ZERO
	if t <= kfs[0].time:
		return Vector2(kfs[0].tx, kfs[0].ty)
	if t >= kfs[kfs.size() - 1].time:
		var last: SpineSkel.TranslateKeyframe = kfs[kfs.size() - 1]
		return Vector2(last.tx, last.ty)

	for i in range(kfs.size() - 1):
		var a: SpineSkel.TranslateKeyframe = kfs[i]
		var b: SpineSkel.TranslateKeyframe = kfs[i + 1]
		if t >= a.time and t < b.time:
			if a.curve == 1:
				return Vector2(a.tx, a.ty)
			var pct = (t - a.time) / (b.time - a.time)
			return Vector2(a.tx + (b.tx - a.tx) * pct, a.ty + (b.ty - a.ty) * pct)
	var last2: SpineSkel.TranslateKeyframe = kfs[kfs.size() - 1]
	return Vector2(last2.tx, last2.ty)
