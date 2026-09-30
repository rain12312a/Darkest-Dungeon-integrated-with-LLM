extends SceneTree

# 临时探针脚本（端到端验证用，非游戏运行时代码）
# 用途：验证「战斗音效」接线
#   ① SfxManager 的表与文件一一对应（每个登记的音效文件都真实存在）
#   ② SKILL_FX_MAP 里每个技能都有施法音（不会出现“有特效没声音”）
#   ③ 战斗里出招 → 真的播了正确的施法音
#   ④ 打出掉血 → 叠命中层（武器类型正确）；一点血没掉 → 播挥空音
#   ⑤ 治疗/增益类技能不播打击音（只有施法音）
# 运行：godot --headless --path <项目> --script res://tools/_probe_sfx_battle.gd

const SFX_DIR := "res://audio/sfx/"
const ENEMY_DIR := "res://audio/sfx/enemy/"

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
		print("[SFXB] FAILED: cannot load Battle.tscn")
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
		_test_tables()
		_test_impact_table()
		_test_battle_playback()
		return false
	if _frame == 6:
		_test_impact_playback()
		_test_no_impact_skills()
		print("[SFXB] ===== PASS=%d FAIL=%d ====" % [_pass, _fail])
		quit(0 if _fail == 0 else 1)
	return false

func _expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("[SFXB]   PASS  ", label)
	else:
		_fail += 1
		print("[SFXB]   FAIL  ", label)

# ------------------------------------------------------------ 工具

func _sfx() -> Node:
	return root.get_node_or_null("Sfx")

# 取"最近一次播放"落到哪个文件（池是轮转的，往回退一格）
func _last_played_path() -> String:
	var sfx := _sfx()
	var pool: Array = sfx.get("_players")
	var next_index: int = int(sfx.get("_next"))
	var p: AudioStreamPlayer = pool[(next_index - 1 + pool.size()) % pool.size()]
	if p.stream == null:
		return ""
	return p.stream.resource_path

func _is_playing() -> bool:
	var sfx := _sfx()
	for p in (sfx.get("_players") as Array):
		if (p as AudioStreamPlayer).playing:
			return true
	return false

func _path_for(entry: String) -> String:
	if entry.begins_with("enemy/"):
		return ENEMY_DIR + entry.substr("enemy/".length()) + ".ogg"
	return SFX_DIR + entry + ".ogg"

# _emit_feedback 的形参是 Array[Dictionary] 强类型数组，通过 call() 调用时必须装箱
func _td(a: Array) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for v in a:
		out.append(v)
	return out

# 技能 id → 拥有它的英雄 id（英雄技能在 SfxManager 里按两层索引）
func _skill_owner() -> Dictionary:
	var out := {}
	for hero_id in HeroConfig.HEROES.keys():
		for skill_id in (HeroConfig.HEROES[hero_id] as Dictionary).get("skills", []):
			out[str(skill_id)] = str(hero_id)
	return out

# 收集表里登记的所有 "文件名 → 来源表名"，用于统一校验文件是否存在
func _collect_entries() -> Array:
	var out: Array = []
	var sfx := _sfx()
	var tables := {
		"HERO_SKILL_SFX": sfx.get("HERO_SKILL_SFX"),
		"HERO_SKILL_MISS_SFX": sfx.get("HERO_SKILL_MISS_SFX"),
		"MONSTER_SKILL_SFX": sfx.get("MONSTER_SKILL_SFX"),
		"MONSTER_SKILL_MISS_SFX": sfx.get("MONSTER_SKILL_MISS_SFX"),
		"IMPACT_SFX": sfx.get("IMPACT_SFX"),
	}
	for table_name in tables.keys():
		var table: Dictionary = tables[table_name]
		for key in table.keys():
			var v: Variant = table[key]
			if v is Dictionary:
				for sub in (v as Dictionary).keys():
					out.append({"table": table_name, "key": "%s/%s" % [key, sub], "entry": str((v as Dictionary)[sub])})
			else:
				out.append({"table": table_name, "key": str(key), "entry": str(v)})
	return out

# ------------------------------------------------------------ ① 表 ↔ 文件

