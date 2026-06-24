# SpineSkel.gd — 解析 Spine 2.1.27 二进制 .skel 文件
# 每个 .skel 文件包含: 骨骼层次、插槽、皮肤附件、动画时间线
class_name SpineSkel

# ─── 数据结构 ───────────────────────────────────────────────────────────────

class BoneData:
	var name: String
	var parent_index: int  # -1 = 无父骨骼
	var x: float
	var y: float
	var scale_x: float
	var scale_y: float
	var rotation: float    # 度
	var length: float
	var flip_x: bool
	var flip_y: bool
	var inherit_scale: bool
	var inherit_rotation: bool

class SlotData:
	var name: String
	var bone_index: int
	var attachment: String  # 默认附件名（可为空）

class RegionAttachment:
	var slot_index: int
	var name: String
	var path: String        # 图集区域名（为空时使用 name）
	var x: float    
	var y: float
	var scale_x: float
	var scale_y: float
	var rotation: float
	var width: float
	var height: float
	var rotate: bool        # 图集中该区域是否旋转了 90°
	# ── 网格附件数据 ──
	var att_type: int = 0   # 0=Region, 1=BoundingBox, 2=Mesh, 3=SkinnedMesh
	var mesh_uvs: PackedFloat32Array       # 区域归一化 UV（0..1），u,v 交替
	var mesh_triangles: PackedInt32Array   # 三角形索引
	var mesh_vertices: PackedFloat32Array  # Mesh: 插槽骨骼局部空间顶点 x,y 交替（Spine Y-up）
	var mesh_bones: Array                  # SkinnedMesh: 每顶点 Array[[bone_index,x,y,weight], ...]

class Keyframe:
	var time: float
	var curve: int          # 0=线性, 1=阶梯, 2=贝塞尔

class RotateKeyframe extends Keyframe:
	var value: float        # 度

class TranslateKeyframe extends Keyframe:
	var tx: float
	var ty: float

class ScaleKeyframe extends Keyframe:
	var sx: float
	var sy: float

class BoneTimeline:
	var bone_index: int
	var timeline_type: int  # 0=旋转, 1=平移, 2=缩放
	var keyframes: Array    # Array[RotateKeyframe|TranslateKeyframe|ScaleKeyframe]

class SpineAnimation:
	var name: String
	var bone_timelines: Array  # Array[BoneTimeline]
	var duration: float

# ─── 公共解析接口 ────────────────────────────────────────────────────────────

# 解析 .skel 文件，返回包含骨骼/插槽/附件/动画的字典
# 字典键: "bones", "slots", "attachments", "animations"
static func parse(file_path: String) -> Dictionary:
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		push_error("SpineSkel: 无法打开文件 " + file_path)
		return {}

	var bytes = file.get_buffer(file.get_length())
	file.close()

	var reader = _Reader.new(bytes)
	return _parse_internal(reader)

# ─── 内部解析 ────────────────────────────────────────────────────────────────

