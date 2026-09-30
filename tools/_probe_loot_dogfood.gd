extends SceneTree

# 临时探针脚本（端到端验证用，非游戏运行时代码）
# 用途：验证「狗粮消耗品 + 战斗结算（战利品）步骤」两件事：
#   ① 狗粮配置 / 初始数量 / 增益状态（伤害 +20%，1 回合）
#   ② 战后战利品掷取范围（食物 1~4 / 绷带 0~1 / 狗粮 0~1）与右侧结算面板流程
# 运行：godot --headless --path <项目> --script res://tools/_probe_loot_dogfood.gd

var _battle: Node = null
var _frame := 0
var _pass := 0
var _fail := 0

func _initialize() -> void:
	HeroConfig.reset_party_state()
	ConsumableConfig.reset_inventory()
	MonsterConfig.CURRENT_ENCOUNTER = ["skeleton_common", "skeleton_defender"]
	var packed := load("res://scenes/battle/Battle.tscn") as PackedScene
	if packed == null:
		print("[LOOT] FAILED: cannot load Battle.tscn")
		quit(1)
		return
	_battle = packed.instantiate()
	root.add_child(_battle)

func _process(_delta: float) -> bool:
	_frame += 1
	if _frame < 3:
		return false
	if _battle == null:
		quit(1)
		return true
	if _frame == 3:
		_test_config()
		_test_loot_ranges()
		_test_dogfood_use()
		# 冻结战斗循环，避免后续帧里战斗自行结束影响结算流程的断言
		_battle.set("battle_over", true)
		return false
	if _frame == 6:
		_test_loot_panel_layout()
		return false
	if _frame == 9:
		_test_end_battle_loot_flow()
		print("[LOOT] ===== PASS=%d FAIL=%d ====" % [_pass, _fail])
		quit(0 if _fail == 0 else 1)
	return false

# ------------------------------------------------------------ 断言

func _expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("[LOOT]   PASS  ", label)
	else:
		_fail += 1
		print("[LOOT]   FAIL  ", label)

func _slot_of(item_id: String) -> int:
	for i in range(ConsumableConfig.INVENTORY.size()):
		if str(ConsumableConfig.INVENTORY[i].get("item_id", "")) == item_id:
			return i
	return -1

# ------------------------------------------------------------ ① 配置与初始补给

func _test_config() -> void:
	print("[LOOT] --- ① 狗粮配置与初始补给 ---")
	_expect(ConsumableConfig.ITEMS.has("dogfood"), "ConsumableConfig 中存在 dogfood")
	var item: Dictionary = ConsumableConfig.get_item("dogfood")
	_expect(str(item.get("buff_status", "")) == "dogfood_buff", "狗粮配置 buff_status = dogfood_buff")
	_expect(int(item.get("buff_duration", 0)) == 1, "狗粮增益持续 1 回合")
	_expect(ResourceLoader.exists(str(item.get("icon", ""))), "狗粮图标资源存在")

	var buff: Dictionary = StatusConfig.get_status("dogfood_buff")
	_expect(not buff.is_empty(), "StatusConfig 中存在 dogfood_buff")
	_expect(is_equal_approx(float(buff.get("damage_mult", 0.0)), 1.2), "dogfood_buff 伤害倍率 = 1.2（乘算乘区）")
	_expect(is_equal_approx(float(buff.get("attack_mult", 1.0)), 1.0), "dogfood_buff 不带 attack_mult（不属攻击力加算区）")
	_expect(ResourceLoader.exists(str(buff.get("icon", ""))), "增益状态图标资源存在")

	_expect(ConsumableConfig.get_count("dogfood") == 2, "初始狗粮数量为 2（实际 %d）" % ConsumableConfig.get_count("dogfood"))
	_expect(ConsumableConfig.get_count("food") == 4, "初始食物数量仍为 4")
	_expect(ConsumableConfig.get_count("bandage") == 2, "初始绷带数量仍为 2")

# ------------------------------------------------------------ ② 战利品掷取范围

