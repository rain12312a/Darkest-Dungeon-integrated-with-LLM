extends SceneTree

# 临时探针脚本（端到端验证用，非游戏运行时代码）
# 用途：
#   ① 复现 BOSS 战"怪物尸体显示 / 打掉尸体后补位"的问题（含怪物与英雄槽位）
#   ② 量出英雄卡槽内各 UI 元素的实际矩形，确认状态栏被下方 UI 遮挡的溢出量
# 运行：godot --headless --path <项目> --script res://tools/_probe_corpse_ui.gd

var _battle: Node = null
var _frame := 0
var _pass := 0
var _fail := 0

func _initialize() -> void:
	MonsterConfig.CURRENT_ENCOUNTER = ["brigand_sapper", "brigand_barrel", "brigand_fuseman", "brigand_cannon"]
	HeroConfig.reset_party_state()
	var packed := load("res://scenes/battle/Battle.tscn") as PackedScene
	if packed == null:
		print("[CUI] FAILED: cannot load Battle.tscn")
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
		_battle.set("battle_over", true) # 冻结自动战斗循环
		_check_corpse_flow()
		return false
	if _frame == 6:
		# 靠近测量帧再铺 fiиxture：战斗循环仍在推进，状态持续时间会被 tick 递减
		_prepare_layout_fixture()
		return false
	if _frame == 9:
		# 等容器完成布局（_update_ui 当帧内子节点尚未排版）后再量尺寸
		_measure_hero_slot()
		print("[CUI] ===== PASS=%d FAIL=%d ====" % [_pass, _fail])
		quit(0 if _fail == 0 else 1)
	return false

# 造出"折磨 + 流血 + 瀕死"的最坏情况，让状态栏与死门行同时存在
# 持续时间给足（99），避免被战斗循环的 tick 提前清掉
func _prepare_layout_fixture() -> void:
	var heroes: Array = _battle.get("heroes")
	if heroes.is_empty():
		return
	var h: Dictionary = heroes[0]
	ActionResolver.apply_status(h, StressConfig.AFFLICTION_STATUS, 1, 99)
	ActionResolver.apply_status(h, "bleed", 3, 99)
	ActionResolver.apply_status(h, "blight", 2, 99)
	h["hp"] = 0
	h["is_death_door"] = true
	_battle.call("_update_ui")

# ------------------------------------------------------------ ① 尸体与补位

