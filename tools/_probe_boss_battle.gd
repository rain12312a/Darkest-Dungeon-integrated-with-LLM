extends SceneTree

# 临时探针脚本（端到端验证用，非游戏运行时代码）
# 用途：真实验证"门前恶狼" BOSS 战的接线是否完整——
#   ① 数据接线：怪物模板 / 技能 / 状态 / 动画与特效资源是否齐全
#   ② 机制接线：首领投弹标记 → 下回合引爆、弹药桶被摧毁 → 哑弹解除、
#              点火员装填 → 大炮开火卸弹、战斗内召唤、生命链接
# 运行：godot --headless --path <项目> --script res://tools/_probe_boss_battle.gd
# 注意：Godot 是 GUI 子系统程序，PowerShell 下必须用管道（| Select-String / Tee-Object）才能拿到输出

const BOSS_ENCOUNTER: Array[String] = ["brigand_sapper", "brigand_barrel", "brigand_fuseman", "brigand_cannon"]
const LEADER_SKILLS := ["sapper_throw", "sapper_summon", "sapper_barrage"]
const CANNON_SKILLS := ["cannon_fire", "cannon_summon", "cannon_blast"]
const FUSEMAN_SKILLS := ["fuseman_light_fuse", "fuseman_hot_shot"]

var _battle: Node = null
var _frame := 0
var _pass := 0
var _fail := 0

func _initialize() -> void:
	MonsterConfig.CURRENT_ENCOUNTER = BOSS_ENCOUNTER
	var packed := load("res://scenes/battle/Battle.tscn") as PackedScene
	if packed == null:
		print("[BOSS] FAILED: cannot load Battle.tscn")
		quit(1)
		return
	_battle = packed.instantiate()
	root.add_child(_battle)

func _process(_delta: float) -> bool:
	_frame += 1
	if _frame < 3:
		return false # 等 _ready 与首帧 UI/Spine 初始化完成
	if _battle == null:
		quit(1)
		return true

	# 冻结自动战斗循环，让断言可以确定性地逐条执行
	_battle.set("battle_over", true)
	_check_data_wiring()
	_check_boss_mechanics()

	print("[BOSS] ===== PASS=%d FAIL=%d =====" % [_pass, _fail])
	quit(0 if _fail == 0 else 1)
	return true

# ------------------------------------------------------------ 断言工具

func _expect(condition: bool, label: String) -> void:
	if condition:
		_pass += 1
		print("[BOSS] PASS  ", label)
	else:
		_fail += 1
		print("[BOSS] FAIL  ", label)

func _monsters() -> Array:
	return _battle.get("monsters")

func _heroes() -> Array:
	return _battle.get("heroes")

# 该怪物当前能否使用某技能（走的就是战斗内真实的筛选函数）
func _can_use(monster_idx: int, skill_id: String) -> bool:
	var sd := SkillConfig.get_skill(skill_id)
	if sd.is_empty():
		return false
	if not _battle.call("_meets_skill_conditions", monster_idx, sd):
		return false
	var targets: Array = _battle.call("_get_valid_targets_for_monster", monster_idx, sd)
	if targets.is_empty():
		return false
	var use_positions: Array = sd.get("use_positions", [])
	if not use_positions.is_empty() and not ((monster_idx + 1) in use_positions):
		return false
	return true

func _skill_constant_map() -> Dictionary:
	var script: GDScript = _battle.get_script()
	return script.get_script_constant_map()

func _check_asset_pair(base_path: String, label: String) -> void:
	var ok := FileAccess.file_exists(base_path + ".skel") and FileAccess.file_exists(base_path + ".atlas")
	_expect(ok, label)

# ------------------------------------------------------------ ① 数据接线