func _test_loot_ranges() -> void:
	print("[LOOT] --- ② 战利品掷取范围（300 次） ---")
	var rounds := 300
	var food_min := 99
	var food_max := -1
	var food_rounds := 0
	var bandage_present := 0
	var dogfood_present := 0
	for _i in range(rounds):
		var loot: Array = _battle.call("_roll_battle_loot")
		for entry in loot:
			var item_id: String = str(entry.get("item_id", ""))
			var count: int = int(entry.get("count", 0))
			if item_id == "food":
				food_rounds += 1
				food_min = mini(food_min, count)
				food_max = maxi(food_max, count)
			elif item_id == "bandage":
				bandage_present += 1
			elif item_id == "dogfood":
				dogfood_present += 1
	_expect(food_rounds == rounds, "每场战斗必定有食物（%d/%d）" % [food_rounds, rounds])
	_expect(food_min >= 1 and food_max <= 4, "食物数量始终落在 1~4（实测 %d~%d）" % [food_min, food_max])
	_expect(food_max >= 3, "食物能掷出较高数值（实测最大 %d）" % food_max)
	# 0 个的场次不会出现在战利品列表里，所以“能掷出 0 个” = 部分场次完全没有该条目
	_expect(bandage_present > 0 and bandage_present < rounds, "绷带可掷出 1 个（%d/%d 场），其余场次为 0" % [bandage_present, rounds])
	_expect(dogfood_present > 0 and dogfood_present < rounds, "狗粮可掷出 1 个（%d/%d 场），其余场次为 0" % [dogfood_present, rounds])

# ------------------------------------------------------------ ③ 狗粮使用效果

func _test_dogfood_use() -> void:
	print("[LOOT] --- ③ 狗粮使用效果（伤害 +20%，1 回合） ---")
	var heroes: Array = _battle.get("heroes")
	if heroes.is_empty():
		_expect(false, "战斗中存在英雄")
		return
	_battle.set("_in_fx_pause", false)
	_battle.set("current_actor", {"unit_type": "hero", "index": 0})
	var hero: Dictionary = heroes[0]
	_expect(not ActionResolver.has_status(hero, "dogfood_buff"), "使用前没有狗粮增益")
	var base_damage: int = ActionResolver.calculate_damage(hero, {"attack_ratio": 1.0})
	_expect(is_equal_approx(ActionResolver.get_attack_multiplier(hero), 1.0), "使用前攻击力倍率 = 1.0")
	_expect(is_equal_approx(ActionResolver.get_damage_multiplier(hero), 1.0), "使用前伤害倍率 = 1.0")

	var slot: int = _slot_of("dogfood")
	_expect(slot >= 0, "物品栏中能找到狗粮格子（index=%d）" % slot)
	var before_count: int = ConsumableConfig.get_count("dogfood")
	_battle.call("_try_use_consumable", slot)

	_expect(ConsumableConfig.get_count("dogfood") == before_count - 1, "使用后狗粮数量 -1（%d → %d）" % [before_count, ConsumableConfig.get_count("dogfood")])
	_expect(ActionResolver.has_status(hero, "dogfood_buff"), "使用后身上带有 dogfood_buff")
	_expect(is_equal_approx(ActionResolver.get_attack_multiplier(hero), 1.0), "狗粮不进攻击力加算区（攻击力倍率仍为 1.0）")
	_expect(is_equal_approx(ActionResolver.get_damage_multiplier(hero), 1.2), "使用后伤害倍率 = 1.2")
	var buffed_damage: int = ActionResolver.calculate_damage(hero, {"attack_ratio": 1.0})
	_expect(buffed_damage == int(round(float(base_damage) * 1.2)), "伤害由 %d 提升到 %d（+20%%）" % [base_damage, buffed_damage])

	# 持续时间只有 1 回合：英雄下一次行动开始时 tick 一次即到期
	var statuses: Dictionary = hero.get("statuses", {})
	_expect(int(statuses.get("dogfood_buff", {}).get("duration", 0)) == 1, "增益剩余回合为 1")
	ActionResolver.tick_statuses(hero)
	_expect(not ActionResolver.has_status(hero, "dogfood_buff"), "经过 1 个回合结算后增益消失")
	_expect(is_equal_approx(ActionResolver.get_damage_multiplier(hero), 1.0), "增益消失后伤害倍率回落 1.0")

# ------------------------------------------------------------ ④ 结算面板布局

