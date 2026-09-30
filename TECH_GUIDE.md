# Dark Dungeon 技术指南

完整的开发工具书，包括添加英雄、怪物、UI 素材和绑定按钮的详细步骤。

---

## 目录

1. [系统架构概览](#1-系统架构概览)
2. [添加新英雄](#2-添加新英雄)
3. [添加新怪物](#3-添加新怪物)
4. [UI 素材与绑定](#4-ui-素材与绑定)
5. [Spine 动画系统](#5-spine-动画系统)
6. [技能系统与按钮绑定](#6-技能系统与按钮绑定)
7. [调试与优化](#7-调试与优化)
8. [大模型激励喊话系统](#8-大模型激励喊话系统)
9. [快速参考](#9-快速参考)
10. [地图系统](#10-地图系统)
11. [BOSS 战：门前恶狼](#11-boss-战门前恶狼brigand-火器小队)
12. [背景音乐（BGM）与音频提取](#12-背景音乐bgm与音频提取)

---

## 1. 系统架构概览

### 项目结构

```
darkdungeon/
├── data/                               # JSON 配置与脚本配置
│   ├── characters.json                 # 角色数据（预留）
│   ├── skills.json                     # 技能数据（预留）
│   ├── HeroConfig.gd                   # 英雄配置（当前使用）
│   ├── SkillConfig.gd                  # 技能配置（当前使用）
│   └── MonsterConfig.gd                # 怪物配置（当前使用）
│
├── characters/                         # 角色素材目录
│   ├── crusader/                       # 英雄 1
│   │   ├── anim/                       # Spine 动画文件（.skel / .atlas / .png）
│   │   ├── crusader_A/                 # 立绘目录
│   │   ├── crusader_guild_header.png   # 头像
│   │   └── crusader.ability.*.png      # 技能图标
│   │
│   ├── highwayman/                     # 英雄 2
│   │   ├── anim/
│   │   ├── highwayman_A/
│   │   ├── highwayman_guild_header.png
│   │   └── highwayman.ability.*.png
│   │
│   └── [new_hero]/                     # 新英雄（复制 crusader 结构）
│
├── monsters/                           # 怪物素材目录
│   ├── brigand_cutthroat/              # 怪物 1
│   │   ├── anim/                       # Spine 动画文件
│   │   └── [其他素材]
│   │
│   └── [new_monster]/                  # 新怪物（复制结构）
│
├── scripts/
│   ├── battle/
│   │   ├── BattleController.gd         # 战斗 UI 控制器
│   │   ├── LLMClient.gd                # 大语言模型 API 异步客户端
│   │   └── spine/
│   │       ├── SpineAtlas.gd           # .atlas 解析
│   │       ├── SpineSkel.gd            # .skel 二进制解析
│   │       └── SpinePlayer.gd          # Spine 动画渲染
│   │
│   └── data/
│       ├── HeroConfig.gd               # 英雄配置脚本
│       ├── SkillConfig.gd              # 技能配置脚本
│       ├── MonsterConfig.gd            # 怪物配置脚本
│       └── ConsumableConfig.gd         # 消耗品配置 + 背包管理
│
└── scenes/
    ├── battle/
    │   └── Battle.tscn                 # 战斗场景主入口
    └── main/
        └── Main.tscn                   # 游戏主场景
```

### 核心系统

| 系统 | 文件 | 职责 |
|------|------|------|
| **配置管理** | `HeroConfig.gd` / `SkillConfig.gd` / `MonsterConfig.gd` | 存储英雄、技能、怪物数据 |
| **动画渲染** | `SpineAtlas.gd` / `SpineSkel.gd` / `SpinePlayer.gd` | Spine 2.1.27 骨骼动画系统 |
| **战斗流程** | `BattleController.gd` | UI 和输入管理 |
| **行动队列** | `TurnQueue.gd` | 按速度排序的行动管理 |
| **伤害计算** | `ActionResolver.gd` | 技能执行和伤害结算 |
| **神性激励** | `LLMClient.gd` | 异步请求云端大模型接口/高保真高吞吐量 Mock 降级 |
| **消耗品背包** | `ConsumableConfig.gd` + `BattleController`（`_build_inventory_panel` 等） | 16 格背包渲染与左键使用 |
| **悬浮提示** | `BattleController._build_skill_tooltip()` / `_format_positions()` | 技能与消耗品的描述/位置/效果提示 |

---

## 2. 添加新英雄

### 2.1 步骤总结

1. **创建英雄目录** → `characters/new_hero/`
2. **准备 Spine 动画文件** → `anim/` 目录
3. **准备素材** → 头像、技能图标
4. **在 HeroConfig.gd 中注册** → 添加英雄模板
5. **在 SkillConfig.gd 中绑定技能** → 分配技能列表
6. **在 BattleController.gd 中设置动画** → 添加动画映射

### 2.2 详细步骤

#### 2.2.1 创建英雄目录结构

```
characters/new_hero/
├── anim/
│   ├── new_hero.sprite.idle.skel
│   ├── new_hero.sprite.idle.atlas
│   ├── new_hero.sprite.idle.png
│   ├── new_hero.sprite.attack.skel
│   ├── new_hero.sprite.attack.atlas
│   ├── new_hero.sprite.attack.png
│   └── [其他动作...]
│
├── new_hero_A/
│   └── [立绘素材]
│
├── new_hero_guild_header.png           # 头像（用于UI）
├── new_hero.ability.one.png            # 技能图标 1
├── new_hero.ability.two.png            # 技能图标 2
├── new_hero.ability.three.png          # 技能图标 3
├── new_hero.ability.four.png           # 技能图标 4
├── new_hero.ability.five.png           # 技能图标 5
├── new_hero.ability.six.png            # 技能图标 6
├── new_hero.ability.seven.png          # 技能图标 7
└── new_hero.ability.eight.png          # 技能图标 8（可选）
```

> **提示**：使用 Spine 编辑器导出动画时，为每个动作创建独立的 .skel + .atlas + .png 文件。

#### 2.2.2 在 HeroConfig.gd 中注册英雄

打开 `scripts/data/HeroConfig.gd`，在 `HEROES` 字典中添加新英雄：

```gdscript
static var HEROES: Dictionary = {
	"crusader": { ... },  # 已存在
	"highwayman": { ... },  # 已存在
	"new_hero": {           # 新英雄
		"id": "new_hero",
		"name": "NewHero",
		"max_hp": 60,
		"attack": 12,
		"speed": 5,
		"skills": ["skill_new_hero_1", "skill_new_hero_2", "skill_new_hero_3", "skill_new_hero_4"],
	},
}
```

**字段说明**：

| 字段 | 类型 | 说明 |
|------|------|------|
| `id` | String | 英雄唯一标识符（与目录名一致） |
| `name` | String | 英雄显示名称 |
| `max_hp` | int | 最大血量 |
| `attack` | int | 攻击力 |
| `speed` | int | 基础速度 |
| `skills` | Array[String] | 技能 ID 数组（对应 SkillConfig 中的 key） |

#### 2.2.3 在 SkillConfig.gd 中注册技能

打开 `scripts/data/SkillConfig.gd`，在 `SKILLS` 字典中添加新英雄的技能：

```gdscript
static var SKILLS: Dictionary = {
	# 已存在的技能...
	
	"skill_new_hero_1": {
		"name": "Basic Attack",
		"description": "Deal attack damage to one enemy",
		"target_type": "single_enemy",
		"target_positions": [],           # 空表示所有位置可选
		"skill_type": "damage",
		"damage_multiplier": 1.0,
		"damage_is_percent": false,
		"effects": [],
		"use_positions": [1, 2, 3, 4],   # 此英雄在位置 1-4 可用
	},
	"skill_new_hero_2": {
		"name": "Heal",
		"description": "Restore HP to one ally",
		"target_type": "single_ally",
		"target_positions": [],
		"skill_type": "heal",
		"heal_amount": 15,
		"use_positions": [1, 2, 3, 4],
	},
	"skill_new_hero_3": {
		"name": "AoE Attack",
		"description": "Attack all enemies",
		"target_type": "all_enemies",
		"target_positions": [1, 2, 3, 4],
		"skill_type": "damage",
		"damage_multiplier": 0.8,
		"use_positions": [1, 2, 3, 4],
	},
	"skill_new_hero_4": {
		"name": "Defense Stance",
		"description": "Reduce damage taken this turn",
		"target_type": "self",
		"skill_type": "buff",
		"use_positions": [1, 2, 3, 4],
	},
}
```

**技能字段说明**：

| 字段 | 类型 | 说明 |
|------|------|------|
| `name` | String | 技能显示名称 |
| `target_type` | String | `"single_enemy"` / `"single_ally"` / `"all_enemies"` / `"self"` |
| `skill_type` | String | `"damage"` / `"heal"` / `"buff"` / `"debuff"` |
| `damage_multiplier` | float | 伤害倍数（攻击力 × 倍数） |
| `heal_amount` | int | 治疗固定值 |
| `use_positions` | Array[int] | 该英雄在哪些位置可用此技能 |
| `target_positions` | Array[int] | 技能可能影响的目标位置（空=所有） |

#### 2.2.4 在 BattleController.gd 中设置动画映射

打开 `scripts/battle/BattleController.gd`，找到英雄常量定义部分，添加新英雄的动画映射：

```gdscript
const NEW_HERO_ANIM_BASE := "res://characters/new_hero/anim/new_hero.sprite."
const NEW_HERO_PNG_DIR   := "res://characters/new_hero/new_hero_A/anim"
const NEW_HERO_ANIM_MAP  := {
	"idle":    "idle",
	"attack":  "attack",
	"defend":  "defend",
	"combat":  "combat",
	"heroic":  "heroic",
	"walk":    "walk",
}
```

> 动画映射的 key 必须与代码中使用的状态名相同（如 `_load_hero_anim(hero_idx, "attack")`）。

然后在 `_load_hero_anim()` 函数中添加新英雄的分支：

```gdscript
func _load_hero_anim(hero_index: int, state: String) -> void:
	if not _spine_players.has(hero_index):
		return
	if _spine_current_state.get(hero_index, "") == state:
		return
	var sp: SpinePlayer = _spine_players[hero_index]
	var hero_id: String = heroes[hero_index].get("id", "")
	var anim_file: String
	var skel_path: String
	var atlas_path: String
	
	if hero_id == "new_hero":                         # 新英雄分支
		anim_file  = NEW_HERO_ANIM_MAP.get(state, "idle")
		skel_path  = NEW_HERO_ANIM_BASE + anim_file + ".skel"
		atlas_path = NEW_HERO_ANIM_BASE + anim_file + ".atlas"
		sp.load_character(skel_path, atlas_path, NEW_HERO_PNG_DIR)
	elif hero_id == "crusader":
		# 既有逻辑...
	# ... 其他英雄
	
	sp.play(anim_file)
	_spine_current_state[hero_index] = state
```

#### 2.2.5 把新英雄加进固定编队

编队选择界面已移除，开局队伍写死在 `scripts/main/StartController.gd`：

```gdscript
const FIXED_TEAM: Array[String] = ["crusader", "highwayman", "occultist", "houndmaster"]
```

把新英雄的 hero_id 填进该数组（同时建议同步 `HeroConfig.CURRENT_TEAM`，两者保持一致）。
> 新增英雄后不需要改任何 UI：`HeroConfig.HEROES` 里能查到模板即可被 `get_team_heroes()` 组装进战斗。

### 2.3 测试新英雄

1. **启动游戏** → 闪屏 → 开始菜单
2. **点 START** → 固定编队（含新英雄）直接开局进地图
3. **进入战斗** → 新英雄应显示头像和技能图标
4. **选择技能** → 应能正常执行伤害/治疗
5. **观察动画** → 应显示对应的 Spine 骨骼动画

---

## 3. 添加新怪物

### 3.1 步骤总结

1. **创建怪物目录** → `monsters/new_monster/`
2. **准备 Spine 动画文件** → `anim/` 目录
3. **在 MonsterConfig.gd 中注册** → 添加怪物模板
4. **在 BattleController.gd 中设置动画** → 添加动画映射
5. **设置遭遇列表** → 配置怪物出现的战斗

### 3.2 详细步骤

#### 3.2.1 创建怪物目录结构

```
monsters/new_monster/
├── anim/
│   ├── new_monster.sprite.combat.skel
│   ├── new_monster.sprite.combat.atlas
│   ├── new_monster.sprite.combat.png
│   ├── new_monster.sprite.attack_1.skel
│   ├── new_monster.sprite.attack_1.atlas
│   ├── new_monster.sprite.attack_1.png
│   └── [其他动作...]
│
└── [其他素材]
```

#### 3.2.2 在 MonsterConfig.gd 中注册怪物

打开 `scripts/data/MonsterConfig.gd`，在 `MONSTERS` 字典中添加新怪物：

```gdscript
static var MONSTERS: Dictionary = {
	"cutthroat": { ... },  # 已存在
	"new_monster": {        # 新怪物
		"id": "new_monster",
		"name": "NewMonster",
		"max_hp": 50,
		"attack": 8,
		"speed": 3,
		"speed_delta_base": -1,
	},
}
```

**字段说明**：

| 字段 | 类型 | 说明 |
|------|------|------|
| `id` | String | 怪物唯一标识符 |
| `name` | String | 怪物显示名称 |
| `max_hp` | int | 最大血量 |
| `attack` | int | 攻击力 |
| `speed` | int | 基础速度 |
| `speed_delta_base` | int | 每轮速度浮动的基准（**已废弃**，实际由 `_start_new_round()` 随机生成） |
| `skills` | Array[String] | 技能 ID 数组，对应 `SkillConfig.SKILLS` 的 key；空数组 = 永不行动 |
| `inert` | bool | `true` = 惰性单位（如弹药桶）：永不进入行动队列、不行动 |
| `life_link` | String | 生命链接：该怪物阵亡时，`life_link` 指向它的怪物一同倒下（如弹药桶随首领、点火员随大炮） |

#### 3.2.3 设置战斗遭遇列表

仍在 `MonsterConfig.gd` 中，修改 `CURRENT_ENCOUNTER` 数组来配置怪物出现：

```gdscript
# 当前关卡的遭遇怪物列表
static var CURRENT_ENCOUNTER: Array[String] = [
	"cutthroat",    # 位置 1
	"new_monster",  # 位置 2
	"new_monster",  # 位置 3
	"cutthroat",    # 位置 4
]
```

> 最多 4 个怪物位置（与英雄位置对应）。地图战斗中由 `DungeonMap.ENCOUNTER_POOL` / `BOSS_ENCOUNTER` 掷出并经 `MapController` 写入 `CURRENT_ENCOUNTER`。

#### 3.2.4 在 BattleController.gd 中登记动画

添加新怪物的动画常量：

```gdscript
const NEW_MONSTER_ANIM_BASE := "res://monsters/new_monster/anim/new_monster.sprite."
const NEW_MONSTER_PNG_DIR   := "res://monsters/new_monster/anim"
const NEW_MONSTER_ANIM_MAP  := {
	"idle":    "combat",
	"attack":  "attack_1",
	"attack2": "attack_2",
	"defend":  "combat",
	"combat":  "combat",
	"heroic":  "combat",
	"walk":    "combat",
}
```

然后在 `MONSTER_ANIM_CONFIG` 表中**登记一条**即可——渲染白名单与 `_load_monster_anim()` 都读这张表，**不再需要写 if/elif 分支**：

```gdscript
const MONSTER_ANIM_CONFIG := {
	# "monster_id": {base = 动画前缀, dir = PNG 目录, map = 状态→动画名}
	"new_monster": {"base": NEW_MONSTER_ANIM_BASE, "dir": NEW_MONSTER_PNG_DIR, "map": NEW_MONSTER_ANIM_MAP},
}
```

> 约定：
> - `map` 的 key 必须是代码用到的状态名（`idle` / `attack` / `attack2` / `defend` / `combat` / `heroic` / `walk` / `dead`），未登记的状态自动回落到 `combat`。
> - `map` 的 value **必须是该资源真实存在的动画名**（即 `{base}{value}.skel` 文件存在）；例如 DD 的 BOSS 怪没有 `dead` 动作，就把 `"dead"` 映射到 `combat`。
> - 战斗内召唤（首领召回弹药桶 / 大炮召回点火员）也走这张表，登记过的怪物才能被召唤渲染。

### 3.3 测试新怪物

1. **启动游戏** → 闪屏 → 开始菜单 → 点 START → 进地图 → 进战斗
2. **观察怪物出现** → 新怪物应在右侧对应位置显示
3. **观察动画** → 应显示对应的 Spine 动画
4. **观察血条** → 应显示正确的血量
5. **战斗交互** → 应能正常受伤、攻击

---

## 4. UI 素材与绑定

### 4.1 英雄头像绑定

**文件位置**：`characters/{hero_id}/{hero_id}_guild_header.png`

**加载逻辑**（在 `BattleController._update_character_portrait()`）：

```gdscript
var portrait_path: String = "res://characters/%s/%s_guild_header.png" % [hero_name.to_lower(), hero_name.to_lower()]
```

**约束**：
- 文件名必须为 `{hero_name}_guild_header.png`
- `hero_name` 为英雄的 `name` 字段（如 `"crusader"` 对应 `"crusader_guild_header.png"`）
- 尺寸：建议 256×256px 或更大

### 4.2 技能图标绑定

**文件位置**：`characters/{hero_id}/{hero_id}.ability.{number}.png`

**加载逻辑**（在 `BattleController._update_skill_buttons()`）：

```gdscript
var skill_num: int = skill_idx + 1  # 技能序号 1-7
var icon_path: String = "res://characters/%s/%s.ability.%s.png" % [
	hero_name.to_lower(),
	hero_name.to_lower(),
	_number_to_word(skill_num)  # 1→"one", 2→"two", ..., 7→"seven"
]
```

**约束**：
- 文件名格式：`{hero_id}.ability.{one|two|three|four|five|six|seven}.png`
- 最多支持 7 个技能图标
- 尺寸：建议 64×64px

### 4.3 动态 UI 按钮生成

所有 UI 按钮（技能、目标选择、HP 条等）都在运行时由 GDScript 动态生成，无需预先在场景编辑器中创建。

**技能按钮创建**（`_update_skill_buttons()`）：

```gdscript
var btn = Button.new()
btn.layout_mode = 1
btn.anchors_preset = 15  # 全填充
btn.icon = icon_texture
btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
btn.pressed.connect(_on_skill_pressed.bind(skill_id), CONNECT_DEFERRED)
icon_box.add_child(btn)
```

**目标选择按钮创建**（`_make_hero_slot()`）：

```gdscript
var btn := Button.new()
btn.custom_minimum_size = Vector2(100.0, 120.0)
btn.text = hero["name"]
btn.pressed.connect(_on_ally_pressed.bind(idx), CONNECT_DEFERRED)
vbox.add_child(btn)
```

### 4.4 UI 布局系统

#### 英雄区布局

```
HeroArea (HBoxContainer)
├─ HeroSlot1 (Control, center anchor)
│  ├─ offset_left: -57, offset_top: 88
│  └─ VBoxContainer (内容排列)
│     ├─ Label (SPD)
│     ├─ ColorRect 或 Button (头像锚点或选择按钮)
│     ├─ ProgressBar (HP条)
│     ├─ Label (HP数值)
│     └─ Label (选中指示器 ▲)
│
├─ HeroSlot2 (对齐方式同上，offset 略有不同)
├─ HeroSlot3
└─ HeroSlot4
```

#### 怪物区布局

```
MonsterArea (HBoxContainer)
├─ MonsterSlot1 (Control, center anchor)
│  ├─ offset_left: 15, offset_top: 40
│  └─ VBoxContainer (内容排列)
│     ├─ Label (SPD)
│     ├─ ColorRect (头像锚点)
│     ├─ ProgressBar (HP条)
│     ├─ Label (HP数值)
│     └─ Label (选中指示器 ▲)
│
├─ MonsterSlot2 (对齐方式同上，offset 略有不同)
├─ MonsterSlot3
└─ MonsterSlot4
```

**重要**：英雄和怪物区完全对称，以确保视觉平衡。

### 4.5 消耗品背包与悬浮提示

**消耗品背包（16 格）**：

- 数据在 `ConsumableConfig.gd`：`ITEMS`（模板，键为 item_id，含 `name`/`icon`/`heal`/`cure_status`/`buff_status`/`buff_duration`/`description`）与 `INVENTORY`（`Array[Dictionary]`，`{"item_id", "count"}`，最多 `MAX_SLOTS=16`，同种无限堆叠）。当前道具：食物（回复 2 HP）、绷带（治愈流血）、狗粮（伤害 +20%，1 回合）。
- 渲染在 `BattleController._build_inventory_panel()` + `_add_inventory_slot()`：16 格网格（主网格 7×2 + 右侧 2 格），每个格子是 `Button`（`flat`，左键触发），显示图标 + 数量角标 `xN`。
- **关键修复**：槽位容器必须挂到全屏 `battle_ui`（`$BattleUI`），并按 `panel_inventory_bg.get_global_rect()` 定位——`PanelInventory` 控件只有 280×130，背景贴图却画在其矩形之外，若直接作为其子节点会因 `has_point` 命中失败而「看得见、点不到」。
- 使用逻辑 `_try_use_consumable()`：仅英雄回合可用；回复类（`heal`）在未满血时回血（`ActionResolver.apply_heal` 自动截断），治愈类（`cure_status`，如绷带治流血）在目标带有对应状态时移除该状态并弹出状态图标，否则拒绍使用且不消耗；增益类（`buff_status`，如狗粮）由 `_use_buff_consumable()` 用 `ActionResolver.apply_status()` 附加 `buff_status` 状态；失败时 `_show_toast()` 显示提示。使用消耗品不占用行动次数。

**战后结算（战利品）**：

- 胜利后 `_end_battle()` → `_begin_loot_step()`：按 `BATTLE_LOOT_TABLE`（食物 1~4 / 绷带 0~1 / 狗粮 0~1）掷取战利品，在右侧面板（`LootLayer`，`CanvasLayer.layer = 110`）展示，并锁定返回按钮至玩家点击「确认」。
- 面板锚点固定为屏幕右边缘（1280 宽下 `x = 980~1260`），与居中结算卡片（`x = 310~970`）留出 10px 间隙不重叠；物品行由 `_make_loot_row()` 动态生成。
- 确认（`_on_loot_confirm_pressed()`）逐条 `ConsumableConfig.add_item()` 入包后收起面板并解锁返回按钮，并播一声音效（`Sfx.play_ui("reward")`）。

### 4.6 战斗结算界面（胜利 / 远征终结 / 战败）

战斗结束后统一由一张卡片接管引导，三种结局共用骨架、只换文案与徽记：

| `_end_state` | 触发条件 | 标题 | 主按钮 | 下一步 |
|--------------|----------|------|--------|--------|
| `victory` | 清完全部敌人且非 BOSS 房 | 胜　利（金） | 返 回 地 图 | `Map.tscn` |
| `run_complete` | 清完 BOSS 房敌人 | 远 征 终 结（金） | 凯 旋 而 归 | `Start.tscn` |
| `defeat` | 全员阵亡 / 濒死未起 | 败　北（血红） | 重 新 开 始 | `Start.tscn` |

**结构（`_create_end_battle_ui()` 在代码里建）**：全屏暗幕（`StyleBoxFlat` 0.88 alpha）+ 上下 52px 黑边 + 居中卡片 660×430。卡片内部从上到下是「装饰条底衬的大标题 → 左徽记 / 右描述 + 分隔线 + 4 行战绩 → 主按钮」。

**素材（全部现成资源，无需新图）**：

| 用途 | 资源 |
|------|------|
| 标题底衬 | `res://overlays/announcement_frame.png`（两端淡出的黑条） |
| 胜利徽记 | `res://overlays/quest_complete.png`（卷轴 + 血色圆徽） |
| 远征终结插画 | `res://panels/quest_return_to_hamlet.png`（归乡木刻） |
| 战败徽记 | `res://panels/seal.affliction.png`（折磨烙印）—— 原图是**黑色剪影 + 透明底**，必须 `modulate` 成血红才看得见 |

**⚠️ 两个容易踩的坑**：

1. **卡片会被角色盖住**。英雄/怪物的 `SpinePlayer` 挂在 `Battle` 根节点下，而且 `_process()` 里被设成 `z_index = 10` —— 它们会画在 `BattleUI` 之上。因此结算面板必须搬进独立的 **`CanvasLayer(layer = 105)`**（而不是给面板调 `z_index`），与战利品结算（110）同一种做法。
2. **`queue_free()` 清不掉旧战绩行**。`_fill_end_stats()` 刷战绩前必须先 `remove_child()` 再 `queue_free()`：`queue_free` 要到帧末才真删，这一帧旧行仍在容器里会被重复绘制，行数统计也会错。

**入场动画（`_play_end_battle_intro()`）**：面板 `modulate:a` 0→1（0.35s）+ 卡片 alpha 0→1、`scale` 0.94→1.0（`TRANS_BACK` / `EASE_OUT`，0.45s）。卡片缩放前**必须**把 `pivot_offset` 设成卡片中心，否则会从左上角“长出来”。音效：胜利 / 远征终结用 `ui/ui_dun_loot_popup_battle`，战败用 `ui/ui_shr_window_popup` 压低音高（0.72）做沉重感。

**战绩四行**：战斗回合 / 存活英雄 / 队伍剩余生命 / 队伍平均压力（≥ 50 标红）。数值全部从真实战场实时算，不额外记账。

**验证**：`godot --headless --path . --script res://tools/_probe_end_battle.gd` → `PASS=80 FAIL=0`。
> 探针坑：入场动画必须**按时间**判定，不能按帧数 —— headless 没有渲染，帧率会煊到几千帧/秒，等 40 帧可能才过了 0.1 秒，断言必然失败。
> 探针坑：headless 下视口可能只有 64px 宽，锚点算出的矩形没有参考价值，几何断言要么先 `root.size = Vector2i(1280, 720)`，要么改用“按设计分辨率算术校验”。

**悬浮提示（tooltip）**：

- 技能图标：`_update_skill_buttons()` 创建按钮时挂 `btn.tooltip_text = _build_skill_tooltip(sd)`。
- 消耗品格子：`_add_inventory_slot()` 里拼接多行提示（名称 + 描述 + 可用位置 + 效果）。
- `_build_skill_tooltip(sd)` 输出：名称 / `description` / `use_positions`（使用位置）/ `target_positions`（目标位置）/ 位移（`move_forward`）/ 目标位移（`target_move_forward`）/ 效果（伤害 % 攻击力、治疗 X 点、复合治疗）。
- `_format_positions(positions)` 把 `[1,2,3]` 格式化为 `"1, 2, 3"`；位置约定「1=最前，4=最后」。

---

## 5. Spine 动画系统

### 5.1 系统概览

Dark Dungeon 使用自定义 Spine 2.1.27 运行时，包含三个核心类：

| 类 | 职责 |
|----|------|
| `SpineAtlas.gd` | 解析 `.atlas` 文本格式，提取纹理区域信息 |
| `SpineSkel.gd` | 解析 `.skel` 二进制格式，提取骨骼、槽位、皮肤、动画数据 |
| `SpinePlayer.gd` | 渲染管理：以 Sprite2D 子节点绘制骨骼动画 |

### 5.2 文件格式

#### .atlas 文件

```
size: 352,1063
format: RGBA8888
filter: Linear,Linear
repeat: none
breastplate
  rotate: 90
  xy: 0, 0
  size: 250, 212
  orig: 250, 212
  offset: 0, 0
dagger
  xy: 250, 0
  size: 52, 143
  orig: 52, 143
  offset: 0, 0
...
```

**字段说明**：
- `size`: 纹理图集总尺寸（宽×高）
- `rotate`: 是否旋转 90°（旋转区域需特殊 UV 处理）
- `xy`: 纹理坐标
- `size`: 区域尺寸
- `orig`: 原始尺寸
- `offset`: 偏移量

#### .skel 文件

二进制格式，包含：
- **骨骼树**：层级结构、骨骼变换
- **槽位**：渲染顺序、骨骼绑定
- **皮肤**：附件集合（Region、Mesh、SkinnedMesh、BoundingBox）
- **动画**：关键帧、变换、时间轴

### 5.3 动画缓存优化与生命周期 (重要)

为彻底解决 Spine 二进制与图集被频繁销毁重建立即导致的**闪烁、黑块、怪物理发动作无法复原、以及特定时序下卡状态**等问题，自定义运行时做了如下革命性深度优化：

1. **骨骼路径匹配绕过**：
   在 `load_character()` 操作拦截中：
   ```gdscript
   func load_character(skel_path: String, atlas_path: String, png_dir: String) -> void:
       if current_skel_path == skel_path and _loaded:
           return  # 骨骼文件一致时立即截断并返回，免除重新销毁
       current_skel_path = skel_path
       _clear_sprites()
       _loaded = false
   ```
   * 如果新加载的姿态文件与当前正在播放的文件是同一个（例如 `idle` 与 `combat` 都在使用同一骨骼，或者是怪物受击回退瞬间），将直接复用当前的渲染器，仅通过 `sp.play()` 修改动画轨道时间轴。这消除了反复删除添加子节点时产生的视觉毛刺和瞬间白屏。

2. **强同步首帧姿态更新**：
   * 采用自定义的时间步进计算时，如果在加载后的一帧内没有主动姿态介入，节点会出现初始 T-Pose 或 0,0 位置堆叠。为此在 `play()` 中追加强同步的 `_update_pose()` 第一帧，消除任何空挡或时间延迟造成的视觉瞬移闪跳。

3. **换位下的实体字典迁移映射保护**：
   * 在发生技能重定位或主动换位时，英雄的数据组会被彻底清空重排，我们重写了 `_apply_hero_reposition_position` 保障算法：除了重映射 `0..3` 的 `int` 类型英雄 Key 外，会遍历在 `_spine_players` 中所有合法的 `String` 类型怪物的底层引用（如 `"monster_idx"` 表项），并将它们原封不动地进行完整拷贝。这保证了在队伍发生任何重定位、位移大招操作后，怪物的 Spine 实体指针绝对不会在内存体系中丢失，各回合动作始终全量保持响应！

### 5.4 渲染流程

```
SpinePlayer._build_sprites()
  ├─ 遍历所有槽位（Slot）
  ├─ 根据附件类型（Attachment）决定渲染方式
  │  ├─ Region → Sprite2D（简单纹理）
  │  ├─ Mesh → Polygon2D（UV 映射多边形）
  │  └─ SkinnedMesh → Polygon2D（多骨骼加权变换）
  └─ 使用 _update_mesh_poly() 计算顶点世界坐标

SpinePlayer._update_pose()
  ├─ 从根骨骼开始递归计算变换
  ├─ 每个骨骼的世界变换 = 父骨骼变换 × 局部变换
  ├─ 应用动画帧的骨骼位置/旋转/缩放
  └─ 更新所有 Sprite2D 或 Polygon2D 的位置/旋转/缩放
```

**越界防护**：`_update_pose()` 累积世界变换时对 `parent_index`、`slots[si].bone_index` 做边界校验（越界时父骨骼回退为自身局部变换、附件骨骼回退为 `Transform2D.IDENTITY`），避免异常骨骼数据触发 `Out of bounds` 崩溃。

_update_mesh_poly()
  ├─ 对于 Mesh：直接应用单个骨骼变换
  ├─ 对于 SkinnedMesh：加权求和多个骨骼变换
  ├─ 计算顶点的世界坐标
  ├─ UV 坐标映射到纹理图集
  │  ├─ 未旋转区域：直接使用 UV
  │  └─ 旋转区域：交换 U/V 轴，处理尺寸变化
  └─ 更新 Polygon2D 的 vertices 和 uv
```

### 5.4 关键数据结构

#### SpineSkel 中的 RegionAttachment

```gdscript
class RegionAttachment:
	var name: String
	var att_type: int                    # 0=Region, 2=Mesh, 3=SkinnedMesh
	var x: float
	var y: float
	var scaleX: float
	var scaleY: float
	var rotation: float
	var width: float
	var height: float
	var color: Color
	var page_index: int
	var region_index: int
	
	# Mesh 和 SkinnedMesh 特有
	var mesh_uvs: PackedFloat32Array       # [u0, v0, u1, v1, ...]
	var mesh_vertices: PackedFloat32Array  # [x0, y0, x1, y1, ...]
	var mesh_triangles: PackedInt32Array   # [t0, t1, t2, ...]
	var mesh_bones: Array                  # [{bone_idx, x, y, weight}, ...]
```

### 5.5 导入 Spine 动画

#### 步骤 1：在 Spine 中导出

1. 打开 Spine 编辑器
2. **菜单** → **Spine** → **Export**
3. **数据格式** → 选择 **Spine 2.1** 或 **2.0**
4. **输出路径** → `characters/{hero_id}/anim/`
5. **输出文件名** → `{hero_id}.sprite.{anim_name}`
   - 示例：`crusader.sprite.idle`, `crusader.sprite.attack`
6. **选项**：
   - ✓ 导出 `.skel`（二进制）
   - ✓ 导出 `.atlas`（纹理映射）
   - ✓ 导出 `.png`（纹理文件）

#### 步骤 2：验证文件结构

导出后应有：

```
anim/
├─ crusader.sprite.idle.skel
├─ crusader.sprite.idle.atlas
├─ crusader.sprite.idle.png
├─ crusader.sprite.attack.skel
├─ crusader.sprite.attack.atlas
├─ crusader.sprite.attack.png
└── [其他动画...]
```

#### 步骤 3：在代码中加载

```gdscript
var sp := SpinePlayer.new()
var skel_path = "res://characters/crusader/anim/crusader.sprite.idle.skel"
var atlas_path = "res://characters/crusader/anim/crusader.sprite.idle.atlas"
var png_dir = "res://characters/crusader/crusader_A/anim"
sp.load_character(skel_path, atlas_path, png_dir)
sp.play("idle")
add_child(sp)
```

### 5.6 常见问题

| 问题 | 原因 | 解决方案 |
|------|------|---------|
| 骨骼不显示 | 附件类型为 SkinnedMesh 但权重数据缺失 | 检查 `.skel` 是否包含权重数据，重新导出 |
| 纹理部分缺失 | 旋转区域的 UV 坐标计算错误 | 检查 `_update_mesh_poly()` 中的旋转处理逻辑 |
| 骨骼位置错误 | Y 轴反向处理不正确 | Spine 为 Y 向上，Godot 为 Y 向下，需要 `y = -y` 转换 |
| 动画播放卡顿 | 关键帧时间间隔设置过大 | 在 Spine 中调整关键帧密度 |
| **控制台刷屏 `Unicode parsing error ... Unexpected NUL character` 且角色模型残缺/不动** | `.skel` 含 **IK 约束**，而 `SpineSkel.parse()` 的 IK 段未完整消费详情块，导致后续 slot / 皮肤 / 动画全线错位 | 已在 `SpineSkel.gd` 修复：IK 块布局为 `name + bonesCount + bones[] + target + mix(float) + bendDirection(1 字节有符号)`，缺失任一字段都会错位。判据：`ik_count > 0` 的资源才会触发（十字军 = 0，训犬师 idle/walk = 5、combat = 4） |
| **同上的 NUL 刷屏，且 IK 明明已处理仍错位** | `bendDirection` 被当成 varint 读：**`bend=+1` 写作 `01`（两种读法同为 1 字节，完美掩盖 bug）；`bend=-1` 写作 `FF`，varint 因高位为 1 而多吃 1 字节** → 后续全部段落偏移 1 字节（症状：插槽名变乱码 + `attachments=0` + `anims=0`） | 改为单字节有符号读（`_Reader.read_byte()`）。实测受害者：`brigand_fuseman.sprite.combat.skel`（`left_leg_IK` 的 bend 为 `-1`）。批量体检：`godot --headless --path <项目> --script res://tools/_probe_skel_integrity.gd`（递归扫描全部 `.skel`，基线：168 个中仅 `crusader.sprite.walk.skel` 为历史遗留 `anims=0`）；字节级定位：`python tools/_diag_skel.py <skel 路径>` |

> **排查手法**：`ERROR: Unicode parsing error ... Unexpected NUL character` 是 `String` 解码读到 `NUL` 字节的信号，几乎总意味着**字节流已错位**（而非文件损坏）。此时对比同类资源的分段计数（bones / slots / animations）即可快速锁定出错段落。

---

## 6. 技能系统与按钮绑定

## 6. 技能系统与按钮绑定

### 6.1 技能配置结构与高级机制

#### SkillConfig.gd 属性全貌

游戏内每一个技能都是完全的数据配置驱动。打开 [scripts/data/SkillConfig.gd](scripts/data/SkillConfig.gd)，你将在 `SKILLS` 静态字典中找到各种类型的技能定义。

```gdscript
static var SKILLS: Dictionary = {
	"my_custom_skill": {
		"name": "My Custom Skill",
		"description": "自定义高阶技能描述",
		"effect_type": "damage",             # 效果类型: "damage" | "heal" | "composite_heal" | "guard"
		"target_type": "single_enemy",       # 目标形式: "single_enemy" | "single_ally" | "all_enemies" | "all_allies" | "self"
		"attack_ratio": 1.2,                 # 攻击系数（基于施法者基础 attack）
		"heal_amount": 0,                    # 固定的治疗量（仅在 effect_type 为 "heal" 时有效）
		
		# 位置约束选项
		"use_positions": [2, 3, 4],          # 施法者可用位置（1~4，1为排头即前排，4为排尾）
		"target_positions": [2, 3, 4],       # 技能可以命中的有效目标站位（1~4，留空数组 [] 视为不限）
		
		# 【高阶核心机制：主动位移】
		"move_forward": 1,                   # 结算后位移值: 正数指排头方向(如1为前进一位); 负数指排尾方向(如-1为退后一位)
		
		# 【高阶核心机制：目标强制位移】
		"target_move_forward": 3,            # 命中目标的强制位移: 正数向排头方向拉前(如3为把怪物拉前3位); 负数向排尾方向推后
		
		# 【高阶核心机制：压力伤害】
		"stress_damage": 15,                 # 造成的精神压力累加值（满200秒杀）
		
		# 【高阶核心机制：附加状态异常 / 控制】
		"status_effects": [                  # 命中后为目标附加的状态数组
			{"status_id": "bleed", "stacks": 3, "duration": 3},  # DoT：每回合扣 层数 点血
			{"status_id": "stun",  "stacks": 1, "duration": 1},  # 控制：目标行动时跳过该次行动，随后解除
			{"status_id": "mark",  "stacks": 1, "duration": 3}   # 易伤：被标记者承受伤害提高 30%
		],
		"guard_duration": 3,                 # 仅 effect_type = "guard" 时有效：守护持续到被守护者行动 N 次
		
		# 【高阶核心机制：怪物AI索敌控制】
		"target_priority": "highest_stress"  # AI单体目标选择规则: "lowest_hp" | "highest_stress" | "random"
	}
}
```

#### 6.1.1 使用条件与召唤类字段（BOSS 联动机制）

除上述通用字段外，技能还支持一组**使用条件**，用于表达“首领需弹药桶在场”“大炮需已被装填”这类联动逻辑（判定在 `BattleController._meets_skill_conditions()`，在站位校验之后、取目标之前）。**条件不满足时该技能直接不入候选**，因此怪物会自动改用其他可用技能。

| 字段 | 类型 | 说明 |
|------|------|------|
| `requires_alive_ally` | Array[String] | 场上必须**存在存活**的这些怪物（全部满足） |
| `requires_absent_ally` | Array[String] | 场上必须**不存在存活**的这些怪物（全部满足） |
| `requires_self_status` | String | 自身必须带有该状态（如大炮需 `cannon_loaded`） |
| `requires_self_status_absent` | String | 自身必须不带有该状态 |
| `consume_self_status` | String | 技能结算后移除自身该状态（如大炮开火后卸弹） |
| `target_ally_id` | String | `single_ally` 时只服务该 id 的友军（点火员只给大炮点火） |
| `target_ally_status_absent` | String | 身上带有该状态的友军不可选（避免对已装填的大炮重复点火） |
| `summon_monster_id` | String | `effect_type: "summon"` 要召唤的怪物 id |
| `skill_priority` | int | **怪物选招优先级**（默认 0）：只有最高档的候选技能参与随机，低档技能仅在高档不可用时兜底（例：`fuseman_light_fuse` 配 `1`，保证点火员能装填就一定装填，装不了才打灼热散弹） |

新增的 `effect_type`：

| 值 | 含义 |
|----|------|
| `apply_status` | 不结算伤害/治疗，只把 `status_effects` 施加给目标（投弹标记、装填引信） |
| `summon` | 在施法者身上播放特效并召唤 `summon_monster_id`（目标类型写 `self`） |

---

### 6.2 深度维护与维护设计说明

#### 6.2.1 技能位移机制设计 (`move_forward`)
当英雄释放配置了 `"move_forward"` 的技能时，其换位运算和流转逻辑在 [scripts/battle/BattleController.gd](scripts/battle/BattleController.gd) 的 `_finish_hero_action()` 中自动闭环调用：
1. **边界安全夹逼 (Clamp Protection)**：
   - 目标索引采用 `clamp(src_idx - move_forward, 0, heroes.size() - 1)` 计算。
   - 这确保了无论是强力前进（如神圣矛前进 1，若当前处于第 1 位则保持为 1）还是向后退弹（如贴身射击后退 1 位），角色的索引都严格驻留在合法战斗位置中，杜绝了数组越界崩溃。
2. **行动点与轮转安全**：
   - 位移结算会首先执行物理自减 `actions_remaining -= 1` 确认其这一行动完成，并调用 `_apply_hero_reposition_position` 实现 `heroes` 数组、SpinePlayer 动画持有者、UI 锚点缓存的同步偏移互换。
   - 位移完成后，通过调用 `turn_queue.build()` **重建行动队列**使轮次和站位对齐，随之直接 `_get_next_actor()` 拉取新的轮次，过程不卡死不重叠。

#### 6.2.2 目标强制位移机制设计 (`target_move_forward`)
当技能配置了 `"target_move_forward"` 时，命中目标会被强制向排头方向拉前（正数，如神秘学者「灵魂之触」`target_move_forward = 3` 把怪物拉前 3 位）或向排尾方向推后（负数）。整条链路完全不依赖新状态机，复用现有的索引位移框架：

1. **结算时机**：在 [scripts/battle/BattleController.gd](scripts/battle/BattleController.gd) 的 `_on_monster_pressed()` 中，等 `ATTACK_ZOOM_DURATION` 打击动画演完、`_clear_focus()` 恢复画面后才结算。避免目标在出招途中发生视觉瞬移；若目标当场死亡留尸或尸体被清除（`was_cleared`），则跳过拉拽。
2. **数据重排 (`_apply_monster_reposition_position`)**：
   - 与英雄版 `_apply_hero_reposition_position` 对称：先按索引顺序缓存 `"monster_%d"` 的 SpinePlayer / 动画状态槽位，再 `remove_at` + `insert` 重排 `monsters` 数组并刷新各怪物 `index` 键。
   - 槽位数组以**同样的位移规则**重排后重新挂载回 `"monster_%d"` 键，保证渲染与数据严格一致；英雄键（`int`）原样保留不受影响。
   - 边界采用 `clamp(target_idx - pull, 0, monsters.size() - 1)`，前进到排头即停，杜绝数组越界。
3. **队列重建的时序陷阱（已规避）**：位移发生在施法者行动点尚未扣除的时刻，若此时立刻 `turn_queue.build()`，施法者会带着 `actions_remaining = 1` 被重新入队，导致同一回合重复行动。因此 `_apply_monster_reposition_position()` **只重排数据与刷新 UI**，并通过成员标记 `_target_reposition_applied` 记录，交由 `_finish_hero_action()` 在扣除行动点之后再 `turn_queue.build()`：
   - 施法者自身有 `move_forward` → 走 A 分支（扣点 → 位移 → 重建队列）；
   - 仅有目标强制位移 → 走 B 分支（扣点 → 重建队列）；
   - 标记在 `_finish_hero_action()` 末尾统一清零，并在 `_setup_battle()` 中重置。
4. **UI 反馈**：技能悬浮提示由 `_build_skill_tooltip()` 输出「目标位移：拉前 N 位 / 推后 N 位」，位置说明沿用「1=最前，4=最后」。

#### 6.2.3 压力与一击必杀机制 (`stress_damage`)
压力数值的变化在战斗数值分发器 [scripts/battle/ActionResolver.gd](scripts/battle/ActionResolver.gd) 的静态方法 `apply_stress` 被严密监控：
1. **暗紫地牢风格指示条**：
   - 每一个英雄卡槽的底部，都通过 `_make_hero_slot()` 的 ProgressBar 进行实时渲染。
   - 该样式不仅配有 `"Stress: N/200"` 的冷淡淡粉紫色字体外，更重设了 `StyleBoxFlat` 纯平样式盒将核心刻度填充色彩修正为**神秘而暗黑的暗紫色** (`Color(0.6, 0.2, 0.7)`)。
2. **狂热濒死死亡规则**：
   - 当怪物使用附带 `"stress_damage"` 属性的技能导致英雄压力上升时，在 `apply_stress()` 函数里判定累加值。
   - **越过 100（越阈）**：只要英雄当前**既没有折磨也没有美德**，就被先**钳制到 100**，再由战斗层掷骰决定「折磨 / 美德」（75% / 25%，详见 6.10）；掷出的状态与压力一起跨战斗保留，因此在带状态期间不会重复掷骰。
   - **一旦突破或达到阈值界限 200**：角色的当前 `stress` 立即**全额重置清零**。
   - 伴随清零，系统向该角色发出高额致死指令 `apply_damage(target, 999)`，达成原本地牢模式在压力绝境下当场心脏骤停的极致体验。
   - 折磨状态下英雄的压力条填充色会转为暗红，作为"随时可能失控"的视觉警示。

#### 6.2.4 怪物智能AI施法限制与索敌筛选规则
怪物在轮次到期时的行为已彻底改写为**位置限制 + 智能权重最优匹配**的机制。其在 [scripts/battle/BattleController.gd](scripts/battle/BattleController.gd) 的 `_execute_monster_action()` 中按以下流水线进行：
1. **行动点锁定防死锁**：在进入逻辑的第一行先自减 `actions_remaining -= 1`，保证任何条件下哪怕跳过该回合也不会陷入无限连动死循环。
2. **站位可用校验**：比对当前行动怪物站位 `monster_pos` （`index + 1`）是否被技能的 `use_positions` 数组所接纳。不被接纳则抛弃该候选。
3. **目标绝对站位筛选**：调用 `_get_valid_targets_for_monster()` 搜寻满足对应技能能射击到的 `target_positions` 且活着的英雄。
4. **AI索敌优先级特征字典 (`target_priority`)**：
   针对上述初筛合格的目标集，根据优先级字段进行精确二次搜寻：
   - `"lowest_hp"`：搜索在目标存活集中生命值 (`hp`) 最低的最脆弱英雄进行针对性打击，完美复刻补刀逻辑。
   - `"highest_stress"`：定位目标存活集中压力值 (`stress`) 最高的英雄，施加压力或伤害以求引发200濒死心碎死，实现精神精准施压。
   - `"random"`：在有效存活集中等概率随机盲选，作为通用的打击策略。
5. **安全退避 (Fallback Skip)**：
   - 遭遇前后排压制且无法释放任何有效技能时，怪物将进入 `else` 虚无 `pass` 退避分支。
   - 极其稳健，保证绝不抛出异常。

---

### 6.3 技能绑定流程

```
BattleController._update_ui()
  ├─ _update_skill_buttons()
  │  ├─ 清空旧按钮
  │  ├─ 获取当前英雄的技能 ID 列表
  │  ├─ 对每个技能加载图标
  │  ├─ 创建 Button 节点
  │  ├─ 连接 pressed 信号到 _on_skill_pressed(skill_id)
  │  └─ 添加到技能容器
  │
  └─ [按钮点击事件]
    _on_skill_pressed(skill_id)
      ├─ 设置 hero_current_skill = skill_id
      ├─ 设置 hero_skill_selected = true
      ├─ 调用 _update_ui() 刷新目标显示
      └─ [等待玩家选择目标]
```

### 6.4 目标选择流程

```
玩家选择技能后
  ├─ 检查技能的 target_type
  │  ├─ "single_enemy" → 显示敌人列表
  │  ├─ "single_ally" → 显示盟友列表
  │  ├─ "all_enemies" → 显示"攻击全体"按钮
  │  └─ "self" → 自动应用
  │
  └─ 玩家点击目标
    _on_monster_pressed(index) / _on_ally_pressed(index)
      ├─ 调用 ActionResolver.resolve_on_target()
      ├─ 计算伤害/治疗
      ├─ 更新目标状态
      ├─ 调用 _finish_hero_action()
      └─ 推进行动队列
```

### 6.5 按钮事件连接示例

#### 技能按钮

```gdscript
var btn = Button.new()
btn.icon = icon_texture
btn.tooltip_text = _build_skill_tooltip(sd)  # 悬浮提示：名称 + 描述 + 使用/目标位置 + 效果
btn.pressed.connect(_on_skill_pressed.bind(skill_id), CONNECT_DEFERRED)
skill_icon_boxes[skill_idx].add_child(btn)
```

#### 目标选择按钮

```gdscript
var btn := Button.new()
btn.text = monster["name"]
btn.pressed.connect(_on_monster_pressed.bind(idx), CONNECT_DEFERRED)
vbox.add_child(btn)
```

#### 187. 英雄位置选择（换位模式）

```gdscript
var btn := Button.new()
btn.text = hero["name"]
btn.pressed.connect(_on_hero_reposition_target.bind(idx), CONNECT_DEFERRED)
vbox.add_child(btn)
```

### 6.6 创建一个新技能的完整开发范例

无论是英雄新终极伤害大招，还是怪物的绝杀精神打击，都可以按照以下规范创建和发布：

#### 步骤 1：在 SkillConfig.gd 中定义技能骨架

在 `SKILLS` 字典下追加。这里以我们配置一个**强盗的前进射击 + 大量压力精神攻击**以及指定怪物**高智能残血收割大槌**为例：

```gdscript
	# 强盗大招，仅能在后排4位释放，必定前进1，攻击并给11号怪造成高额伤害和10点压力伤害
	"point_blank_shot": {
		"name": "Point Blank Shot",
		"effect_type": "damage",
		"target_type": "single_enemy",
		"attack_ratio": 2.0,
		"stress_damage": 10,
		"description": "前进1，攻击目标敌人",
		"use_positions": [4],
		"target_positions": [1, 2],
		"move_forward": 1
	},
	
	# 怪物神技：断罪重置，仅在一号位可用，优先选取生命值最低的目标重锤打击
	"judge_smash": {
		"name": "Judge Smash",
		"effect_type": "damage",
		"target_type": "single_enemy",
		"attack_ratio": 1.4,
		"description": "重锤打击濒死之人",
		"use_positions": [1],
		"target_positions": [1, 2, 3],
		"target_priority": "lowest_hp"
	}
```

#### 步骤 2：在 HeroConfig.gd 或 MonsterConfig.gd 中进行装备绑定

```gdscript
# 如果是英雄... 绑定给 highwayman 的技能栏中
static var HEROES: Dictionary = {
	"highwayman": {
		"id": "highwayman",
		"name": "Highwayman",
		"max_hp": 48,
		"attack": 10,
		"speed": 6,
		"skills": ["shotgun", "cut", "Close-range shooting", "point_blank_shot"], # 追加进去
	}
}

# 如果是怪物... 绑定给 Brigand Cutthroat 
static var MONSTERS: Dictionary = {
	"cutthroat": {
		"id": "cutthroat",
		"name": "Brigand Cutthroat",
		"max_hp": 42,
		"attack": 8,
		"speed": 4,
		"skills": ["cutthroat_strike", "temptation", "judge_smash"], # 绑定AI大槌技能
	}
}
```

#### 步骤 3：准备技能图标（对英雄有效）

在 `characters/highwayman/` 目录下提供切片图标 `highwayman.ability.four.png`：
- 因为其在英雄技能数组中排在第 4 位（索引 3），加载引擎会根据排列顺序自动装配加载第四个。

#### 步骤 4：运行验证与测试

1. 启动项目，进入战斗。
2. 当英雄/怪物当前站位和条件可用（例如把强盗逼退至 4 号位时），技能便会激活。
3. 释放带有 `move_forward` 技能后，检查排位，验证是否有安全的循环向右或向左换位，并观察暗色调的紫色压力指示槽是否完美记录并响应了 `apply_stress` 及 200 点秒杀机制。

---

#### 步骤 1：定义技能数据（SkillConfig.gd）

```gdscript
static var SKILLS: Dictionary = {
	# ...
	"skill_my_new_attack": {
		"name": "My New Attack",
		"description": "A custom attack",
		"target_type": "single_enemy",
		"target_positions": [],
		"skill_type": "damage",
		"damage_multiplier": 1.5,
		"use_positions": [1, 2, 3, 4],
	},
}
```

#### 步骤 2：分配给英雄（HeroConfig.gd）

```gdscript
static var HEROES: Dictionary = {
	"my_hero": {
		"id": "my_hero",
		"name": "MyHero",
		"max_hp": 60,
		"attack": 12,
		"speed": 5,
		"skills": ["skill_my_new_attack", "skill_heal", ...],  # 添加技能
	},
}
```

#### 步骤 3：准备技能图标（文件）

```
characters/my_hero/
├─ my_hero.ability.one.png      # 对应 skills[0]
├─ my_hero.ability.two.png      # 对应 skills[1]
├─ my_hero.ability.three.png    # 对应 skills[2]
└── ...
```

#### 步骤 4：测试

1. 选择英雄进入战斗
2. 当该英雄行动时，应显示新技能图标
3. 点击技能应弹出目标选择
4. 选择目标应执行伤害计算

---

## 6.7 技能特效（VFX）偏移、缩放与映射配置

本项目通过 [scripts/battle/BattleController.gd](scripts/battle/BattleController.gd) 的 `SKILL_FX_MAP` 进行管理，支持通过 `.offset` 控制生成的特效与受击目标原点的相对偏移，以及 `.scale` 控制其缩放大小。

### 6.7.1 为什么需要偏移和缩放？
* **偏移量 (Offset)**：Spine 导出的视觉特效（例如十字军的 `smite.skel`、强盗的受击特效等）在制作时的原点坐标可能并不在角色脚底。若不加偏移，特效将全部渲染在角色物理脚底，例如目标胸部的受击闪光效果，如果不设置 `offset`，就会显示在地上。
* **受击特效（`target_fx`）默认无需手填偏移**：程序会按双方实际绘制范围自动对齐到目标躯干（详见 6.7.4），只有自动结果不满意时才手动写 `target_offset` 覆盖。
* **缩放 (Scale)**：非角色主体的特效文件，其导出的画布单位和像素比例可能比角色的要大或要小，通过 `scale` 可以控制它们的实际高宽对齐。

### 6.7.2 如何在 `SKILL_FX_MAP` 中进行配置
打开 [scripts/battle/BattleController.gd](scripts/battle/BattleController.gd)，定位常数 `SKILL_FX_MAP`。每个技能有对应的配置：

```gdscript
const SKILL_FX_MAP := {
	# 十字军技能特效
	"slash": {
		"caster_fx": "res://characters/crusader/fx/crusader.sprite.smite",
		"caster_offset": Vector2(50.0, -80.0),    # 施法特效在施法者右侧 50，靠上 80 像素处播放
		"caster_scale": 1.2                       # 放大为 1.2 倍
	},
	"heal": {
		"caster_fx": "res://characters/crusader/fx/crusader.sprite.battle_heal",
		"caster_offset": Vector2(0.0, -100.0),    # 在施法者身体中部（偏上100像素）
		"caster_scale": 1.0,
		"target_fx": "res://characters/crusader/fx/crusader.sprite.battle_heal_target",
		"target_offset": Vector2(0.0, -90.0),     # 被治疗者头部偏下特效原点对齐
		"target_scale": 0.8                       # 缩小为 0.8 倍
	},
	"holy spear": {
		"caster_fx": "res://characters/crusader/fx/crusader.sprite.holy_lance",
		"caster_offset": Vector2(120.0, -30.0),   # 冲锋攻击向前大偏移
		"caster_scale": 1.1
	},
	
	# 强盗技能特效
	"shotgun": {
		"caster_fx": "res://characters/highwayman/fx/highwayman.sprite.grape_shot_blast",
		"caster_offset": Vector2(100.0, -70.0),
		"caster_scale": 1.0,
		"target_fx": "res://characters/highwayman/fx/highwayman.sprite.grape_shot_blast_target",
		"target_offset": Vector2(0.0, -60.0),
		"target_scale": 1.0
	},
	"cut": {
		"caster_fx": "res://characters/highwayman/fx/highwayman.sprite.wicked_slice",
		"caster_offset": Vector2(40.0, -50.0),
		"caster_scale": 1.0,
		"target_fx": "res://characters/highwayman/fx/highwayman.sprite.opened_vein",
		"target_offset": Vector2(-20.0, -60.0),
		"target_scale": 1.0
	}
}
```

### 6.7.3 参数机制说明

1. **`caster_offset` / `target_offset`**:
   * 类型：`Vector2`。
   * Y轴坐标：**向上为负，向下为正**（Godot Y-down 原则）。要想特效往人物头部方向挪，请填写 `-80` 到 `-120` 之间的值。
   * X轴坐标：施法者和受击者如果是翻转朝向的（如向左看），**程序中已自动计算了朝向并对 offset.x 自动取反 `offset.x = -offset.x`**。无需手动增加极性判定，统一写成攻击方向的水平偏移数值即可。
   * **`target_offset` 现在是可选项**：不填时受击特效会按“双方实际绘制内容范围”自动纵向对齐到目标躯干（见 6.7.4）；仅在自动对齐不理想时才手动指定覆盖它。
2. **`caster_scale` / `target_scale`**:
   * 类型：`float`。
   * 默认值：`1.0`。此值会乘算底层 Spine 渲染模板的系统对齐缩放 (Spineplayer 系统默认缩放是 `0.5`)，通过此变量可微调最终显示的像素画面。

### 6.7.4 受击特效的自动纵向对齐（默认行为）

**背景（曾经的 bug）**：受击特效过去使用一个写死的默认偏移 `Vector2(0, -100)`。但 DD 特效资源的原点位置并不统一：

| 类型 | 代表资源 | 内容相对自身原点的范围 | 写死 `-100` 的后果 |
|------|----------|------------------------|----------------------|
| 斩击/血花类（原点在脚底） | `highwayman.sprite.opened_vein` | -203 ~ +1 | **上移到人物头顶上方 34~60px** |
| 治疗/祝福类（原点在脚底） | `crusader.sprite.battle_heal_target` | -291 ~ +10 | 超出头顶 78~104px |
| 曳引/深渊类（原点在脚底） | `occultist.sprite.hands_from_abyss_target` | -306 ~ +56 | 超出头顶 86~112px |
| 弹着/闪光类（原点在自身中心） | `highwayman.sprite.pistol_shot_target` | -31 ~ +32 | 恰好落在躯干（正确） |

即：写死偏移对“原点在自身中心”的小特效是对的，但对“原点在脚底”的大特效会把它们整体推到头顶上方。而且目标既有英雄（高约 300~400 骨架单位）也有怪物（约 300），固定像素值无法兼顾。

**现方案**：`BattleController` 在特效加载完成后计算双方的“实际绘制几何包围盒”（`_spine_content_bounds()`，网格槽取 `Polygon2D.polygon`，区域槽取 `Sprite2D` 四角经 `transform` 变换），再把特效内容中心对齐到目标身体自上而下 `BODY_FX_ANCHOR_RATIO`（默认 `0.45`）处：

```
anchor_local  = body.pos.y + body.size.y * 0.45      # 骨架单位
fx_center     = fx.pos.y + fx.size.y * 0.5
fx_origin_y   = (anchor_local * body.scale.y) - (fx_center * fx.scale.y)
```

实测效果（屏幕像素，相对目标脚底，负 = 脚底之上）：

| 技能 / 特效 | 旧（写死 -100） | 新（自动对齐） |
|-------------|------------------|----------------|
| `cut` → `opened_vein` | 超出头顶 34~60px | 覆盖躯干，无超出 |
| `heal` → `battle_heal_target` | 超出头顶 78~104px | 贴身体（≤8px 溢出） |
| `深渊之手` → `hands_from_abyss_target` | 超出头顶 86~112px | ≤26px（该特效本身体积大于人物，必然略有溢出） |
| `pistol_shot` → `pistol_shot_target` | 躯干（原本就正常） | 仍为躯干 |

> 调试工具：`tools/_probe_spine_bounds.gd`（测量任意 skel 的绘制包围盒）与 `tools/_probe_fx_runtime.gd`（真实实例化 Battle.tscn，直接调用 `_play_skill_fx_v2()` 打印各技能特效的实际屏幕落点）。均以 `godot --headless --path <项目> --script <脚本>` 运行。

---

### 6.8 状态异常（Buff / Debuff）系统

状态定义集中在 [scripts/data/StatusConfig.gd](scripts/data/StatusConfig.gd) 的静态字典 `STATUSES`，数值结算在 [scripts/battle/ActionResolver.gd](scripts/battle/ActionResolver.gd)。

> **结算时机（统一规则）**：所有状态的效果与持续时间都在**该状态的携带者自己行动时**结算，回合开始（`_start_new_round()`）**不做任何统一结算**。唯一调用点是 `BattleController._tick_current_actor_statuses()`，由 `_get_next_actor()` 在弹出行动者后调用——A 行动时不会影响 B 身上的状态。新增带回合效果的状态时，一律挂到这条链上（在 `tick_statuses()` 里按 `StatusConfig` 字段分支），**不要**写成回合开始遍历全场。

#### 6.8.1 状态字段

| 字段 | 说明 |
|------|------|
| `id` / `name` | 状态 ID 与中文显示名 |
| `type` | `"dot"`（持续伤害）/ `"control"`（控制）/ `"debuff"` / `"buff"` |
| `description` | 悬浮提示中的描述文本 |
| `icon` | 状态图标（`res://overlays/*.png`），在角色卡槽下方渲染 |
| `dot` | `true` 时每回合扣血（**扣血时机 = 该单位自己行动时**，非回合开始），扣血值 = 当前层数 |
| `skip_turn` | `true` 时为控制类状态：**在该单位行动时判定，跳过这一次行动并立即解除** |
| `manual_duration` | `true` 时**不参与按回合衰减**，存续由战斗逻辑掌握（爆破标记、折磨、美德） |
| `damage_taken_mult` | 目标承受伤害的倍率（`> 1.0` 表示易伤，如"标记"的 `1.3`） |
| `attack_mult` | **攻击力加成**（`> 1.0` 表示增伤，如"美德激励"/"战意高涨"的 `1.2`）——**多个 `attack_mult` 之间加算**：`攻击力 ×(1 + Σ(mult - 1))` |
| `damage_mult` | **最终伤害加成**（`> 1.0` 表示增伤，如"狗粮"的 `1.2`）——**多个 `damage_mult` 之间乘算**，乘在公式最后 |
| `stress_taken_mult` | 携带者受到压力的倍率（`> 1.0` 表示更易崩溃，如"折磨"的 `1.2`） |

当前内置：

| 状态 | id | 关键字段 | 效果 |
|------|----|----------|------|
| 流血 | `bleed` | `dot` | 每回合扣除当前层数点生命 |
| 腐蚀 | `blight` | `dot` | 每回合扣除当前层数点生命 |
| 晕眩 | `stun` | `skip_turn` | 该单位行动时跳过一次行动，跳过即解除 |
| 标记 | `mark` | `damage_taken_mult = 1.3` | 承受伤害 +30%（不含流血/腐蚀等 DoT） |
| 守护 | `guard` | 携带 `guardian_id` / `guardian_slot` | 被敌人单体攻击时伤害转移给守护者 |
| 折磨 | `afflicted` | `stress_taken_mult = 1.2` / `manual_duration` | 压力越阈 75% 概率进入：受压力 +20%，每次行动 30% 概率失控（见 6.10） |
| 美德 | `virtuous` | `manual_duration` | 压力越阈 25% 概率进入：清空自身压力，成为全队精神支柱 |
| 美德激励 | `virtue_buff` | `attack_mult = 1.2` | 全体英雄攻击力 +20%，持续 5 回合（美德触发时施加；与战意高涨**加算**） |
| 狗粮 | `dogfood_buff` | `damage_mult = 1.2` | 最终伤害 +20%，持续 1 回合（消耗品「狗粮」使用后附加；**乘算**乘区） |
| 战意高涨 | `inspired` | `attack_mult = 1.2` | 攻击力 +20%，持续 3 回合（AI 激励喊话的 ② 增益结果，见 8.4；与美德激励**加算**） |

#### 6.8.2 晕眩（`stun`）的判定时序

1. **施加**：技能配置了 `status_effects` 后，`ActionResolver.resolve_on_target()` 末尾调用 `apply_status()` 写入目标的 `statuses` 字典。
2. **不随回合衰减**：`ActionResolver.tick_statuses()` 对 `skip_turn` 状态**跳过 `duration` 递减**，避免它在触发之前就被归零移除。
3. **行动时判定**：轮到该单位行动时，`BattleController._get_next_actor()` 首先调用 `_tick_current_actor_statuses()`：
   - 先执行 `ActionResolver.consume_skip_turn(unit)`——判定并**立即移除**该控制状态，返回是否命中；
   - 再做常规 DoT 结算（`tick_statuses`）；
   - 若被晕眩且单位仍存活，调用 `_skip_turn_by_stun(unit)`：把 `actions_remaining` 减 1（**真正跳过**该次行动，防止队列重建后再次入队）、在头顶弹出晕眩图标、刷新 UI，最后返回 `false`；
   - `_get_next_actor()` 收到 `false` 后 `continue` 直接取下一个行动者。
4. **边界**：`actions_remaining` 用 `max(0, ...)` 夹逼；`_start_new_round()` 会重置为 1，不会残留。

#### 6.8.3 UI 呈现

- 角色卡槽下方的 `_make_status_row()` 渲染状态图标；**只有 `dot` 状态显示层数角标**（层数只对 DoT 有意义）。
- `_build_status_tooltip()` 对 `skip_turn` 状态只显示名称 + 描述，其余状态显示「剩余回合」，仅 `dot` 追加「层数」。
- 技能悬浮提示 `_build_skill_tooltip()`：`status_effects` 中的 `skip_turn` 状态显示为「跳过下一次行动（跳过即解除）」，其余显示「X 层 / 持续 Y 回合」；`effect_type: "guard"` 显示守护持续回合数。

#### 6.8.4 进阶内置机制

- **标记易伤（`mark`）**：`ActionResolver.get_damage_taken_multiplier(target)` 取目标身上所有 `damage_taken_mult` 的最大值，由 `apply_damage(target, amount, apply_mark_mult := true)` 施加。**DoT 结算显式传 `apply_mark_mult = false`**（流血/腐蚀不吃标记加成）。
- **守护转移（`guard`）**：`ActionResolver.apply_guard(guardian, target, duration)` 把守护者登记到目标身上，身份用 `(guardian_id, guardian_slot)` 记录——英雄在战斗中会因换位改变 `heroes` 下标，但 `id` / `slot` 始终跟随本人。`BattleController._resolve_guard(unit)` 在敌人单体攻击选中目标后做转移（守护者阵亡或指向自己时不转移），挂接点在 `_execute_monster_action()` 的 `single_enemy` 分支。群体技能不转移。

### 6.9 死门（Death's Door / 濒死）机制

英雄专属的「续命」机制，全部实现在 `BattleController._handle_hero_damage_aftermath(hero_idx, took_damage := true)`，规则与暗黑地牢一致：

1. **归零不死**：生命值降到 0 时不会直接阵亡，而是进入濒死状态（`is_death_door = true`、`hp = 0`），并在头顶弹出 `res://overlays/tray_deathsdoor.png`。
2. **濒死时受到伤害要掷命**：按该角色自己的概率掷一次死亡骰，命中则 `_kill_hero()` 当场阵亡；否则继续支撑，并弹出 `res://overlays/poptext_death_avoided.png`（死里逃生）作为反馈。
3. **非伤害结算不掷骰**：治疗、净化等一律传 `took_damage = false`，生命值回到 0 以上即自动脱离濒死。
4. **濒死仍可行动**：`TurnQueue` 把 `hp > 0 or is_death_door` 视为存活，因此濒死英雄照常入队、可被治疗/守护，也可被选作目标。

#### 6.9.1 概率写在哪里

写在**每个角色自己的配置条目**里：

```gdscript
static var HEROES: Dictionary = {
	"crusader": {
		"name": "Crusader",
		"max_hp": 50,
		"attack": 17,
		"speed": 4,
		"skills": ["slash", "heal", "holy spear", "battle_cry"],
		"death_blow_chance": 0.5, # ← 死门状态（濒死）下受到伤害时的死亡概率
		"personality": "……"
	},
}

# 死门默认死亡概率（角色未单独配置时使用）
const DEFAULT_DEATH_BLOW_CHANCE := 0.5

static func get_death_blow_chance(hero_id: String) -> float:
	if hero_id in HEROES:
		return clampf(float(HEROES[hero_id].get("death_blow_chance", DEFAULT_DEATH_BLOW_CHANCE)), 0.0, 1.0)
	return DEFAULT_DEATH_BLOW_CHANCE
```

链路：`HeroConfig.HEROES[*].death_blow_chance` → `BattleController._setup_battle()` 经 `_death_blow_chance_of()` 写入英雄运行时字典 → `_handle_hero_damage_aftermath()` 掷骰时再 `clampf` 一次。

#### 6.9.2 `took_damage` 参数（易错点）

**只有真的挨了伤害才掷死亡骰**。各调用点必须显式区分：

| 调用点 | 传参 |
|--------|------|
| `_tick_current_actor_statuses()`（流血/腐蚀 DoT） | `true` |
| `_execute_monster_action()` 单体 / 群体技能 | `is_dmg`（仅 `effect_type == "damage"`） |
| `_detonate_bomb()` 首领炸药 | `true` |
| `_execute_inspire_betrayal()` 倒戈攻击队友 | `true` |
| `_on_ally_pressed()` 治疗技能、`_try_use_consumable()` 回血 | `false` |

> 早期版本在治疗分支也调用了同一个函数，导致「为队友治疗（或治疗量掷出 0）时也会给濒死队友掷死亡骰」的误杀缺陷，已由 `took_damage` 参数修正。

#### 6.9.3 UI

`_make_hero_slot()` 在濒死英雄的卡槽血条/压力条下方渲染一行：`tray_deathsdoor.png` 图标 + `DEATH'S DOOR 50%` 文本（百分比取自该角色自己的概率），两者均带悬浮提示：

```
死门（濒死）：生命值已归零，仍可行动与受治疗；
在此期间受到任何伤害时有 50% 概率当场死亡。
```

> 验证：`godot --headless --path <项目> --script res://tools/_probe_deaths_door.gd`（`PASS=33 FAIL=0`，含卡片死门图标/概率提示的渲染校验）。

---

### 6.10 压力系统：折磨（Affliction）/ 美德（Virtue）

数值与概率集中在 [scripts/data/StressConfig.gd](scripts/data/StressConfig.gd)（全部为 `static var`，方便探针脚本临时改写以确定性覆盖分支）。流程图：

```
压力 +N（怪物 stress_damage / 失控加压 / 激励喊话…）
  │  ActionResolver.apply_stress()
  ├─ 折磨加成：amount > 0 时 × stress_taken_mult（1.2）
  ├─ 越过 100 且【当前既无折磨也无美德】→ 钳制到 100 + stress_resolve_pending = true
  │     │  BattleController._resolve_pending_stress_states()（_emit_feedback 末尾 / 激励路径）
  │     └─ 75% 折磨（afflicted）  /  25% 美德（virtuous + 全体 virtue_buff ×5 回合）
  ├─ 压力归零 → 清除折磨（平静下来）
  └─ 达到 200 → 清除美德 + 压力清零（连带清折磨）+ apply_damage(999)；
                 若为折磨且已在瀕死 → 打上 instant_death 标记，无视死门死扛直接处决
```

#### 6.10.1 越阈掷骰（以状态为准，不按战斗重置）

- 触发点：`apply_stress()` 内判定，条件是【当前既没有 `afflicted` 也没有 `virtuous`】——
  **不是"每场战斗掷一次"**（早期版本用 `stress_resolved` 标记，已删除）。
- 结算点：`BattleController._resolve_pending_stress_states()`，由 `_emit_feedback()` 末尾与激励喊话路径调用——**任何压力来源都走同一条结算链**。
- 折磨：施加 `afflicted`（`stress_taken_mult = 1.2`），头顶弹 `tray_afflicted.png` + `panels/seal.affliction.png`，Toast 提示机制。
- 美德：压力清零、施加 `virtuous`，并给**全体英雄**施加 `virtue_buff`（`attack_mult = 1.2`，持续 `VIRTUE_BUFF_ROUNDS = 5` 回合）。
- 掷完状态就挂在身上，因此之后压力可以正常累到 200（不再反复钳制）；
  一旦状态被清掉（见下），再次越阈就会重新掷骰。

#### 6.10.2 压力的三条"清零/满值"规则

| 时机 | 行为 |
|------|------|
| 压力**归零** | 解除折磨（`remove_status(afflicted)`）—— 减压类效果（激励喊话、鼓舞犬吠、美德清空）都能让英雄平静下来 |
| 压力**达到 200** | ① 清除美德；② 压力清零（并按上一条连带清除折磨）；③ `apply_damage(999)`（心脏骤停） |
| 压力达到 200 **且处于折磨且已在瀕死** | 在上述基础上额外打上 `instant_death` 标记，`_handle_hero_damage_aftermath()` 见到后**直接处决**（不掷死门死亡骰），随后 999 伤害/移除照常生效 |

> `instant_death` 由 `ActionResolver.consume_instant_death()` 消费（读一次即清空），避免标记残留到下一次结算。

#### 6.10.3 跨战斗保留

折磨 / 美德与压力一起**跨战斗保留**：`HeroConfig.persist_party_after_battle()` 从英雄的 `statuses` 字典里把 `afflicted` / `virtuous` 写进 `PARTY_STATES` 的 `is_afflicted` / `is_virtuous`，
`get_team_heroes()` 还原到编队模板，`BattleController._build_hero_runtime()` 再还原成状态。
因此下一场战斗开局时英雄仍带折磨 / 美德，也就不会因为“重新进战斗”而白拿一次越阈掷骰。

> 只有这两个无时限的状态会持久化；`virtue_buff`（攻击加成）是按携带者行动次数递减的限时增益，不跨战斗，需重新触发美德才会再次获得。

#### 6.10.4 折磨失控（30%）

`_get_next_actor()` 轮到英雄行动时先过 `_should_roll_breakdown()`；命中则本回合交给 `_execute_affliction_breakdown()`，四种行为等概率：

| 行为 | 实现要点 |
|------|----------|
| 跳过行动 | 直接消耗行动点（与晕眩跳过一致） |
| 攻击队友 | 复用 `_execute_inspire_betrayal(actor, StressConfig.BREAKDOWN_ATTACK_RATIO)` |
| 增加队友压力 | `_execute_breakdown_stress_ally()`：给随机队友加 8~14 压力（会连带触发对方的越阈结算） |
| 自动随机行动 | `_auto_perform_random_action()`：随机挑一个站位可用、目标合法的技能，再走与玩家操作**完全相同**的技能流程（特效/聚焦/数值/扣点/推进队列） |

> **两个实现陷阱（已规避）**：
> ① "自动随机行动"走的是正常技能流程（`_on_monster_pressed` / `_on_attack_all_enemies` / `_on_ally_pressed`），内部已扣点并推进队列，
>    因此 `_execute_affliction_breakdown()` 返回 `true`，调用方 `_get_next_actor()` 必须直接 `return`——若再 `continue` 就会双重推进队列。
> ② 前三种行为需要自己扣点，且"攻击队友"可能击杀队友导致 `heroes` 补位，因此收尾要用 `heroes.find(hero)` 按引用重新定位（与激励倒戈同一套防护）。
>
> 退化保护：没有可用技能 / 没有可攻击的队友 → 自动降为"跳过行动"；濒死（HP = 0）英雄因 `_can_act()` 不通过也会退化为跳过。

#### 6.10.5 攻击力加成

`ActionResolver.calculate_damage()` 的公式为：

```
伤害 = int( 攻击力 × get_attack_multiplier() × attack_ratio × get_damage_multiplier() )
        ① attack_mult：加算（1.2 + 1.2 → ×1.4）
        ② damage_mult：乘算（×1.2，乘在最后）
```

因此美德激励与战意高涨对全体英雄的伤害技能都生效，且**彼此加算**（不会变成 ×1.44）；狗粮属于独立的伤害乘区，会与攻击力加成**乘算**（×1.4 × 1.2 = ×1.68）。验证：`res://tools/_probe_buff_zones.gd`（`PASS=15 FAIL=0`）。

> 验证：`godot --headless --path <项目> --script res://tools/_probe_stress.gd`（`PASS=75 FAIL=0`：配置接线、越阈钳制与两种掷骰结果、以状态为准不重复掷骰、折磨加压 +20%、压力归零解除折磨、美德清空压力与全体 5 回合加攻、四种失控行为、200 的清美德/清折磨/濒死直接处决、跨战斗持久化、与 `_emit_feedback` 的集成）。

### 6.11 尸体显示、卡槽补位与卡槽纵向布局

这一节记录三个容易复发的坑：怪物尸体"站着"、单位移除后卡槽残留旧内容、卡槽内容被下方面板遮挡。

#### 6.11.1 尸体必须"看起来像尸体"（直接借用普通小怪的残骸）

`_update_monster_animations()` 对尸体统一调用 `_load_monster_anim(i, "dead")`，但**不是每个骨架都有独立的 dead 动画**：
首领/大炮/点火员/弹药桶的 `MONSTER_ANIM_CONFIG[id]["map"]["dead"]` 都只是回落到 `"combat"`，
直接播放的结果是尸体笔直站着，与活体无法分辨。

因此 `_load_monster_anim()` 里加了一段替换：**没有真实 dead 动画的骨架阵亡时，直接借用普通小怪的残骸资源**
（默认 `brigand_cutthroat.sprite.dead`，与 BOSS 同属强盗阵营）：

| 骨架情况 | 判定 | 处理 |
|----------|------|------------------------|
| 有真实 dead 动画（`map["dead"] != map["combat"]`，如强盗/骷髅系） | `_monster_has_real_dead_anim()` 为真 | 照旧播自己的 dead |
| 无真实 dead 动画（首领/大炮/点火员/弹药桶） | 判定为假 | 换成 `CORPSE_REMAINS_DEFAULT`（`base`/`dir`/`anim` 三字段）加载并 `play("dead")` |

- 需要单个怪物单独指定残骸时，在 `MONSTER_ANIM_CONFIG` 条目里加一条 `"corpse": {"base": ..., "dir": ..., "anim": ...}` 即可（`_load_monster_anim` 优先读它）。
- 残骸资源自带倒地姿态与原点，**不需要**再压暗/旋转：实测 `brigand_cutthroat.sprite.dead` 的绘制内容 y 区间 `[-141.5, +15.8]`（局部单位，节点 scale=0.5），
  底部与站立骨架的脚底同高，因此尸体正好躺在地面线上（实测屏幕上尸体矩形 `281~359`，站立单位脚底 `361`）。
- 残骸不影响聚焦：`_apply_focus()` / `_clear_focus()` 仍统一用 `Color.WHITE` / `FOCUS_DIM`。
- `_summon_monster()` 会销毁并重建该槽位的 SpinePlayer，因此召唤回尸体槽时**自动换回自己的骨架**（不需要额外清理）。

#### 6.11.2 `_update_list_ui()` 必须清空"全部"槽位

`heroes` / `monsters` 数组会因为阵亡、清尸体而变短，但场景里 `HeroSlot1~4` / `MonsterSlot1~4` 始终存在。

```gdscript
# ✅ 正确：遍历槽位，先清空，再按数组长度填内容
for i in range(monster_slots.size()):
	_clear_children(monster_slots[i])
	if i < monsters.size():
		monster_slots[i].add_child(_make_monster_content(monsters[i], i, target_type, target_positions))
```

> ❌ 反例（旧实现）：`for i in range(monsters.size())`——尾部槽位不会被清理，打掉尸体后 4 号槽仍留着旧血条与旧图标，看起来像"补位错乱"。

`_clear_children()` 用的是 `queue_free()`，**同帧内旧节点仍在树上**：探针/截图脚本若要统计"玩家实际看到的子节点数"，必须过滤 `is_queued_for_deletion()`，并且布局测量要等 2~3 帧后再取 `get_global_rect()`。

> **配套防守**：单位移除后 `current_actor["index"]` 可能短暂指向不存在的下标（英雄阵亡即在同帧内发生）。
> `_update_character_portrait()` 与 `_update_skill_buttons()` 已加 `idx < 0 or idx >= heroes.size()` 卫语句（与 `_update_selected_text()` 同一套防护），
> 否则这种瞬间会抛 `Invalid access of index '3' on a base object of type: 'Array[Dictionary]'`。

#### 6.11.3 英雄/怪物卡槽的纵向预算（避免再次被遮挡）

卡槽 `HeroSlot*`/`MonsterSlot*` 自身只有 200px 高，而下方 `BottomLeftPanel/BottomPanelsContainer` 的**不透明区域从 y≈278 开始**（屏幕 720p），
所以卡槽内所有内容行都必须落在 `y ≤ 278`；同时角色脚底（SpinePlayer 原点）要停在锚点 `0.9 × 高度` 处，位置不能因为排版改动而漂移。

当前布局（`_make_hero_slot()` / `_make_monster_slot()`）：

| 行 | 全局 Y | 说明 |
|----|--------|------|
| 顶部悬浮区（状态图标行 + 死门/尸体行） | ≈28~70 | `slot.add_child(top_overlay)`，`offset_top = -TOP_OVERLAY_HEIGHT`、`alignment = END`、锚在**内容顶部**，因此落在卡槽上方空闲带里 |
| 速度标签（兼作当前行动者指示 `▲`） | 70~87 | 字号 12；原地把"▲"并入文本，省掉一整行 |
| 肖像锚点 | 89~209 | 120 高，脚底 197≈200 |
| 血条（数值内嵌条上） | 211~223 | 12 高，`_make_bar_value_label()` 全铺居中 |
| 压力条（数值内嵌条上） | 225~237 | 同上 |

关键手法：**数值内嵌进度条**（`hp_bar.add_child(_make_bar_value_label(...))`）省掉两行文本；VBox `alignment = BEGIN` + `separation = 2`；
死门/尸体/状态三类"提示行"放进绝对定位的顶部悬浮区，既不被遮挡也不会把角色顶下去。

> 验证：`godot --headless --path <项目> --script res://tools/_probe_corpse_ui.gd`（`PASS=28 FAIL=0`：尸体标记与姿态、真实 dead 动画骨架不误伤、清尸体后补位、尾位槽清空、召唤回尸体槽复位姿态、英雄阵亡补位、卡槽所有行 ≤278、状态栏/死门行落在 0~70 空闲带、角色脚底仍 197±8）。
> 需要肉眼复核时可用 `tools/_shot_check.gd`：`godot --path <项目> --script res://tools/_shot_check.gd` 会渲染一帧并保存 `res://shot_check.png`。

---

## 7. 调试与优化

### 7.1 调试工具

#### 打印调试信息

```gdscript
# 在 BattleController 中添加调试输出
print("Round %d, Current Actor: %s" % [round_number, current_actor.get("name")])
print("Hero HP: %s" % [heroes.map(func(h): return "%s:%d/%d" % [h["name"], h["hp"], h["max_hp"]])])
```

#### 查看 Spine 动画数据

```gdscript
# 在 SpinePlayer 中检查加载的数据
var skel = SpineSkel.new()
skel.parse(skel_path)
print("Bones: %d" % skel.bones.size())
print("Slots: %d" % skel.slots.size())
print("Attachments: %d" % skel.default_skin.size())
```

### 7.2 常见错误

| 错误 | 原因 | 修复 |
|------|------|------|
| `Could not resolve class "HeroConfig"` | 脚本未保存或路径错误 | 检查脚本路径，确保文件名与 class_name 一致 |
| `Assertion error: index out of bounds` | 数组越界 | 添加边界检查：`if idx < array.size(): ...` |
| 技能按钮不显示 | 英雄没有分配技能 | 检查 HeroConfig 中的 `skills` 字段 |
| 头像不显示 | 文件路径或名称错误 | 确保文件存在，文件名为小写 `{hero_id}_guild_header.png` |
| 怪物不显示 | 未在 `MONSTER_ANIM_CONFIG` 登记，或未出现在 `CURRENT_ENCOUNTER` | 在 `MONSTER_ANIM_CONFIG` 中添加 `{base, dir, map}` 一条（`_setup_battle()` 的渲染白名单与 `_load_monster_anim()` 都读这张表） |
| 怪物贴图不显示（`No loader found for resource: ...png`） | 新增资源的 PNG 尚未被 Godot 导入（缺 `.import` 元数据） | 打开一次编辑器，或执行 `godot --headless --path <项目> --import` |
| 消耗品按钮左/右键都点不到 | 槽位挂载在过小的 `PanelInventory` 下，背景贴图画在父控件矩形外，`has_point` 命中失败 | 改挂到全屏 `battle_ui`，按 `panel_inventory_bg.get_global_rect()` 定位 |
| `Invalid assignment of index '5'`（地图生成） | `_empty_neighbors()` 未判边界，把地图外格子当空格子 | 在 `DungeonMap._empty_neighbors()` 中显式校验 `nr`/`nc` 边界 |
| 打掉尸体后"补位错乱"、末位卡槽还留着旧血条 | `_update_list_ui()` 只遍历到 `units.size()`，尾部槽位没被清理 | 遍历**全部** `hero_slots`/`monster_slots`，先 `_clear_children()` 再按长度填内容（见 §6.11.2） |
| `Invalid access of index 'N' on ... 'Array[Dictionary]'` | 单位移除（阵亡/清尸体）后 `current_actor["index"]` 短暂失效，而 UI 函数直接 `heroes[...]` | 在 `_update_character_portrait()` / `_update_skill_buttons()` 加下标范围卫语句（同 `_update_selected_text()`） |
| 怪物尸体笔直站着，与活体看不出区别 | 该骨架没有独立 dead 动画（`map["dead"] == map["combat"]`），播 dead 实际播的是 combat | `_load_monster_anim()` 自动改用普通小怪残骸（`CORPSE_REMAINS_DEFAULT`，见 §6.11.1）；也可用条目里的 `"corpse"` 字段单独指定 |
| 英雄状态图标/死门提示被下方面板遮住 | 卡槽内容行累计高度超过 y≈278（`BottomPanelsContainer` 顶边） | 数值内嵌血条/压力条 + 提示行改挂顶部悬浮区 `TOP_OVERLAY_HEIGHT`（见 §6.11.3） |

### 7.3 性能优化

#### 缓存 Spine 数据

```gdscript
# 避免重复解析相同的 .skel 文件
var _skel_cache: Dictionary = {}

func load_character(skel_path: String, atlas_path: String, png_dir: String) -> void:
	if not _skel_cache.has(skel_path):
		var skel = SpineSkel.new()
		skel.parse(skel_path)
		_skel_cache[skel_path] = skel
	else:
		var skel = _skel_cache[skel_path]
```

#### 减少动画重新加载

```gdscript
# 检查当前动画是否与目标相同
if _spine_current_state.get(hero_idx, "") == state:
	return  # 跳过重新加载
```

#### 批量更新 UI

```gdscript
# 在单一函数中更新所有 UI，避免多次重绘
func _update_ui() -> void:
	_update_crusader_animations()
	_update_monster_animations()
	_update_list_ui()
	_update_selected_text()
	_update_character_portrait()
	_update_skill_buttons()
```

---

## 8. 大模型激励喊话系统

由于集成了让领主（玩家）通过输入任意自定义文本去安抚或激发处于疯狂恐惧中的英雄，我们提供了极具生存代入感的大语言模型喊话回复模组。

### 8.1 核心调用流程

1. **性格注册**：
   在 `HeroConfig.gd` 内为每个英雄分配并初始化了 `personality` 模组（Crusader 的守护与狂热忠诚、Highwayman 的游侠冷酷及愤世嫉俗）。
2. **激活激励 UI**：
   当轮到某位英雄行动时，玩家可以点击其个人立绘顶部的“神圣激励”图标，打开一个位于主前台视图的 Canvas Layer 遮罩。
3. **大模型请求**：
   玩家输入激励的台词后，点击“神圣激励”发送。后台开始创建对 `LLMClient.gd` 的并发任务。
4. **效果反馈与应答显示**：
   大模型回复或本地 Mock 降级短语将自上而下通过淡入气泡弹出。同时，该英雄身上会爆发出璀璨夺目的专属 `"battle_cry"` 法术闪光动态粒子束。**激励的结果并非固定，而是由英雄对这句话的真实反应决定（共四种，见 8.4）**，并会改变精神压力值（Stress Bar）。
5. **占用行动点**：激励喊话**消耗该英雄本回合的行动点**，结算完毕后立即推进到下一个行动者。因此「喊话」是一次与其他技能互斥的完整行动。

### 8.2 多层级 CanvasLayers 遮挡优化

由于本作为自定义 Spine 运行时开发，Spine 人物是以多个动态多边形实体（Sprite2D、Polygon2D）形式直接渲染在主场景 2D 画布中的。这些骨骼实体极易在一些具有动画更新的帧下穿透或盖在普通的控制和文本输入组件上层，造成输入栏被手臂或怪物尾巴遮盖的恶性 UI Bug。

**金标准解决方案（层级前置架构）**：
- **`BattleController._parent_ui_layer` (CanvasLayer, layer=100)**：专门用于放置玩家输入弹窗（包含文本框、发送按钮、取消按钮）。通过高优先级的 CanvasLayer 将其直接渲染在引擎的高级重画栈，彻底跟 Spine 节点视口隔离开。
- **`BattleController._bubble_layer` (CanvasLayer, layer=101)**：专门承载并渲染大模型的回复对话框气泡。它比输入框还要更高一层，能杜绝在输入框关闭瞬间的最后一像素渲染闪烁，从而保证了完美的观感体验。
- **`END_LAYER` (CanvasLayer, layer=105)**：战斗结算卡片（见 4.6）。
- **`LOOT_LAYER` (CanvasLayer, layer=110)**：战后战利品结算。
- **`_floating_text_layer` (CanvasLayer, layer=50)**：浮字伤害 / 压力图标。

> 顺序：浮字(50) < 战斗 UI/自建层(100/101) < 结算卡片(105) < 战利品(110)。胜利时 105 与 110 **同时在屏**（左战绩 / 右战利品），所以卡片宽度必须控制在 660 以内。

### 8.3 画面缩放及布局提升

为了防止新增的“神圣激励”表单和英雄面板把底部的普通战斗选项按钮占领，我们将所有英雄与怪物的世界坐标槽位整体**向上高位平移了 140 像素**：
* 边界扩展：槽位统一扩大到 `110x220` 宽高限额，以容纳大型动画剪影。
* 状态可视化：在每个人物正上方挂载了高对比度的 HP 进度条，以及代表疯狂指标、以深紫原色填充的压力进度条（Stress Bar），让战场形势和神圣激励前后的效果对比极其清晰直观。

### 8.4 四种激励结果与行动点占用

英雄对领主喊话的反应被建模为**四种互斥行为**，由 `LLMClient.Outcome` 枚举定义，模型只需在台词开头输出对应标签即可：

| 标签 | Outcome | 结算效果 | 光环图标 |
|------|---------|----------|----------|
| `[RELIEVE]` | `RELIEVE` | ① 减压：压力 `-35`（`INSPIRE_STRESS_RELIEVE`） | heroic |
| `[BUFF]` | `BUFF` | ② 增益：附加 `StatusConfig.inspired`（战意高涨）——攻击力 `+20%`，持续 `INSPIRE_BUFF_ROUNDS = 3` 回合 | heroic |
| `[STRESS]` | `STRESS` | ③ 加压：压力 `+20`（`INSPIRE_STRESS_STRESS`） | affliction |
| `[BETRAY]` | `BETRAY` | ④ 攻击队友：随机选中一名存活队友，造成 `攻击力 × 0.5`（`INSPIRE_BETRAY_DAMAGE_RATIO`）伤害 | affliction |

**② 增益（`[BUFF]`）的实现**：`ActionResolver.apply_status(hero, INSPIRE_BUFF_STATUS, 1, INSPIRE_BUFF_ROUNDS)` 为英雄附加 `inspired`（战意高涨，`attack_mult = 1.2`，3 回合）；面板状态行的百分比由 `StatusConfig.inspired.attack_mult` 反算得到，不硬编码。

> ⚠️ 文案里的 `%%` 必须写成双百分号：`status_text` 在末尾还会统一做一次 `status_text % status_args`，直接写单个 `%` 会被当成格式符。

**判定尺度（写入 System Prompt，引导模型分布）**：
- 真诚的鼓舞 / 信任 / 感谢 / 承诺 → 倾向 `[RELIEVE]` / `[BUFF]`；
- 明显的质疑、不耐烦、轻蔑、冷嘲 → 倾向 `[STRESS]`；
- **明确贬低 / 羞辱 / 辱骂 / 诅咒 / 威胁抛弃**（骂他废物无能、叫他闭嘴、说后悔带他出来）→ 必须偏向 `[STRESS]`，措辞极其恶劣且精神脆弱时可直接 `[BETRAY]`；
- 仅当原话本身不刺人时，才按战况判定：压力 > 70 倾向 `[STRESS]`，压力 > 100 或血量 < 20% 才可能 `[BETRAY]`。
- **领主的原话是首要依据，战场形势是次要依据**（2026-09 调整）。

**本地语气分析**（`evaluate_input_tone()` / `input_tone_label()`，评分 `[-4, +4]`，同时作为“语气预判”写进 Prompt）：

| 档位 | 分值 | 例词（每档只取首个命中，避免“蠢货”同时命中“蠢”与“蠢货”而重复扣分） |
|------|------|------|
| `TONE_INSULT_HEAVY` | `-3` | 废物 / 蠢 / 傻 / 没用 / 无能 / 懦弱 / 胆小鬼 / 不如狗 / 拖后腿 / 丢人 / 滚 / 闭嘴 / 畜生 |
| `TONE_NEGATIVE` | `-1` | 必须 / 少废话 / 赶紧 / 你敢 / 军法 / 丢下你 / 失望 / 活该 |
| `TONE_PRAISE_HEAVY` | `+3` | 相信你 / 依靠你 / 佩服 / 英雄 / 了不起 / 谢谢你 / 以你为荣 / 顶梁柱 |
| `TONE_POSITIVE` | `+1` | 勇敢 / 坚持 / 挺住 / 圣光 / 信仰 / 感激 / 守护 / 必胜 |

**本地 Mock 权重**（无 API Key / 请求超时 / 解析失败时降级，`_generate_mock_result(is_crusader, hp, stress, player_input)`）：
基权重随 `stress/200` 与血量变化，再用**语气评分**修正（负面：(1+严重度×2) 抬高压加、`w_betray += max(严重度-0.5,0)×0.5`；正面：抬高压减/增益、压低加压）。实测（hp45 / stress0）：

| 领主原话 | 语气 | 减压 | 增益 | 加压 | 倒戈 |
|------|------|------|------|------|------|
| 中性陈述（基准） | `0` | 55.7% | 23.8% | 20.5% | 0% |
| “你这废物，真是个没用的懦夫，给我闭嘴赶紧上，否则我丢了你自己走。” | `-4` | 6.0% | 4.0% | **66.0%** | **24.0%** |
| “我一直相信你，你是我们最勇敢的英雄，拜托你了，辛苦了。” | `+4` | **75.0%** | 21.0% | 4.0% | 0% |

> 中性输入时旧的压力 / 血量权重依然生效（例：高压 stress=190 → 加压 66.2%、倒戈 17.8%；瀕死 hp=8 → 倒戈 12.8%）。
> 模型未打标签时：`_keyword_outcome()` 先按台词判定，**若领主原话明显贬低（语气 ≤ -2）且台词无明确姿态，则不会给出减压、至少按加压处理**。

**回应窗口（2026-09 调整）**：结算完成后弹出 `ReplyModal`（金边面板：标题 + 英雄台词 + 结算文案 + **「确定」按钮**），`_execute_llm_inspiration()` 会 `await reply_confirmed` 挂起，**由玩家点击确定后才收起窗口、扣除该英雄本回合行动点并推进回合**（不再 2.5s 自动散去）；聆听阶段按钮隐藏，防止在模型返回前跳过。信号与 `_reply_confirm_clicked` 标记共同防止“await 注册前的点击”被漏掉。

**解析与兜底**：`_parse_outcome_reply()` 解析标签；若模型未输出标签，则由 `_keyword_outcome()` 按关键词判定——**倒戈必须出现明确暴力/背叛措辞才成立**，宁可漏判也不误伤队友；其余默认归入 `RELIEVE`。

**攻击队友的实现要点**（`_execute_inspire_betrayal()`）：
1. 候选池为「除自己以外、存活或濒死」的队友，随机取一名。
2. 伤害走 `ActionResolver.apply_damage()`，并用 `_emit_feedback()` 弹出红色伤害浮字；命中特效由 `_play_attack_hit_fx()` 取施动者第一个带 `target_fx` 的技能特效播放。
3. 随后调用 `_handle_hero_damage_aftermath()` 处理濒死/死亡骰——**队友可能因此阵亡并从 `heroes` 中移除**。
4. 因为没有可攻击的队友（例如只剩自己），则退化为单纯加压，避免出现“无人可打”的空转。

**行动点占用的两个时序陷阱（均已规避）**：
- **索引失效**：队友阵亡补位会改变 `heroes` 下标。收尾时不能沿用旧的 `hero_idx`，必须 `heroes.find(hero)` 按引用重新定位，并同步刷新 `current_actor["index"]`。
- **队列重建时序**：`_kill_hero()` 内部会 `turn_queue.build()`，而此时施动者的 `actions_remaining` 仍为 1，会被重新入队 → 同回合重复行动。因此在扣除行动点**之后**再 `turn_queue.build()` 一次，并配合 `max(0, ...)` 夹逼，确保该角色本回合绝不重复出手。

---

## 9. 快速参考

### 添加新角色的最小步骤

```
1. 创建目录：characters/new_hero/anim/
2. 导出 Spine 动画到该目录
3. 在 HeroConfig.gd 中添加英雄模板（含 personality 字段）
4. 在 SkillConfig.gd 中添加技能
5. 在 BattleController.gd 中添加动画映射
6. 测试
```

### 添加新怪物的最小步骤

```
1. 创建目录：monsters/new_monster/anim/
2. 导出 Spine 动画到该目录（并确认 PNG 已被 Godot 导入）
3. 在 MonsterConfig.gd 中添加怪物模板（可选 inert / life_link）
4. 在 BattleController.gd 的 MONSTER_ANIM_CONFIG 中登记一条（base / dir / map）
5. 修改 CURRENT_ENCOUNTER 或 DungeonMap.BOSS_ENCOUNTER 以包含该怪物
6. 测试
```

### 关键文件位置

| 需求 | 文件 |
|------|------|
| 添加英雄 | `data/HeroConfig.gd` + `battle/BattleController.gd` |
| 添加技能 | `data/SkillConfig.gd` |
| 添加怪物 | `data/MonsterConfig.gd` + `battle/BattleController.gd` |
| 修改动画 | 导出到 `characters/` 或 `monsters/` 下的 `anim/` 目录 |
| 修改 UI | `battle/BattleController.gd` 中的 `_make_hero_slot()` / `_make_monster_slot()` |
| 地图尺寸 | `map/DungeonMap.gd` 中 `MAP_SIZE` / `set_size()` |
| 地图扩散倾向 | `map/DungeonMap.gd` 中 `BRANCHINESS` / `set_branchiness()` |
| 地图渲染 | `map/MapController.gd` |

---

## 10. 地图系统

### 10.1 概览

- **`scripts/map/DungeonMap.gd`**（`class_name DungeonMap`，静态单例）：地图尺寸配置、随机生成、房间/走廊/遭遇数据。
- **`scripts/map/MapController.gd`** + **`scenes/map/Map.tscn`**：地图渲染与房间点击交互。

### 10.2 尺寸与生成参数

| 尺寸 | `MAP_SIZE` | 网格 | 房间数 |
|------|-----------|------|--------|
| 小 | `"small"` | 5×5 | 10 |
| 中 | `"medium"` | 7×7 | 15 |
| 大 | `"large"` | 9×9 | 20 |

- 扩散倾向 `BRANCHINESS`（0~1）：`0`=一条路径（线性），`1`=四通八达（分支），默认 `0.5`。
- 通过 `DungeonMap.set_size()` / `DungeonMap.set_branchiness()` 在进入地图前设置。

### 10.3 生成规则

1. 全图随机选一个格子作为起点。
2. 从已有房间向四周扩散，直到达到目标房间数（线性/分支由 `BRANCHINESS` 决定）。
3. BFS 计算各房间到起点的行走步数，选最远的房间作为 Boss 房。

> **边界防护**：`_empty_neighbors()` 必须显式校验邻居行列是否在 `MAP_GRID` 范围内。`_cell_kind()` 对「空格」和「地图外」都返回 `""`，若先不判边界，会把地图外格子（如小地图第 5 行/列）当成可用空格写入候选，导致 `_set_cell()` 报 `Invalid assignment of index '5'`。

### 10.4 自定义地图

- **改尺寸**：在 `DungeonMap._grid_side()` / `_target_room_count()` 中增减档位，并在 `StartController.MAP_SIZES` 中加一条（开始界面会自动多出一个按钮）。
- **改倾向默认值**：修改 `DungeonMap.BRANCHINESS` 初值。
- **改遭遇**：编辑 `DungeonMap.ENCOUNTER_POOL`（普通房）与 `BOSS_ENCOUNTER`（Boss 房）。

### 10.5 显示：当前房间永远处于视野中心

地图内容与显示彻底分离：

```
MapUI(全屏 Control)
└── MapViewport(Control, position.y=VIEW_TOP, size=(窗口宽, 492), clip_contents=true)
    ├── ViewportBg(固定背景方块)
    └── MapRoot(Node2D)          ← 只改它的 position 来平移整张地图
        ├── 走廊 Line2D×N（地图坐标）
        └── RoomLayer(Control) → 房间按钮（地图坐标）
```

- `_room_center()` 返回**地图坐标**（`col*STEP_X` / `row*STEP_Y`，不再叠加居中偏移）；
- `_center_on_current_room(animate)` 把整张地图平移 `视口中心 - 当前房间中心`，当前房间永远落在视口正中；
  换房（`_refresh_rooms()` 末尾）与窗口尺寸变化（`size_changed` 信号）时都会重新居中，换房用 `TRANS_SINE` 补间（`CENTER_TWEEN_TIME = 0.28s`）滑动过去。
- 尺寸不再“缩到刚好装下整张图”，而是固定 `ROOM_SIZE=76` / `STEP_X=150` / `STEP_Y=126`：
  小图（5×5，676×580）基本一屏可见，中/大图（最大约 1276×1084）纵向明显超出视口，靠平移查看——超出部分由 `clip_contents` 裁掉。
- 视野外的房间按钮本就 `disabled`；而**相邻房间必然紧贴当前房间**，所以永远落在视口内、不会点不到。

> 验证：`godot --headless --path <项目> --script res://tools/_probe_map_center.gd`（12 条断言：视口裁剪/尺寸跟随窗口/不与标题提示重叠/MapRoot 存在/开局与换房后当前房间偏差 ≤1.5px/大地图内容超出视口）。
> 肉眼复核：`godot --path <项目> --script res://tools/_shot_map.gd` → `res://shot_map_a.png`（开局）、`res://shot_map_b.png`（移到最远房间后）。

---

## 11. BOSS 战：门前恶狼（Brigand 火器小队）

### 11.1 编队与站位

`DungeonMap.BOSS_ENCOUNTER` 决定 Boss 房遭遇，**数组下标即怪物站位（下标 0 = 1 号位）**：

| 站位 | 怪物 id | 名称 | HP | 攻击 | 速度 | 角色 |
|------|---------|------|----|------|------|------|
| 1 | `brigand_sapper` | Brigand Vvulf | 80 | 7 | 5 | 首领：投弹 / 召回弹药桶 / 炮击前排 |
| 2 | `brigand_barrel` | Brigand Barrel | 50 | — | — | 弹药桶：**惰性**，永不行动 |
| 3 | `brigand_fuseman` | Brigand Fuseman | 16 | 4 | 3 | 点火员：为大炮装填引信 |
| 4 | `brigand_cannon` | Brigand Cannon | 60 | 6 | 2 | 大炮：装填后全体轰击 |

设计取自暗黑地牢原版的「门前恶狼」（Vvulf）+「迫击炮」（Brigand Pounder）两套机制。

### 11.2 四条联动规则

1. **弹药桶在场 → 首领投弹标记**（`sapper_throw`）
   `effect_type: "apply_status"`，不给伤害，只给英雄挂 `bomb_mark`。
   投弹时 `_register_pending_bomb()` 登记一枚 `{"hero_slot", "due_round"}` 到 `_pending_bombs`。
2. **引爆在下个回合开始时结算，不占用任何人的行动次数**
   `_start_new_round()` → `_resolve_pending_bombs()`：到期则播放 `brigand_sapper.sprite.detonate_target` 特效并造成 `StatusConfig.bomb_mark.detonate_damage`（14~20）伤害。属于 **debuff 结算行为**，不进行动队列、不占 `actions_remaining`。
   > 时序要点：`bomb_mark` 在 `StatusConfig` 里带 **`manual_duration: true`**，`ActionResolver.tick_statuses()` 会**跳过它的 duration 递减**，防止标记在炸药落地前自行消失。新增“由战斗逻辑掌握寿命”的状态时一律加这个字段。
3. **弹药桶不存在 → 首领召回弹药桶或炮击前排**
   `sapper_summon`（`effect_type: "summon"`, `requires_absent_ally: ["brigand_barrel"]`）与 `sapper_barrage`（`requires_absent_ally` 同上，AoE 只命中 `target_positions: [1, 2]`）二选一，由 AI 在候选技能中随机决定。
4. **大炮 ↔ 点火员**
   - `fuseman_light_fuse`：`single_ally` + `target_ally_id: "brigand_cannon"` + `target_ally_status_absent: "cannon_loaded"` + `skill_priority: 1` → 只给**尚未装填**的大炮挂 `cannon_loaded`，且只要大炮还需装填就**一定会点火**（备选攻击 `fuseman_hot_shot` 优先级低，仅兜底）。
   - `cannon_fire`：`requires_self_status: "cannon_loaded"` + `consume_self_status: "cannon_loaded"` → 装填好的大炮行动时对全体英雄造成高额 AoE（+压力），开火后自动卸弹（因此每装填一次只开一炮）。
   - `cannon_summon`：`requires_absent_ally: ["brigand_fuseman"]` → 点火员不在场时召回一名新点火员；`cannon_blast` 则要求点火员在场且自身未装填，保证三招互斥、任何局面都有明确行为。

### 11.3 反制手段（给玩家的可玩性）

| 玩家行为 | 结果 |
|----------|------|
| 摧毁弹药桶 | `_handle_monster_damage_aftermath()` 检测到 `brigand_barrel` 阵亡 → `_disarm_pending_bombs()`：清空所有 `bomb_mark` 与待引爆炸药（即使之后首领再召回弹药桶，本轮的炸药也已作废） |
| 引爆时场上无弹药桶 | 同样的双击保险：`_resolve_pending_bombs()` 自带 `_has_alive_monster("brigand_barrel")` 校验，无桶则转为哑弹（Toast 提示） |
| 杀死点火员 | 大炮当回合改去召回新点火员，本回合无法开火 |
| 杀死大炮 | **生命链接**：点火员随之倒下（`life_link: "brigand_cannon"`） |
| 杀死首领 | **生命链接**：弹药桶随之损毁（`life_link: "brigand_sapper"`），投弹彻底停摆 |

### 11.4 战斗内召唤（`_summon_monster()`）

- **尸体让位**：优先占用 `is_corpse` 的槽位（直接 `monsters[slot] = 新单位`，**不改变其它单位的索引**），无尸体时追加到队尾；槽位满（≥4）则放弃召唤。这样能避免超出 UI 的 4 个怪物槽。
- 该槽位的 `SpinePlayer` 原本在播尸体姿态，需要 `queue_free()` 后按 `MONSTER_ANIM_CONFIG` 重建。
- 新单位 `actions_remaining = 0`，**登场当回合不行动**，下回合 `_start_new_round()` 起正常入队。
- 调用点：`_execute_monster_action()` 结算完技能后统一走 `_apply_monster_skill_post_effects()`（先消耗自身状态，再召唤）。

### 11.5 验证方式

```powershell
# ① 机制断言（106 条：数据接线 + 投弹引爆 + 弹药桶解除 + 装填开火 + 召唤 + 生命链接）
godot --headless --path <项目> --script res://tools/_probe_boss_battle.gd
# ② 真实行动管线（不冻结循环，逐只怪物跑 _execute_monster_action：技能筛选→聚焦→特效→结算→召唤）
godot --headless --path <项目> --script res://tools/_probe_boss_live.gd
```

> 探针 ① 会冻结战斗循环（`battle_over = true`）后逐条断言，输出 `PASS=106 FAIL=0` 即全部通过；
> 探针 ② 输出 `PASS=11 FAIL=0`，并在日志中打印 `[Bomb]` / `[Summon]` / `[FX]` 关键行。
> 注意：Godot 是 GUI 子系统程序，PowerShell 下需用管道（`| Tee-Object ... | Select-String`）才能取到输出。

---

## 12. 背景音乐（BGM）与音频提取

### 12.1 audio/ 里是什么

`audio/` 是原版《暗黑地牢》的 **FMOD Studio 音效库**（`.bank`），不是普通音频文件，**Godot 无法直接播放**：

| bank | 编码 | 内容 |
|------|------|------|
| `secondary_banks/music.bank` | **FADPCM (0x10)** | 全部音乐，64 首（`mus_theme_*` / `Explore_Vaults_*` / `Combat_Level1_*` / `mus_combat_*` …） |
| `secondary_banks/ambience.bank` | FADPCM | 环境音循环 |
| `secondary_banks/voiceover*.bank` | FADPCM | 旁白语音 |
| `secondary_banks/en_*.bank` / `hero_*.bank` / `props_*.bank` / `ui_*.bank` / `town.bank` / `title_screen.bank` / `general.bank` | **VORBIS (0x0F)** | 怪物 / 英雄音效与语音、UI 音效、道具音效 |

> bank 是 RIFF 容器，音频以 `SND ` 块内的 **FSB5** 子库存储；FSB5 头部的 `mode` 字段就是 codec id（0x0F=VORBIS、0x10=FADPCM）。

### 12.2 提取工具 `tools/extract_fmod_bank.py`

```powershell
# 列出 bank 内曲目（名称 / 时长 / 声道 / 大小 / 循环点）
python tools/extract_fmod_bank.py --list audio/secondary_banks/music.bank
# 按名称（子串）提取为 ogg
python tools/extract_fmod_bank.py --bank audio/secondary_banks/music.bank --out audio/bgm --track mus_theme --track Combat_Level1
```

- **FADPCM 解码是纯 Python 实现**（移植自 vgmstream `src/coding/fadpcm_decoder.c`）：每声道每帧 0x8C 字节 → 256 采样；帧头 12 字节 = coefs(u32) + shifts(u32) + hist1/hist2(s16)；帧体 8 组 ×4 dword ×8 nibble；系数表 `[(0,0),(60,0),(122,60),(115,52),(98,55),(0,0),(0,0)]`，`shift = 22 - (shifts>>i*4 & 0xF)`。
- 声道数据按 **0x8C 块交错**（块 b 的声道 c 位于 `(b*channels+c)*0x8C`）。
- 输出：FADPCM → libsndfile 编码 OGG/Vorbis：**必须分块写**（每秒一块），一次性写大数组会让 libsndfile 崩溃（`STATUS_STACK_OVERFLOW`）。
- **VORBIS bank（音效）**：FSB5 把 setup 头（codebook）**外置**，每个采样只用 `setup_id`（CRC32）引用；vgmstream 内置了从 FMOD 抽出的 codebook 表，先下载一份：

  ```powershell
  Invoke-WebRequest https://raw.githubusercontent.com/vgmstream/vgmstream/master/src/coding/libs/vorbis_codebooks_fsb.h -OutFile tools/_vgmstream/vorbis_codebooks_fsb.h
  ```

  `--codebooks` 默认就指向该路径。重封装做的事：按 `setup_id` 取回 setup 包 → 用 FSB5 的声道/采样率**重建识别头**（blocksize 字节 `0xB8` = 小 256 / 大 2048）→ 造一个最简注释头 → 音频包按**16 位小端长度前缀**拆出 → 按 Ogg 分页写出（**不重新编码**，只换容器）。

### 12.3 角色 / 怪物技能音效（已提取 85 个）

| 目录 | 内容 | 数量 |
|------|------|------|
| `audio/sfx/` | 英雄技能 `char_al_*`（含 `_miss` 挥空版）、通用命中层 `char_share_imp_*`、重击甜化层 | 54 个 / 3.7MB |
| `audio/sfx/enemy/` | 怪物技能 `char_en_skl*`（骸骨系）/ `char_en_brig*`（强盗系） | 31 个 / 1.7MB |

**四个英雄 16 个技能 → 音效**（`​char_al_<英雄>_<技能>`，`cry_` 是原素材里的拼写，非错字）：

| 英雄 | 技能 → 音效 |
|------|-------------|
| crusader | slash→`cru_smite`；heal→`cru_battleheal`；holy spear→`cry_holylance`；battle_cry→`cru_inspiringcry` |
| highwayman | cut→`hwy_wickedslice`；pistol_shot→`hwy_pistolshot`；Close-range shooting→`hwy_pointblank`；shotgun→`hwy_grapeshot` |
| occultist | 命运重构→`occ_wyrdrecon`；祭祀切割→`occ_bloodlet`；深渊之手→`occ_daemons`；灵魂之触→`occ_abyssalart` |
| houndmaster | 释放猎犬→`hnd_hounds_rush`；标记弱点→`hnd_whistle`；振奋犬吠→`hnd_howl`；守护队友→`hnd_guard_dog` |

**怪物技能**：`sklar`(弩手) `sklco`(酒杯) `sklcom`(士兵) `sklde`(盾卫) `sklmi`(剑士) `sklsp`(枪兵) `sklcap`(骸骨队长) / `brigcut`(刀手) `brigfus`(点火员) `brigblood`。

> 校验：`godot --headless --path <项目> --script res://tools/_probe_sfx.gd` → `PASS=4 FAIL=0`（文件均可加载、时长合理）。

### 12.4 播放：Autoload `Bgm`

`scripts/core/BgmManager.gd` 注册为 Autoload（`project.godot` → `[autoload] Bgm="*res://scripts/core/BgmManager.gd"`），提供 `Bgm.play("title"|"map"|"battle")` / `Bgm.stop()`：

- 双播放器交叉淡入淡出（0.8s）；cue 可配「前奏 + 循环段」，前奏播完由 `finished` 回调接循环；
- `AudioStreamOggVorbis.loop` 在运行时设置（导入默认不循环）；
- 挂 Autoload 保证 `change_scene_to_file` 换场景时音乐不断。

> 验证：`godot --headless --path <项目> --script res://tools/_probe_bgm.gd` → `PASS=42 FAIL=0`。

### 12.5 播放：Autoload `Sfx`（战斗音效接线）

`scripts/core/SfxManager.gd` 注册为 Autoload（`[autoload] Sfx="*res://scripts/core/SfxManager.gd"`），核心是一张 **技能 id → 音效文件** 的表 + **12 个 AudioStreamPlayer 的轮转池**（同帧叠多个音不会互相打断；池满覆盖最旧的一个，好过排队延迟）。

```gdscript
Sfx.play_skill_cast(skill_id, hero_id)  # 施法音：先查英雄表（hero_id 两层索引），再查怪物表
Sfx.play_impact("sword")               # 通用命中层（sword/axe/hammer/knife/shield/gun/arrow/magic_light/magic_dark/heavy）
Sfx.play_skill_impact(skill_id)         # 按技能查命中层；治疗/增益类无条目 → 默认静音
Sfx.play_skill_miss(skill_id)           # 挥空音（技能 id 全项目唯一，不需再定位英雄）
Sfx.play("char_al_hnd_howl", - 9.0)   # 按文件名直接播（"enemy/" 前缀表示去 audio/sfx/enemy/）
```

**接线方式（集中在 2 个函数，不散落在各个战斗分支）：**

| 挂点 | 作用 |
|------|------|
| `BattleController._play_skill_fx_v2()` 开头 | 播**施法音**，并记下 `_pending_impact_skill`。放在 `SKILL_FX_MAP` 校验**之前** —— 没配 Spine 特效的技能也得有声音 |
| `BattleController._emit_feedback()` 开头 | 用快照差值判断：有目标真掉血 → 叠**命中层**（AoE 只响一次，命中数越多音量略高）；一点血没掉 → **挥空音**；结束后清空 `_pending_impact_skill` 避免污染下一招 |
| `_execute_inspire_betrayal()` | 倒戈一击额外叠一句刀剑命中音 |
| `_detonate_bomb()` | 炸药引爆 = 重击甜化层 + 火器音 |

**两个设计要点：**

1. `_play_skill_fx_v2` 与 `_emit_feedback` 是**同步**调用且一一配对，所以用一个成员变量传「本次出招」是安全的，不需要给 `_emit_feedback` 加参数（它被 8 处调用，加参数要改的地方太多）。
2. 治疗/增益类靠 `SKILL_IMPACT` **没有条目** 来自然静音 —— 不用在每个疗伤分支写 `if`。

**运行时随机化**：每次播放 ±4% 音高、±1.5dB 音量，重复出招不会听起来像复读机。

> 验证：`godot --headless --path <项目> --script res://tools/_probe_sfx_battle.gd` → `PASS=50 FAIL=0`（表↔文件一致性、`SKILL_FX_MAP` 37 个技能全覆盖、战斗内真播到正确文件、掉血/零伤害分流、治疗不误响、池不扩容）。
> 探针坑：`_emit_feedback` 的形参是 `Array[Dictionary]` 强类型数组，用 `call()` 传 `[x]` 会报 “does not have the same element type” → 必须先装箱成 `Array[Dictionary]`。

---

**版本**：1.14
**最后更新**：2026-09-29

**v1.14 更新内容**：
- 新增 4.6：**战斗结算界面**（胜利 / 远征终结 / 战败）—— 全屏暗幕 + 上下黑边 + 660×430 卡片（装饰条底衬标题 / 徽记 / 4 行战绩 / 主按钮）+ 入场动画 + 结算音效
- ⚠️ 两个坑：① SpinePlayer 的 `z_index = 10` 会盖住 `BattleUI`，结算面板必须搬进独立 `CanvasLayer(105)`；② 刷战绩行前必须 `remove_child()` 再 `queue_free()`，否则旧行会在当帧重复绘制
- 8.2 补全层级表（浮字 50 / 输入 100 / 气泡 101 / 结算 105 / 战利品 110）
- 新探针 `tools/_probe_end_battle.gd`（`PASS=80 FAIL=0`）；15 个探针全量回归通过（580 条断言）

**v1.13 更新内容**：
- 新增 12.5：Autoload `Sfx`（`scripts/core/SfxManager.gd`）—— 技能 id → 音效表 + 12 个播放器轮转池；战斗挂点只有两处（`_play_skill_fx_v2` 播施法音、`_emit_feedback` 按真实掉血分流命中层/挥空音）
- 12.3 扩充为 85 个音效（新增通用命中层 10 个 + 怪物技能 31 个）；修正小节编号顺序（12.3/12.4/12.5）
- 新探针 `tools/_probe_sfx_battle.gd`（`PASS=50 FAIL=0`）；14 个探针全量回归通过

**v1.12 更新内容**：
- 提取工具支持 **FSB5-Vorbis**（音效库）：`setup_id` → vgmstream codebook 表补全 setup 头 + 重建识别/注释头 + 16 位小端包长拆分 → **Ogg 重封装**（不重新编码）；新增 `tools/_vgmstream/vorbis_codebooks_fsb.h`（3.1MB）
- 新增 12.4：四个英雄 16 个技能 → `audio/sfx/` 44 个音效的对应表；探针 `tools/_probe_sfx.gd`（`PASS=4 FAIL=0`）

**v1.11 更新内容**：
- 新增「背景音乐（BGM）与音频提取」章节（12）：`audio/` 是原版 FMOD Studio bank（`music.bank` 为 **FADPCM**，Godot 不能直读）→ `tools/extract_fmod_bank.py` 解码并导出 ogg → Autoload `Bgm` 播放
- ⚠️ 两个坑：① libsndfile 的 Vorbis 编码器一次性写大数组会 StackOverflow，**必须分块写**；② `AudioStreamOggVorbis.loop` 需运行时设置，`load()` 直读时是导入默认值

**v1.10 更新内容**：
- 激励回应窗口：`reply_confirmed` 信号 + 「确定」按钮，玩家点击后才收起并推进回合（不再 2.5s 自动散去；聆听阶段按钮隐藏）
- 激励结果更看重玩家原话：`evaluate_input_tone()` 词表四档语气分析（`[-4,+4]`）→ 修正 Mock 权重 + 写入 Prompt；无标签兜底在明显贬低时不再给减压（8.4）
- 新增探针 `tools/_probe_inspire_reply.gd`（`PASS=23 FAIL=0`），截图 `tools/_shot_inspire_reply.gd`

**v1.9 更新内容**：
- 重做开始界面：`fe_flow` 素材（闪屏 `demo_splash` + 原版主菜单：辉光底板/宅邸剪影/流云/描金按钮），版式沿用 `fe_flow.layout.darkest` 的原始坐标（页面内 y = 布局 y − 1080）
- 移除编队选择（删除 `TeamSelect.tscn` / `TeamSelectController.gd`），开局固定编队写死在 `StartController.FIXED_TEAM`（2.2.5 / 2.3）
- ⚠️ 踩坑：**Godot 4 的 `TextureRect` 没有 `region_enabled` / `region_rect`**，取子图要用 `AtlasTexture`；对已删除的 png 要记得清掉残留 `.import`
- 新增探针 `tools/_probe_start_menu.gd`（`PASS=37 FAIL=0`）、截图 `tools/_shot_start.gd`

**v1.8 更新内容**：
- 伤害拆成**两个乘区**（6.8.1 / 6.10.5）：`attack_mult`（美德激励 / 战意高涨）**加算**，`damage_mult`（狗粮）**乘算**
- 新增 `ActionResolver.get_damage_multiplier()`；`get_attack_multiplier()` 从“取最大”改为“加算求和 + `snappedf` 抹平浮点误差”
- `StatusConfig.dogfood_buff` 由 `attack_mult` 改为 `damage_mult`；验证探针 `tools/_probe_buff_zones.gd`（`PASS=15 FAIL=0`）

**v1.7 更新内容**：
- 实装 AI 激励喊话的 ② `[BUFF]` 分支：新增 `StatusConfig.inspired`（战意高涨，`attack_mult = 1.2`）+ `INSPIRE_BUFF_STATUS` / `INSPIRE_BUFF_ROUNDS = 3`（8.4）
- ⚠️ 拼接提示文案时注意 `%%` 转义：`status_text` 末尾还会统一做一次 `% status_args`，直接写单个 `%` 会被当成格式符

**v1.6 更新内容**：
- 新增消耗品「狗粮」：`buff_status` / `buff_duration` 字段 + `StatusConfig.dogfood_buff`（`attack_mult = 1.2`），`_use_buff_consumable()` 走 `ActionResolver.apply_status()` 分支（4.5）
- 新增战后结算（战利品）步骤：`BATTLE_LOOT_TABLE` 掷取食物 1~4 / 绷带 0~1 / 狗粮 0~1，右侧 `LootLayer` 面板确认后入包，未确认前锁定返回按钮（4.5）
- `_end_battle()` 新增 `battle_over` 守卫，避免重复掷战利品

**v1.5 更新内容**：
- 新增「压力系统：折磨 / 美德」章节（6.10）：越阈（100）钳制与 75%/25% 掷骰、折磨受压力 +20%、每次行动 30% 概率失控（跳过 / 攻击队友 / 加队友压力 / 自动随机行动）、美德清空压力并给全体 +20% 攻击（5 回合）
- 新增配置文件 `scripts/data/StressConfig.gd`；状态系统补 `attack_mult` / `stress_taken_mult` 字段与三个内置状态
- `apply_stress()` 越阈改以【当前是否已处于折磨/美德】为准（删除了按战斗重置的 `stress_resolved`），且折磨/美德与压力一起跨战斗保留；压力归零解除折磨、200 清除美德并清零压力（折磨且濒死时直接处决）
- 6.2.3 补充越阈规则与"折磨压力条转暗红"的 UI 说明

**v1.4 更新内容**：
- 新增「死门（Death's Door / 濒死）机制」章节（6.9）：归零不死、濒死受伤害掷死亡骰、`took_damage` 参数区分伤害/治疗
- 死门死亡概率改为写在每个角色的配置条目里（`HeroConfig.HEROES[*].death_blow_chance`，默认 `DEFAULT_DEATH_BLOW_CHANCE = 0.5`），并修正「治疗也会给濒死队友掷死亡骰」的误杀缺陷
- 濒死英雄卡槽新增死门图标与概率提示（`tray_deathsdoor.png` / 死里逃生 `poptext_death_avoided.png`）

**v1.3 更新内容**：
- 新增「BOSS 战：门前恶狼」章节（11）：投弹标记引爆、弹药桶解除、大炮/点火员联动、战斗内召唤、生命链接
- 技能系统新增使用条件字段（`requires_*` / `consume_self_status` / `target_ally_*` / `summon_monster_id`）与 `apply_status` / `summon` 两种 `effect_type`（6.1.1）
- 怪物注册流程改为 `MONSTER_ANIM_CONFIG` 单表登记（3.2.4 / 9）
- Spine 常见问题新增 **IK `bendDirection` 必须按单字节有符号读**（`bend=-1` 写作 `FF`，按 varint 读会多吃 1 字节导致全局错位）

**v1.2 更新内容**：
- 新增「消耗品背包与悬浮提示」章节（4.5）：16 格背包渲染/左键使用 + 技能/消耗品 tooltip
- 补充 Spine `_update_pose` 骨骼索引越界防护说明
- 补充地图生成 `_empty_neighbors` 边界校验说明（10.3）
- 常见错误表新增消耗品命中失效、地图生成越界两条
