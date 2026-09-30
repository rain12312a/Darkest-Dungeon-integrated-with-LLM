class_name StatusConfig
extends Node

# 状态异常数据库 - 集中管理所有状态效果
# dot = true 表示每回合开始时结算一次持续伤害，伤害值 = 当前层数
# skip_turn = true 表示轮到该单位行动时判定：跳过本次行动，判定后立即解除
# manual_duration = true 表示存续回合数不参与 ActionResolver.tick_statuses 的按回合衰减，
#                    改由战斗逻辑显式移除（如首领的"爆破标记"在引爆/解除时由 BattleController 清除）
# damage_taken_mult = 目标承受伤害的倍率（> 1.0 表示易伤，如"标记"）
# attack_mult = 攻击力加成（> 1.0 表示增伤）——**多个 attack_mult 之间【加算】**
#              例：美德激励 1.2 + 战意高涨 1.2 → 攻击力 ×(1 + 0.2 + 0.2) = ×1.4
# damage_mult = 最终伤害加成（> 1.0 表示增伤）——**多个 damage_mult 之间【乘算】**，如"狗粮"的 1.2
#              伤害 = 攻击力 ×(attack_mult 加算) × attack_ratio ×(damage_mult 连乘)
# stress_taken_mult = 携带者受到压力值的倍率（> 1.0 表示更易崩溃，如"折磨"的 1.2）
# detonate_damage = 引爆类状态（manual_duration）在引爆时造成的伤害区间
#
# 注意：折磨 / 美德相关数值的真实来源是 StressConfig，本文件仅做展示与倍率承载，
#       调整数值时需同步两处（description 文案对应的数字也要改）。

static var STATUSES: Dictionary = {
	"bleed": {
		"id": "bleed",
		"name": "流血",
		"type": "dot",
		"description": "每回合扣除当前层数点生命值",
		"icon": "res://overlays/poptext_bleed.png",
		"dot": true
	},
	"blight": {
		"id": "blight",
		"name": "腐蚀",
		"type": "dot",
		"description": "每回合扣除当前层数点生命值",
		"icon": "res://overlays/poptext_poison.png",
		"dot": true
	},
	"stun": {
		"id": "stun",
		"name": "晕眩",
		"type": "control",
		"description": "轮到该单位行动时跳过一次行动，跳过之后立即解除",
		"icon": "res://overlays/tray_stun.png",
		"dot": false,
		"skip_turn": true
	},
	"mark": {
		"id": "mark",
		"name": "标记",
		"type": "debuff",
		"description": "被标记者承受的伤害提高 30%（不含流血/腐蚀等持续伤害）",
		"icon": "res://overlays/tray_tag.png",
		"dot": false,
		"damage_taken_mult": 1.3
	},
	"guard": {
		"id": "guard",
		"name": "守护",
		"type": "buff",
		"description": "被敌人单体攻击时，该次伤害转移给守护者",
		"icon": "res://overlays/tray_guard.png",
		"dot": false
	},
	# === 门前恶狼 BOSS 战专用状态 ===
	# 首领投出炸药锁定英雄：标记在回合结算时引爆（不占用任何人的行动次数）
	"bomb_mark": {
		"id": "bomb_mark",
		"name": "爆破标记",
		"type": "debuff",
		"description": "已被首领投出的炸药锁定：下一回合开始时受到大量伤害（摧毁弹药桶可解除）",
		"icon": "res://overlays/tray_dot_burn.png",
		"dot": false,
		"manual_duration": true,
		"detonate_damage": [14, 20]
	},
	# 点火员装填引信：大炮带着该状态行动时会向全体英雄开火，开火后状态被消耗
	"cannon_loaded": {
		"id": "cannon_loaded",
		"name": "装填完毕",
		"type": "buff",
		"description": "大炮已被点火员装填：其下次行动会向全体英雄开火并造成高额伤害",
		"icon": "res://overlays/tray_buff.png",
		"dot": false
	},
	# === 压力系统：折磨 / 美德（数值来源：StressConfig）===
	# 折磨：压力越过 100 时 75% 概率进入；受到压力 +20%，每次行动 30% 概率失控
	"afflicted": {
		"id": "afflicted",
		"name": "折磨",
		"type": "debuff",
		"description": "精神崩溃：受到的压力提高 20%，每次行动有 30% 概率失控（跳过行动 / 攻击队友 / 增加队友压力 / 自动随机行动）",
		"icon": "res://overlays/tray_afflicted.png",
		"dot": false,
		"manual_duration": true, # 本场战斗持续，不按回合衰减
		"stress_taken_mult": 1.2
	},
	# 美德：压力越过 100 时 25% 概率进入；本场战斗持续的状态标记（数值增益由 virtue_buff 承担）
	"virtuous": {
		"id": "virtuous",
		"name": "美德",
		"type": "buff",
		"description": "精神升华：自身压力被清空，并感召全队（全体攻击力 +20%，持续 5 回合）",
		"icon": "res://overlays/tray_virtued.png",
		"dot": false,
		"manual_duration": true # 本场战斗持续，不按回合衰减
	},
	# 美德激励：美德触发时施加给全体英雄的攻击力增益（按携带者行动次数递减）
	"virtue_buff": {
		"id": "virtue_buff",
		"name": "美德激励",
		"type": "buff",
		"description": "受美德的感召：攻击力提高 20%",
		"icon": "res://overlays/tray_buff_plus.png",
		"dot": false,
		"attack_mult": 1.2
	},
	# 战意高涨：LLM 激励喊话掷到【增益】结果时附加的攻击力增益（攻击力乘区，与美德激励【加算】）
	# 注意：持续回合数写在 BattleController.INSPIRE_BUFF_ROUNDS，调整数值时需同步两处（description 文案也要改）
	"inspired": {
		"id": "inspired",
		"name": "战意高涨",
		"type": "buff",
		"description": "受领主激励而斗志沸腾：攻击力提高 20%（持续 3 回合）",
		"icon": "res://overlays/tray_buff.png",
		"dot": false,
		"attack_mult": 1.2
	},
	# 狗粮：消耗品"狗粮"使用后附加的【伤害】增益（乘算乘区，持续 1 回合）
	"dogfood_buff": {
		"id": "dogfood_buff",
		"name": "狗粮",
		"type": "buff",
		"description": "吃下狗粮后血脉贯张：造成的伤害提高 20%（持续 1 回合）",
		"icon": "res://panels/icons_equip/supply/inv_supply+dog_treats.png",
		"dot": false,
		"damage_mult": 1.2
	},
}

static func get_status(status_id: String) -> Dictionary:
	if status_id in STATUSES:
		return STATUSES[status_id].duplicate()
	return {}

static func status_exists(status_id: String) -> bool:
	return status_id in STATUSES

static func get_all_status_ids() -> Array[String]:
	var result: Array[String] = []
	for status_id in STATUSES.keys():
		result.append(str(status_id))
	return result