func _test_tables() -> void:
	print("[SFXB] --- ① 音效表与文件一致性 ---")
	_expect(_sfx() != null, "Sfx 已注册为 Autoload")
	var entries := _collect_entries()
	_expect(entries.size() >= 60, "音效表共登记 %d 条" % entries.size())
	var missing: Array = []
	var empty: Array = []
	for e in entries:
		if str(e["entry"]).is_empty():
			continue # 空串是"该技能不发声"的合法写法
		if not ResourceLoader.exists(_path_for(str(e["entry"]))):
			missing.append("%s.%s → %s" % [e["table"], e["key"], e["entry"]])
		if str(e["entry"]).is_empty():
			empty.append(e["key"])
	_expect(missing.is_empty(), "登记的文件全部存在（缺失 %d 条）" % missing.size())
	for m in missing:
		print("[SFXB]     缺失：", m)

	# 每个英雄的每个技能都要有施法音
	var hero_missing: Array = []
	for hero_id in HeroConfig.HEROES.keys():
		for skill_id in (HeroConfig.HEROES[hero_id] as Dictionary).get("skills", []):
			if not _sfx().has_cast_sound(str(skill_id), str(hero_id)):
				hero_missing.append("%s/%s" % [hero_id, skill_id])
	_expect(hero_missing.is_empty(), "四个英雄 16 个技能的施法音齐全（缺 %d）" % hero_missing.size())
	for m in hero_missing:
		print("[SFXB]     缺施法音：", m)

	# 每个怪物技能同样要有施法音
	var mon_missing: Array = []
	for mon_id in MonsterConfig.MONSTERS.keys():
		for skill_id in (MonsterConfig.MONSTERS[mon_id] as Dictionary).get("skills", []):
			if not _sfx().has_cast_sound(str(skill_id)):
				mon_missing.append("%s/%s" % [mon_id, skill_id])
	_expect(mon_missing.is_empty(), "怪物技能施法音齐全（缺 %d）" % mon_missing.size())
	for m in mon_missing:
		print("[SFXB]     缺施法音：", m)

	# SKILL_FX_MAP 里的英雄技能应该跟英雄表对得上（反向查一下归属）
	var owner := _skill_owner()
	_expect(owner.has("slash") and str(owner["slash"]) == "crusader", "技能归属反查正确（slash → crusader）")
	_expect(owner.has("释放猎犬") and str(owner["释放猎犬"]) == "houndmaster", "技能归属反查正确（释放猎犬 → houndmaster）")

# ------------------------------------------------------------ ② SKILL_FX_MAP 全覆盖

func _test_impact_table() -> void:
	print("[SFXB] --- ② SKILL_FX_MAP 全覆盖 + 打击层表 ---")
	var consts: Dictionary = (_battle.get_script() as Script).get_script_constant_map()
	var fx_map: Dictionary = consts.get("SKILL_FX_MAP", {})
	_expect(fx_map.size() >= 35, "SKILL_FX_MAP 共 %d 个技能" % fx_map.size())
	var owner := _skill_owner()
	var silent: Array = []
	for skill_id in fx_map.keys():
		if not _sfx().has_cast_sound(str(skill_id), str(owner.get(str(skill_id), ""))):
			silent.append(str(skill_id))
	_expect(silent.is_empty(), "有特效的技能全都有施法音（静音 %d 个）" % silent.size())
	for s in silent:
		print("[SFXB]     无施法音：", s)

	# 打击层：每个 SKILL_IMPACT 值都必须是 IMPACT_SFX 里登记过的武器类型
	var impact_map: Dictionary = _sfx().get("SKILL_IMPACT")
	var impact_files: Dictionary = _sfx().get("IMPACT_SFX")
	var bad_kind: Array = []
	for skill_id in impact_map.keys():
		var kind := str(impact_map[skill_id])
		if kind.is_empty():
			continue
		if not impact_files.has(kind):
			bad_kind.append("%s → %s" % [skill_id, kind])
	_expect(bad_kind.is_empty(), "SKILL_IMPACT 引用的武器类型都在 IMPACT_SFX 中（错误 %d）" % bad_kind.size())
	for b in bad_kind:
		print("[SFXB]     未登记命中层：", b)

	# 治疗 / 增益类绝不能有打击层（否则打不死人也会响"命中"）
	for skill_id in ["heal", "battle_cry", "标记弱点", "振奋犬吠", "守护队友", "sapper_summon", "cannon_summon", "fuseman_light_fuse"]:
		_expect(not _sfx().has_impact_sound(skill_id), "%s 无打击层（治疗/增益/召唤类）" % skill_id)
	# 攻击类必须有
	for skill_id in ["slash", "shotgun", "深渊之手", "释放猎犬", "pistol_shot", "defender_axe"]:
		_expect(_sfx().has_impact_sound(skill_id), "%s 有打击层（攻击类）" % skill_id)