static func _parse_internal(r: _Reader) -> Dictionary:
	# ── 1. 标题 ──
	var hash    = r.read_string()   # 哈希字符串
	var version = r.read_string()   # "2.1.27"
	@warning_ignore("unused_variable")
	var width   = r.read_float()
	@warning_ignore("unused_variable")
	var height  = r.read_float()
	var non_essential = r.read_bool()
	if non_essential:
		r.read_float()    # fps
		r.read_string()   # imagesPath

	# ── 2. 骨骼 ──
	var bone_count = r.read_varint()
	var bones: Array = []
	for i in range(bone_count):
		var bd = BoneData.new()
		bd.name              = r.read_string()
		var parent_raw       = r.read_varint()  # 0=无父, 1=bones[0], ...
		bd.parent_index      = parent_raw - 1   # 转换为 -1 表示无父
		bd.x                 = r.read_float()
		bd.y                 = r.read_float()
		bd.scale_x           = r.read_float()
		bd.scale_y           = r.read_float()
		bd.rotation          = r.read_float()
		bd.length            = r.read_float()
		bd.flip_x            = r.read_bool()
		bd.flip_y            = r.read_bool()
		bd.inherit_scale     = r.read_bool()
		bd.inherit_rotation  = r.read_bool()
		bones.append(bd)

	# ── 3. IK 约束（跳过，Darkest Dungeon 使用 count=0）──
	var ik_count = r.read_varint()
	# 如果有 IK 约束，跳过（本项目不使用）
	for _i in range(ik_count):
		r.read_string()  # name
		r.read_varint()  # boneCount
		r.skip(1)        # target_bone

	# ── 4. 插槽 ──
	var slot_count = r.read_varint()
	var slots: Array = []
	for _i in range(slot_count):
		var sd = SlotData.new()
		sd.name        = r.read_string()
		sd.bone_index  = r.read_varint()
		r.skip(4)       # color RGBA（跳过，全白）
		sd.attachment  = r.read_string_or_empty()
		r.skip(1)       # blendMode（Spine 2.1.x 每个槽位固定有此字节）
		slots.append(sd)

	# ── 5. 默认皮肤（全类型附件）──
	# Spine 2.1.27 格式：每个 attachment = att_name(rs) + outer_path(rs,null) + att_type(rv)
	# Region(0): rotate(bool)+x+y+sx+sy+rot+w+h+color(4)  [无 inner_path，无哨兵]
	# Mesh(2):   inner_path(rs) + uvc(rv) + uvc floats + tric(rv) + tric*2 bytes
	#            + vc(rv,float数量) + vc floats + SENTINEL(4字节0xFFFFFFFF) + hull(rv)
	# SkinnedMesh(3): 同 Mesh，但 vc floats 为 boneCount/boneIdx/x/y/weight 混合格式
	# BoundingBox(1): inner_path(rs) + vc(rv) + vc*4 bytes
	var attachments: Dictionary = {}  # slot_index -> RegionAttachment
	var skin_slot_count = r.read_varint()
	for _si in range(skin_slot_count):
		var slot_idx  = r.read_varint()
		var att_count = r.read_varint()
		for _ai in range(att_count):
			var att_name = r.read_string()
			@warning_ignore("unused_variable")
			var _outer   = r.read_string()  # outer_path（始终为 null）
			var att_type = r.read_varint()  # 真实类型：0=Region,1=BBox,2=Mesh,3=SkMesh

			if att_type == 0:  # Region — 无 inner_path
				var ra        = RegionAttachment.new()
				ra.slot_index = slot_idx
				ra.name       = att_name
				ra.path       = att_name
				ra.att_type   = 0
				ra.rotate     = r.read_bool()
				ra.x          = r.read_float()
				ra.y          = r.read_float()
				ra.scale_x    = r.read_float()
				ra.scale_y    = r.read_float()
				ra.rotation   = r.read_float()
				ra.width      = r.read_float()
				ra.height     = r.read_float()
				r.skip(4)     # color RGBA
				attachments[slot_idx] = ra

			elif att_type == 2:  # Mesh — 有 inner_path，有哨兵
				r.read_string()  # inner_path（null）
				var uvc2 = r.read_varint()
				var uvs2 := PackedFloat32Array()
				for _u2 in range(uvc2): uvs2.append(r.read_float())
				var tric2 = r.read_varint()
				var tris2 := PackedInt32Array()
				for _t2 in range(tric2):
					tris2.append(r.read_short())
				var vc2 = r.read_varint()  # 浮点数总数（= 顶点数 * 2）
				var verts2 := PackedFloat32Array()
				for _v2 in range(vc2): verts2.append(r.read_float())
				r.skip(4)   # sentinel 0xFFFFFFFF
				r.read_varint()  # hull
				var ra2       = RegionAttachment.new()
				ra2.slot_index = slot_idx; ra2.name = att_name; ra2.path = att_name
				ra2.att_type   = 2
				ra2.rotate     = false
				ra2.mesh_uvs       = uvs2
				ra2.mesh_triangles = tris2
				ra2.mesh_vertices  = verts2
				attachments[slot_idx] = ra2

			elif att_type == 3:  # SkinnedMesh — 有 inner_path，混合顶点格式，有哨兵
				r.read_string()  # inner_path（null）
				var uvc3 = r.read_varint()
				var uvs3 := PackedFloat32Array()
				for _u3 in range(uvc3): uvs3.append(r.read_float())
				var tric3 = r.read_varint()
				var tris3 := PackedInt32Array()
				for _t3 in range(tric3):
					tris3.append(r.read_short())
				var vc3 = r.read_varint()  # 浮点数总数
				var fi3 := 0
				var mesh_bones3: Array = []   # 每顶点 Array[[bone_index,x,y,weight], ...]
				while fi3 < vc3:
					var bc3 := int(r.read_float() + 0.5); fi3 += 1
					var vbinds: Array = []
					for _j3 in range(bc3):
						var bi3 := int(r.read_float() + 0.5); fi3 += 1
						var vx3 := r.read_float(); var vy3 := r.read_float()
						var ww3 := r.read_float(); fi3 += 3
						vbinds.append([bi3, vx3, vy3, ww3])
					mesh_bones3.append(vbinds)
				r.skip(4)   # sentinel 0xFFFFFFFF
				r.read_varint()  # hull
				var ra3       = RegionAttachment.new()
				ra3.slot_index = slot_idx; ra3.name = att_name; ra3.path = att_name
				ra3.att_type   = 3
				ra3.rotate     = false
				ra3.mesh_uvs       = uvs3
				ra3.mesh_triangles = tris3
				ra3.mesh_bones     = mesh_bones3
				attachments[slot_idx] = ra3

			else:  # BoundingBox(1) 或未知类型
				r.read_string()  # inner_path
				var vc_bb = r.read_varint()
				r.skip(vc_bb * 4)
				# BoundingBox 也创建一个占位 RegionAttachment（无纹理，不渲染）
				var ra_bb       = RegionAttachment.new()
				ra_bb.slot_index = slot_idx; ra_bb.name = att_name; ra_bb.path = att_name
				ra_bb.att_type   = 1
				ra_bb.rotate     = false
				attachments[slot_idx] = ra_bb
		if r.failed:
			break

	# ── 6. 命名皮肤（跳过）──
	var named_skin_count = r.read_varint()
	for _nsi in range(named_skin_count):
		r.read_string()  # 皮肤名
		var ns_ssc = r.read_varint()
		for _nssi in range(ns_ssc):
			r.read_varint()  # slot_idx
			var ns_ac = r.read_varint()
			for _nsai in range(ns_ac):
				r.read_string()  # att_name
				r.read_string()  # outer_path
				var ns_at = r.read_varint()
				_skip_attachment_fields(r, ns_at)

	# ── 7. 事件（跳过）──
	var event_count = r.read_varint()
	for _ei in range(event_count):
		r.read_string()   # name
		r.read_varint()   # intValue
		r.read_float()    # floatValue
		r.read_string()   # stringValue

	# ── 8. 动画（顺序解析）──
	var anim_count = r.read_varint()

	var animations: Array = []
	for _ai in range(anim_count):
		if r.failed: break
		var anim = _parse_animation(r)
		if anim != null:
			animations.append(anim)

	return {
		"bones": bones,
		"slots": slots,
		"attachments": attachments,
		"animations": animations,
		"version": version,
	}

