extends Node

# ============================================================
# 游戏开始界面（复刻《暗黑地牢》原版前端，素材全部取自 res://fe_flow/）
#
#   ① 闪屏：demo_splash.png —— 点击 / 任意按键 / 超时 2.4s 后跳过
#      （只在本次运行“首次”进入开始界面时播放，失败/通关返回时不再闪）
#   ② 主菜单：title_bg（黑天 + 红色辉光）+ title_house（宅邸剪影）+ sky01/02（流云）
#             + DEMO 标志 + 地图尺寸选择 + START 按钮
#   ③ START：写入固定初始编队（十字军 / 强盗 / 神秘学者 / 训犬师）→ 开新局 → 地图
#
# 版式坐标直接沿用 fe_flow.layout.darkest 的原始数值（1920×2160 虚拟空间）：
# 主菜单页 = 该空间的下半屏（y 1080~2160），故“页面内 y = 布局 y - PAGE_SCROLL”。
# 所有元素画在 1920×1080 的 DesignRoot 上，再按窗口尺寸等比缩放并居中。
# ============================================================

const FE_FLOW_DIR := "res://fe_flow/"
const SPLASH_IMAGE := FE_FLOW_DIR + "demo_splash.png"
const TITLE_BG_IMAGE := FE_FLOW_DIR + "title_bg.png"
const TITLE_HOUSE_IMAGE := FE_FLOW_DIR + "title_house.png"
const SKY_FAR_IMAGE := FE_FLOW_DIR + "sky01.png"
const SKY_NEAR_IMAGE := FE_FLOW_DIR + "sky02.png"
const BUTTON_ART := FE_FLOW_DIR + "start_button.png"

# demo_splash.png 里 logo 的实测包围盒（剔除整幅黑底，便于单独当标题摆放）
const LOGO_REGION := Rect2(510, 199, 962, 550)

const DESIGN_SIZE := Vector2(1920.0, 1080.0)
const PAGE_SCROLL := 1080.0 # fe_flow 虚拟空间 → 主菜单页的纵向偏移

# fe_flow.layout.darkest 的原始坐标（均按“元素左上角 / 原始位置”直接使用）
const HOUSE_TOP_LEFT := Vector2(0.0, 1486.0)
const HOUSE_SIZE := Vector2(1920.0, 674.0)
const SKY_FAR_TOP_LEFT := Vector2(0.0, 1450.0)
const SKY_FAR_SIZE := Vector2(1920.0, 179.0)
const SKY_NEAR_TOP_LEFT := Vector2(300.0, 1600.0)
const SKY_NEAR_SIZE := Vector2(1229.0, 106.0)
const START_BUTTON_CENTER := Vector2(960.0, 2070.0)
const START_BUTTON_SIZE := Vector2(372.0, 92.0)
const LOGO_SIZE := Vector2(560.0, 320.0)
const LOGO_TOP := 46.0
const SIZE_ROW_TOP := 846.0

const SPLASH_DURATION := 2.4
const SPLASH_FADE := 0.45

# 固定初始编队：十字军 / 强盗 / 神秘学者 / 训犬师（编队选择功能已移除）
const FIXED_TEAM: Array[String] = ["crusader", "highwayman", "occultist", "houndmaster"]

# 地图尺寸三档（沿用原开始界面的选项）
const MAP_SIZES := [
	{"key": "small", "label": "SMALL", "hint": "5 × 5 · 10 rooms"},
	{"key": "medium", "label": "MEDIUM", "hint": "7 × 7 · 15 rooms"},
	{"key": "large", "label": "LARGE", "hint": "9 × 9 · 20 rooms"},
]

# 闪屏只在本次运行首次进入开始界面时播放
static var _splash_played := false

var _menu_layer: Control = null
var _design_root: Control = null
var _splash_layer: Control = null
var _splash_done := false
var _start_button: Button = null
var _size_buttons: Array[Button] = []
var _size_hint_label: Label = null
var _size_key := "medium"

# --- LLM 设置（首次启动引导 + 随时可改）---
const LLM_SETUP_FLAG := "user://llm_setup_done"
const LLM_DEFAULT_URL := "https://api.deepseek.com/v1/chat/completions"
const LLM_DEFAULT_MODEL := "deepseek-chat"
const LLM_PANEL_SIZE := Vector2(900.0, 580.0)
var _llm_button: Button = null
var _llm_panel: Control = null
var _llm_url_edit: LineEdit = null
var _llm_key_edit: LineEdit = null
var _llm_model_edit: LineEdit = null
var _llm_status: Label = null
var _pending_start := false

