extends SceneTree

# 临时探针：校验 audio/sfx 下提取出来的技能音效都能被 Godot 正常加载（可保留复用）
# 运行：godot --headless --path <项目> --script res://tools/_probe_sfx.gd

const SFX_DIR := "res://audio/sfx/"

# 四个英雄 4 个技能 → 音效映射（供后续接线参考/校验）
const SKILL_SFX := {
	"crusader": {"slash": "char_al_cru_smite", "heal": "char_al_cru_battleheal",
				 "holy spear": "char_al_cry_holylance", "battle_cry": "char_al_cru_inspiringcry"},
	"highwayman": {"cut": "char_al_hwy_wickedslice", "pistol_shot": "char_al_hwy_pistolshot",
				   "Close-range shooting": "char_al_hwy_pointblank", "shotgun": "char_al_hwy_grapeshot"},
	"occultist": {"命运重构": "char_al_occ_wyrdrecon", "祭祀切割": "char_al_occ_bloodlet",
				  "深渊之手": "char_al_occ_daemons", "灵魂之触": "char_al_occ_abyssalart"},
	"houndmaster": {"释放猎犬": "char_al_hnd_hounds_rush", "标记弱点": "char_al_hnd_whistle",
					"振奋犬吠": "char_al_hnd_howl", "守护队友": "char_al_hnd_guard_dog"},
}

var _frame := 0
var _pass := 0
var _fail := 0

func _process(_delta: float) -> bool:
	_frame += 1
	if _frame < 2:
		return false
	_test_files()
	_test_mapping()
	print("[SFX] ===== PASS=%d FAIL=%d ====" % [_pass, _fail])
	quit(0 if _fail == 0 else 1)
	return true

func _expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("[SFX]   PASS  ", label)
	else:
		_fail += 1
		print("[SFX]   FAIL  ", label)

# ① audio/sfx 下每个 .ogg 都能加载且时长合理（0.2~6s）
func _test_files() -> void:
	print("[SFX] --- ① 技能音效文件 ---")
	var files: Array = []
	for f in DirAccess.get_files_at(SFX_DIR):
		if f.ends_with(".ogg"):
			files.append(f)
	files.sort()
	_expect(files.size() >= 40, "audio/sfx 下有 %d 个音效文件" % files.size())
	var bad := 0
	var shortest := 99.0
	var longest := 0.0
	for f in files:
		var stream: AudioStream = load(SFX_DIR + f)
		if stream == null or not (stream is AudioStreamOggVorbis):
			print("[SFX]   加载失败：", f)
			bad += 1
			continue
		var dur: float = stream.get_length()
		shortest = minf(shortest, dur)
		longest = maxf(longest, dur)
		if dur < 0.15 or dur > 6.0:
			print("[SFX]   时长异常：", f, " = ", dur)
			bad += 1
	_expect(bad == 0, "全部 %d 个文件均可加载且时长合理（%.2f~%.2fs）" % [files.size(), shortest, longest])

# ② 四个英雄 × 4 技能的音效都在磁盘上
func _test_mapping() -> void:
	print("[SFX] --- ② 技能 → 音效映射 ---")
	var missing := 0
	var total := 0
	for hero_id in SKILL_SFX.keys():
		for skill_id in SKILL_SFX[hero_id].keys():
			total += 1
			var name: String = SKILL_SFX[hero_id][skill_id]
			if not ResourceLoader.exists(SFX_DIR + name + ".ogg"):
				print("[SFX]   缺失：%s / %s → %s" % [hero_id, skill_id, name])
				missing += 1
	_expect(missing == 0, "四个英雄共 %d 个技能的音效齐全（缺 %d）" % [total, missing])
	_expect(ResourceLoader.exists(SFX_DIR + "char_al_cru_smite_miss.ogg"), "挥空版（_miss）音效也已提取")
