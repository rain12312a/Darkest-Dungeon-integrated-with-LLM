extends SceneTree

# 临时探针脚本（端到端验证用，非游戏运行时代码）
# 用途：验证「战斗结算界面」（胜利 / 远征终结 / 战败）
#   ① 层级与几何：面板搬进了独立 CanvasLayer(105)，卡片与右侧战利品面板不重叠
#   ② 三种结局的标题 / 描述 / 徽记 / 按钮文案
#   ③ 战绩数值与真实战场一致，重复刷新不产生重复行
#   ④ 入场动画（淡入 + 缩放）真的播了
#   ⑤ 端到端 _end_battle()：普通胜利 / BOSS 胜利 / 全灭 三条路径
# 运行：godot --headless --path <项目> --script res://tools/_probe_end_battle.gd

var _battle: Node = null
var _frame := 0
var _elapsed := 0.0
var _intro_at := -1.0
var _phase := 0
var _pass := 0
var _fail := 0

func _initialize() -> void:
	HeroConfig.reset_party_state()
	ConsumableConfig.reset_inventory()
	MonsterConfig.CURRENT_ENCOUNTER = ["skeleton_common", "skeleton_defender"]
	var packed := load("res://scenes/battle/Battle.tscn") as PackedScene
	if packed == null:
		print("[END] FAILED: cannot load Battle.tscn")
		quit(1)
		return
	_battle = packed.instantiate()
	root.add_child(_battle)
	# 尽量把窗口设回设计分辨率：headless 下视口可能只有 64px 宽，
	# 那种尺寸下锚点算出来的矩形没有参考价值（几何断言会失真）
	root.size = Vector2i(1280, 720)

func _process(delta: float) -> bool:
	_frame += 1
	_elapsed += delta
	if _frame < 3:
		return false
	if _battle == null:
		quit(1)
		return true
	# 入场动画必须按【时间】判定，不能按帧数：
	# headless 下没有渲染，帧率会飙到几千帧/秒，等 40 帧可能才过了 0.1 秒
	if _phase == 0:
		_battle.set("battle_over", true) # 冻结自动战斗循环
		_test_layer_and_geometry()
		_test_states()
		_test_stats()
		_start_intro_animation()
		_intro_at = _elapsed
		_phase = 1
		return false
	if _phase == 1 and _elapsed - _intro_at >= 0.15:
		# 动画进行中：alpha 应该已经离开 0，但还没到 1
		var a := _panel_alpha()
		_expect(a > 0.0 and a < 1.0, "入场动画进行中（alpha=%.3f 介于 0 和 1）" % a)
		_phase = 2
		return false
	if _phase == 2 and _elapsed - _intro_at >= 0.9:
		_expect(is_equal_approx(_panel_alpha(), 1.0), "入场动画结束（alpha=%.4f）" % _panel_alpha())
		var card: Panel = _battle.get("_end_card")
		# TRANS_BACK 会先冲过 1.0 再回落，容差给 0.01
		_expect(absf(card.scale.x - 1.0) <= 0.01, "卡片缩放已回正（%s）" % str(card.scale))
		_test_end_to_end()
		_phase = 3
		return false
	if _phase == 3:
		_test_end_to_end_aftermath()
		print("[END] ===== PASS=%d FAIL=%d ====" % [_pass, _fail])
		quit(0 if _fail == 0 else 1)
		return true
	return false

func _expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("[END]   PASS  ", label)
	else:
		_fail += 1
		print("[END]   FAIL  ", label)

# 标题/按钮文案里刻意放了全角空格做字距（「返  回  地  图」），比对前先抹掉空格
func _flat(s: String) -> String:
	return s.replace(" ", "").replace("\u3000", "")

func _consts() -> Dictionary:
	return (_battle.get_script() as Script).get_script_constant_map()

func _panel_alpha() -> float:
	return (_battle.get("victory_panel") as Panel).modulate.a

# ------------------------------------------------------------ ① 层级与几何