func _check_data_wiring() -> void:
	print("[BOSS] --- ① 数据接线 ---")
	for mid in BOSS_ENCOUNTER:
		_expect(MonsterConfig.monster_exists(mid), "怪物模板存在：" + mid)

	# 所有怪物技能都能解析，附带状态都已登记
	for mid in MonsterConfig.get_all_monster_ids():
		var tpl: Dictionary = MonsterConfig.MONSTERS[mid]
		for sid in tpl.get("skills", []):
			var sd := SkillConfig.get_skill(str(sid))
			_expect(not sd.is_empty(), "技能已定义：%s → %s" % [mid, sid])
			for se in sd.get("status_effects", []):
				var status_id := str(se.get("status_id", ""))
				_expect(StatusConfig.status_exists(status_id), "状态已定义：%s → %s" % [sid, status_id])

	# 动画资源：MONSTER_ANIM_CONFIG 中登记的每个状态映射都必须有 .skel/.atlas 文件
	# 只全量校验 4 名新怪物（旧怪物的映射已在既有玩法中验证过，避免输出过长）
	var consts := _skill_constant_map()
	var anim_config: Dictionary = consts.get("MONSTER_ANIM_CONFIG", {})
	_expect(anim_config.size() >= 11, "MONSTER_ANIM_CONFIG 已登记全部怪物（%d 条）" % anim_config.size())
	for mid in BOSS_ENCOUNTER:
		_expect(anim_config.has(mid), "MONSTER_ANIM_CONFIG 已登记：" + mid)
		if not anim_config.has(mid):
			continue
		var cfg: Dictionary = anim_config[mid]
		var anim_map: Dictionary = cfg.get("map", {})
		var missing := PackedStringArray()
		for state in anim_map.keys():
			var base: String = str(cfg.get("base", "")) + str(anim_map[state])
			if not (FileAccess.file_exists(base + ".skel") and FileAccess.file_exists(base + ".atlas")):
				missing.append("%s→%s" % [state, str(anim_map[state])])
		var anim_label := "动画资源齐全：" + mid
		if not missing.is_empty():
			anim_label = "动画资源缺失：%s → %s" % [mid, ", ".join(missing)]
		_expect(missing.is_empty(), anim_label)

	# 特效资源：新增 BOSS 技能引用的特效文件必须齐全
	var fx_map: Dictionary = consts.get("SKILL_FX_MAP", {})
	for sid in LEADER_SKILLS + CANNON_SKILLS + FUSEMAN_SKILLS:
		_expect(fx_map.has(sid), "SKILL_FX_MAP 已登记：" + sid)
		if not fx_map.has(sid):
			continue
		var fx: Dictionary = fx_map[sid]
		for key in ["caster_fx", "target_fx"]:
			if fx.has(key):
				_check_asset_pair(str(fx[key]), "特效资源存在：%s.%s" % [sid, key])
	_expect(FileAccess.file_exists(str(consts.get("SAPPER_DETONATE_FX", "")) + ".skel"),
		"引爆特效资源存在：" + str(consts.get("SAPPER_DETONATE_FX", "")))

# ------------------------------------------------------------ ② 机制接线