# 跳过附件的字段（用于跳过命名皮肤附件）
static func _skip_attachment_fields(r: _Reader, att_type: int) -> void:
	if att_type == 0:   # Region
		r.skip(1)       # rotate bool
		r.skip(7 * 4)   # x,y,sx,sy,rotation,w,h
		r.skip(4)       # color
	elif att_type == 2: # Mesh
		r.read_string() # inner_path
		var uvc = r.read_varint(); r.skip(uvc * 4)
		var tric = r.read_varint(); r.skip(tric * 2)
		var vc = r.read_varint(); r.skip(vc * 4)
		r.skip(4)       # sentinel
		r.read_varint() # hull
	elif att_type == 3: # SkinnedMesh
		r.read_string() # inner_path
		var uvc = r.read_varint(); r.skip(uvc * 4)
		var tric = r.read_varint(); r.skip(tric * 2)
		var vc = r.read_varint(); r.skip(vc * 4)
		r.skip(4)       # sentinel
		r.read_varint() # hull
	else:               # BoundingBox 或未知
		r.read_string() # inner_path
		var vc = r.read_varint(); r.skip(vc * 4)

# 解析单个动画（从 r 当前位置）
static func _parse_animation(r: _Reader) -> SpineAnimation:
	var anim = SpineAnimation.new()
	anim.name = r.read_string()
	if anim.name == null or anim.name == "":
		return null
	anim.bone_timelines = []
	anim.duration = 0.0

	# Spine 2.x 格式: 槽位时间线在前，骨骼时间线在后
	if r.pos >= r.data.size():
		return anim

	# ── 槽位时间线（跳过，不影响运动，但必须消耗正确字节数）──
	var slot_tl_count = r.read_varint()

	for _si2 in range(slot_tl_count):
		if r.failed:
			break
		r.read_varint()           # slot index
		var stl_count = r.read_varint()
		for _sti in range(stl_count):
			if r.failed:
				break
			var stl_type = r.data[r.pos]; r.pos += 1
			var sfc      = r.read_varint()
			if stl_type == 0:    # attachment: time(float) + name(string)，无 curve
				for _k in range(sfc):
					r.read_float()
					r.read_string()
			elif stl_type == 1:  # color: time(float) + rgba(4 bytes) + curve(byte，最后帧除外)
				for _k in range(sfc):
					r.read_float()
					r.skip(4)
					if _k < sfc - 1:
						var cv2 = r.data[r.pos]; r.pos += 1
						if cv2 == 2:
							r.skip(16)
			else:
				r.failed = true
				break

	# ── 骨骼时间线 ──
	var bone_tl_count = r.read_varint()

	for _bi in range(bone_tl_count):
		if r.failed:
			break
		var bone_idx = r.read_varint()
		var tl_count = r.read_varint()
		for _ti in range(tl_count):
			if r.failed:
				break
			var raw_type  = r.data[r.pos]; r.pos += 1
			var frame_cnt = r.read_varint()
			# Spine 2.1.27 实际类型映射: 0=缩放 1=旋转 2=平移
			# 重新映射为内部约定: 0=旋转 1=平移 2=缩放
			var tl_type: int
			if raw_type == 0:
				tl_type = 2   # scale
			elif raw_type == 1:
				tl_type = 0   # rotate
			elif raw_type == 2:
				tl_type = 1   # translate
			else:
				tl_type = raw_type  # 未知，透传
			var bt        = BoneTimeline.new()
			bt.bone_index    = bone_idx
			bt.timeline_type = tl_type
			bt.keyframes     = []

			for _ki in range(frame_cnt):
				if r.failed:
					break
				var t = r.read_float()
				var is_last: bool = (_ki == frame_cnt - 1)
				var curve: int

				if tl_type == 0:  # 旋转 (raw=1)
					var kf    = RotateKeyframe.new()
					kf.time   = t
					kf.value  = r.read_float()
					if not is_last:
						curve     = r.data[r.pos]; r.pos += 1
						kf.curve  = curve
						if curve == 2:
							r.skip(16)
					bt.keyframes.append(kf)
					anim.duration = maxf(anim.duration, t)

				elif tl_type == 1:  # 平移 (raw=2)
					var kf = TranslateKeyframe.new()
					kf.time = t
					kf.tx   = r.read_float()
					kf.ty   = r.read_float()
					if not is_last:
						curve   = r.data[r.pos]; r.pos += 1
						kf.curve = curve
						if curve == 2:
							r.skip(16)
					bt.keyframes.append(kf)
					anim.duration = maxf(anim.duration, t)

				elif tl_type == 2:  # 缩放 (raw=0)
					var kf = ScaleKeyframe.new()
					kf.time = t
					kf.sx   = r.read_float()
					kf.sy   = r.read_float()
					if not is_last:
						curve   = r.data[r.pos]; r.pos += 1
						kf.curve = curve
						if curve == 2:
							r.skip(16)
					bt.keyframes.append(kf)
					anim.duration = maxf(anim.duration, t)

				else:

					r.failed = true
					break

			if not bt.keyframes.is_empty():
				anim.bone_timelines.append(bt)


	return anim