func _test_layer_and_geometry() -> void:
	print("[END] --- ① 层级与几何 ---")
	var consts := _consts()
	_expect(int(consts.get("END_LAYER", -1)) == 105, "END_LAYER = 105")
	_expect(int(consts.get("LOOT_LAYER", -1)) == 110, "LOOT_LAYER = 110（结算界面在其之下）")
	var size: Vector2 = consts.get("END_CARD_SIZE", Vector2.ZERO)
	_expect(size.is_equal_approx(Vector2(660, 430)), "卡片设计尺寸 660x430")

	# 面板必须搬进独立 CanvasLayer —— 否则角色 SpinePlayer（z_index=10）会画在卡片前面
	var panel: Panel = _battle.get("victory_panel")
	var parent := panel.get_parent()
	_expect(parent is CanvasLayer, "结算面板已移入 CanvasLayer（实得 %s）" % parent.get_class())
	if parent is CanvasLayer:
		_expect((parent as CanvasLayer).layer == 105, "该 CanvasLayer.layer = 105")
	_expect(panel.mouse_filter == Control.MOUSE_FILTER_STOP, "面板阻挡底层战斗 UI 的点击")

	var card: Panel = _battle.get("_end_card")
	_expect(card != null, "卡片节点已构建")
	if card == null:
		return
	var card_rect: Rect2 = card.get_global_rect()
	_expect(absf(card_rect.size.x - 660.0) <= 8.0, "卡片实际宽度 %.1f ≈ 660" % card_rect.size.x)
	_expect(absf(card_rect.size.y - 430.0) <= 8.0, "卡片实际高度 %.1f ≈ 430" % card_rect.size.y)

	var loot_panel: Panel = _battle.get("loot_panel")
	_expect(loot_panel != null, "战利品面板存在")
	# 战利品面板贴右边缘：它距右边 300px（offset_left = -300）
	var loot_left_inset: float = - loot_panel.offset_left if loot_panel != null else 300.0
	var vw := float(root.size.x)
	if vw >= 1200.0:
		# 视口够宽：直接比实际矩形
		_expect(absf(card_rect.get_center().x - vw * 0.5) <= 6.0,
			"卡片水平居中（中心 x=%.1f，视口中心 %.1f）" % [card_rect.get_center().x, vw * 0.5])
		if loot_panel != null:
			var loot_rect: Rect2 = loot_panel.get_global_rect()
			_expect(not card_rect.intersects(loot_rect),
				"卡片与战利品面板不重叠（卡片右缘 %.1f < 战利品左缘 %.1f）" % [card_rect.end.x, loot_rect.position.x])
	else:
		print("[END]   注：headless 视口仅 %d 宽 → 几何改用设计分辨率（1280）算术校验" % int(vw))
		# 不重叠条件：卡片右缘 + 间隙 ≤ 战利品左缘
		#   W/2 + 330 + 8 ≤ W - 300  →  2 × (330 + 8 + 300) ≤ W
		var need_w := 2.0 * (card_rect.size.x * 0.5 + 8.0 + loot_left_inset)
		_expect(need_w <= 1280.0,
			"在 1280 宽下不重叠（需要至少 %.0f，余量 %.0f px）" % [need_w, 1280.0 - need_w])

	# 装饰条 / 三张徽记素材必须真实存在
	_expect(ResourceLoader.exists(str(_consts().get("END_DECOR", ""))), "装饰条素材存在（announcement_frame.png）")
	var art: Dictionary = _consts().get("END_ART_BY_STATE", {})
	_expect(art.size() == 3, "三种结局各有一张徽记/插画")
	for key in art.keys():
		_expect(ResourceLoader.exists(str(art[key])), "%s 的徽记素材存在（%s）" % [key, str(art[key]).get_file()])

# ------------------------------------------------------------ ② 三种结局

# 直接驱动内容刷新（不经过 _end_battle），逐项核对文案与素材
func _test_states() -> void:
	print("[END] --- ② 三种结局的文案与素材 ---")
	var cases := [
		{"state": "victory", "won": true, "complete": false, "title": "胜", "button": "返回", "art": "quest_complete.png"},
		{"state": "run_complete", "won": true, "complete": true, "title": "远征", "button": "凯旋", "art": "quest_return_to_hamlet.png"},
		{"state": "defeat", "won": false, "complete": false, "title": "败", "button": "重新", "art": "seal.affliction.png"},
	]
	var panel: Panel = _battle.get("victory_panel")
	var title: Label = _battle.get("victory_label")
	var button: Button = _battle.get("back_button")
	var subtitle: Label = _battle.get("_end_subtitle")
	var art: TextureRect = _battle.get("_end_art")
	_expect(title != null and button != null and subtitle != null and art != null, "标题/描述/按钮/徽记四个控件都已构建")
	if title == null or button == null or art == null:
		return

	for c in cases:
		_battle.set("_battle_won", bool(c["won"]))
		_battle.set("_run_complete", bool(c["complete"]))
		panel.visible = true
		_battle.call("_refresh_end_battle_content")
		_expect(str(_battle.get("_end_state")) == str(c["state"]), "%s：内部状态正确" % c["state"])
		_expect(str(c["title"]) in _flat(title.text), "%s：标题含「%s」（实得「%s」）" % [c["state"], c["title"], title.text])
		_expect(str(c["button"]) in _flat(button.text), "%s：按钮含「%s」（实得「%s」）" % [c["state"], c["button"], button.text])
		_expect(art.texture != null and art.texture.resource_path.ends_with(str(c["art"])),
			"%s：徽记 = %s" % [c["state"], str(c["art"])])
		_expect(not subtitle.text.is_empty(), "%s：有结局描述文本" % c["state"])
		_expect(button.text.strip_edges().length() >= 4, "%s：按钮文案非空" % c["state"]) # 战败标题必须走血红、徽记也要染红（原本是黑色剪影，不染会完全看不见）
		if str(c["state"]) == "defeat":
			var tc: Color = title.get_theme_color("font_color")
			_expect(tc.r > tc.g and tc.r > tc.b, "战败标题为血红色（%s）" % str(tc))
			_expect(art.modulate.r > art.modulate.g, "战败徽记染成血色（modulate=%s）" % str(art.modulate))
		else:
			var tg: Color = title.get_theme_color("font_color")
			_expect(tg.g >= tg.b and tg.r > 0.8, "%s 标题为金色（%s）" % [c["state"], str(tg)])
			_expect(art.modulate.is_equal_approx(Color(1, 1, 1, 1)), "%s 徽记保持原色" % c["state"])