func _test_loot_panel_layout() -> void:
	print("[LOOT] --- ④ 结算面板布局 ---")
	var modal: ColorRect = _battle.get("loot_modal")
	var panel: Panel = _battle.get("loot_panel")
	var layer: CanvasLayer = _battle.get_node_or_null("BattleUI/LootLayer") as CanvasLayer
	_expect(modal != null and panel != null, "结算面板节点已创建")
	if modal == null or panel == null:
		return
	_expect(not modal.visible, "未结算时面板默认隐藏")
	if layer == null:
		_expect(false, "结算层 LootLayer 存在")
	else:
		_expect(layer.layer > 100, "结算层高于激励喊话层（实际 %d）" % layer.layer)
	# 面板贴在屏幕右侧：左右锚点都固定到 1.0（右边缘），且只向左延伸
	_expect(is_equal_approx(panel.anchor_left, 1.0) and is_equal_approx(panel.anchor_right, 1.0), "面板锚定在屏幕右侧")
	_expect(panel.offset_left < 0.0 and panel.offset_right < 0.0, "面板以负偏移从右边缘内收")
	# 右侧面板与居中的胜利面板（0.25~0.75 锚点）不重叠：1280 宽下前者左边缘 980 > 后者右边缘 960
	var screen_w := 1280.0
	var loot_left := screen_w + panel.offset_left
	var victory_right := screen_w * 0.75
	_expect(loot_left >= victory_right, "结算面板不遮挡胜利面板（左边缘 %.0f ≥ %.0f）" % [loot_left, victory_right])

# ------------------------------------------------------------ ⑤ 战后结算流程

func _test_end_battle_loot_flow() -> void:
	print("[LOOT] --- ⑤ 战后结算流程 ---")
	var monsters: Array = _battle.get("monsters")
	monsters.clear() # 全歼 → 判定胜利
	var modal: ColorRect = _battle.get("loot_modal")
	var back_button: Button = _battle.get("back_button")
	var items_root: VBoxContainer = _battle.get("loot_items_root")
	if modal == null or back_button == null or items_root == null:
		_expect(false, "结算 UI 节点齐备")
		return

	_battle.set("battle_over", false)
	var food_before: int = ConsumableConfig.get_count("food")
	var bandage_before: int = ConsumableConfig.get_count("bandage")
	var dogfood_before: int = ConsumableConfig.get_count("dogfood")
	_battle.call("_end_battle")

	_expect(bool(_battle.get("_battle_won")), "全歼怪物判定为胜利")
	_expect(modal.visible, "胜利后弹出结算面板")
	_expect(back_button.disabled, "未确认前返回按钮被锁定")
	# _pending_loot 是同一个数组对象的引用，确认时会被 clear()，先取深拷贝
	var pending_ref: Array = _battle.get("_pending_loot")
	var pending: Array = pending_ref.duplicate(true)
	_expect(pending.size() >= 1, "掷出至少 1 种战利品（实际 %d 种）" % pending.size())
	var row_count := 0
	for child in items_root.get_children():
		if not child.is_queued_for_deletion():
			row_count += 1
	_expect(row_count == pending.size(), "面板行数与战利品种类一致（%d）" % row_count)

	_battle.call("_on_loot_confirm_pressed")
	_expect(not modal.visible, "确认后结算面板收起")
	_expect(not back_button.disabled, "确认后返回按钮解锁")
	_expect(ConsumableConfig.get_count("food") == food_before + _pending_count(pending, "food"), "食物已入包（%d → %d）" % [food_before, ConsumableConfig.get_count("food")])
	_expect(ConsumableConfig.get_count("bandage") == bandage_before + _pending_count(pending, "bandage"), "绷带已入包（%d → %d）" % [bandage_before, ConsumableConfig.get_count("bandage")])
	_expect(ConsumableConfig.get_count("dogfood") == dogfood_before + _pending_count(pending, "dogfood"), "狗粮已入包（%d → %d）" % [dogfood_before, ConsumableConfig.get_count("dogfood")])
	_expect(ConsumableConfig.get_count("food") >= food_before + 1, "本场至少获得 1 个食物")

func _pending_count(pending: Array, item_id: String) -> int:
	for entry in pending:
		if str(entry.get("item_id", "")) == item_id:
			return int(entry.get("count", 0))
	return 0