func _check_corpse_flow() -> void:
	print("[CUI] --- ① 尸体显示与补位 ---")
	var monsters: Array = _battle.get("monsters")
	_expect(monsters.size() == 4, "BOSS 遭遇共 4 名怪物")
	print("[CUI] 初始怪物：", _monster_brief())

	# 1) 打死 2 号位（弹药桶）→ 应变成尸体（hp=10、is_corpse=true、换成普通小怪残骸）
	_kill_monster(1)
	_battle.call("_update_ui")
	var corpse: Dictionary = monsters[1]
	_expect(bool(corpse.get("is_corpse", false)), "怪物阵亡后标记为尸体")
	_expect(int(corpse.get("hp", 0)) == 10, "尸体血量为 10（实际 %d）" % int(corpse.get("hp", 0)))
	_expect(_battle.get("_spine_players").has("monster_1"), "尸体仍保留 SpinePlayer（不会立刻消失）")
	var state: String = str(_battle.get("_spine_current_state").get("monster_1", ""))
	_expect(state == "dead", "尸体 SpinePlayer 切到 dead 姿态（实际 %s）" % state)
	_expect(_is_remains(_corpse_asset(1)), "无 dead 动画的骨架改用普通小怪残骸（实际 %s）" % _corpse_asset(1))
	_expect(_slot_has_text("MonsterSlot2", "CORPSE"), "2 号怪物槽显示尸体标记")

	# 2) 打掉尸体 → 后方怪物补位，且 4 号槽不应残留旧内容
	var ids_before := _monster_ids()
	_kill_monster(1) # 尸体 hp 10 → 归零 → 清除尸体 + 补位
	_battle.call("_update_ui")
	var ids_after := _monster_ids()
	_expect(_battle.get("monsters").size() == 3, "尸体被清除后怪物数为 3（实际 %d）" % _battle.get("monsters").size())
	_expect(ids_after == [ids_before[0], ids_before[2], ids_before[3]],
		"后方怪物正确补位：%s → %s" % [str(ids_before), str(ids_after)])
	_expect(not _battle.get("_spine_players").has("monster_3"), "4 号 SpinePlayer 缓存已清除")
	_expect(_spine_matches_monsters(), "补位后每个 SpinePlayer 与怪物数据一一对应（骨架路径一致）")
	_expect(_slot_child_count("MonsterSlot4") == 0, "补位后 4 号怪物槽已清空（实际 %d 个子节点）" % _slot_child_count("MonsterSlot4"))

	# 2.5) 尸体槽位召唤：新单位必须换回自己的骨架（而不是继续顶着残骸）
	_kill_monster(0) # 首领阵亡 → 留下尸体
	_battle.call("_update_ui")
	_expect(_is_remains(_corpse_asset(0)), "首领尸体同样换成普通小怪残骸：%s" % _corpse_asset(0))
	var summon_idx: int = int(_battle.call("_summon_monster", "brigand_sapper"))
	_battle.call("_update_ui")
	_expect(summon_idx == 0, "召唤复用了尸体槽位 1（实际 %d）" % (summon_idx + 1))
	var summoned: Dictionary = (_battle.get("monsters") as Array)[summon_idx]
	_expect(not bool(summoned.get("is_corpse", false)), "召唤单位不是尸体")
	_expect(not _is_remains(_corpse_asset(summon_idx)), "召唤单位换回自身骨架（实际 %s）" % _corpse_asset(summon_idx))
	_expect(_spine_matches_monsters(), "召唤后 SpinePlayer 与数据仍一一对应")

	# 3) 英雄阵亡补位同理：最后一个英雄槽不应残留
	var heroes: Array = _battle.get("heroes")
	var hero_count_before := heroes.size()
	var hero_slot_last := "HeroSlot%d" % hero_count_before
	_expect(_slot_child_count(hero_slot_last) > 0, "阵亡前最后一个英雄槽有内容")
	var victim: Dictionary = heroes[hero_count_before - 1]
	victim["hp"] = 0
	victim["is_death_door"] = false
	_battle.call("_handle_hero_damage_aftermath", hero_count_before - 1, true)
	_battle.call("_kill_hero", _battle.get("heroes").find(victim))
	_battle.call("_update_ui")
	_expect(_battle.get("heroes").size() == hero_count_before - 1, "英雄阵亡后从数组移除")
	_expect(_slot_child_count(hero_slot_last) == 0, "英雄补位后末位英雄槽已清空（实际 %d 个子节点）" % _slot_child_count(hero_slot_last))

	# 探针直接改数组绕过了正常流程，这里补一次队列重建（真实游戏里单位移除必然伴随 build），
	# 否则 current_actor 可能仍指向被移除的下标，async 战斗循环恢复时会越界访问
	var queue = _battle.get("turn_queue")
	if queue != null:
		queue.build(_battle.get("heroes"), _battle.get("monsters"))
	_battle.set("current_actor", {})

func _kill_monster(idx: int) -> void:
	var monsters: Array = _battle.get("monsters")
	if idx < 0 or idx >= monsters.size():
		return
	monsters[idx]["hp"] = 0
	_battle.call("_handle_monster_damage_aftermath", idx)

func _monster_ids() -> Array:
	var ids: Array = []
	for m in _battle.get("monsters"):
		ids.append(str(m.get("id", "")))
	return ids

func _monster_brief() -> String:
	var parts := PackedStringArray()
	for m in _battle.get("monsters"):
		parts.append("%s(hp=%d%s)" % [str(m.get("id", "")), int(m.get("hp", 0)), ",尸" if m.get("is_corpse", false) else ""])
	return " ".join(parts)

# 校验每个 "monster_i" 的 SpinePlayer 加载的骨架路径与 monsters[i].id 一致
func _spine_matches_monsters() -> bool:
	var players: Dictionary = _battle.get("_spine_players")
	var monsters: Array = _battle.get("monsters")
	for i in range(monsters.size()):
		var key := "monster_%d" % i
		if not players.has(key):
			print("[CUI]   缺少 SpinePlayer：", key)
			return false
		var sp: SpinePlayer = players[key]
		if not is_instance_valid(sp):
			print("[CUI]   SpinePlayer 无效：", key)
			return false
		var skel_path: String = str(sp.current_skel_path)
		if not skel_path.contains(str(monsters[i].get("id", ""))):
			print("[CUI]   %s 骨架路径与数据不匹配：%s vs id=%s" % [key, skel_path, str(monsters[i].get("id", ""))])
			return false
	return true

# 尸体当前加载的骨架资源路径（无 dead 动画的骨架应指向普通小怪残骸）
func _corpse_asset(idx: int) -> String:
	var players: Dictionary = _battle.get("_spine_players")
	var key := "monster_%d" % idx
	if not players.has(key):
		return ""
	var sp: SpinePlayer = players[key]
	if not is_instance_valid(sp):
		return ""
	return str(sp.current_skel_path)