# ------------------------------------------------------------ ③ 战绩

func _test_stats() -> void:
	print("[END] --- ③ 战绩数值 ---")
	var stats: VBoxContainer = _battle.get("_end_stats")
	_expect(stats != null, "战绩容器已构建")
	if stats == null:
		return
	_expect(stats.get_child_count() == 4, "战绩共 4 行（实得 %d）" % stats.get_child_count())

	var heroes: Array = _battle.get("heroes")
	var hp_sum := 0
	var max_sum := 0
	for h in heroes:
		hp_sum += int(h.get("hp", 0))
		max_sum += int(h.get("max_hp", 0))
	var alive: int = _battle.call("_count_heroes_alive")

	var texts: Array = []
	for row in stats.get_children():
		var parts: Array = []
		for c in row.get_children():
			parts.append((c as Label).text)
		texts.append(parts)

	_expect("战斗回合" in str(texts[0][0]), "① 战斗回合")
	_expect(str(texts[0][1]) == str(int(_battle.get("round_number"))), "回合数与 round_number 一致（%s）" % texts[0][1])
	_expect("存活英雄" in str(texts[1][0]), "② 存活英雄")
	_expect(str(texts[1][1]) == "%d / %d" % [alive, heroes.size()], "存活英雄 = %d / %d" % [alive, heroes.size()])
	_expect("生命" in str(texts[2][0]), "③ 队伍剩余生命")
	_expect(str(texts[2][1]) == "%d / %d" % [hp_sum, max_sum], "剩余生命 = %d / %d" % [hp_sum, max_sum])
	_expect("压力" in str(texts[3][0]), "④ 队伍平均压力")

	# 重复刷新不能翻倍（旧行必须先 remove_child 再 queue_free）
	_battle.call("_refresh_end_battle_content")
	_expect(stats.get_child_count() == 4, "重复刷新后仍是 4 行（实得 %d）" % stats.get_child_count())
	_battle.call("_refresh_end_battle_content")
	_expect(stats.get_child_count() == 4, "再刷新一次仍是 4 行（实得 %d）" % stats.get_child_count())

# ------------------------------------------------------------ ④ 入场动画

func _start_intro_animation() -> void:
	print("[END] --- ④ 入场动画 ---")
	var panel: Panel = _battle.get("victory_panel")
	_battle.set("_battle_won", true)
	_battle.set("_run_complete", false)
	panel.visible = true
	_battle.call("_refresh_end_battle_content")
	_expect(is_equal_approx(_panel_alpha(), 0.0), "刷新瞬间面板 alpha = 0（等待淡入）")
	var card: Panel = _battle.get("_end_card")
	_expect(card.scale.x < 1.0, "卡片起始缩放 < 1（%s）" % str(card.scale))
	_expect(card.pivot_offset.is_equal_approx(Vector2(330, 215)), "缩放支点在卡片中心（%s）" % str(card.pivot_offset))

# ------------------------------------------------------------ ⑤ 端到端