func _ready() -> void:
	_build_menu()
	var vp := get_viewport()
	if vp != null and not vp.size_changed.is_connected(_layout_design_root):
		vp.size_changed.connect(_layout_design_root)
	_layout_design_root()

	# 背景音乐：闪屏一出现就淡入主题曲（Autoload，换场景不会中断）
	Bgm.play("title")

	if not _splash_played:
		_splash_played = true
		_build_splash()
		_play_splash()

func _input(event: InputEvent) -> void:
	# 闪屏期间：点击 / 任意按键都可以跳过
	if _splash_done:
		return
	if event is InputEventMouseButton:
		if (event as InputEventMouseButton).pressed:
			_dismiss_splash()
	elif event is InputEventKey:
		var key := event as InputEventKey
		if key.pressed and not key.echo:
			_dismiss_splash()

# ------------------------------------------------------------ 版式缩放

# DesignRoot 固定 1920×1080，随窗口等比缩放并居中（多出来的黑边由底层黑色底板补齐）
func _layout_design_root() -> void:
	if not is_instance_valid(_design_root):
		return
	var vp_size: Vector2 = get_viewport().get_visible_rect().size
	if vp_size.x <= 1.0 or vp_size.y <= 1.0:
		return
	var fit: float = minf(vp_size.x / DESIGN_SIZE.x, vp_size.y / DESIGN_SIZE.y)
	_design_root.scale = Vector2(fit, fit)
	_design_root.position = (vp_size - DESIGN_SIZE * fit) * 0.5

# ------------------------------------------------------------ 主菜单

func _build_menu() -> void:
	_menu_layer = Control.new()
	_menu_layer.name = "MenuLayer"
	_menu_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_menu_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_menu_layer)

	var backdrop := ColorRect.new()
	backdrop.name = "BlackBackdrop"
	backdrop.color = Color(0, 0, 0, 1)
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_menu_layer.add_child(backdrop)

	_design_root = Control.new()
	_design_root.name = "DesignRoot"
	_design_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_design_root.size = DESIGN_SIZE
	_menu_layer.add_child(_design_root)

	_add_title_glow()
	_add_house()
	_add_clouds()
	_add_logo()
	_add_size_row()
	_add_start_button()
	_add_llm_button()
	_add_build_label()

# 底板：title_bg.png 是 1920×2160 的整段前端背景，取下半屏（黑天 + 红色辉光）
func _add_title_glow() -> void:
	var glow := TextureRect.new()
	glow.name = "TitleGlow"
	glow.texture = _atlas(TITLE_BG_IMAGE, Rect2(0.0, PAGE_SCROLL, DESIGN_SIZE.x, DESIGN_SIZE.y))
	glow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	glow.stretch_mode = TextureRect.STRETCH_SCALE
	glow.size = DESIGN_SIZE
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_design_root.add_child(glow)

# 宅邸剪影：黑色剪影压在红色辉光之上（原版就是这一构图）
func _add_house() -> void:
	var house := TextureRect.new()
	house.name = "TitleHouse"
	house.texture = load(TITLE_HOUSE_IMAGE)
	house.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	house.stretch_mode = TextureRect.STRETCH_SCALE
	house.position = Vector2(HOUSE_TOP_LEFT.x, HOUSE_TOP_LEFT.y - PAGE_SCROLL)
	house.size = HOUSE_SIZE
	house.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_design_root.add_child(house)

# 两层流云：低透明度 + 极缓慢横向漂移（云压在宅邸之上，形成纵深）
func _add_clouds() -> void:
	var clouds := [
		{"name": "SkyFar", "path": SKY_FAR_IMAGE, "pos": SKY_FAR_TOP_LEFT, "size": SKY_FAR_SIZE, "alpha": 0.16, "drift": 30.0, "time": 22.0},
		{"name": "SkyNear", "path": SKY_NEAR_IMAGE, "pos": SKY_NEAR_TOP_LEFT, "size": SKY_NEAR_SIZE, "alpha": 0.22, "drift": - 46.0, "time": 16.0},
	]
	for entry in clouds:
		var cloud := TextureRect.new()
		cloud.name = str(entry["name"])
		cloud.texture = load(str(entry["path"]))
		cloud.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		cloud.stretch_mode = TextureRect.STRETCH_SCALE
		var pos: Vector2 = entry["pos"]
		cloud.position = Vector2(pos.x, pos.y - PAGE_SCROLL)
		cloud.size = entry["size"]
		cloud.modulate = Color(1, 1, 1, float(entry["alpha"]))
		cloud.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_design_root.add_child(cloud)
		_drift(cloud, float(entry["drift"]), float(entry["time"]))