# ─── 字节流读取器 ─────────────────────────────────────────────────────────────

class _Reader:
	var data: PackedByteArray
	var pos: int = 0
	var failed: bool = false

	func _init(bytes: PackedByteArray) -> void:
		data = bytes
		pos = 0
		failed = false

	func skip(n: int) -> void:
		pos += n

	# 读取大端序 float
	func read_float() -> float:
		if pos + 4 > data.size():
			failed = true
			return 0.0
		var b0 = data[pos];     var b1 = data[pos+1]
		var b2 = data[pos+2];   var b3 = data[pos+3]
		pos += 4
		var bits: int = (b0 << 24) | (b1 << 16) | (b2 << 8) | b3
		# 将 32 位整数解释为 IEEE 754 float
		var tmp = PackedByteArray([b3, b2, b1, b0])  # 小端序
		return tmp.decode_float(0)

	# 读取优化 varint（LEB128，每字节7位，高位为延续标志）
	func read_varint() -> int:
		var result: int = 0
		var shift: int = 0
		while true:
			if pos >= data.size():
				failed = true
				return result
			var b = data[pos]; pos += 1
			result |= (b & 0x7F) << shift
			shift += 7
			if (b & 0x80) == 0:
				break
		return result

	# 读取布尔值（1 字节）
	func read_bool() -> bool:
		if pos >= data.size():
			failed = true
			return false
		var b = data[pos]; pos += 1
		return b != 0

	# 读取大端序无符号 short（2 字节，网格三角形索引）
	func read_short() -> int:
		if pos + 2 > data.size():
			failed = true
			return 0
		var b0 = data[pos]; var b1 = data[pos+1]
		pos += 2
		return (b0 << 8) | b1

	# 读取 Spine 字符串：varint byteCount, null if 0, empty if 1, else byteCount-1 chars
	func read_string() -> String:
		var byte_count = read_varint()
		if byte_count == 0:
			return ""   # null 当空字符串处理
		if byte_count == 1:
			return ""
		var length = byte_count - 1
		if pos + length > data.size():
			failed = true
			return ""
		var result = ""
		for i in range(length):
			result += char(data[pos + i])
		pos += length
		return result

	# 同 read_string，null 返回 ""
	func read_string_or_empty() -> String:
		return read_string()
