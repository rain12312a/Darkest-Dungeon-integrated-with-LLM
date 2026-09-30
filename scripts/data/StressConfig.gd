class_name StressConfig
extends Node

# ============================================================
# 压力系统配置（折磨 / 美德）
#
# 规则总览：
#   ① 未结算过的英雄压力**越过 100** → 先把压力钳制到 100，再掷骰：
#        75% 进入「折磨」（受压力 +20%，每次行动 30% 概率失控）
#        25% 进入「美德」（清空自身压力，全体英雄攻击力 +20%，持续 5 回合）
#   ② 结算过之后压力可继续累积，第 200 点触发"心脏骤停"（压力清零 + 999 真实伤害）
#
# 注意：所有数值都用 static var（而非 const），以便探针脚本在测试中临时改写，
#       从而确定性地覆盖每个分支（例如把 BREAKDOWN_CHANCE 设为 1.0 强制失控）。
#       StatusConfig 中各状态的 description 文案与此处数值对应，改动时请同步文案。
# ============================================================

# 压力上限：达到该值触发"心脏骤停"
static var MAX_STRESS := 200

# 状态 id（唯一来源：StatusConfig / ActionResolver / BattleController / HeroConfig 都引用这里）
static var AFFLICTION_STATUS := "afflicted" # 折磨
static var VIRTUE_STATUS := "virtuous" # 美德
static var VIRTUE_BUFF_STATUS := "virtue_buff" # 美德激励（全体攻击力增益）

# 折磨阈值：英雄越过该值时钳制并掷骰。
# 注意：是否掷骰看的是**当前是否已处于折磨/美德状态**（不按战斗重置），
#       因此折磨 / 美德与压力一起跨战斗保留（见 HeroConfig.PARTY_STATES）。
static var AFFLICTION_THRESHOLD := 100

# 越过阈值后的掷骰概率（两者独立：全部落空时只钳制压力、不改变状态）
static var AFFLICTION_CHANCE := 0.75 # 折磨
static var VIRTUE_CHANCE := 0.25 # 美德

# 折磨（Afflicted）：受到的压力倍率（+20%，只放大加压、不影响减压）
static var AFFLICTION_STRESS_TAKEN_MULT := 1.2

# 折磨（Afflicted）：每次行动失控的概率
static var BREAKDOWN_CHANCE := 0.3

# 失控行为"攻击队友"的伤害系数（基于失控者攻击力）
static var BREAKDOWN_ATTACK_RATIO := 0.5

# 失控行为"增加队友压力"的压力值区间 [min, max]
static var BREAKDOWN_STRESS_AMOUNT := [8, 14]

# 美德激励：全体英雄的攻击力倍率与持续回合数
static var VIRTUE_ATTACK_MULT := 1.2
static var VIRTUE_BUFF_ROUNDS := 5