# ------------------------------------------------------------ ③ 战斗内真播

func _test_battle_playback() -> void:
	print("[SFXB] --- ③ 战斗中出招真的播了正确的施法音 ---")
	_battle.set("battle_over", true) # 冻结自动战斗循环，手动驱动
	var heroes: Array = _battle.get("heroes")
	var monsters: Array = _battle.get("monsters")
	_expect(heroes.size() == 4 and monsters.size() >= 1, "战场已生成 4 英雄 / %d 怪物" % monsters.size())

	# 十字军 slash：应是 char_al_cru_smite
	_battle.call("_play_skill_fx_v2", heroes[0], "slash", [monsters[0]])
	var p1 := _last_played_path()
	_expect(p1.ends_with("audio/sfx/char_al_cru_smite.ogg"), "十字军 slash → char_al_cru_smite.ogg（实得 %s）" % p1.get_file())
	_expect(_is_playing(), "AudioStreamPlayer 处于播放状态")

	# 强盗 shotgun：应是 char_al_hwy_grapeshot
	_battle.call("_play_skill_fx_v2", heroes[1], "shotgun", [monsters[0]])
	var p2 := _last_played_path()
	_expect(p2.ends_with("char_al_hwy_grapeshot.ogg"), "强盗 shotgun → char_al_hwy_grapeshot.ogg（实得 %s）" % p2.get_file())

	# 怪物技能：走 enemy/ 目录
	_battle.call("_play_skill_fx_v2", monsters[0], "skeleton_melee", [heroes[0]])
	var p3 := _last_played_path()
	_expect(p3.ends_with("enemy/char_en_sklcom_cudgel.ogg"), "怪物 skeleton_melee → enemy/char_en_sklcom_cudgel.ogg（实得 %s）" % p3.get_file())

	# 一次出招只占一个播放器，不会打断前一个（池化）
	_expect(bool(_battle.get("_pending_impact_skill") == "skeleton_melee"), "_play_skill_fx_v2 记下了待结算的打击层技能")

	# 未知技能不应报错，也不该误播别的音
	var before := _last_played_path()
	_battle.call("_play_skill_fx_v2", heroes[0], "no_such_skill_xyz", [monsters[0]])
	_expect(_last_played_path() == before, "未知技能不发声（没误播上一条音效）")

# ------------------------------------------------------------ ④ 命中 / 挥空

func _test_impact_playback() -> void:
	print("[SFXB] --- ④ 掉血 → 命中层；零伤害 → 挥空音 ---")
	var heroes: Array = _battle.get("heroes")
	var monsters: Array = _battle.get("monsters")
	var sfx := _sfx()

	# 手动构造一次「slash 打中并掉血」：_play_skill_fx_v2 记状态 + _emit_feedback 结算
	var hero: Dictionary = heroes[0]
	var target: Dictionary = monsters[0]
	_battle.call("_play_skill_fx_v2", hero, "slash", [target])
	var snap: Dictionary = _battle.call("_snap_unit", target)
	target["hp"] = int(target.get("hp", 0)) - 7
	_battle.call("_emit_feedback", _td([target]), _td([snap]))
	var pi := _last_played_path()
	_expect(pi.ends_with("char_share_imp_sword.ogg"), "slash 掉血 → 命中层 char_share_imp_sword.ogg（实得 %s）" % pi.get_file())

	# 枪械类技能 → gun 命中层
	_battle.call("_play_skill_fx_v2", hero, "pistol_shot", [target])
	var snap2: Dictionary = _battle.call("_snap_unit", target)
	target["hp"] = int(target.get("hp", 0)) - 5
	_battle.call("_emit_feedback", _td([target]), _td([snap2]))
	_expect(_last_played_path().ends_with("char_share_imp_gun.ogg"), "pistol_shot 掉血 → 命中层 char_share_imp_gun.ogg")

	# 一点血没掉（完全被抵消）→ 挥空音（slash 配了 _miss 素材）
	_battle.call("_play_skill_fx_v2", hero, "slash", [target])
	var snap3: Dictionary = _battle.call("_snap_unit", target)
	_battle.call("_emit_feedback", _td([target]), _td([snap3]))
	_expect(_last_played_path().ends_with("char_al_cru_smite_miss.ogg"), "slash 零伤害 → 挥空音 char_al_cru_smite_miss.ogg")

	# 怪物技能零伤害 → 怪物挥空音（走 enemy 目录）
	_battle.call("_play_skill_fx_v2", monsters[0], "defender_shield", [hero])
	var snap4: Dictionary = _battle.call("_snap_unit", hero)
	_battle.call("_emit_feedback", _td([hero]), _td([snap4]))
	_expect(_last_played_path().ends_with("enemy/char_en_sklde_shieldbash_miss.ogg"), "怪物零伤害 → enemy/char_en_sklde_shieldbash_miss.ogg")

	# 结算一次就该清干净，避免污染下一招
	_expect(str(_battle.get("_pending_impact_skill")) == "", "_emit_feedback 后待结算状态已清空")

	# 直接调用 play_impact / play_skill_miss 的契约
	_expect(sfx.play_impact("sword"), "play_impact(\"sword\") 返回 true")
	_expect(not sfx.play_impact("no_such_weapon"), "play_impact(未登记类型) 返回 false")
	_expect(sfx.play_skill_miss("pistol_shot"), "pistol_shot 有挥空素材")
	_expect(not sfx.play_skill_miss("heal"), "heal 没有挥空素材（返回 false）")
	_expect(sfx.has_miss_sound("spear_pierce"), "spear_pierce 有挥空素材（怪物表）")

