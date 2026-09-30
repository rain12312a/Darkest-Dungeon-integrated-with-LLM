extends SceneTree

# 临时探针脚本（端到端验证用，非游戏运行时代码）
# 用途：验证伤害的两个增益乘区规则
#   ① attack_mult（战意高涨 / 美德激励）—— 彼此【加算】：att × (1 + 0.2 + 0.2) = ×1.4
#   ② damage_mult（狗粮）             —— 【乘算】乘在最后：× 1.2
# 伤害 = int(攻击力 × 攻击力总倍率 × attack_ratio × 伤害总倍率)
# 运行：godot --headless --path <项目> --script res://tools/_probe_buff_zones.gd

var _pass := 0
var _fail := 0
var _frame := 0

func _process(_delta: float) -> bool:
	_frame += 1
	if _frame < 2:
		return false
	_run()
	print("[ZONE] ===== PASS=%d FAIL=%d ====" % [_pass, _fail])
	quit(0 if _fail == 0 else 1)
	return true

func _expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("[ZONE]   PASS  ", label)
	else:
		_fail += 1
		print("[ZONE]   FAIL  ", label)

func _unit(attack: int) -> Dictionary:
	return {"attack": attack, "statuses": {}, "hp": 100, "max_hp": 100}

func _dmg(u: Dictionary) -> int:
	return ActionResolver.calculate_damage(u, {"attack_ratio": 1.0})

func _run() -> void:
	print("[ZONE] --- ① 无增益基准 ---")
	var u := _unit(20)
	_expect(_dmg(u) == 20, "无增益伤害 = 攻击力 20")
	_expect(is_equal_approx(ActionResolver.get_attack_multiplier(u), 1.0), "攻击力总倍率 = 1.0")
	_expect(is_equal_approx(ActionResolver.get_damage_multiplier(u), 1.0), "伤害总倍率 = 1.0")

	print("[ZONE] --- ② 攻击力乘区：战意高涨 ---")
	ActionResolver.apply_status(u, "inspired", 1, 3)
	_expect(is_equal_approx(ActionResolver.get_attack_multiplier(u), 1.2), "战意高涨：攻击力 ×1.2")
	_expect(is_equal_approx(ActionResolver.get_damage_multiplier(u), 1.0), "战意高涨不进伤害乘区")
	_expect(_dmg(u) == 24, "战意高涨：伤害 20 → 24")

	print("[ZONE] --- ③ 攻击力乘区【加算】：战意 + 美德 ---")
	ActionResolver.apply_status(u, "virtue_buff", 1, 5)
	_expect(is_equal_approx(ActionResolver.get_attack_multiplier(u), 1.4), "战意 + 美德 = 加算 ×1.4（而非 1.44）")
	_expect(_dmg(u) == 28, "战意 + 美德：伤害 20 → 28（浮点误差已被抹平，未截断成 27）")

	print("[ZONE] --- ④ 伤害乘区【乘算】：再叠狗粮 ---")
	ActionResolver.apply_status(u, "dogfood_buff", 1, 3)
	_expect(is_equal_approx(ActionResolver.get_attack_multiplier(u), 1.4), "狗粮不改变攻击力乘区（仍 ×1.4）")
	_expect(is_equal_approx(ActionResolver.get_damage_multiplier(u), 1.2), "狗粮让伤害乘区 = ×1.2")
	_expect(_dmg(u) == 33, "三 buff 叠加：20 ×1.4 ×1.2 = 33.6 → 33")

	print("[ZONE] --- ⑤ 单独狗粮（乘算区独立生效） ---")
	var v := _unit(20)
	ActionResolver.apply_status(v, "dogfood_buff", 1, 3)
	_expect(is_equal_approx(ActionResolver.get_attack_multiplier(v), 1.0), "只带狗粮时攻击力乘区 = 1.0")
	_expect(_dmg(v) == 24, "只带狗粮：伤害 20 → 24")
	var w := _unit(11)
	ActionResolver.apply_status(w, "dogfood_buff", 1, 3)
	_expect(_dmg(w) == 13, "带狗粮且非整除：11 ×1.2 = 13.2 → 13（沿用 int 截断策略）")
	_expect(_dmg(_unit(11)) == 11, "同角色无增益：11 → 11")