func _test_end_to_end() -> void:
	print("[END] --- ⑤ 端到端 _end_battle() ---")
	var panel: Panel = _battle.get("victory_panel")
	var title: Label = _battle.get("victory_label")
	var button: Button = _battle.get("back_button")
	var modal: ColorRect = _battle.get("loot_modal")
	var heroes: Array = _battle.get("heroes")
	var monsters: Array = _battle.get("monsters")

	# ① 普通胜利 → 胜利 + 战利品锁定返回按钮
	DungeonMap.current_room = "room_not_boss"
	for m in monsters:
		m["hp"] = 0
		m["is_corpse"] = false
	_battle.set("battle_over", false)
	_battle.call("_end_battle")
	_expect(panel.visible, "普通胜利：结算界面可见")
	_expect("胜" in _flat(title.text), "普通胜利：标题「胜利」（实得「%s」）" % title.text)
	_expect("返回地图" in _flat(button.text), "普通胜利：按钮「返回地图」（实得「%s」）" % button.text)
	_expect(modal.visible, "普通胜利：右侧战利品面板同时弹出")
	_expect(button.disabled, "普通胜利：未确认战利品前按钮被锁定")
	_expect(panel.get_parent() is CanvasLayer and (panel.get_parent() as CanvasLayer).layer < 110,
		"结算层级低于战利品层级（%d < 110）" % (panel.get_parent() as CanvasLayer).layer)

	# ② BOSS 房胜利 → 远征终结
	DungeonMap.set_size("small")
	var boss_room := DungeonMap.BOSS_ROOM
	_expect(not boss_room.is_empty(), "已拿到 BOSS 房 id（%s）" % boss_room)
	DungeonMap.current_room = boss_room
	_battle.set("battle_over", false)
	_battle.call("_end_battle")
	_expect(str(_battle.get("_end_state")) == "run_complete", "BOSS 胜利：判定为远征终结")
	_expect("远征终结" in _flat(title.text), "BOSS 胜利：标题「远征终结」（实得「%s」）" % title.text)
	_expect("凯旋而归" in _flat(button.text), "BOSS 胜利：按钮「凯旋而归」（实得「%s」）" % button.text)

	# ③ 全灭 → 败北，没有战利品、按钮直接可用
	for m in monsters:
		m["hp"] = int(m.get("max_hp", 10))
		m["is_corpse"] = false
	for h in heroes:
		h["hp"] = 0
	_battle.set("battle_over", false)
	_battle.call("_end_battle")
	_expect(str(_battle.get("_end_state")) == "defeat", "全灭：判定为败北")
	_expect("败北" in _flat(title.text), "全灭：标题「败北」（实得「%s」）" % title.text)
	_expect("重新开始" in _flat(button.text), "全灭：按钮「重新开始」（实得「%s」）" % button.text)
	_expect(not modal.visible, "全灭：不弹战利品面板")
	_expect(not button.disabled, "全灭：按钮立即可用（无需确认战利品）")
	_expect((_battle.get("_pending_loot") as Array).is_empty(), "全灭：待领战利品已清空")
	_update_stat_hp_expect()

func _update_stat_hp_expect() -> void:
	# 全灭后再刷一次内容：存活英雄 / 剩余生命 都必须变成红色
	var stats: VBoxContainer = _battle.get("_end_stats")
	if stats == null or stats.get_child_count() < 4:
		return
	var alive_val: Label = (stats.get_child(1) as HBoxContainer).get_child(1) as Label
	var hp_val: Label = (stats.get_child(2) as HBoxContainer).get_child(1) as Label
	_expect(alive_val.text == "0 / 4", "全灭战绩：存活英雄 0 / 4（实得 %s）" % alive_val.text)
	var c: Color = alive_val.get_theme_color("font_color")
	_expect(c.r > c.g, "全灭战绩：存活英雄数值标红")
	_expect(hp_val.text.begins_with("0 / "), "全灭战绩：剩余生命 0 / N（实得 %s）" % hp_val.text)

# 结束时补一条：结算面板在角色之上（靠 CanvasLayer 而非 z_index）
func _test_end_to_end_aftermath() -> void:
	print("[END] --- ⑥ 收尾 ---")
	var panel: Panel = _battle.get("victory_panel")
	var layer := panel.get_parent() as CanvasLayer
	_expect(layer != null, "结算面板始终挂在 CanvasLayer 下")
	# 角色 SpinePlayer 挂在 Battle 根节点下、并被设成 z_index=10，
	# 只有独立 CanvasLayer 才能保证结算卡片盖在它们前面
	var spine_above := false
	for child in _battle.get_children():
		if child is SpinePlayer:
			spine_above = int(child.z_index) >= int(layer.layer)
			break
	_expect(not spine_above, "角色 SpinePlayer 的 z_index(10) < 结算层(105) → 卡片盖住角色")
	_expect((_battle.get("_end_stats") as VBoxContainer).get_child_count() == 4, "收尾后战绩行数仍为 4")
