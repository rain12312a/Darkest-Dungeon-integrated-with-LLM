extends SceneTree

# 临时探针脚本（端到端验证用，非游戏运行时代码）
# 用途：验证新的「闪屏 + 暗黑地牢原版风格开始菜单」与固定编队开局
#   ① 闪屏层（demo_splash）与菜单层并存，菜单默认被闪屏盖住
#   ② 跳过闪屏 → 淡出并释放；同一进程内二次进入不再闪屏
#   ③ 主菜单构件：红色辉光底板 / 宅邸剪影 / DEMO 标志 / 尺寸三选一 / START 按钮 / LLM 设置入口
#   ④ 首次 START → 先弹 LLM 设置面板（点「离线开始」）→ 固定编队（十字军·强盗·神秘学者·训犬师）→ 重置补给与关卡 → 进地图
# 运行：godot --headless --path <项目> --script res://tools/_probe_start_menu.gd

const EXPECTED_TEAM: Array[String] = ["crusader", "highwayman", "occultist", "houndmaster"]
const USER_CFG := "user://llm_config.json"
const USER_BACKUP := "user://llm_config.probe_backup"
const SETUP_FLAG := "user://llm_setup_done"

var _start: Node = null
var _second: Node = null
var _frame := 0
var _pass := 0
var _fail := 0
var _stage := 0 # 0=待测闪屏 1=等淡出结束 2=已测完菜单
var _wait_frames := 0

func _initialize() -> void:
	# 先污染静态状态，验证 START 会重置
	HeroConfig.CURRENT_TEAM = ["crusader", "crusader", "crusader", "crusader"]
	HeroConfig.PARTY_STATES = [ {"dead": true}]
	ConsumableConfig.reset_inventory(9, 9, 9)
	var packed := load("res://scenes/start/Start.tscn") as PackedScene
	if packed == null:
		print("[START] FAILED: cannot load Start.tscn")
		quit(1)
		return
	_start = packed.instantiate()
	root.add_child(_start)

func _process(_delta: float) -> bool:
	_frame += 1
	if _frame < 2:
		return false
	if _start == null:
		quit(1)
		return true
	if _frame == 2:
		_test_splash_and_menu()
		return false
	if _frame == 3:
		_start.call("_dismiss_splash")
		_test_dismiss()
		_stage = 1
		return false
	if _stage == 1:
		# 等淡出补间跑完并把闪屏 queue_free 掉（无头下帧率不稳，用轮询而非固定帧号）
		_wait_frames += 1
		var splash: Variant = _start.get("_splash_layer")
		var freed: bool = splash == null or not is_instance_valid(splash)
		if not freed and _wait_frames < 900:
			return false
		_expect(freed, "淡出结束后闪屏被释放（等待 %d 帧）" % _wait_frames)
		_stage = 2
		_test_menu_widgets()
		_test_fixed_team_start()
		print("[START] ===== PASS=%d FAIL=%d ====" % [_pass, _fail])
		quit(0 if _fail == 0 else 1)
		return true
	return false

func _expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("[START]   PASS  ", label)
	else:
		_fail += 1
		print("[START]   FAIL  ", label)

# ------------------------------------------------------------ ① 闪屏 + 菜单

func _test_splash_and_menu() -> void:
	print("[START] --- ① 闪屏与菜单 ---")
	var splash: Control = _start.get("_splash_layer")
	var menu: Control = _start.get("_menu_layer")
	_expect(splash != null and menu != null, "闪屏层与菜单层都已创建")
	_expect(bool(_start.get("_splash_done")) == false, "闪屏默认未跳过")
	if splash != null:
		_expect(splash.visible, "闪屏层可见（盖住菜单）")
		_expect(splash.get_child_count() == 1, "闪屏层内有 1 张图片")
		var img: TextureRect = splash.get_child(0) as TextureRect
		_expect(img != null and img.texture != null, "闪屏图片已加载 demo_splash.png")
		_expect(img != null and img.stretch_mode == TextureRect.STRETCH_KEEP_ASPECT_COVERED, "闪屏按 cover 铺满窗口")
	if menu != null:
		_expect(menu.get_node_or_null("DesignRoot") != null, "菜单层里有 1920×1080 的 DesignRoot")

