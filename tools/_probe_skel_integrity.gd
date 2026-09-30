extends SceneTree

# 临时诊断脚本（非游戏运行时代码，可删）
# 用途：递归解析项目内所有 .skel，找出"字节流错位"的资源——
#       错位症状：插槽名出现不可打印字符 / attachments=0 / anims=0，
#       控制台会伴随大量 "Unicode parsing error ... Unexpected NUL character"。
# 运行：godot --headless --path <项目> --script res://tools/_probe_skel_integrity.gd
# 当前基线（168 个 .skel）：仅 crusader.sprite.walk.skel 为已知历史遗留（anims=0）

var _total := 0
var _bad := 0

func _initialize() -> void:
	for root_dir in ["res://monsters", "res://characters", "res://death_medium"]:
		_scan(root_dir)
	print("[SKEL] ===== 共解析 %d 个 .skel，异常 %d 个 =====" % [_total, _bad])
	quit(0 if _bad == 0 else 1)

func _scan(dir_path: String) -> void:
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return
	dir.list_dir_begin()
	var name := dir.get_next()
	while name != "":
		if name.begins_with("."):
			name = dir.get_next()
			continue
		var full := dir_path.path_join(name)
		if dir.current_is_dir():
			_scan(full)
		elif name.ends_with(".skel"):
			_check(full)
		name = dir.get_next()
	dir.list_dir_end()

func _check(path: String) -> void:
	_total += 1
	var data := SpineSkel.parse(path)
	var bones: Array = data.get("bones", [])
	var slots: Array = data.get("slots", [])
	var anims: Array = data.get("animations", [])
	var attach_count: int = (data.get("attachments", {}) as Dictionary).size()
	# 插槽名必须是可打印 ASCII
	var garbled := 0
	for slot in slots:
		var sname := str(slot.name)
		if sname == "":
			continue
		for i in range(sname.length()):
			var c := sname.unicode_at(i)
			if c < 32 or c >= 127:
				garbled += 1
				break
	var problems := PackedStringArray()
	if garbled > 0:
		problems.append("插槽名乱码 %d 个" % garbled)
	if attach_count == 0:
		problems.append("attachments=0")
	if anims.is_empty():
		problems.append("anims=0")
	if not problems.is_empty():
		_bad += 1
		print("[SKEL] BAD  %s (bones=%d slots=%d anims=%d) → %s" % [path, bones.size(), slots.size(), anims.size(), ", ".join(problems)])
