# SpineAtlas.gd — 解析 Spine 2.x 文本格式 .atlas 文件
# 格式: 页名行(无缩进无冒号), 页属性(无缩进有冒号), 区域名(无缩进无冒号), 区域属性(2空格缩进有冒号)
class_name SpineAtlas

class Region:
	var texture_path: String  # 相对于图集文件夹的 PNG 路径
	var x: int
	var y: int
	var width: int
	var height: int
	var rotate: bool   # atlas 中该区域是否旋转了 90 度
	var orig_w: int
	var orig_h: int
	var offset_x: int
	var offset_y: int

# 解析 atlas 文本内容，base_dir 是存放 PNG 的文件夹路径（res://...）
# 返回 Dictionary: region_name -> Region
static func parse(text: String, base_dir: String) -> Dictionary:
	var result: Dictionary = {}
	var lines = text.split("\n")
	var current_texture_path: String = ""
	var current_region_name: String = ""
	var in_page_header: bool = true  # 第一个非空行是页名

	for raw_line in lines:
		var line = raw_line.rstrip("\r")

		# 跳过空行（空行表示新页面开始）
		if line.strip_edges() == "":
			in_page_header = true
			current_region_name = ""
			continue

		# 页头：第一个非空行是 PNG 文件名（无缩进、无冒号）
		if in_page_header:
			if not line.begins_with(" ") and ":" not in line:
				current_texture_path = base_dir + "/" + line.strip_edges()
				in_page_header = false
			# 页属性行（size:, format:, filter:, repeat:）跳过
			continue

		# 区域名行: 无缩进，无冒号
		if not line.begins_with(" ") and ":" not in line:
			current_region_name = line.strip_edges()
			if current_region_name != "":
				var r = Region.new()
				r.texture_path = current_texture_path
				r.rotate = false
				result[current_region_name] = r
			continue

		# 区域属性行: 2 空格缩进 + "key: value"
		if line.begins_with("  ") and ":" in line:
			if current_region_name == "":
				continue
			var colon_pos = line.find(":")
			var key = line.substr(0, colon_pos).strip_edges()
			var value = line.substr(colon_pos + 1).strip_edges()

			var region: Region = result.get(current_region_name)
			if region == null:
				continue

			match key:
				"rotate":
					region.rotate = (value == "true")
				"xy":
					var parts = value.split(",")
					if parts.size() >= 2:
						region.x = int(parts[0].strip_edges())
						region.y = int(parts[1].strip_edges())
				"size":
					var parts = value.split(",")
					if parts.size() >= 2:
						region.width = int(parts[0].strip_edges())
						region.height = int(parts[1].strip_edges())
				"orig":
					var parts = value.split(",")
					if parts.size() >= 2:
						region.orig_w = int(parts[0].strip_edges())
						region.orig_h = int(parts[1].strip_edges())
				"offset":
					var parts = value.split(",")
					if parts.size() >= 2:
						region.offset_x = int(parts[0].strip_edges())
						region.offset_y = int(parts[1].strip_edges())

	return result