# ------------------------------------------------------------ ② 跳过闪屏

func _test_dismiss() -> void:
	print("[START] --- ② 跳过闪屏 ---")
	_expect(bool(_start.get("_splash_done")), "调用后标记为已跳过")
	var tween_alive := false
	var splash: Control = _start.get("_splash_layer")
	if splash != null:
		tween_alive = splash.modulate.a <= 1.0
	_expect(tween_alive, "闪屏进入淡出（alpha ≤ 1）")

	# 同一进程内再开一次开始界面：不应再出现闪屏
	var packed := load("res://scenes/start/Start.tscn") as PackedScene
	_second = packed.instantiate()
	root.add_child(_second)
	_expect(_second.get("_splash_layer") == null, "同一进程二次进入不再闪屏")
	_expect(bool(_second.get("_splash_done")) == false, "二次进入时闪屏状态保持未触发")

# ------------------------------------------------------------ ③ 菜单构件

func _test_menu_widgets() -> void:
	print("[START] --- ③ 主菜单构件 ---")
	var design: Control = _start.get("_design_root")
	_expect(design != null, "DesignRoot 存在")
	if design == null:
		return
	_expect(design.size == Vector2(1920.0, 1080.0), "DesignRoot 设计尺寸 1920×1080")

	var glow: TextureRect = design.get_node_or_null("TitleGlow") as TextureRect
	_expect(glow != null and glow.texture != null, "红色辉光底板已加载 title_bg.png")
	var glow_atlas: AtlasTexture = glow.texture as AtlasTexture if glow != null else null
	_expect(glow_atlas != null and glow_atlas.region == Rect2(0, 1080, 1920, 1080), "底板取的是 title_bg 的下半屏（AtlasTexture 裁切）")

	var house: TextureRect = design.get_node_or_null("TitleHouse") as TextureRect
	_expect(house != null and house.texture != null, "宅邸剪影已加载 title_house.png")
	_expect(house != null and is_equal_approx(house.position.y, 406.0), "宅邸位置沿用布局值（1486-1080=406）")

	var logo: TextureRect = design.get_node_or_null("TitleLogo") as TextureRect
	_expect(logo != null and logo.texture != null, "DEMO 标志已加载")
	var logo_atlas: AtlasTexture = logo.texture as AtlasTexture if logo != null else null
	_expect(logo_atlas != null and logo_atlas.region == Rect2(510, 199, 962, 550), "标志按实测包围盒裁切摆放")

	var far: TextureRect = design.get_node_or_null("SkyFar") as TextureRect
	var near: TextureRect = design.get_node_or_null("SkyNear") as TextureRect
	_expect(far != null and near != null, "两层流云已创建")
	_expect(far != null and far.modulate.a < 0.5, "远层云为半透明")

	var start_btn: Button = _start.get("_start_button")
	_expect(start_btn != null and start_btn.text == "START", "START 按钮存在且文案为 START")
	_expect(start_btn != null and start_btn.size == Vector2(372.0, 92.0), "START 按钮沿用原版尺寸 372×92")
	_expect(start_btn != null and is_equal_approx(start_btn.position.y, 944.0), "START 按钮位置沿用布局值（2070-1080-46=944）")

	var size_buttons: Array = _start.get("_size_buttons")
	_expect(size_buttons.size() == 3, "地图尺寸三选一（实际 %d 个）" % size_buttons.size())
	_expect(str(_start.get("_size_key")) == "medium", "默认尺寸为 medium")
	_start.call("_on_size_pressed", "large")
	_expect(str(_start.get("_size_key")) == "large", "点击 LARGE 后选中大图")
	var hint: Label = _start.get("_size_hint_label")
	_expect(hint != null and "9 × 9" in hint.text, "尺寸说明随选择更新（%s）" % (hint.text if hint != null else ""))