# ------------------------------------------------------------ ⑤ 治疗/增益不响打击音

func _test_no_impact_skills() -> void:
	print("[SFXB] --- ⑤ 治疗 / 增益类不播打击层 ---")
	var heroes: Array = _battle.get("heroes")
	var h: Dictionary = heroes[0]
	var sfx := _sfx()
	var before := _last_played_path()

	# heal：施法音换成 battle_heal，但不应叠打击层
	_battle.call("_play_skill_fx_v2", h, "heal", [h])
	_expect(_last_played_path().ends_with("char_al_cru_battleheal.ogg"), "heal 施法音 = char_al_cru_battleheal.ogg")
	var snap: Dictionary = _battle.call("_snap_unit", h)
	h["hp"] = int(h.get("hp", 0)) + 6 # 治疗量 > 0
	_battle.call("_emit_feedback", _td([h]), _td([snap]))
	_expect(_last_played_path().ends_with("char_al_cru_battleheal.ogg"), "治疗结算不改播打击音（仍是施法音）")

	# battle_cry（激励喊话）：完全静音的打击层
	_expect(not sfx.has_impact_sound("battle_cry"), "battle_cry 无打击层")
	_battle.call("_play_skill_fx_v2", h, "battle_cry", [h])
	_expect(_last_played_path().ends_with("char_al_cru_inspiringcry.ogg"), "battle_cry 施法音 = char_al_cru_inspiringcry.ogg")
	# 激励喊话音（任意英雄通用的战吼常量）
	# 常量不能用 Object.get() 读，得看脚本的常量表
	var sfx_consts: Dictionary = (sfx.get_script() as Script).get_script_constant_map()
	var inspire_sfx := str(sfx_consts.get("INSPIRE_SFX", ""))
	_expect(inspire_sfx == "char_al_cru_inspiringcry", "INSPIRE_SFX 常量 = 十字军战吼")
	_expect(sfx.play(inspire_sfx, -8.0), "激励喊话音能正常播放（任意英雄可用）")
	var before_cry := _last_played_path()
	var snap2: Dictionary = _battle.call("_snap_unit", h)
	_battle.call("_emit_feedback", _td([h]), _td([snap2]))
	_expect(_last_played_path() == before_cry, "battle_cry 结算后没有额外打击音")
	_expect(before != "", "上一轮确实播过音（对照组有效）")

	# 池容量：连续播 20 次不应越界 / 报错
	for i in range(20):
		sfx.play("char_al_hnd_howl", -9.0)
	var pool: Array = sfx.get("_players")
	_expect(pool.size() == 12, "播放器池固定 12 个（连播 20 次未扩容）")
	var valid := true
	for p in pool:
		if not is_instance_valid(p):
			valid = false
	_expect(valid, "池内播放器全部有效")
	sfx.stop_all()
	_expect(not _is_playing(), "stop_all() 之后全部停止")
