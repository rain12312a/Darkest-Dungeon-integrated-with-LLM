extends SceneTree

# 临时探针脚本（端到端验证用，非游戏运行时代码）
# 用途：验证死门（Death's Door）机制——
#   ① 生命值归零不会立刻死亡，而是进入濒死（仍可行动/受治疗）
#   ② 濒死状态下受到伤害时按「角色自己的 death_blow_chance」掷死亡骰
#   ③ 治疗等非伤害结算不会掷死亡骰（含失败治疗 / 治疗他人）
#   ④ 概率取自 HeroConfig.HEROES[*].death_blow_chance
# 运行：godot --headless --path <项目> --script res://tools/_probe_deaths_door.gd

var _battle: Node = null
var _frame := 0
var _pass := 0
var _fail := 0

func _initialize() -> void:
	MonsterConfig.CURRENT_ENCOUNTER = ["skeleton_common", "skeleton_defender", "skeleton_arbalist", "skeleton_courtier"]
	var packed := load("res://scenes/battle/Battle.tscn") as PackedScene
	if packed == null:
		print("[DD] FAILED: cannot load Battle.tscn")
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
	_battle.set("battle_over", true) # 冻结自动战斗循环，保证断言确定性
	_check_config()
	_check_mechanics()
	print("[DD] ===== PASS=%d FAIL=%d =====" % [_pass, _fail])
	quit(0 if _fail == 0 else 1)
	return true

# ------------------------------------------------------------ ① 配置接线

func _check_config() -> void:
	print("[DD] --- ① 角色配置里的死门概率 ---")
	_expect(is_equal_approx(HeroConfig.DEFAULT_DEATH_BLOW_CHANCE, 0.5), "默认死门死亡概率为 0.5")
	for hero_id in HeroConfig.get_all_hero_ids():
		var chance: float = HeroConfig.get_death_blow_chance(hero_id)
		_expect(is_equal_approx(chance, 0.5), "角色 %s 自带 death_blow_chance = 0.5" % hero_id)
		_expect(HeroConfig.HEROES[hero_id].has("death_blow_chance"),
			"角色 %s 的配置条目里显式写了 death_blow_chance" % hero_id)
	# 战斗内运行时字典也带上该字段
	for h in _battle.get("heroes"):
		_expect(h.has("death_blow_chance"), "运行时英雄 %s 携带 death_blow_chance" % str(h.get("name", "?")))
		_expect(is_equal_approx(float(h.get("death_blow_chance", -1.0)), 0.5),
			"运行时英雄 %s 的概率为 0.5" % str(h.get("name", "?")))

# ------------------------------------------------------------ ② 机制