# 是否为普通小怪的残骸资源（默认借用 brigand_cutthroat 的 dead）
func _is_remains(skel_path: String) -> bool:
	return skel_path.contains("cutthroat") and skel_path.contains("dead")

func _slot_has_text(slot_name: String, needle: String) -> bool:
	var slot := _find_slot(slot_name)
	if slot == null:
		return false
	return _tree_has_text(slot, needle)

func _tree_has_text(node: Node, needle: String) -> bool:
	if node is Label and str(node.text).contains(needle):
		return true
	for c in node.get_children():
		if _tree_has_text(c, needle):
			return true
	return false

func _slot_child_count(slot_name: String) -> int:
	var slot := _find_slot(slot_name)
	if slot == null:
		return -1
	# _clear_children 用 queue_free（帧末才释放），同帧内旧内容仍挂在树上，
	# 因此只统计"未被标记删除"的节点，才能反映玩家实际看到的画面
	var n := 0
	for c in slot.get_children():
		if not c.is_queued_for_deletion():
			n += 1
	return n

func _find_slot(slot_name: String) -> Node:
	var battle_ui: Node = _battle.get("battle_ui")
	if battle_ui == null:
		return null
	return _find_by_name(battle_ui, slot_name)

func _find_by_name(node: Node, target: String) -> Node:
	if node.name == target:
		return node
	for c in node.get_children():
		var found := _find_by_name(c, target)
		if found != null:
			return found
	return null

# ------------------------------------------------------------ ② 英雄卡槽布局测量