func _check_boss_mechanics() -> void:
	print("[BOSS] --- ② 机制接线 ---")
	var monsters := _monsters()
	var heroes := _heroes()
	_expect(monsters.size() == 4, "BOSS 遭遇共 4 名怪物")
	_expect(heroes.size() >= 2, "英雄编队至少 2 人，可验证炸药/炮击")
	if monsters.size() < 4 or heroes.size() < 2:
		return

	var leader: Dictionary = monsters[0]
	var barrel: Dictionary = monsters[1]
	var fuseman: Dictionary = monsters[2]
	var cannon: Dictionary = monsters[3]
	_expect(leader["id"] == "brigand_sapper", "1 号位是首领 Brigand Vvulf")
	_expect(barrel["id"] == "brigand_barrel", "2 号位是弹药桶")
	_expect(fuseman["id"] == "brigand_fuseman", "3 号位是点火员")
	_expect(cannon["id"] == "brigand_cannon", "4 号位是大炮")

	# --- 弹药桶：惰性单位 ---
	_expect(bool(barrel.get("inert", false)), "弹药桶标记为惰性单位")
	_expect(int(barrel.get("actions_remaining", -1)) == 0, "弹药桶永不行动（actions_remaining = 0）")
	_expect(int(barrel.get("max_hp", 0)) >= 45, "弹药桶拥有较高生命值（%d）" % int(barrel.get("max_hp", 0)))

	# --- 首领：弹药桶在场时只能投弹 ---
	_expect(_can_use(0, "sapper_throw"), "弹药桶在场：首领可投弹标记")
	_expect(not _can_use(0, "sapper_summon"), "弹药桶在场：首领不会再召唤弹药桶")
	_expect(not _can_use(0, "sapper_barrage"), "弹药桶在场：首领不会改用炮击")

	# --- 大炮 / 点火员：装填 → 开火 ---
	_expect(not _can_use(3, "cannon_fire"), "未装填：大炮无法开火")
	_expect(_can_use(3, "cannon_blast"), "未装填且点火员在场：大炮使用散弹")
	_expect(not _can_use(3, "cannon_summon"), "点火员在场：大炮无需召唤")
	_expect(_can_use(2, "fuseman_light_fuse"), "点火员可为大炮装填")

	var fuse_skill := SkillConfig.get_skill("fuseman_light_fuse")
	ActionResolver.resolve_on_target(fuseman, fuse_skill, cannon)
	_expect(ActionResolver.has_status(cannon, "cannon_loaded"), "装填后大炮获得 cannon_loaded")
	_expect(_can_use(3, "cannon_fire"), "装填后：大炮可开火")
	_expect(not _can_use(3, "cannon_blast"), "装填后：大炮不再使用散弹")
	_expect(not _can_use(2, "fuseman_light_fuse"), "已装填：点火员不重复点火（target_ally_status_absent）")
	_expect(not _can_use(2, "fuseman_light_fuse") and _can_use(2, "fuseman_hot_shot"),
		"已装填：点火员改用灼热散弹")
	_battle.call("_apply_monster_skill_post_effects", 3, SkillConfig.get_skill("cannon_fire"))
	_expect(not ActionResolver.has_status(cannon, "cannon_loaded"), "开火后自动卸弹（consume_self_status）")

	# --- 首领投弹 → 下回合引爆（不占用行动） ---
	var hero: Dictionary = heroes[0]
	var throw_skill := SkillConfig.get_skill("sapper_throw")
	ActionResolver.resolve_on_target(leader, throw_skill, hero)
	_expect(ActionResolver.has_status(hero, "bomb_mark"), "投弹后英雄获得爆破标记")
	_battle.call("_register_pending_bomb", hero, throw_skill)
	var bombs: Array = _battle.get("_pending_bombs")
	_expect(bombs.size() == 1, "待引爆炸药已登记（1 枚）")
	var hp_before: int = int(hero["hp"])
	var round_before: int = int(_battle.get("round_number"))
	_battle.set("round_number", round_before + 1)
	_battle.call("_resolve_pending_bombs")
	var hp_after: int = int(hero["hp"])
	_expect(hp_after < hp_before, "炸药引爆造成大量伤害（%d → %d）" % [hp_before, hp_after])
	_expect(not ActionResolver.has_status(hero, "bomb_mark"), "引爆后标记被清除")
	_expect((_battle.get("_pending_bombs") as Array).is_empty(), "引爆炸药队列已清空")

	# --- 弹药桶被摧毁 → 哑弹解除 + 首领改用召唤/炮击 ---
	var hero2: Dictionary = heroes[1]
	ActionResolver.resolve_on_target(leader, throw_skill, hero2)
	_battle.call("_register_pending_bomb", hero2, throw_skill)
	_expect(ActionResolver.has_status(hero2, "bomb_mark"), "第二枚炸药已标记")
	barrel["hp"] = 0
	_battle.call("_handle_monster_damage_aftermath", 1)
	_expect(bool(barrel.get("is_corpse", false)), "弹药桶被摧毁后留下尸体")
	_expect(not ActionResolver.has_status(hero2, "bomb_mark"), "弹药桶被摧毁：标记立即解除（哑弹）")
	_expect((_battle.get("_pending_bombs") as Array).is_empty(), "弹药桶被摧毁：待引爆炸药清空")
	_expect(not _can_use(0, "sapper_throw"), "无弹药桶：首领无法投弹")
	_expect(_can_use(0, "sapper_summon"), "无弹药桶：首领可召唤弹药桶")
	_expect(_can_use(0, "sapper_barrage"), "无弹药桶：首领可炮击前排")
	var barrage_skill := SkillConfig.get_skill("sapper_barrage")
	var barrage_targets: Array = _battle.call("_get_valid_targets_for_monster", 0, barrage_skill)
	_expect(barrage_targets.size() == mini(2, heroes.size()),
		"炮击只命中前两位英雄（命中 %d 人）" % barrage_targets.size())

	# --- 战斗内召唤：弹药桶 / 点火员（尸体让位） ---
	var re_slot: int = _battle.call("_summon_monster", "brigand_barrel")
	_expect(re_slot == 1, "首领召回弹药桶时占用尸体槽位（slot=%d）" % re_slot)
	_expect(_monsters().size() == 4, "召唤后仍为 4 名怪物（未超出 4 个槽位）")
	_expect(int(_monsters()[1].get("actions_remaining", -1)) == 0, "召唤物登场当回合不行动")
	_expect(_can_use(0, "sapper_throw"), "弹药桶回来后：首领恢复投弹")

	fuseman["hp"] = 0
	_battle.call("_handle_monster_damage_aftermath", 2)
	_expect(bool(fuseman.get("is_corpse", false)), "点火员阵亡留下尸体")
	_expect(_can_use(3, "cannon_summon"), "点火员不在场：大炮可召唤点火员")
	_expect(not _can_use(3, "cannon_blast"), "点火员不在场：大炮不再散弹")
	var new_slot: int = _battle.call("_summon_monster", "brigand_fuseman")
	_expect(new_slot == 2, "大炮召回点火员时占用尸体槽位（slot=%d）" % new_slot)
	_expect(not _can_use(3, "cannon_summon"), "点火员回来后：大炮不再召唤")

	# --- 生命链接 ---
	var cannon_now: Dictionary = _monsters()[3]
	cannon_now["hp"] = 0
	_battle.call("_handle_monster_damage_aftermath", 3)
	_expect(bool(_monsters()[2].get("is_corpse", false)), "大炮阵亡：点火员随之倒下（life_link）")
	leader["hp"] = 0
	_battle.call("_handle_monster_damage_aftermath", 0)
	_expect(bool(_monsters()[1].get("is_corpse", false)), "首领阵亡：弹药桶随之损毁（life_link）")