func _drift(node: Control, distance: float, duration: float) -> void:
	var home: Vector2 = node.position
	var tw := create_tween().set_loops()
	tw.tween_property(node, "position", home + Vector2(distance, 0.0), duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(node, "position", home, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

# 标题标志：从 demo_splash.png 里裁出 logo 区域单独摆放
func _add_logo() -> void:
	var logo := TextureRect.new()
	logo.name = "TitleLogo"
	logo.texture = _atlas(SPLASH_IMAGE, LOGO_REGION)
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.size = LOGO_SIZE
	logo.position = Vector2((DESIGN_SIZE.x - LOGO_SIZE.x) * 0.5, LOGO_TOP)
	logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_design_root.add_child(logo)

# 裁图：Godot 4 的 TextureRect 没有 region 属性，要包一层 AtlasTexture
func _atlas(path: String, region: Rect2) -> AtlasTexture:
	var tex: Texture2D = load(path)
	if tex == null:
		return null
	var atlas := AtlasTexture.new()
	atlas.atlas = tex
	atlas.region = region
	return atlas

# 地图尺寸三选一 + 说明文字
func _add_size_row() -> void:
	var btn_w := 216.0
	var btn_h := 42.0
	var gap := 14.0
	var total: float = btn_w * float(MAP_SIZES.size()) + gap * float(MAP_SIZES.size() - 1)
	var left: float = (DESIGN_SIZE.x - total) * 0.5

	_size_buttons.clear()
	for i in range(MAP_SIZES.size()):
		var entry: Dictionary = MAP_SIZES[i]
		var btn := Button.new()
		btn.name = "SizeButton%d" % i
		btn.text = str(entry["label"])
		btn.focus_mode = Control.FOCUS_NONE
		btn.position = Vector2(left + float(i) * (btn_w + gap), SIZE_ROW_TOP)
		btn.size = Vector2(btn_w, btn_h)
		_style_banner_button(btn, 15)
		btn.pressed.connect(_on_size_pressed.bind(str(entry["key"])))
		_design_root.add_child(btn)
		_size_buttons.append(btn)

	_size_hint_label = Label.new()
	_size_hint_label.name = "SizeHint"
	_size_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_size_hint_label.position = Vector2(0.0, SIZE_ROW_TOP + btn_h + 10.0)
	_size_hint_label.size = Vector2(DESIGN_SIZE.x, 24.0)
	_size_hint_label.add_theme_font_size_override("font_size", 15)
	_size_hint_label.add_theme_color_override("font_color", Color(0.72, 0.66, 0.52, 1))
	_size_hint_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_design_root.add_child(_size_hint_label)
	_refresh_size_row()

func _add_start_button() -> void:
	_start_button = Button.new()
	_start_button.name = "StartButton"
	_start_button.text = "START"
	_start_button.focus_mode = Control.FOCUS_NONE
	_start_button.position = START_BUTTON_CENTER - START_BUTTON_SIZE * 0.5 - Vector2(0.0, PAGE_SCROLL)
	_start_button.size = START_BUTTON_SIZE
	_style_banner_button(_start_button, 30)
	_start_button.pressed.connect(_on_start_pressed)
	_design_root.add_child(_start_button)

func _add_build_label() -> void:
	var build := Label.new()
	build.name = "BuildLabel"
	build.text = "Dark Dungeon · Godot 4.6 · Demo Build"
	build.position = Vector2(24.0, DESIGN_SIZE.y - 44.0)
	build.add_theme_font_size_override("font_size", 14)
	build.add_theme_color_override("font_color", Color(0.45, 0.42, 0.36, 1))
	build.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_design_root.add_child(build)

# 用原版 start_button.png（深色底 + 上下描金）做九宫格按钮外观
func _style_banner_button(btn: Button, font_size: int) -> void:
	var texture: Texture2D = load(BUTTON_ART)
	if texture == null:
		return
	var base := StyleBoxTexture.new()
	base.texture = texture
	base.texture_margin_left = 12.0
	base.texture_margin_right = 12.0
	base.texture_margin_top = 9.0
	base.texture_margin_bottom = 9.0
	var hover := base.duplicate() as StyleBoxTexture
	hover.modulate_color = Color(1.35, 1.22, 0.95, 1.0)
	var pressed_style := base.duplicate() as StyleBoxTexture
	pressed_style.modulate_color = Color(0.75, 0.7, 0.6, 1.0)
	btn.add_theme_stylebox_override("normal", base)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", pressed_style)
	btn.add_theme_stylebox_override("focus", base)
	btn.add_theme_stylebox_override("disabled", base)
	btn.add_theme_font_size_override("font_size", font_size)
	btn.add_theme_color_override("font_color", Color(0.86, 0.8, 0.6, 1))
	btn.add_theme_color_override("font_hover_color", Color(1.0, 0.94, 0.72, 1))
	btn.add_theme_color_override("font_pressed_color", Color(1.0, 1.0, 1.0, 1))

func _refresh_size_row() -> void:
	for i in range(_size_buttons.size()):
		if i >= MAP_SIZES.size():
			continue
		var entry: Dictionary = MAP_SIZES[i]
		var selected: bool = str(entry["key"]) == _size_key
		var btn: Button = _size_buttons[i]
		btn.modulate = Color(1, 1, 1, 1) if selected else Color(0.62, 0.62, 0.62, 1)
		btn.add_theme_color_override("font_color", Color(1.0, 0.88, 0.55, 1) if selected else Color(0.62, 0.58, 0.5, 1))
	if _size_hint_label != null:
		_size_hint_label.text = _size_hint_of(_size_key)

func _size_hint_of(size_key: String) -> String:
	for entry in MAP_SIZES:
		if str(entry["key"]) == size_key:
			return str(entry["hint"])
	return ""

# ------------------------------------------------------------ 闪屏

func _build_splash() -> void:
	_splash_layer = Control.new()
	_splash_layer.name = "SplashLayer"
	_splash_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_splash_layer.mouse_filter = Control.MOUSE_FILTER_STOP # 吃掉点击，避免误触后方菜单
	add_child(_splash_layer)

	var img := TextureRect.new()
	img.name = "DemoSplash"
	img.texture = load(SPLASH_IMAGE)
	img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	img.set_anchors_preset(Control.PRESET_FULL_RECT)
	img.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_splash_layer.add_child(img)

func _play_splash() -> void:
	if not is_instance_valid(_splash_layer):
		return
	await get_tree().create_timer(SPLASH_DURATION).timeout
	_dismiss_splash()

func _dismiss_splash() -> void:
	if _splash_done or not is_instance_valid(_splash_layer):
		return
	_splash_done = true
	_splash_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tw := create_tween()
	tw.tween_property(_splash_layer, "modulate:a", 0.0, SPLASH_FADE)
	tw.tween_callback(_splash_layer.queue_free)

# ------------------------------------------------------------ 开局

func _on_size_pressed(size_key: String) -> void:
	_size_key = size_key
	_refresh_size_row()

# START：本机完全没有可用在线配置时才引导一次；已配好内置代理则直接开局（0 点击）
func _on_start_pressed() -> void:
	if _start_button != null:
		_start_button.disabled = true
	if _needs_llm_setup():
		_open_llm_panel(true)
		return
	_begin_run()

# 写入固定编队 → 重置关卡与补给 → 直接进入地图（不再经过编队选择）
func _begin_run() -> void:
	if _start_button != null:
		_start_button.disabled = true # 防子开局途中重复点击（取消引导时才会重新启用）
	var team: Array[String] = []
	for hero_id in FIXED_TEAM:
		team.append(str(hero_id))
	HeroConfig.set_team(team)
	HeroConfig.reset_party_state()
	ConsumableConfig.reset_inventory()
	DungeonMap.set_size(_size_key)
	DungeonMap.reset_run()
	print("[Start] New run: team=", team, " map=", _size_key)
	get_tree().change_scene_to_file("res://scenes/map/Map.tscn")

# ------------------------------------------------------------ LLM 设置面板

func _llm_setup_done() -> bool:
	return FileAccess.file_exists(LLM_SETUP_FLAG)

# 是否需要首次引导：已引导过（玩家点过离线开始）就不弹；已有可用在线配置也不弹
# （发布版把代理地址填进 api_public.gd 后，玩家双击 exe → 点 START 即直接开局 = 0 点击）
func _needs_llm_setup() -> bool:
	if _llm_setup_done():
		return false
	return not _llm_online_available()

func _llm_online_available() -> bool:
	var client := LLMClient.new()
	var online := client.has_online_config()
	client.free()
	return online

func _mark_llm_setup_done() -> void:
	var f := FileAccess.open(LLM_SETUP_FLAG, FileAccess.WRITE)
	if f != null:
		f.store_string("1")
		f.close()

# 右上角常驻入口：随时可改 Key / 切回离线
func _add_llm_button() -> void:
	_llm_button = Button.new()
	_llm_button.name = "LlmSettingsButton"
	_llm_button.focus_mode = Control.FOCUS_NONE
	_llm_button.position = Vector2(DESIGN_SIZE.x - 208.0, 24.0)
	_llm_button.size = Vector2(184.0, 40.0)
	_style_banner_button(_llm_button, 17)
	_llm_button.pressed.connect(_on_llm_button_pressed)
	_design_root.add_child(_llm_button)
	_refresh_llm_button()

func _refresh_llm_button() -> void:
	if not is_instance_valid(_llm_button):
		return
	var online := _llm_online_available()
	if online and LLMClient.online_disabled:
		_llm_button.text = "LLM 设置 · 在线不可达"
		_llm_button.add_theme_color_override("font_color", Color(0.95, 0.78, 0.45, 1))
		return
	_llm_button.text = "LLM 设置 · 在线" if online else "LLM 设置 · 离线"
	_llm_button.add_theme_color_override("font_color", Color(0.68, 0.92, 0.68, 1) if online else Color(0.66, 0.62, 0.54, 1))

func _on_llm_button_pressed() -> void:
	_open_llm_panel(false)

func _open_llm_panel(first_run: bool) -> void:
	if is_instance_valid(_llm_panel):
		return
	_pending_start = first_run

	var client := LLMClient.new()
	var cur_key := client.api_key
	var cur_url := client.api_url
	var cur_model := client.model
	var cur_source := client.config_source
	client.free()

	var mask := ColorRect.new()
	mask.name = "LlmMask"
	mask.color = Color(0, 0, 0, 0.74)
	mask.size = DESIGN_SIZE
	mask.mouse_filter = Control.MOUSE_FILTER_STOP
	_design_root.add_child(mask)
	_llm_panel = mask

	var frame := PanelContainer.new()
	frame.name = "LlmFrame"
	frame.position = (DESIGN_SIZE - LLM_PANEL_SIZE) * 0.5
	frame.size = LLM_PANEL_SIZE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.07, 0.06, 0.98)
	style.border_color = Color(0.55, 0.45, 0.24, 1.0)
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(26.0)
	frame.add_theme_stylebox_override("panel", style)
	mask.add_child(frame)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	frame.add_child(box)

	var title := Label.new()
	title.text = "LLM 激励喊话 · 连接设置"
	title.add_theme_font_size_override("font_size", 27)
	title.add_theme_color_override("font_color", Color(0.93, 0.83, 0.55, 1))
	box.add_child(title)

	var desc := Label.new()
	desc.text = ("① 不填任何内容：直接用内置离线 Mock 引擎（四种结果逻辑完整，单机也能玩）。\n"
		+"② 填入自己的 API Key：喊话交由在线大模型判定。\n"
		+"③ 使用自建代理：地址填代理地址、Key 填代理令牌（推荐，真 Key 不会下发到玩家机器）。\n"
		+"设置只保存在本机，随时可改。当前生效：" + cur_source)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.add_theme_font_size_override("font_size", 17)
	desc.add_theme_color_override("font_color", Color(0.74, 0.7, 0.62, 1))
	box.add_child(desc)

	_llm_url_edit = _add_llm_row(box, "API 地址", cur_url, false)
	_llm_key_edit = _add_llm_row(box, "API Key", cur_key, true)
	_llm_model_edit = _add_llm_row(box, "模型", cur_model, false)

	_llm_status = Label.new()
	_llm_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_llm_status.custom_minimum_size = Vector2(0.0, 44.0)
	_llm_status.add_theme_font_size_override("font_size", 17)
	_llm_status.add_theme_color_override("font_color", Color(0.72, 0.68, 0.6, 1))
	_llm_status.text = "填好后点「%s」，会先测试连通性再开局。" % ("保存并开始" if first_run else "保存并测试")
	box.add_child(_llm_status)

	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_END
	btn_row.add_theme_constant_override("separation", 14)
	box.add_child(btn_row)
	if first_run:
		_add_llm_action(btn_row, "保存并开始", _on_llm_save_pressed)
		_add_llm_action(btn_row, "离线开始", _on_llm_offline_pressed)
		_add_llm_action(btn_row, "返回", _on_llm_cancel_pressed)
	else:
		_add_llm_action(btn_row, "保存并测试", _on_llm_save_pressed)
		_add_llm_action(btn_row, "清除（改用离线）", _on_llm_clear_pressed)
		_add_llm_action(btn_row, "关闭", _on_llm_cancel_pressed)

	if is_instance_valid(_llm_key_edit):
		_llm_key_edit.grab_focus()

func _add_llm_row(parent: VBoxContainer, label_text: String, value: String, secret: bool) -> LineEdit:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	parent.add_child(row)

	var lbl := Label.new()
	lbl.text = label_text
	lbl.custom_minimum_size = Vector2(140.0, 0.0)
	lbl.add_theme_font_size_override("font_size", 18)
	lbl.add_theme_color_override("font_color", Color(0.8, 0.74, 0.6, 1))
	row.add_child(lbl)

	var edit := LineEdit.new()
	edit.text = value
	edit.secret = secret
	if secret:
		edit.placeholder_text = "留空 = 离线 Mock"
	edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	edit.custom_minimum_size = Vector2(0.0, 40.0)
	edit.add_theme_font_size_override("font_size", 18)
	row.add_child(edit)
	return edit

func _add_llm_action(parent: HBoxContainer, text: String, handler: Callable) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.focus_mode = Control.FOCUS_NONE
	btn.custom_minimum_size = Vector2(190.0, 46.0)
	_style_banner_button(btn, 18)
	btn.pressed.connect(handler)
	parent.add_child(btn)
	return btn

func _set_llm_status(text: String, ok: bool) -> void:
	if not is_instance_valid(_llm_status):
		return
	_llm_status.text = text
	_llm_status.add_theme_color_override("font_color", Color(0.62, 0.9, 0.62, 1) if ok else Color(0.93, 0.6, 0.5, 1))

# 保存 → 自检 → 若来自 START 引导则直接开局
func _on_llm_save_pressed() -> void:
	if not is_instance_valid(_llm_key_edit):
		return
	var key := _llm_key_edit.text.strip_edges()
	if key.is_empty():
		_set_llm_status("请先填写 API Key；只想离线游玩请点「离线开始」。", false)
		return
	var url := _llm_url_edit.text.strip_edges()
	var mdl := _llm_model_edit.text.strip_edges()
	var client := LLMClient.new()
	if not client.save_user_config(key, url, mdl):
		client.free()
		_set_llm_status("无法写入本机配置目录（user://）", false)
		return
	_mark_llm_setup_done()
	_set_llm_status("已保存，正在测试连接…", true)
	var r: Dictionary = await client.test_connection(self)
	client.free()
	var ok: bool = r.get("ok", false)
	_set_llm_status(str(r.get("message", "")), ok)
	_refresh_llm_button()
	if ok and _pending_start:
		_close_llm_panel()
		_begin_run()

# 不配 Key：清空游戏内设置并直接开局（离线 Mock）
func _on_llm_offline_pressed() -> void:
	var client := LLMClient.new()
	client.clear_user_config()
	client.free()
	_mark_llm_setup_done()
	_refresh_llm_button()
	var start := _pending_start
	_close_llm_panel()
	if start:
		_begin_run()

func _on_llm_clear_pressed() -> void:
	var client := LLMClient.new()
	client.clear_user_config()
	client.free()
	_refresh_llm_button()
	if is_instance_valid(_llm_key_edit):
		_llm_key_edit.text = ""
	if is_instance_valid(_llm_url_edit):
		_llm_url_edit.text = LLM_DEFAULT_URL
	if is_instance_valid(_llm_model_edit):
		_llm_model_edit.text = LLM_DEFAULT_MODEL
	_set_llm_status("已清除游戏内设置，回落到离线 Mock 模式。", true)

func _on_llm_cancel_pressed() -> void:
	_refresh_llm_button()
	_close_llm_panel()

func _close_llm_panel() -> void:
	if is_instance_valid(_llm_panel):
		_llm_panel.queue_free()
	_llm_panel = null
	_llm_url_edit = null
	_llm_key_edit = null
	_llm_model_edit = null
	_llm_status = null
	_pending_start = false
	if _start_button != null:
		_start_button.disabled = false