func _measure_hero_slot() -> void:
	print("[CUI] --- ② 英雄卡槽布局测量 ---")
	var heroes: Array = _battle.get("heroes")
	if heroes.is_empty():
		_expect(false, "没有可用英雄用于布局测量")
		return
	print("[CUI] 测量时英雄0：%s hp=%d 死门=%s 状态=%s" % [
		str(heroes[0].get("name", "?")), int(heroes[0].get("hp", -1)),
		str(heroes[0].get("is_death_door", false)), str((heroes[0].get("statuses", {}) as Dictionary).keys())])
	var slots: Array = _battle.get("hero_slots")
	var slot: Control = slots[0]
	# 注意：_clear_children 用 queue_free（帧末释放），同帧内旧内容仍在，
	# 因此必须取"未被标记删除"的内容节点（本次刚重建的那份）
	var content: Control = null
	for c in slot.get_children():
		if c is Control and not (c is VBoxContainer) and not c.is_queued_for_deletion():
			content = c
	if content == null:
		_expect(false, "英雄槽内未找到内容容器")
		return
	# 卡槽内容内：竖排 VBox（速度/肖像/血条/压力条）与顶部悬浮 VBox（状态行/死门行）
	var vbox: VBoxContainer = null
	var overlay: VBoxContainer = null
	for c in content.get_children():
		if c is VBoxContainer and not c.is_queued_for_deletion():
			if str(c.name).contains("TopOverlay"):
				overlay = c
			else:
				vbox = c
	print("[CUI] 英雄槽 rect=%s 内容 rect=%s（内容高 %.1f vs 槽高 %.1f）" % [
		str(slot.get_global_rect()), str(content.get_global_rect()), content.size.y, slot.size.y])
	# 真正需要保证的不是"不溢出卡槽"（设计上血条/压力条就落在卡槽下沿外、角色脚底踩在卡槽底部），
	# 而是"没有任何一行被下方不透明 UI 遮住"
	var occluder: Control = _find_slot("BottomPanelsContainer") as Control
	var occluder_top: float = occluder.get_global_rect().position.y if occluder != null else 344.0
	print("[CUI] 下方不透明 UI 顶边 y=%.1f" % occluder_top)

	var all_rows := PackedStringArray()
	var row_nodes: Array[Control] = []
	for list in [overlay, vbox]:
		if list == null:
			continue
		for c in list.get_children():
			if c is Control and not c.is_queued_for_deletion():
				var ctl: Control = c
				var label := ""
				if ctl is Label:
					label = str((ctl as Label).text)
				elif ctl is ProgressBar:
					label = "bar %d/%d" % [int((ctl as ProgressBar).value), int((ctl as ProgressBar).max_value)]
				all_rows.append("[%.1f~%.1f h=%.1f %s]%s" % [
					ctl.get_global_rect().position.y, ctl.get_global_rect().end.y, ctl.size.y,
					ctl.get_class(), (" " + label) if label != "" else ""])
				row_nodes.append(ctl)
	print("[CUI] 卡槽内元素（全局 Y 区间）：")
	for r in all_rows:
		print("[CUI]   ", r)
	var lowest: float = 0.0
	for ctl in row_nodes:
		lowest = maxf(lowest, ctl.get_global_rect().end.y)
	print("[CUI] 最低一行底部 %.1f（可见上限 %.1f）" % [lowest, occluder_top])
	_expect(lowest <= occluder_top, "英雄卡槽所有行都未被下方 UI 遮挡（最低 %.1f ≤ %.1f）" % [lowest, occluder_top])

	# 状态栏必须存在于顶部悬浮区，且完全落在可见范围内
	var status_row: Control = null
	if overlay != null:
		for c in overlay.get_children():
			if c is HBoxContainer and not c.is_queued_for_deletion():
				status_row = c
				break
	_expect(status_row != null, "状态栏被挂到卡槽顶部悬浮区（不再被下方 UI 遮挡）")
	if status_row == null:
		print("[CUI] （未找到状态栏行，跳过遮挡分析）")
		return
	var srect: Rect2 = status_row.get_global_rect()
	print("[CUI] 状态栏 rect=%s（底部 %.1f）" % [str(srect), srect.end.y])
	var content_top: float = content.get_global_rect().position.y
	_expect(srect.end.y <= occluder_top, "状态栏完全可见（底部 %.1f ≤ %.1f）" % [srect.end.y, occluder_top])
	_expect(srect.position.y >= 0.0 and srect.end.y <= content_top,
		"状态栏落在角色上方空白带（%.1f~%.1f，应在 0~%.1f）" % [srect.position.y, srect.end.y, content_top])
	if not _battle.get("heroes")[0].get("is_death_door", false):
		_expect(false, "测试用英雄应处于死门状态（否则测不到死门行）")
	var dd_row: Control = null
	if overlay != null:
		for c in overlay.get_children():
			if c is HBoxContainer and not c.is_queued_for_deletion() and c != status_row:
				dd_row = c
	_expect(dd_row != null, "死门提示行挂在顶部悬浮区")
	if dd_row != null:
		var drect: Rect2 = dd_row.get_global_rect()
		print("[CUI] 死门行 rect=%s（底部 %.1f）" % [str(drect), drect.end.y])
		_expect(drect.end.y <= occluder_top, "死门行完全可见（底部 %.1f ≤ %.1f）" % [drect.end.y, occluder_top])
		_expect(drect.position.y >= 0.0 and drect.end.y <= content_top,
			"死门行落在角色上方空白带（%.1f~%.1f，应在 0~%.1f）" % [drect.position.y, drect.end.y, content_top])

	# 角色脚底（SpinePlayer 原点）必须仍在卡槽底部（约 y=200），不能因为排版下移扎进下方面板
	var anchor: Control = null
	if vbox != null:
		for c in vbox.get_children():
			if c is Control and not (c is Label) and not (c is ProgressBar) and not c.is_queued_for_deletion():
				anchor = c
				break
	if anchor != null:
		var feet: float = anchor.get_global_rect().position.y + anchor.size.y * 0.9
		print("[CUI] 角色脚底线 y=%.1f（锚点 %s）" % [feet, str(anchor.get_global_rect())])
		_expect(absf(feet - 200.0) <= 8.0, "角色脚底仍踩在卡槽底部（y=%.1f，目标 200±8）" % feet)
	var sep: int = -1
	if vbox != null:
		sep = vbox.get_theme_constant("separation")
	print("[CUI] 当前 vbox separation=%d" % sep)

	# 统计所有与该区域内相交的外部 UI（帮助定位潜在遮挡）
	var overlappers := PackedStringArray()
	_collect_overlaps(_battle.get("battle_ui"), Rect2(530.0, 20.0, 110.0, 60.0), overlappers)
	print("[CUI] 顶部悬浮区(530,20,110,60) 相交的外部 UI：")
	for o in overlappers:
		print("[CUI]   ", o)

# 递归收集与该矩形相交的控件（排除卡槽内部节点自身）
func _collect_overlaps(node: Node, target: Rect2, out: PackedStringArray) -> void:
	for c in node.get_children():
		if c is Control:
			var ctl: Control = c
			var r: Rect2 = ctl.get_global_rect()
			if r.size.x > 1.0 and r.size.y > 1.0 and r.intersects(target):
				out.append("%s(%s) rect=[%.1f~%.1f]" % [str(ctl.name), ctl.get_class(), r.position.y, r.end.y])
		_collect_overlaps(c, target, out)

func _expect(condition: bool, label: String) -> void:
	if condition:
		_pass += 1
		print("[CUI] PASS  ", label)
	else:
		_fail += 1
		print("[CUI] FAIL  ", label)