# ------------------------------------------------------------ ④ 固定编队开局

func _test_fixed_team_start() -> void:
	print("[START] --- ④ START 开新局（首次引导门禁 / 0 点击）---")
	# 隔离本机 LLM 配置：面板的「离线开始」会清空 user://llm_config.json，探针不许动真配置
	var had_cfg := FileAccess.file_exists(USER_CFG)
	if had_cfg:
		DirAccess.copy_absolute(USER_CFG, USER_BACKUP)
		DirAccess.remove_absolute(USER_CFG)
	if FileAccess.file_exists(SETUP_FLAG):
		DirAccess.remove_absolute(SETUP_FLAG)

	var client := LLMClient.new()
	var online := client.has_online_config()
	client.free()
	_expect(_start.call("_needs_llm_setup") == not online, "引导判定 = 本机无任何可用在线配置（实际在线=%s）" % str(online))

	# 手动入口必须随时可用（非首次形态），且 Key 是密文
	_start.call("_open_llm_panel", false)
	_expect(is_instance_valid(_start.get("_llm_panel")), "「LLM 设置」面板可手动打开")
	var key_edit: LineEdit = _start.get("_llm_key_edit")
	_expect(key_edit != null and key_edit.secret, "Key 输入框为密文（secret=true）")
	_start.call("_on_llm_cancel_pressed")
	_expect(_start.get("_llm_panel") == null, "点「关闭」后引导面板已释放")

	_start.call("_on_start_pressed")
	if online:
		_expect(_start.get("_llm_panel") == null, "已有可用的在线配置 → 首次 START 不弹引导，直接开局（0 点击）")
	else:
		_expect(is_instance_valid(_start.get("_llm_panel")), "无任何在线配置 → 首次 START 先弹引导面板")
		_expect(HeroConfig.CURRENT_TEAM != EXPECTED_TEAM, "引导阶段尚未写入固定编队")
		_expect(DungeonMap.current_room == "", "引导阶段尚未进入地图")
		_start.call("_on_llm_offline_pressed")
		_expect(_start.get("_llm_panel") == null, "点「离线开始」后面板已关闭")
		_expect(FileAccess.file_exists(SETUP_FLAG), "已写入 user://llm_setup_done（下次不再引导）")

	var team: Array = HeroConfig.CURRENT_TEAM
	_expect(team == EXPECTED_TEAM, "编队固定为 十字军/强盗/神秘学者/训犬师（实际 %s）" % str(team))
	_expect(HeroConfig.PARTY_STATES.is_empty(), "队伍跳战斗状态已重置")
	_expect(ConsumableConfig.get_count("food") == 4 and ConsumableConfig.get_count("bandage") == 2 and ConsumableConfig.get_count("dogfood") == 2,
		"初始补给重置为 4 食物 / 2 绷带 / 2 狗粮")
	_expect(str(_start.get("_size_key")) == "large", "使用玩家选中的尺寸开局")
	_expect(DungeonMap.MAP_SIZE == "large", "地图尺寸写入 DungeonMap")
	_expect(DungeonMap.get_all_room_ids().size() == 20, "大地图生成 20 个房间（实际 %d）" % DungeonMap.get_all_room_ids().size())
	_expect(DungeonMap.current_room != "", "已进入起始房间")
	var button: Button = _start.get("_start_button")
	_expect(button != null and button.disabled, "开局后 START 按钮禁用，防重复点击")

	# 还原本机 LLM 配置与首次引导标记，不影响开发者自己的环境
	if FileAccess.file_exists(SETUP_FLAG):
		DirAccess.remove_absolute(SETUP_FLAG)
	if had_cfg:
		DirAccess.copy_absolute(USER_BACKUP, USER_CFG)
		DirAccess.remove_absolute(USER_BACKUP)