func _check_mechanics() -> void:
	print("[DD] --- ② 死门机制 ---")
	var heroes: Array = _battle.get("heroes")
	if heroes.size() < 2:
		_expect(false, "英雄数量不足以验证")
		return
	var h: Dictionary = heroes[0]
	var idx := 0
	# 保证是“从满血被打到 0”的路径
	h["hp"] = 3
	ActionResolver.apply_damage(h, 999)
	var died: bool = _battle.call("_handle_hero_damage_aftermath", idx, true)
	_expect(not died, "生命值归零不会立刻死亡")
	_expect(bool(h.get("is_death_door", false)), "英雄进入濒死（death's door）状态")
	_expect(int(h.get("hp", -1)) == 0, "濒死状态下生命值钳制为 0")
	_expect(_battle.get("heroes").size() == heroes.size(), "英雄仍在场上（未被移除）")

	# 濒死状态下仍可正常入队行动
	_expect(int(_battle.call("_count_heroes_alive")) >= 1, "濒死英雄仍计为存活单位（不会直接判负）")
	h["actions_remaining"] = 1
	var queue: TurnQueue = _battle.get("turn_queue")
	queue.call("build", _battle.get("heroes"), _battle.get("monsters"))
	var queued := false
	for entry in queue.get("_queue"):
		if str(entry.get("unit_type", "")) == "hero" and int(entry.get("index", -1)) == idx:
			queued = true
	_expect(queued, "濒死英雄仍会进入行动队列")

	# UI：濒死卡槽要渲染出死门图标 + 该角色的死亡概率提示
	_battle.call("_update_ui")
	var shown_label := false
	var shown_icon := false
	for slot in _battle.get("hero_slots"):
		if not is_instance_valid(slot):
			continue
		shown_label = shown_label or _has_text_node(slot, "DEATH'S DOOR")
		shown_icon = shown_icon or _has_texture_node(slot, "tray_deathsdoor")
	_expect(shown_label, "濒死英雄卡槽渲染出 DEATH'S DOOR 概率提示")
	_expect(shown_icon, "濒死英雄卡槽渲染出死门图标")
	_expect(_has_text_node(_battle.get("battle_ui"), "死门"), "死门提示文案可查（悬浮提示已就绪）")

	# 概率 = 0 → 反复挨打也不会死
	h["death_blow_chance"] = 0.0
	for i in range(20):
		ActionResolver.apply_damage(h, 5)
		var killed: bool = _battle.call("_handle_hero_damage_aftermath", idx, true)
		if killed:
			break
	_expect(bool(h.get("is_death_door", false)), "死亡概率 0% 时始终撑住（仍处于濒死）")
	_expect(int(h.get("hp", -1)) == 0, "死亡概率 0% 时生命值保持 0")

	# 治疗（非伤害）不掷死亡骰：即便治疗量为 0 也必须活着
	for i in range(10):
		_battle.call("_handle_hero_damage_aftermath", idx, false)
	_expect(not h.is_empty(), "治疗等非伤害结算不会掷死亡骰")
	_expect(bool(h.get("is_death_door", false)), "非伤害结算后仍处于濒死（未被误杀）")

	# 强制概率 = 100% → 下一次伤害必死
	h["death_blow_chance"] = 1.0
	var hero_name: String = str(h.get("name", "?"))
	ActionResolver.apply_damage(h, 5)
	var died_now: bool = _battle.call("_handle_hero_damage_aftermath", idx, true)
	_expect(died_now, "死亡概率 100% 时受到伤害必死")
	# 注意：用引用比对判定是否离场（队伍里可能存在同名英雄，如两个 Crusader）
	var still_there := false
	for hero in _battle.get("heroes"):
		if is_same(hero, h):
			still_there = true
	_expect(not still_there, "死亡后英雄被移出战场：%s" % hero_name)

	# 治疗脱离濒死
	var heroes2: Array = _battle.get("heroes")
	var h2: Dictionary = heroes2[0]
	h2["death_blow_chance"] = 0.5
	h2["hp"] = 0
	h2["is_death_door"] = true
	ActionResolver.apply_heal(h2, 5)
	_battle.call("_handle_hero_damage_aftermath", 0, false)
	_expect(not bool(h2.get("is_death_door", false)), "生命值回复后自动脱离濒死状态")

func _expect(condition: bool, label: String) -> void:
	if condition:
		_pass += 1
		print("[DD] PASS  ", label)
	else:
		_fail += 1
		print("[DD] FAIL  ", label)

# 递归查找文本节点（用于验证 UI 是否渲染出死门提示）
func _has_text_node(node: Node, needle: String) -> bool:
	if node == null or not is_instance_valid(node):
		return false
	if node is Label and str(node.text).contains(needle):
		return true
	if node is Control and str(node.tooltip_text).contains(needle):
		return true
	for child in node.get_children():
		if _has_text_node(child, needle):
			return true
	return false

# 递归查找使用了指定贴图的节点（用于验证死门图标）
func _has_texture_node(node: Node, path_fragment: String) -> bool:
	if node == null or not is_instance_valid(node):
		return false
	if node is TextureRect and node.texture != null and str(node.texture.resource_path).contains(path_fragment):
		return true
	for child in node.get_children():
		if _has_texture_node(child, path_fragment):
			return true
	return false
