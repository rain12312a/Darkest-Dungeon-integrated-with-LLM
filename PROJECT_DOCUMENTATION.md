# Dark Dungeon 项目管理文档

## 目录

1. [项目概述](#1-项目概述)
2. [文件架构](#2-文件架构)
3. [游戏流程](#3-游戏流程)
4. [脚本函数详解](#4-脚本函数详解)
   - [4.1 core/GameState.gd](#41-coregamestate)
   - [4.2 core/Database.gd](#42-coredatabasegd)
   - [4.3 data/HeroConfig.gd](#43-dataheroconfiggd)
   - [4.4 data/SkillConfig.gd](#44-dataskillconfiggd)
   - [4.5 data/MonsterConfig.gd](#45-datamonsterconfig)
   - [4.6 data/CharacterData.gd](#46-datacharacterdatagd)
   - [4.6 data/SkillData.gd](#46-dataskilldatagd)
   - [4.7 data/StatusData.gd](#47-datastatusdatagd)
   - [4.8 main/StartController.gd](#48-mainstartcontrollergd)
   - [4.9 main/TeamSelectController.gd](#49-mainteamselectcontrollergd)
   - [4.10 battle/BattleController.gd](#410-battlebattlecontrollergd)
   - [4.11 battle/TurnQueue.gd](#411-battleturnqueuegd)
   - [4.12 battle/ActionResolver.gd](#412-battleactionresolvergd)
   - [4.13 battle/LLMClient.gd](#413-battlellmclientgd)
   - [4.14 town/TownController.gd](#414-towntowncontrollergd)
   - [4.15 ui/HudController.gd](#415-uihudcontrollergd)
   - [4.16 battle/spine/SpineAtlas.gd](#416-battlespinespineatlasgd)
   - [4.17 battle/spine/SpineSkel.gd](#417-battlespinespineskelgd)
   - [4.18 battle/spine/SpinePlayer.gd](#418-battlespinespineplayergd)
5. [数据文件说明](#5-数据文件说明)
6. [已知问题与解决方案](#6-已知问题与解决方案)
7. [核心系统设计](#7-核心系统设计)
   - [7.1 行动队列系统](#71-行动队列系统)
   - [7.2 Spine 动画运行机制](#72-spine-动画运行机制)
   - [7.3 特效与受击痛苦反馈机制](#73-特效与受击痛苦反馈机制)
   - [7.4 暗黑地牢风格镜头放大系统](#74-暗黑地牢风格镜头放大系统)
   - [7.5 浮字伤害/治疗数字系统](#75-浮字伤害治疗数字系统)
   - [7.6 压力光环图标系统](#76-压力光环图标系统)
   - [7.7 技能特效映射系统 (SKILL_FX_MAP)](#77-技能特效映射系统-skill_fx_map)
8. [扩展指南](#8-扩展指南)

---

## 1. 项目概述

| 属性 | 值 |
|------|-----|
| 项目名称 | Dark Dungeon RPG Battle System |
| 引擎 | Godot 4.6 |
| 游戏类型 | 回合制 RPG 战斗系统 |
| 开发语言 | GDScript |

**核心特性**：
- 基于有效速度（speed + speed_delta）的行动队列排序系统
- 静态配置驱动的英雄与技能数据管理
- 动态 UI 生成（技能按钮、目标选择界面运行时创建）
- 多种技能效果类型：单体伤害、群体伤害、单体治疗、群体治疗（复合技能）
- 压力系统：精神压力累积与满额即死机制（200 点阈值）
- 编队自由选择（支持重复选择同一英雄）
- 自定义 Spine 2.1.27 骨骼动画运行时（SpineAtlas + SpineSkel + SpinePlayer），渲染 Darkest Dungeon 原版角色动画
- **6 种骷髅系怪物**：弩手、酒杯、勇士、盾卫、剑士、枪兵，每种配备独立 Spine 动画与技能特效
- **UI 布局**：英雄和怪物区完全对称，动态锚点跟踪
- **SkinnedMesh 支持**：多骨骼加权顶点变换，支持复杂角色肢体动画
- **LLM 大模型激励喊话系统**：支持 OpenAI 标准兼容协议（DeepSeek 等多源大模型），英雄能根据场上形势、血量、精神压力、敌人数量与自身性格，生动回应领主的训示，并同步触发精神抚慰效果
- **暗黑地牢风格镜头放大系统**：所有技能释放时攻击方与目标同步放大至 200%，配合 Spine 骨骼特效形成特写镜头
- **浮字伤害/治疗数字系统**：鲜红伤害数字与翠绿治疗数字在放大状态下弹出并渐隐
- **压力光环图标系统**：压力上升显示 `seal.affliction.png`，压力下降显示 `seal.heroic.png`，悬挂于角色头顶

---

## 2. 文件架构

```
darkdungeon/
│
├── project.godot                        # Godot 项目配置文件
│                                        # 定义主场景入口、引擎版本、自动加载节点等
│
├── export_presets.cfg                   # 导出预设配置
│
├── README.md                            # 项目简要说明
├── PROJECT_DOCUMENTATION.md            # 本项目管理文档（详细）
│
├── assets/                              # 静态资源目录
│   ├── icons/                           # 技能/物品图标（暂未使用）
│   ├── portraits/                       # 角色立绘图片（暂未使用）
│   ├── sfx/                             # 音效文件（暂未使用）
│   └── ui/                              # UI 界面素材（暂未使用）
│
├── data/                                # JSON 数据文件目录
│   ├── characters.json                  # 角色静态数据（由 Database.gd 加载）
│   ├── skills.json                      # 技能静态数据（由 Database.gd 加载）
│   ├── statuses.json                    # 状态效果数据（由 Database.gd 加载）
│   └── towns.json                       # 城镇数据（由 Database.gd 加载）
│
├── scenes/                              # Godot 场景文件目录（.tscn）
│   ├── main/
│   │   ├── Main.tscn                    # 根场景，挂载 GameState.gd，作为场景管理容器
│   │   └── TeamSelect.tscn             # 编队选择场景，挂载 TeamSelectController.gd
│   │
│   ├── start/
│   │   └── Start.tscn                   # 游戏开始画面，挂载 StartController.gd
│   │
│   ├── battle/
│   │   ├── Battle.tscn                  # 战斗主场景，挂载 BattleController.gd
│   │   └── TurnQueue.tscn              # 行动队列可视化场景，挂载 TurnQueue.gd（预留）
│   │
│   ├── town/
│   │   └── Town.tscn                    # 城镇场景，挂载 TownController.gd（预留）
│   │
│   └── ui/
│       ├── Hud.tscn                     # HUD 界面场景，挂载 HudController.gd（预留）
│       ├── SkillButton.tscn             # 技能按钮预制体（当前使用动态创建，此文件未用）
│       └── StressBar.tscn              # 压力条 UI 预制体（预留）
│
└── scripts/                             # GDScript 脚本目录
    ├── core/
    │   ├── GameState.gd                 # 全局场景管理器，处理场景切换逻辑
    │   ├── GameState.gd.uid             # Godot UID 资源引用文件（自动生成）
    │   ├── Database.gd                  # JSON 数据加载工具类
    │   └── Database.gd.uid
    │
    ├── data/
    │   ├── HeroConfig.gd                # 英雄静态配置（全局单例模式，含当前编队状态）
    │   ├── HeroConfig.gd.uid
    │   ├── SkillConfig.gd               # 技能静态配置（全局单例模式）
    │   ├── SkillConfig.gd.uid
    │   ├── MonsterConfig.gd             # 怪物模板配置（全局单例模式，含遭遇列表）
    │   ├── CharacterData.gd             # 角色 Resource 数据类（供 Godot 编辑器使用）
    │   ├── CharacterData.gd.uid
    │   ├── SkillData.gd                 # 技能 Resource 数据类（供 Godot 编辑器使用）
    │   ├── SkillData.gd.uid
    │   ├── StatusData.gd                # 状态 Resource 数据类（供 Godot 编辑器使用）
    │   └── StatusData.gd.uid
    │
    ├── main/
    │   ├── StartController.gd           # 开始画面的 UI 控制器
    │   ├── StartController.gd.uid
    │   ├── TeamSelectController.gd      # 编队选择画面的 UI 控制器（含编队逻辑）
    │   └── TeamSelectController.gd.uid
    │
    ├── battle/
    │   ├── BattleController.gd          # 战斗 UI 控制器与输入处理层（委托逻辑给 TurnQueue/ActionResolver）
    │   ├── BattleController.gd.uid
    │   ├── TurnQueue.gd                 # 行动队列：构建、速度排序、弹出、状态查询
    │   ├── TurnQueue.gd.uid
    │   ├── ActionResolver.gd            # 伤害/治疗计算与技能分发（全静态方法）
    │   ├── ActionResolver.gd.uid
    │   ├── LLMClient.gd                 # 负责大语言模型 API 异步通信、JSON 编解码与 Mock 回退引擎
    │   └── spine/
    │       ├── SpineAtlas.gd            # 解析 Spine .atlas 文本，返回 region_name → Region 字典
    │       ├── SpineSkel.gd             # 解析 Spine 2.1.27 二进制 .skel 文件（骨骼/槽位/皮肤/动画）
    │       └── SpinePlayer.gd           # Node2D，以 Sprite2D 子节点渲染 Spine 骨骼动画
    │
    ├── town/
    │   ├── TownController.gd            # 城镇场景控制器（预留）
    │   └── TownController.gd.uid
    │
    └── ui/
        ├── HudController.gd             # HUD 界面控制器（预留，当前为空）
        └── HudController.gd.uid
```

---

## 3. 游戏流程

```
┌──────────────────────────────────────────────────┐
│  启动：Main.tscn (GameState.gd)                  │
│  → _ready() 调用 _goto_start()                   │
│  → 加载并实例化 Start.tscn                       │
└─────────────────────┬────────────────────────────┘
                      │
┌─────────────────────▼────────────────────────────┐
│  Start.tscn (StartController.gd)                 │
│  → 显示"Start Battle"按钮                        │
│  → 玩家点击 → change_scene_to_file(TeamSelect)   │
└─────────────────────┬────────────────────────────┘
                      │ 点击 Start Battle
┌─────────────────────▼────────────────────────────┐
│  TeamSelect.tscn (TeamSelectController.gd)       │
│  → 左侧显示 4 个编队槽位                         │
│  → 右侧显示可用英雄列表                          │
│  → 玩家点击 Select → 选择槽位                    │
│  → 玩家点击英雄 → 填入槽位                       │
│  → 点击 Confirm → 显示确认面板                   │
│  → 点击 Start Battle → HeroConfig.set_team()     │
│     → change_scene_to_file(Battle.tscn)          │
└─────────────────────┬────────────────────────────┘
                      │ 保存编队后跳转
┌─────────────────────▼────────────────────────────┐
│  Battle.tscn (BattleController.gd)               │
│  → _setup_battle(): 初始化英雄和怪物数据          │
│  → _start_new_round(): 设置速度浮动值，构建队列  │
│  → _get_next_actor(): 取出第一个行动者           │
│                                                  │
│  [ 行动循环 ]                                    │
│  英雄行动: 玩家选技能 → 选目标 → 执行           │
│  怪物行动: 自动攻击第一个活着的英雄              │
│  → _advance_action() → 取下一个行动者            │
│  → 队列空 → _start_new_round() 开始新轮          │
│                                                  │
│  [ 结束条件 ]                                    │
│  所有怪物死亡 → Victory 面板                     │
│  所有英雄死亡 → Defeat 面板                      │
│  → 点击 Back → 返回 Start.tscn                  │
└──────────────────────────────────────────────────┘
```

---

## 4. 脚本函数详解

### 4.1 core/GameState.gd

**类继承**：`extends Node`  
**挂载场景**：`scenes/main/Main.tscn`  
**职责**：作为根节点的场景管理器，负责全局场景切换和子场景信号监听。

**常量**：

| 常量名 | 值 | 说明 |
|--------|-----|------|
| `START_SCENE_PATH` | `"res://scenes/start/Start.tscn"` | 开始场景路径 |
| `TOWN_SCENE_PATH` | `"res://scenes/town/Town.tscn"` | 城镇场景路径 |
| `BATTLE_SCENE_PATH` | `"res://scenes/battle/Battle.tscn"` | 战斗场景路径 |

**变量**：

| 变量名 | 类型 | 说明 |
|--------|------|------|
| `current_scene` | `Node` | 当前已实例化的子场景节点引用 |

---

#### `_ready() -> void`
- **触发时机**：节点进入场景树时自动调用
- **功能**：游戏启动后立即跳转到开始画面
- **调用链**：`_ready()` → `_goto_start()` → `_change_scene(START_SCENE_PATH)`

---

#### `_goto_start() -> void`
- **功能**：切换到游戏开始场景（Start.tscn）
- **调用方**：`_ready()`、子场景发出 `return_to_start` 信号时
- **实现**：调用 `_change_scene(START_SCENE_PATH)`

---

#### `_goto_town() -> void`
- **功能**：切换到城镇场景（Town.tscn）
- **调用方**：子场景发出 `return_to_town` 信号时
- **实现**：调用 `_change_scene(TOWN_SCENE_PATH)`
- **状态**：预留，城镇功能尚未实现

---

#### `_goto_battle() -> void`
- **功能**：切换到战斗场景（Battle.tscn）
- **调用方**：子场景发出 `start_battle` 信号时
- **实现**：调用 `_change_scene(BATTLE_SCENE_PATH)`

---

#### `_change_scene(scene_path: String) -> void`
- **参数**：`scene_path` — 目标场景的资源路径
- **功能**：销毁当前子场景，加载并实例化新场景，连接新场景的信号
- **流程**：
  1. 如果 `current_scene` 不为 null，调用 `queue_free()` 异步销毁
  2. 将 `current_scene` 置为 null
  3. 用 `load(scene_path)` 加载 PackedScene
  4. 调用 `instantiate()` 创建场景实例
  5. 用 `add_child()` 添加到自身
  6. 调用 `_wire_scene_events()` 连接信号

---

#### `_wire_scene_events(scene: Node) -> void`
- **参数**：`scene` — 新实例化的场景节点
- **功能**：自动检测并连接新场景上的导航信号
- **连接的信号**：
  | 信号名 | 连接目标 |
  |--------|---------|
  | `start_battle` | `_goto_battle()` |
  | `return_to_start` | `_goto_start()` |
  | `return_to_town` | `_goto_town()` |

---

### 4.2 core/Database.gd

**类继承**：`extends Node`  
**职责**：提供从本地 JSON 文件读取游戏数据的工具方法。该类不自动加载数据，需要由外部调用。

**常量**：

| 常量名 | 值 | 说明 |
|--------|-----|------|
| `DATA_DIR` | `"res://data"` | JSON 数据文件所在目录 |

---

#### `load_json(path: String) -> Dictionary`
- **参数**：`path` — JSON 文件的完整资源路径
- **返回值**：解析后的 Dictionary；文件不存在或解析失败时返回空 `{}`
- **功能**：通用 JSON 文件读取方法
- **流程**：
  1. 用 `FileAccess.open(path, FileAccess.READ)` 打开文件
  2. 文件为 null 时直接返回 `{}`
  3. 调用 `file.get_as_text()` 读取全部文本
  4. 用 `JSON.parse_string(text)` 解析
  5. 检查结果类型为 `TYPE_DICTIONARY` 后返回，否则返回 `{}`

---

#### `get_characters() -> Dictionary`
- **功能**：加载角色数据文件
- **返回值**：`data/characters.json` 的内容

---

#### `get_skills() -> Dictionary`
- **功能**：加载技能数据文件
- **返回值**：`data/skills.json` 的内容

---

#### `get_statuses() -> Dictionary`
- **功能**：加载状态效果数据文件
- **返回值**：`data/statuses.json` 的内容

---

#### `get_towns() -> Dictionary`
- **功能**：加载城镇数据文件
- **返回值**：`data/towns.json` 的内容

---

### 4.3 data/HeroConfig.gd

**类名**：`HeroConfig`  
**类继承**：`extends Node`  
**模式**：静态变量单例（所有方法均为 `static`，数据全局共享）  
**职责**：集中管理所有英雄模板数据，以及当前战斗编队的配置。

**静态变量**：

```gdscript
static var HEROES: Dictionary = {
    "crusader":   { "name": "Crusader",   "max_hp": 50, "attack": 10, "speed": 4,
                    "skills": ["slash", "heal"] },
    "highwayman": { "name": "Highwayman", "max_hp": 30, "attack": 12, "speed": 5,
                    "skills": ["shotgun", "cut"] }
}

static var CURRENT_TEAM: Array[String] = ["crusader", "highwayman", "crusader", "highwayman"]
```

---

#### `static get_hero_template(hero_id: String) -> Dictionary`
- **参数**：`hero_id` — 英雄唯一标识符（如 `"crusader"`）
- **返回值**：英雄数据的深拷贝 Dictionary；不存在时返回 `{}`
- **功能**：获取英雄的初始模板，附加两个字段：`id`（英雄 ID）和 `hp`（初始值等于 `max_hp`）
- **用途**：TeamSelectController 用于显示英雄信息；BattleController 通过 `get_team_heroes()` 间接调用

---

#### `static get_team_heroes() -> Array[Dictionary]`
- **返回值**：按 `CURRENT_TEAM` 顺序排列的英雄模板数组
- **功能**：根据当前编队配置构建英雄数据列表，供 BattleController 初始化战斗数据
- **流程**：遍历 `CURRENT_TEAM`，对每个 hero_id 调用 `get_hero_template()`，跳过空字符串和不存在的 ID

---

#### `static hero_exists(hero_id: String) -> bool`
- **参数**：`hero_id` — 英雄唯一标识符
- **返回值**：英雄是否存在于 `HEROES` 字典中

---

#### `static set_team(team: Array[String]) -> void`
- **参数**：`team` — 包含 4 个 hero_id 字符串的数组（空位用 `""` 表示）
- **功能**：更新全局编队配置 `CURRENT_TEAM`
- **调用方**：`TeamSelectController._on_start_battle_pressed()`

---

#### `static get_all_hero_ids() -> Array[String]`
- **返回值**：所有已注册英雄的 ID 列表（如 `["crusader", "bandit"]`）
- **功能**：提供可用英雄列表，供 TeamSelectController 渲染选英雄 UI

---

### 4.4 data/SkillConfig.gd

**类名**：`SkillConfig`  
**类继承**：`extends Node`  
**模式**：静态变量单例  
**职责**：集中管理所有技能数据，提供技能查询接口。

**技能数据结构**：

| 字段 | 类型 | 说明 |
|------|------|------|
| `name` | String | 技能显示名称 |
| `effect_type` | String | `"damage"` 或 `"heal"` |
| `target_type` | String | `"single_enemy"` / `"all_enemies"` / `"single_ally"` |
| `attack_ratio` | float | 仅 damage 类型，伤害 = 攻击力 × attack_ratio |
| `heal_amount` | int | 仅 heal 类型，固定治疗量 |
| `description` | String | 技能描述文本 |
| `use_positions` | Array[int] | 英雄可使用该技能的己方站位（1=最前，4=最后）；空数组表示无限制 |
| `target_positions` | Array[int] | 该技能可命中的对方站位编号；空数组表示无限制 |

**已注册技能**：

| ID | 名称 | 类型 | 目标 | 效果 | use_positions | target_positions |
|----|------|------|------|------|--------------|------------------|
| `slash` | Slash | damage | single_enemy | ATK × 1.0 | [1, 2] | [1, 2] |
| `heal` | Heal | heal | single_ally | +10 HP | [1, 2, 3, 4] | [1, 2, 3, 4] |
| `shotgun` | Shotgun | damage | all_enemies | ATK × 0.5（1-3位） | [2, 3, 4] | [1, 2, 3] |
| `cut` | Cut | damage | single_enemy | ATK × 1.1 | [1, 2, 3] | [1, 2, 3] |
| `Close-range shooting` | Close-range shooting | damage | single_enemy | ATK × 1.5 | [1] | [1] |
| `pistol_shot` | Pistol Shot | damage | single_enemy | ATK × 0.9 | [2, 3, 4] | [1, 2, 3, 4] |
| `holy spear` | Holy Spear | damage | single_enemy | ATK × 1.2, 前进1 | [2, 3, 4] | [2, 3, 4] |
| `battle_cry` | Battle Cry | composite_heal | single_ally | 目标 HP+2/Stress-7, 其他友方 Stress-2 | [1, 2, 3, 4] | [1, 2, 3, 4] |

**怪物技能**：

| ID | 名称 | 类型 | 目标 | 效果 | use_positions | target_positions |
|----|------|------|------|------|--------------|------------------|
| `cutthroat_strike` | Cutthroat Strike | damage | single_enemy | ATK × 1.0 | [1, 2, 3] | [1, 2] |
| `temptation` | Temptation | damage | single_enemy | ATK × 0.5, stress+30 | [3, 4] | [1, 2, 3, 4] |
| `troll_smash` | Troll Smash | damage | single_enemy | ATK × 1.2 | [1, 2] | [1, 2] |
| `arbalist_crossbow` | Crossbow Shot | damage | single_enemy | ATK × 1.3（后排远程） | [3, 4] | [1, 2, 3, 4] |
| `arbalist_bayonet` | Bayonet Jab | damage | single_enemy | ATK × 0.7（前排近战） | [1, 2] | [1, 2] |
| `courtier_goblet` | Goblet Toss | damage | all_enemies | ATK × 0.3, stress+15 | [3, 4] | [1, 2, 3, 4] |
| `courtier_dagger` | Poisoned Dagger | damage | single_enemy | ATK × 0.6, stress+20 | [1, 2] | [1, 2, 3] |
| `skeleton_melee` | Rusty Blade | damage | single_enemy | ATK × 1.0 | [1, 2, 3] | [1, 2] |
| `defender_axe` | Axe Cleave | damage | single_enemy | ATK × 0.8 | [1, 2] | [1, 2] |
| `defender_shield` | Shield Bash | damage | single_enemy | ATK × 0.5, stress+10 | [1, 2] | [1, 2] |
| `militia_slash` | Militia Slash | damage | single_enemy | ATK × 1.0 | [1, 2, 3] | [1, 2] |
| `spear_thrust` | Spear Thrust | damage | single_enemy | ATK × 1.0（穿刺后排） | [1, 2, 3] | [2, 3, 4] |

---

#### `static get_skill(skill_id: String) -> Dictionary`
- **参数**：`skill_id` — 技能唯一标识符（如 `"slash"`）
- **返回值**：技能数据的深拷贝 Dictionary；不存在时返回 `{}`
- **用途**：BattleController 在计算伤害、渲染技能按钮、判断目标类型、验证站位限制时调用

---

#### `static skill_exists(skill_id: String) -> bool`
- **参数**：`skill_id` — 技能唯一标识符
- **返回值**：技能是否存在于 `SKILLS` 字典中

---

### 4.5 data/CharacterData.gd

**类名**：`CharacterData`  
**类继承**：`extends Resource`  
**职责**：Godot Resource 数据类，用于编辑器内创建角色数据资源文件（.tres）。与运行时 HeroConfig 并行存在，面向编辑器工作流。

**导出属性**（`@export`）：

| 属性 | 类型 | 说明 |
|------|------|------|
| `id` | String | 角色唯一标识符 |
| `name` | String | 角色名称 |
| `max_hp` | int | 最大血量 |
| `speed` | int | 基础速度 |
| `stress_threshold` | int | 压力阈值（默认 100，预留字段） |
| `skills` | Array[String] | 技能 ID 列表 |
| `statuses` | Array[String] | 初始状态列表（预留） |

> 该类无自定义方法，仅作数据容器。

---

### 4.6 data/SkillData.gd

**类名**：`SkillData`  
**类继承**：`extends Resource`  
**职责**：Godot Resource 数据类，用于编辑器内创建技能数据资源文件。

**导出属性**（`@export`）：

| 属性 | 类型 | 说明 |
|------|------|------|
| `id` | String | 技能唯一标识符 |
| `name` | String | 技能名称 |
| `type` | String | 技能类型字符串 |
| `power` | int | 技能威力基础值 |
| `hit` | int | 命中率（默认 100，预留） |
| `stress_delta` | int | 施加的压力变化量（预留） |
| `target` | String | 目标类型字符串 |
| `cooldown` | int | 冷却回合数（预留） |

> 该类无自定义方法，仅作数据容器。

---

### 4.7 data/StatusData.gd

**类名**：`StatusData`  
**类继承**：`extends Resource`  
**职责**：Godot Resource 数据类，用于编辑器内创建状态效果数据资源。

**导出属性**（`@export`）：

| 属性 | 类型 | 说明 |
|------|------|------|
| `id` | String | 状态唯一标识符 |
| `name` | String | 状态名称 |
| `type` | String | 状态类型（如 `"dot"`、`"buff"` 等） |
| `duration` | int | 持续回合数 |
| `effects` | Dictionary | 状态具体效果（键值对，预留） |

> 该类无自定义方法，仅作数据容器。

---

### 4.8 main/StartController.gd

**类继承**：`extends Node`  
**挂载场景**：`scenes/start/Start.tscn`  
**职责**：管理游戏开始画面，响应玩家点击"开始"按钮。

**节点引用**（`@onready`）：

| 变量 | 类型 | 路径 |
|------|------|------|
| `start_button` | Button | `$StartUI/StartButton` |

---

#### `_ready() -> void`
- **触发时机**：Start.tscn 加载完成时
- **功能**：检查 `start_button` 节点是否存在，若存在则将其 `pressed` 信号连接到 `_on_start_pressed()`

---

#### `_on_start_pressed() -> void`
- **触发时机**：玩家点击"Start Battle"按钮
- **功能**：切换到编队选择场景
- **实现**：`get_tree().change_scene_to_file("res://scenes/main/TeamSelect.tscn")`

---

### 4.9 main/TeamSelectController.gd

**类继承**：`extends Node`  
**挂载场景**：`scenes/main/TeamSelect.tscn`  
**职责**：管理编队选择画面的全部 UI 逻辑，包括槽位选择、英雄选择、编队确认。

**信号**：

| 信号名 | 说明 |
|--------|------|
| `team_selected` | 编队确认后发出（当前未使用，预留） |

**成员变量**：

| 变量 | 类型 | 初始值 | 说明 |
|------|------|--------|------|
| `hero_slots` | Array[HBoxContainer] | `[]` | 4 个槽位容器节点的引用 |
| `confirm_button` | Button | null | "Confirm"确认按钮 |
| `available_heroes_container` | VBoxContainer | null | 可用英雄列表容器 |
| `confirm_panel` | Panel | null | 编队确认弹出面板 |
| `team_summary_label` | Label | null | 面板中显示编队摘要的标签 |
| `start_button` | Button | null | 面板中的"Start Battle"按钮 |
| `back_button` | Button | null | 面板中的"Back"返回按钮 |
| `current_team` | Array[String] | `["crusader","highwayman","crusader","highwayman"]` | 当前编队的 hero_id 数组 |
| `selected_slot` | int | `-1` | 当前处于"等待选择英雄"状态的槽位索引；-1 表示未选中 |

---

#### `_ready() -> void`
- **触发时机**：TeamSelect.tscn 加载完成时
- **功能**：获取所有 UI 节点引用，初始化 UI，连接按钮信号
- **流程**：
  1. 用 `get_node()` 手动获取 4 个槽位（Slot1-Slot4）、确认面板等节点
  2. 调用 `_setup_ui()`
  3. 连接 `confirm_button.pressed` → `_on_confirm_pressed()`
  4. 连接 `start_button.pressed` → `_on_start_battle_pressed()`
  5. 连接 `back_button.pressed` → `_on_confirm_back_pressed()`

---

#### `_setup_ui() -> void`
- **功能**：初始化整个编队选择界面
- **流程**：
  1. 调用 `_update_available_heroes()` 生成右侧英雄列表
  2. 调用 `_update_team_display()` 渲染当前编队槽位

---

#### `_update_available_heroes() -> void`
- **功能**：清空并重新生成右侧可选英雄列表
- **流程**：
  1. 删除 `available_heroes_container` 的所有子节点
  2. 遍历 `HeroConfig.get_all_hero_ids()`
  3. 对每个 hero_id：
     - 调用 `HeroConfig.get_hero_template(hero_id)` 获取数据
     - 创建 Button，文本为 `"名字 (HP:xx ATK:xx)"`
     - 设置最小尺寸 `Vector2(300, 40)`
     - 连接 `pressed` → `_on_hero_selected(hero_id)`
     - 添加到容器

---

#### `_update_team_display() -> void`
- **功能**：根据 `current_team` 和 `selected_slot` 重新渲染 4 个槽位
- **对每个槽位 i 的逻辑**：
  - `current_team[i] != ""`（已有英雄）：
    - 显示英雄名称 Label
    - 显示 Remove 按钮，连接到 `_on_slot_remove(i)`
  - `current_team[i] == ""`（空槽位）且 `selected_slot == i`（当前等待选择）：
    - 显示黄色 Label `"N. [SELECT HERO] <"`
    - 显示 Select 按钮（disabled，UI 提示用）
  - 其他空槽位：
    - 显示灰色 Label `"N. Empty"`
    - 显示 Select 按钮，连接到 `_on_slot_select(i)`

---

#### `_on_hero_selected(hero_id: String) -> void`
- **参数**：`hero_id` — 被点击的英雄 ID
- **触发时机**：玩家点击右侧英雄列表中的某个英雄按钮
- **功能**：将选中的英雄放入当前激活的槽位
- **流程**：
  1. 检查 `selected_slot` 是否在 `[0, 3]` 范围内
  2. 将 `hero_id` 写入 `current_team[selected_slot]`
  3. 重置 `selected_slot = -1`
  4. 调用 `_update_team_display()` 刷新显示

---

#### `_on_slot_select(slot_index: int) -> void`
- **参数**：`slot_index` — 被点击的槽位索引（0-3）
- **触发时机**：玩家点击某个空槽位的"Select"按钮
- **功能**：将该槽位设为"待选英雄"状态
- **流程**：
  1. 设置 `selected_slot = slot_index`
  2. 调用 `_update_team_display()`（该槽位会变为黄色提示）

---

#### `_on_slot_remove(slot_index: int) -> void`
- **参数**：`slot_index` — 被操作的槽位索引（0-3）
- **触发时机**：玩家点击已有英雄的槽位上的"Remove"按钮
- **功能**：清空该槽位的英雄
- **流程**：
  1. 验证 `slot_index` 在有效范围内
  2. 将 `current_team[slot_index]` 设为 `""`
  3. 调用 `_update_team_display()`

---

#### `_on_confirm_pressed() -> void`
- **触发时机**：玩家点击"Confirm"按钮
- **功能**：验证编队有效性后弹出确认面板
- **流程**：
  1. 遍历 `current_team`，检查是否至少有一个非空 hero_id
  2. 若全为空，直接返回（不弹面板）
  3. 调用 `_show_confirm_panel()`

---

#### `_show_confirm_panel() -> void`
- **功能**：构建编队摘要文本并显示确认面板
- **流程**：
  1. 构建字符串，格式为 `"1. 英雄名\n2. 英雄名\n..."` 或 `"N. Empty"`
  2. 将字符串写入 `team_summary_label.text`
  3. 设置 `confirm_panel.visible = true`

---

#### `_on_start_battle_pressed() -> void`
- **触发时机**：玩家在确认面板中点击"Start Battle"
- **功能**：保存编队配置并跳转到战斗场景
- **流程**：
  1. 调用 `HeroConfig.set_team(current_team)` 写入全局编队
  2. 调用 `get_tree().change_scene_to_file("res://scenes/battle/Battle.tscn")`

---

#### `_on_confirm_back_pressed() -> void`
- **触发时机**：玩家在确认面板中点击"Back"
- **功能**：关闭确认面板，返回编队编辑状态
- **实现**：`confirm_panel.visible = false`

---

### 4.10 battle/BattleController.gd

**类继承**：`extends Node`  
**挂载场景**：`scenes/battle/Battle.tscn`  
**职责**：战斗系统的 UI 控制器与输入处理层；所有战斗逻辑委托给 `TurnQueue`、`ActionResolver`、`MonsterConfig`。

**信号**：

| 信号名 | 说明 |
|--------|------|
| `return_to_start` | 战斗结束后点击返回按钮时发出 |

**常量**：

| 常量名 | 值 | 说明 |
|--------|-----|------|
| `SPEED_DELTA_RANGE` | `4` | 速度浮动范围；每轮对所有单位随机生成 `[-4, +4]` |
| `CRUSADER_ANIM_BASE` | `"res://characters/crusader/anim/crusader.sprite."` | Crusader .skel/.atlas 路径前缀 |
| `CRUSADER_PNG_DIR` | `"res://characters/crusader/crusader_A/anim"` | Crusader PNG 皮肤目录 |
| `CRUSADER_ANIM_MAP` | Dictionary | Crusader 状态→动画文件名映射（idle/attack/heal/defend/combat/heroic/walk）|
| `HIGHWAYMAN_ANIM_BASE` | `"res://characters/highwayman/anim/highwayman.sprite."` | Highwayman .skel/.atlas 路径前缀 |
| `HIGHWAYMAN_PNG_DIR` | `"res://characters/highwayman/highwayman_A/anim"` | Highwayman PNG 皮肤目录 |
| `HIGHWAYMAN_ANIM_MAP` | Dictionary | Highwayman 状态→动画文件名映射 |
| `CUTTHROAT_ANIM_BASE` | `"res://monsters/brigand_cutthroat/anim/brigand_cutthroat.sprite."` | Cutthroat .skel/.atlas 路径前缀 |
| `CUTTHROAT_PNG_DIR` | `"res://monsters/brigand_cutthroat/anim"` | Cutthroat PNG 皮肤目录 |
| `CUTTHROAT_ANIM_MAP` | Dictionary | Cutthroat 状态→动画文件名映射 |

**节点引用**（`@onready`）：

| 变量 | 节点路径 | 说明 |
|------|---------|------|
| `hero_list` | `$BattleUI/BattleContainer/LeftArea/HeroArea` | 英雄信息列表容器 (HBoxContainer) |
| `monster_list` | `$BattleUI/BattleContainer/RightArea/MonsterArea` | 怪物列表/目标选择容器 (HBoxContainer) |
| `selected_label` | `$BattleUI/BattleContainer/RightArea/SelectedLabel` | 当前行动状态描述文本 |
| `skill_icon_boxes` | 数组[4] | 技能图标容器数组（4个 ColorRect，50×50 每个） |
| `skill_container` | `$BattleUI/BattleContainer/LeftArea/BottomLeftPanel/PanelBanner/BannerContent/SkillContainer` | 技能按钮容器 (HBoxContainer) |
| `portrait_box` | `$BattleUI/BattleContainer/LeftArea/BottomLeftPanel/PanelBanner/BannerContent/CharacterPortrait` | 英雄头像容器 (ColorRect) |
| `skip_button` | `$BattleUI/BattleContainer/LeftArea/BottomLeftPanel/BottomPanelsContainer/PanelHero/SkipButton` | 跳过按钮 |
| `reposition_button` | `$BattleUI/BattleContainer/LeftArea/BottomLeftPanel/BottomPanelsContainer/PanelHero/ReposButton` | 换位按钮 |
| `victory_panel` | `$BattleUI/VictoryPanel` | 胜负结果面板 |
| `back_button` | `$BattleUI/VictoryPanel/BackToStartButton` | 返回开始画面按钮 |
| `hero_slots` | 数组[4] | 英雄位置容器 (预设的 Control 节点数组) |
| `monster_slots` | 数组[4] | 怪物位置容器 (预设的 Control 节点数组) |

**成员变量**：

| 变量 | 类型 | 说明 |
|------|------|------|
| `heroes` | Array[Dictionary] | 当前战斗中所有英雄的运行时数据 |
| `monsters` | Array[Dictionary] | 当前战斗中所有怪物的运行时数据 |
| `turn_queue` | TurnQueue | 行动队列管理器实例 |
| `battle_over` | bool | 战斗是否已结束 |
| `round_number` | int | 当前回合数（从 1 开始） |
| `current_actor` | Dictionary | 当前行动单位，格式 `{"unit_type": "hero"/"monster", "index": int}` |
| `hero_skill_selected` | bool | 当前行动英雄是否已选择技能 |
| `hero_current_skill` | String | 当前选择的技能 ID |
| `reposition_mode` | bool | 是否处于换位选目标模式 |
| `_spine_players` | Dictionary | SpinePlayer 缓存：key=英雄 index(int) 或 `"monster_%d"`，value=SpinePlayer 节点 |
| `_spine_current_state` | Dictionary | 动画状态缓存：key=索引，value=当前加载的动画名 |
| `_spine_anchors` | Dictionary | UI 锚点缓存：key=索引，value=ColorRect（用于位置同步） |

---

#### `_ready() -> void`
- **触发时机**：Battle.tscn 加载完成时
- **调用链**：`_setup_battle()` → `_start_new_round()` → `_get_next_actor()`
- **信号连接**：
  - `back_button.pressed` → `_on_back_pressed()`
  - `reposition_button.pressed` → `_on_reposition_pressed()`
  - `skip_button.pressed` → `_on_skip_pressed()`
- **延迟调用**：`call_deferred("_update_ui")` 等待树完全布局

---

#### `_process(_delta: float) -> void`
- **触发时机**：每帧调用
- **职责**：同步 SpinePlayer 位置到 UI 锚点
- **实现流程**：
  1. 遍历 `_spine_anchors` 字典中的所有锚点（英雄和怪物）
  2. 对每个有效的锚点和对应的 SpinePlayer：
     - 获取锚点的全局位置和尺寸
     - 计算目标位置：`rect_global + Vector2(rect_size.x * 0.5, rect_size.y * 0.9)`
       - 这将 SpinePlayer 原点放在锚点中心的下方约 90%（脚线处）
     - 设置 `sp.global_position = target_pos`
     - 设置 `sp.z_index = 10` 确保在 UI 前面
- **关键设计**：
  - 英雄和怪物完全对称，都从各自的 UI 预设位置提取锚点
  - 无动态偏移或计算，位置由场景中的 `hero_slots` / `monster_slots` Control 节点决定
  - 每帧同步确保动画位置始终与 UI 保持一致

---

#### `_setup_battle() -> void`
- **功能**：清空并重新初始化 `heroes` 与 `monsters` 数组，重置所有战斗状态变量
- **数据来源**：
  - 英雄：`HeroConfig.get_team_heroes()`
  - 怪物：`MonsterConfig.get_encounter_monsters()`
- **SpinePlayer 初始化**：
  - 遍历所有英雄，若 `id == "crusader"` 或 `"highwayman"` 则调用 `_create_spine_player_for_hero(i)`
  - 遍历所有怪物，若 `id == "cutthroat"` 则调用 `_create_spine_player_for_monster(i)`
- **状态清理**：`_spine_current_state.clear()` 确保旧动画状态不会阻塞新场景

---

#### `_start_new_round() -> void`
- **功能**：递增 `round_number`，重置所有存活单位的 `actions_remaining = 1` 和 `speed_delta`，构建行动队列
- **速度浮动**：对每个活着的英雄和怪物独立随机 `randi_range(-SPEED_DELTA_RANGE, SPEED_DELTA_RANGE)`

---

#### `_advance_action() -> void`
- **功能**：若当前行动者是英雄则递减其 `actions_remaining`，然后调用 `_get_next_actor()`

---

#### `_get_next_actor() -> void`
- **功能**：`while true` 循环驱动整个行动流转
- **流程**：
  1. `battle_over` → return
  2. 队列空 + 有剩余行动 → 重建队列，continue
  3. 队列空 + 无剩余行动 → `_start_new_round()`，continue
  4. `turn_queue.pop_next_alive()` 取单位；空则 continue
  5. 英雄 → 重置技能状态，`_update_ui()`，**return**（等待玩家输入）
  6. 怪物 → `_execute_monster_action()`，continue

---

#### `_execute_monster_action() -> void`
- **功能**：自动决策并执行当前轮次怪物的AI行为（施法与攻击）
- **流程**：
  1. **安全性检查**：校验当前行动者是否有效且为怪物，怪物 `hp` 是否大于0。
  2. **行动点扣除**：绝不保留行动点（在决策前立即扣除 `actions_remaining -= 1`），完美保障防止死循环。
  3. **可用技能筛查**：
     - 获取怪物的技能列表 `skills`。
     - 逐一匹配技能配置 `use_positions` 字段，验证怪物当前所处的第 1~4 站位（`index + 1`）是否处于该技能可用释放范围。
     - 若不处于可用释放范围，则直接剔除该技能。
  4. **候选目标搜寻**：
     - 调用 `_get_valid_targets_for_monster()` 搜寻符合当前技能 `target_positions` 站位范围约束、且处于存活状态的所有目标单位。
     - 包含该技能和符合条件的目标存活列表封装进候选技能组。
  5. **技能与目标AI路由**：
     - 若候选技能集非空，则随机选择其中一个技能，并根据 `target_type` 执行分发：
       - `single_enemy` 或 `single_ally`：根据技能属性中的 `target_priority` 属性，调用 `_select_target_by_priority()` 智能检索最优先级目标，随后分发至 `ActionResolver.resolve_on_target()` 计算效果。
       - `all_enemies` 或 `all_allies`：对符合条件的全体目标调用 `ActionResolver.resolve_on_all()` 造成范围群体效果。
       - `self`：直接对施法者自身应用效果。
     - 若可用候选技能集为空，则当前轮次作 `pass` 跳过处理（无需任何退避动作，极其安全）。
  6. **状态检验与刷新**：检查英雄是否被击败，更新 UI。

---

#### `_get_valid_targets_for_monster(idx: int, skill_data: Dictionary) -> Array[Dictionary]`
- **功能**：检索怪物释放指定技能时，满足位置限制的所有存活目标
- **参数**：
  - `idx`: 当前行动怪物在 `monsters` 阵列中的 0-based 索引。
  - `skill_data`: 被检索的技能配置字典。
- **流程**：
  - 读取技能的 `target_type` 以及限定目标站位的 `target_positions`（站位 `1 ~ 4`，若为空则表明对目标站位无限制）。
  - 若目标类型为 `single_enemy` / `all_enemies`，遍历英雄队列中每一个 `hp > 0` 的单位，校验其相对于排头（第 `1` 位）的真实位置（`index + 1`）是否在 `target_positions` 范围内，若满足，则判定为有效目标添加至返回阵列中。
  - 若目标类型为 `single_ally` / `all_allies`，则对怪物同排友方执行相同的存活和站位校验。

---

#### `_select_target_by_priority(targets: Array, priority: String) -> Dictionary`
- **功能**：怪物AI目标选择核心决策器，根据特定优先级规则从有效目标集中挑出最终受击目标
- **参数**：
  - `targets`: 已筛选出的有效目标列表。
  - `priority`: 优先级决策字（如 `"lowest_hp"`, `"highest_stress"`, `"random"` 等）。
- **返回值**：决策后最终被选中的单个目标字典。如果是空列表则返回 `{}`。
- **实现算法**：
  - `lowest_hp`：遍历目标列表，寻找到并返回当前 `hp` 值最低（生命值最低）的英雄。
  - `highest_stress`：遍历目标列表，寻找到并返回当前 `stress` 压力值最高（最逼近极限）的英雄。
  - `random` 或缺省：调用 `randi() % targets.size()` 随机均匀挑选返回。

---

#### `_count_alive(units: Array[Dictionary]) -> int`
- **返回值**：`hp > 0` 的单位数量

---

#### `_first_alive(units: Array[Dictionary]) -> Dictionary`
- **返回值**：第一个 `hp > 0` 的单位；无存活时返回 `{}`

---

#### `_check_victory() -> bool`
- **功能**：所有怪物死亡时调用 `_end_battle()`，返回 `true`

---

#### `_check_defeat() -> bool`
- **功能**：所有英雄死亡时调用 `_end_battle()`，返回 `true`

---

#### `_end_battle() -> void`
- **功能**：设置 `battle_over = true`，清空 `current_actor`，显示 `victory_panel`，刷新 UI

---

#### `_can_act() -> bool`
- **功能**：验证当前英雄是否可执行技能
- **条件**：非战斗结束 + 行动者非空 + 是英雄 + 已选技能 + 英雄存活

---

#### `_finish_hero_action() -> void`
- **功能**：处理英雄行动完成后的后续流程，尤其是计算与解析**技能附带的主动位移效果**
- **逻辑流程**：
  1. **读取技能位移字段**：如果当前英雄有选中的技能，在配置字典中读取 `move_forward` 整数值。
  2. **位移索引计算**：
     - 若 `move_forward > 0`（如十字军“神圣矛” `move_forward = 1`）：将当前英雄在 `heroes` 中的索引 `src_index` 向左（排头方向，也是前排方向）推移，换算目标索引：`target_index = clamp(src_index - move_forward, 0, max_index)`。
     - 若 `move_forward < 0`（如强盗“贴身射击” `move_forward = -1`）：将当前英雄向后方（排尾方向）推移，换算目标索引：`target_index = clamp(src_index - move_forward, 0, max_index)`。
  3. **应用位移矩阵**：
     - 如果满足 `target_index != src_index`，首先扣除前一个英雄所处对应位置的剩余行动次数 `actions_remaining -= 1`。
     - 调用 `_apply_hero_reposition_position(src_index, target_index)` 执行物理数组顺序移动与 Spine 动画及 UI 锚点映射表重建。
     - 立即调用 `turn_queue.build()` 实现在位移条件下的**重新排队排序**，并调用 `_get_next_actor()` 拉取新状态继续推进。
  4. **常规推进**：若没有发生位移，则直接重置技能选择状态（`hero_skill_selected = false`、`hero_current_skill = ""`），并调用 `_advance_action()` 结束此项回合。

---

#### `_apply_hero_reposition_position(src_idx: int, target_idx: int) -> void`
- **功能**：基础换位矩阵处理器，实现英雄角色在 `heroes` 数据数组和 Spine 动画实例映射 `_spine_players` 字典中的双向循环位移
- **核心逻辑**：
  1. **保存现场引用**：保存 `src_idx` 的 SpinePlayer 实味引用 `src_spine` 和当前播放动画名称 `src_state`。
  2. **物理重排数组**：将 `heroes` 数组中 `src_idx` 切片拉出并插入至新索引位置 `target_idx`，随后重新设置每个英雄字典的局部 `index` 键。
  3. **Spine 渲染器重新定位**：
     - 如果是向右侧（排尾）方向位移，将处于中间位置的所有英雄向左移位，重新装载到 `new_spine_players` 数组映射内；
     - 如果是向左侧（排头）方向位移，相应地将沿途英雄向右移位；
     - 将原本的 `src_spine` 实例及其播放姿态 `src_state` 赋予目标 `target_idx` 位置。
  4. **变量刷新**：将全局 `current_actor["index"]` 更新为全新 `insert_at` 位置，避免坐标系错乱。

---

#### `_on_skill_pressed(skill_id: String) -> void`
- **触发时机**：玩家点击技能按钮
- **功能**：验证站位 → 设置 `hero_current_skill` → `hero_skill_selected = true` → `_update_ui()`

---

#### `_on_skip_pressed() -> void`
- **触发时机**：玩家点击跳过按钮
- **功能**：重置技能状态，退出换位模式，推进战斗

---

#### `_on_reposition_pressed() -> void`
- **触发时机**：玩家点击换位按钮
- **功能**：切换 `reposition_mode` 状态，清除技能选择，刷新 UI

---

#### `_on_hero_reposition_target(target_idx: int) -> void`
- **触发时机**：换位模式下玩家点击目标英雄
- **功能**：循环位移英雄位置，更新 SpinePlayer 映射，重建行动队列，推进战斗
- **关键细节**：
  - 保存旧 SpinePlayer 引用
  - 修改 heroes 数组
  - 重建 `_spine_players` 和 `_spine_current_state` 字典，确保索引与新位置对齐
  - 调用 `turn_queue.build()` 重新排序

---

#### `_on_monster_pressed(index: int) -> void`
- **触发时机**：玩家点击敌人卡片
- **条件**：`single_enemy` 类型技能
- **功能**：执行技能 → 检查胜利 → 推进回合

---

#### `_on_attack_all_enemies() -> void`
- **触发时机**：玩家点击"攻击全体"按钮
- **条件**：`all_enemies` 类型技能
- **功能**：过滤有效目标 → 执行群体技能 → 检查胜利

---

#### `_on_ally_pressed(index: int) -> void`
- **触发时机**：玩家点击友方英雄卡片
- **条件**：`single_ally` 类型技能
- **功能**：执行技能 → 推进回合

---

#### `_on_cancel_skill() -> void`
- **触发时机**：玩家点击取消按钮
- **功能**：清除技能选择，回到选择技能状态

---

#### `_on_back_pressed() -> void`
- **功能**：发出 `return_to_start` 信号

---

#### `_create_spine_player_for_hero(hero_index: int) -> void`
- **功能**：创建 SpinePlayer，scale = (0.5, 0.5)，加入场景树，缓存，加载初始动画 "idle"

---

#### `_create_spine_player_for_monster(monster_index: int) -> void`
- **功能**：创建 SpinePlayer，scale = (-0.5, 0.5)（水平镜像，面向左），加入场景树，缓存，加载初始动画 "idle"

---

#### `_load_hero_anim(hero_index: int, state: String) -> void`
- **功能**：根据英雄 ID 选择路径常量，拼出 .skel / .atlas 路径，加载动画
- **去重优化**：若当前状态已等于目标状态，直接返回

---

#### `_load_monster_anim(monster_index: int, state: String) -> void`
- **功能**：根据怪物 ID 选择路径常量，拼出 .skel / .atlas 路径，加载动画
- **去重优化**：若当前状态已等于目标状态，直接返回

---

#### `_update_crusader_animations() -> void`
- **功能**：遍历所有英雄，根据战斗状态选择动画
- **状态映射**：
  - `hp <= 0` → "combat"
  - 是当前行动者且已选技能 → "attack"
  - 是当前行动者未选技能 → "combat"
  - 其他 → "idle"

---

#### `_update_monster_animations() -> void`
- **功能**：遍历所有怪物，根据战斗状态选择动画
- **状态映射**：
  - `hp <= 0` → "combat"
  - 是当前行动者 → "attack"
  - 其他 → "idle"

---

#### `_update_ui() -> void`
- **功能**：依次调用 `_update_crusader_animations()`、`_update_monster_animations()`、`_update_list_ui()`、`_update_selected_text()`、`_update_character_portrait()`、`_update_skill_buttons()`
- **副作用**：同步 skip_button 和 reposition_button 的启用/禁用状态

---

#### `_update_list_ui() -> void`
- **功能**：动态构建英雄列表和敌人列表 UI
- **关键优化**：使用 `queue_free()` 清理旧节点，所有按钮信号用 `CONNECT_DEFERRED`
- **流程**：
  1. 提取当前技能的 `target_type` 和 `target_positions`
  2. 清空旧 UI（`_clear_children()`）
  3. 遍历英雄，调用 `_make_hero_content()` 生成 UI
  4. 遍历敌人，调用 `_make_monster_content()` 生成 UI

---

#### `_update_selected_text() -> void`
- **功能**：更新 `selected_label` 的状态描述文本
- **规则**：战斗结束 → Victory/Defeat；技能选择中 → 目标类型提示；待选技能 → "choose skill"；怪物行动 → "attacking..."

---

#### `_update_character_portrait() -> void`
- **功能**：加载并显示当前行动英雄的头像
- **路径格式**：`res://characters/{hero_name}/{hero_name}_guild_header.png`
- **清理**：若文件不存在，portrait_box 保持空白

---

#### `_update_skill_buttons() -> void`
- **功能**：根据技能选择状态生成技能图标或选择提示
- **未选技能模式**：显示技能图标（加载 `{hero}.ability.{one|two|...}.png`）
- **已选技能模式**：根据 `target_type` 显示提示（"Select Enemy"、"Select Ally" 或 "Attack All"）
- **取消按钮**：始终显示在第二个技能框
- **关键优化**：所有按钮信号使用 `CONNECT_DEFERRED`

---

#### `_make_hero_content(hero: Dictionary, idx: int, target_type: String, target_positions: Array) -> VBoxContainer`
- **功能**：调用 `_make_hero_slot()` 生成英雄 UI

---

#### `_make_hero_slot(hero: Dictionary, idx: int, target_type: String, target_positions: Array) -> Control`
- **功能**：为单个英雄单元绘制卡槽 UI面板（包含生命状态、速度姿态及全新**暗紫压力指示器**）
- **位置配置**（中心锚点，对应 hero_slots 预设位置）：
  ```
  位置 0: offset (-57, 88, -15, 111)
  位置 1: offset (-55, 88, -13, 111)
  位置 2: offset (-55, 88, -13, 111)
  位置 3: offset (-55, 88, -13, 111)
  ```
- **UI 元素**（VBoxContainer 内呈纵向线性排开）：
  - 速度标签：显示有效速度（`speed` + `speed_delta`），黄色前景色。
  - 头像/按钮区：100×120像素。换位模式、被选目标模式下呈现交互按钮；有骨骼角色处作为 SpinePlayer 渲染所需的对齐锚点。
  - 生命条：100×14像素，ProgressBar。
  - HP 数值文本：形如 `"HP / Max_HP"`。
  - **压力刻度条 (ProgressBar)**：
    - 尺寸结构：100×14像素。
    - 数值范围：`min_value = 0`，`max_value = 200`（上限200点）。
    - 纹理重设：动态注入 `StyleBoxFlat` 主题框，将前置填充色彩填充为**深暗神秘色调的紫色**（`Color(0.6, 0.2, 0.7, 1.0)`），忠实重现暗黑地牢风格。
  - **压力数值文本 (Label)**：
    - 格式化输出：`"Stress: N/200"`。
    - 主题配色：选用淡粉紫色偏冷色调字体颜色（`Color(0.9, 0.4, 0.9, 1)`），便于用户追踪。
  - 选中指示器：若为当前行动者则显示 ▲ 指针。
- **按钮逻辑**：
  - 换位模式且英雄活着 → 可点击换位
  - 技能模式且满足单体对友目标类型及位置集限制 → 呈现高亮选择按钮
  - 否则作为空置遮罩渲染
- **关键点**：所有 Button 的 `pressed` 信号使用 `CONNECT_DEFERRED` 延迟执行，防止在事件调用链生命期内产生由于数组突变导致的节点操作崩溃。

---

#### `_make_monster_content(monster: Dictionary, idx: int, target_type: String, target_positions: Array) -> VBoxContainer`
- **功能**：调用 `_make_monster_slot()` 生成怪物 UI

---

#### `_make_monster_slot(monster: Dictionary, idx: int, target_type: String, target_positions: Array) -> Control`
- **功能**：为单个怪物生成 UI（Button 或信息展示）
- **位置配置**（中心锚点，对称英雄位置，对应 monster_slots 预设位置）：
  ```
  位置 0: offset (15, 40, 57, 111)    // 对称 HeroSlot1 的 (-57, 88) → (15, 40)
  位置 1: offset (13, 40, 55, 111)    // 对称 HeroSlot2 的 (-55, 88) → (13, 40)
  位置 2: offset (13, 40, 55, 111)    // 对称 HeroSlot3
  位置 3: offset (13, 40, 55, 111)    // 对称 HeroSlot4
  ```
- **重要说明**：
  - `offset_top = 40` 而非 88，因为 MonsterArea 容器高度不同
  - 英雄和怪物区在视觉上完全对称，脚线（约 90% 处）对齐
- **UI 元素**（VBoxContainer 内）：
  - 速度标签（褐色，font_size=13）
  - 头像/按钮（100×120）
  - 血条（100×14，ProgressBar）
  - HP 数值（font_size=11）
  - 选中指示器（▲ 如为当前行动者）
- **按钮逻辑**：
  - 技能模式且 `target_type == "single_enemy"` → 可点击选择按钮
  - 否则显示 ColorRect 或标签
- **关键点**：所有 Button 的 `pressed` 信号使用 `CONNECT_DEFERRED`

---

#### `_clear_children(node: Node) -> void`
- **功能**：删除 `node` 的所有子节点
- **实现**：调用 `queue_free()` 延迟删除，避免在信号处理中访问已删除节点
- **时序**：
  1. 旧节点标记为删除
  2. 新节点创建，信号用 `CONNECT_DEFERRED` 延迟执行
  3. 帧末旧节点实际删除
  4. 下一帧信号回调执行

**运行时数据字段**：

```
英雄 Dictionary：
  "name"              : String  — 名称
  "hp"                : int     — 当前血量
  "max_hp"            : int     — 最大血量
  "attack"            : int     — 攻击力（来自 HeroConfig 模板）
  "speed"             : int     — 基础速度（不变）
  "speed_delta"       : int     — 本轮速度浮动（每轮随机 randi_range(-4, 4)）
  "actions_remaining" : int     — 本轮剩余行动次数
  "skills"            : Array   — 技能 ID 列表
  "index"             : int     — 在 heroes 数组中的索引

怪物 Dictionary（以上字段均有，另加）：
  "speed_delta_base"  : int     — 已废弃，速度浮动现由 BattleController 随机生成
  attack 来自 MonsterConfig 模板
```

---

#### `_ready() -> void`
- **触发时机**：Battle.tscn 加载完成时
- **调用链**：`_setup_battle()` → `_start_new_round()` → `_get_next_actor()`
- **信号连接**：
  - `back_button.pressed` → `_on_back_pressed()`
  - `reposition_button.pressed` → `_on_reposition_pressed()`
  - `skip_button.pressed` → `_on_skip_pressed()`

---

#### `_setup_battle() -> void`
- **功能**：清空并重新初始化 `heroes` 与 `monsters` 数组，重置所有战斗状态变量
- **数据来源**：
  - 英雄：`HeroConfig.get_team_heroes()`
  - 怪物：`MonsterConfig.get_encounter_monsters()`
- **SpinePlayer 初始化**：对每个 id 为 `"crusader"` 或 `"highwayman"` 的英雄调用 `_create_spine_player_for_hero(i)`

---

#### `_start_new_round() -> void`
- **功能**：递增 `round_number`，重置所有存活单位的 `actions_remaining = 1` 和 `speed_delta`，调用 `turn_queue.build(heroes, monsters)`
- **速度浮动来源**：
  - 英雄 & 怪物：`randi_range(-SPEED_DELTA_RANGE, SPEED_DELTA_RANGE)`，每轮独立随机

---

#### `_advance_action() -> void`
- **功能**：若当前行动者是英雄则递减其 `actions_remaining`，然后调用 `_get_next_actor()`

---

#### `_get_next_actor() -> void`
- **功能**：`while true` 循环驱动整个行动流转
- **流程**：
  1. `battle_over` → return
  2. 队列空 + 有剩余行动 → 重建队列，continue
  3. 队列空 + 无剩余行动 → `_start_new_round()`，continue
  4. `turn_queue.pop_next_alive()` 取单位；空则 continue（全死了）
  5. 英雄 → 重置技能状态，`_update_ui()`，**return**（等待玩家输入）
  6. 怪物 → `_execute_monster_action()`，continue（自动推进）

---

#### `_execute_monster_action() -> void`
- **功能**：自动决策并执行当前轮次怪物的AI行为（施法与攻击）
- **流程**：
  1. **安全性检查**：校验当前行动者是否有效且为怪物，怪物 `hp` 是否大于0。
  2. **行动点扣除**：在决策前立即扣除行动点：`actions_remaining -= 1`，彻底规避卡死或死循环。
  3. **可用技能筛查**：匹配技能配置 `use_positions` 字段，验证当前所处的 1-4 站位（`index + 1`）是否在技能可用范围内。
  4. **候选目标搜寻**：调用 `_get_valid_targets_for_monster()` 搜寻满足当前技能配置站位范围限制、且还处于存活状态的英雄/怪物。
  5. **技能与目标AI路由**：从挑选出的候选技能组合中随机抽选之一。若技能的目标为 `single_enemy` 或 `single_ally`，则根据技能的 `target_priority`（例如 `lowest_hp`，`highest_stress`，`random`）调用 `_select_target_by_priority()` 索敌，交由 `ActionResolver.resolve_on_target()` 处理。若为群攻或自身，对应进行群体伤害分发或应用。若无合适候选技能则安全执跳过。
  6. **状态检验与刷新**：检查英雄是否被击败，更新 UI。

---

#### `_count_alive(units: Array[Dictionary]) -> int`
- **返回值**：`hp > 0` 的单位数量

---

#### `_first_alive(units: Array[Dictionary]) -> Dictionary`
- **返回值**：第一个 `hp > 0` 的单位；无存活时返回 `{}`

---

#### `_check_victory() -> bool`
- **功能**：所有怪物死亡时调用 `_end_battle()`，返回 `true`

---

#### `_check_defeat() -> bool`
- **功能**：所有英雄死亡时调用 `_end_battle()`，返回 `true`

---

#### `_end_battle() -> void`
- **功能**：设置 `battle_over = true`，清空 `current_actor`，显示 `victory_panel`，刷新 UI

---

#### `_can_act() -> bool`
- **功能**：验证当前英雄是否可执行技能（非战斗结束 + 行动者非空 + 是英雄 + 已选技能 + 英雄存活）
- **调用方**：`_on_monster_pressed()`、`_on_attack_all_enemies()`、`_on_ally_pressed()`

---

#### `_finish_hero_action() -> void`
- **功能**：处理英雄行动完成后的后续流程，尤其是计算与解析**技能附带的主动位移效果**
- **逻辑流程**：
  1. **读取技能位移字段**：如果当前英雄有选中的技能，在配置字典中读取 `move_forward` 整数值。
  2. **位移索引计算**：
     - 若 `move_forward > 0`（如十字军“神圣矛” `move_forward = 1`）：将当前英雄在 `heroes` 中的索引 `src_index` 向左（排头方向，也是前排方向）推移，换算目标索引：`target_index = clamp(src_index - move_forward, 0, max_index)`。
     - 若 `move_forward < 0`（如强盗“贴身射击” `move_forward = -1`）：将当前英雄向后方（排尾方向）推移，换算目标索引：`target_index = clamp(src_index - move_forward, 0, max_index)`。
  3. **应用位移矩阵**：
     - 如果满足 `target_index != src_index`，首先扣除前一个英雄所处对应位置的剩余行动次数 `actions_remaining -= 1`。
     - 调用 `_apply_hero_reposition_position(src_index, target_index)` 执行物理数组顺序移动与 Spine 动画及 UI 锚点映射表重建。
     - 立即调用 `turn_queue.build()` 实现在位移条件下的**重新排队排序**，并调用 `_get_next_actor()` 拉取新状态继续推进。
  4. **常规推进**：若没有发生位移，则直接重置技能选择状态（`hero_skill_selected = false`、`hero_current_skill = ""`），并调用 `_advance_action()` 结束此项回合。

---

#### `_on_skill_pressed(skill_id: String) -> void`
- **触发时机**：玩家点击技能按钮
- **功能**：验证当前英雄站位是否在技能的 `use_positions` 内；通过验证后设置 `hero_current_skill`、`hero_skill_selected = true`，调用 `_update_ui()`；不符合站位时直接返回（即使按钮被点击也不生效）

---

#### `_on_skip_pressed() -> void`
- **触发时机**：玩家点击跳过按钮（使用 ability_pass.png 纹理的 TextureButton）
- **功能**：跳过当前英雄的行动，进入下一个行动单位的回合
- **实现流程**：
  1. 重置技能选择状态（`hero_skill_selected = false`、`hero_current_skill = ""`）
  2. 退出换位模式（`reposition_mode = false`）
  3. 调用 `_advance_action()` 推进战斗流程
- **使用场景**：英雄决定放弃本回合的行动，直接进入下一单位的行动
- **按钮状态**：英雄行动时启用，非英雄行动时禁用（与换位按钮的启用状态相同）

---

#### `_on_reposition_pressed() -> void`
- **触发时机**：玩家点击"换位"按钮
- **功能**：切换 `reposition_mode` 的开/关状态
- **实现流程**：
  1. 若 `reposition_mode == false`（进入换位模式）：
     - 设置 `reposition_mode = true`
     - 重置技能选择状态（`hero_skill_selected = false`、`hero_current_skill = ""`）
     - 更新按钮文字为"Cancel Reposition"
     - 调用 `_update_ui()` 刷新显示
  2. 若 `reposition_mode == true`（退出换位模式）：
     - 设置 `reposition_mode = false`
     - 更新按钮文字为"Reposition"
     - 调用 `_update_ui()` 刷新显示
- **注意**：换位模式与技能选择互斥；进入换位模式会自动清除任何已选技能

---

#### `_on_hero_reposition_target(target_idx: int) -> void`
- **触发时机**：换位模式下玩家点击目标英雄卡片
- **参数**：`target_idx` — 目标英雄在 `heroes` 数组中的索引
- **功能**：执行当前英雄与目标英雄的位置互换
- **位移规则**（循环移位）：
  - 若 `src_idx < target_idx`（右移）：当前英雄向右移动，中间英雄左移补位
  - 若 `src_idx > target_idx`（左移）：当前英雄向左移动，中间英雄右移补位
  - 示例：4个英雄 [A,B,C,D]，A(索引0)与C(索引2)交换 → [C,B,A,D]
- **实现流程**：
  1. 保存当前英雄索引 `src_idx` 和目标英雄索引 `target_idx`
  2. 保存旧 SpinePlayer 节点和动画状态引用（因为接下来要修改数组）
  3. 使用循环移位算法重新排列 `heroes` 数组
  4. 更新所有英雄的 `index` 字段以匹配新位置
  5. 重建 `_spine_players` 字典：根据新位置索引映射 SpinePlayer 节点
  6. 重建 `_spine_current_state` 字典：根据新位置索引映射动画状态
  7. 扣除当前英雄的 `actions_remaining`（换位消耗一个行动）
  8. 调用 `turn_queue.build()` 重新构建行动队列（使队列内的索引与新位置对齐）
  9. 退出换位模式（`reposition_mode = false`）
  10. 调用 `_update_ui()` 刷新所有 UI（包括人物模型、血条、按钮状态）
  11. 调用 `_get_next_actor()` 推进战斗流程
- **重要细节**：
  - SpinePlayer 节点 index 必须始终匹配 heroes 数组 index，否则人物动画状态会错乱
  - 互换后需要立即重建队列，否则队列内的 index 指向错误的单位
  - 使用 `queue_free()` 而非 `free()` 延迟节点删除，避免信号处理期间的崩溃

---

#### `_on_skill_pressed(skill_id: String) -> void`
- **触发时机**：玩家点击技能图标
- **功能**：设置当前选择的技能并进入目标选择模式
- **实现流程**：
  1. 安全检查：战斗结束、当前行动者不是英雄 → 返回
  2. 从 SkillConfig 获取技能数据
  3. 验证当前英雄是否能在该位置使用此技能（检查 `use_positions` 数组）
     - 若英雄位置不在使用位置范围内，返回（无反馈）
  4. 设置 `hero_current_skill = skill_id` 和 `hero_skill_selected = true`
  5. 调用 `_update_ui()` 刷新 UI：
     - 技能按钮消失，替换为目标选择提示
     - 英雄/敌人卡片变为可点击按钮（若技能需要目标选择）
- **调用方**：技能图标 Button 的 pressed 信号

---

#### `_on_cancel_skill() -> void`
- **触发时机**：玩家点击取消按钮
- **功能**：退出技能选择，回到选择技能状态
- **实现流程**：
  1. 设置 `hero_skill_selected = false` 和 `hero_current_skill = ""`
  2. 调用 `_update_ui()` 刷新 UI 回到技能图标显示
- **调用方**：取消按钮 Button 的 pressed 信号

---

#### `_on_monster_pressed(index: int) -> void`
- **触发时机**：玩家点击敌人卡片进行目标选择
- **条件**：仅在 `single_enemy` 类型技能的目标选择期间可点击
- **功能**：对选中的敌人执行技能
- **实现流程**：
  1. 安全检查：`_can_act()` 验证当前是英雄行动且可以行动
  2. 检查敌人索引有效性和血量 > 0
  3. 从 SkillConfig 获取当前技能配置
  4. 调用 `ActionResolver.resolve_on_target(heroes[当前英雄], 技能配置, monsters[敌人])`
  5. 检查胜利条件 `_check_victory()`
     - 若游戏结束，返回
     - 否则推进回合 `_finish_hero_action()`
- **调用方**：敌人卡片 Button 的 pressed 信号（当 `target_type == "single_enemy"` 时）

---

#### `_on_attack_all_enemies() -> void`
- **触发时机**：玩家点击"Attack (pos X, Y, ...)"按钮
- **条件**：仅在 `all_enemies` 类型技能的目标选择期间可点击
- **功能**：对所有有效目标执行群体技能
- **实现流程**：
  1. 安全检查：`_can_act()` 验证当前是英雄行动且可以行动
  2. 从 SkillConfig 获取当前技能配置
  3. 获取技能的 `target_positions` 数组：
     - 若为空数组，表示无位置限制，命中所有怪物
     - 若为 [1,2,3] 等，仅命中指定位置的怪物
  4. 过滤敌人列表，仅保留"存活且在有效位置"的敌人
  5. 调用 `ActionResolver.resolve_on_all(heroes[当前英雄], 技能配置, 过滤后的敌人列表)`
  6. 检查胜利条件 `_check_victory()` 并推进回合
- **示例**：shotgun 技能 `target_positions = [1, 2, 3]`，因此对位置 1/2/3 的敌人各造成伤害
- **调用方**：攻击按钮 Button 的 pressed 信号（当 `target_type == "all_enemies"` 时）

---

#### `_on_ally_pressed(index: int) -> void`
- **触发时机**：玩家点击友方英雄卡片进行目标选择
- **条件**：仅在 `single_ally` 类型技能的目标选择期间可点击
- **功能**：对选中的友方英雄执行技能
- **实现流程**：
  1. 安全检查：`_can_act()` 验证当前是英雄行动且可以行动
  2. 检查目标英雄索引有效性
  3. 从 SkillConfig 获取当前技能配置
  4. 调用 `ActionResolver.resolve_on_target(heroes[当前英雄], 技能配置, heroes[目标英雄])`
  5. 推进回合 `_finish_hero_action()`
- **调用方**：友方英雄卡片 Button 的 pressed 信号（当 `target_type == "single_ally"` 时）

---

#### `_on_back_pressed() -> void`
- **功能**：发出 `return_to_start` 信号

---

#### `_create_spine_player_for_hero(hero_index: int) -> void`
- **功能**：创建 `SpinePlayer` 节点，设置 `scale = Vector2(0.5, 0.5)`，加入场景树并缓存到 `_spine_players`，然后调用 `_load_hero_anim(hero_index, "idle")` 载入初始动画

---

#### `_play_skill_fx_v2(caster: Dictionary, skill_id: String, targets: Array) -> void`
- **功能**：施放指定技能时，在施法者（Caster）和对应目标群（Targets）坐标处，自适应朝面加载独立的 Spine 特效资产。
- **机制与公式**：
  1. 通过 `_get_spine_player_ref_info()` 获取演员实例。
  2. 检索自定义配置 `SKILL_FX_MAP` 获取资源基本路径（`caster_fx` 或 `target_fx`）、局部偏移坐标（`caster_offset` 或 `target_offset`）和缩放大小（`caster_scale` 或 `target_scale`）。
  3. 执行 `flip` 状态物理镜像运算。若目标呈现反向姿态（即 `scale.x < 0`），则坐标偏移自动取极性变换：`offset.x = -offset.x`。
  4. 追加调用底层单体容器 `_play_fx_at_position(...)` 生成特效。

---

#### `_play_fx_at_position(global_pos: Vector2, skel_path: String, atlas_path: String, png_dir: String, flip: bool, scale_multiplier: float) -> void`
- **功能**：在指定的全局物理坐标点临时生成并播毕 1 秒左右的纯 Spine 动画粒子图层后自动卸载销毁。
- **技术要点**：
  * 使用硬磁盘文件检测 `FileAccess.file_exists(...)` 进行双重装载防御，如果文件不存在，触发警告退出。
  * 实例化全新 `SpinePlayer` 节点并将 `z_index` 置为高于普通角色的重叠图层等级 `20`。
  * 特效播放完成后通过定时器触发回调连接 `queue_free()` 自动卸载，完美防止运行期内存泄露。

---

#### `_load_hero_anim(hero_index: int, state: String) -> void`
- **功能**：根据 `heroes[hero_index]["id"]` 自动选择 Crusader 或 Highwayman 的路径常量，拼出 `.skel` 和 `.atlas` 路径，调用 `SpinePlayer.load_character()` 并 `play(anim_file)`
- **去重优化**：若 `_spine_current_state[hero_index]` 已等于 `state`，直接返回，不重复加载
- **状态别名**：`_load_crusader_anim()` 保留为 `_load_hero_anim()` 的兼容包装

---

#### `_update_crusader_animations() -> void`
- **功能**：遍历所有有 SpinePlayer 的英雄（crusader 和 highwayman），根据当前战斗状态调用 `_load_hero_anim()`：
  - `hp <= 0` → `"combat"`
  - 是当前行动者且已选技能 → `"attack"`
  - 是当前行动者未选技能 → `"combat"`
  - 其他（待机）→ `"idle"`

---

#### `_update_ui() -> void`
- **功能**：依次调用 `_update_crusader_animations()`、`_update_list_ui()`、`_update_selected_text()`、`_update_skill_buttons()`，同步更新 `skip_button.disabled`、`reposition_button.disabled` 及按钮文字

---

#### `_update_list_ui() -> void`
- **功能**：动态构建英雄列表和敌人列表，根据战斗状态显示不同样式
- **安全设计**：使用 `queue_free()` 清理旧 UI 节点，并在所有新按钮信号连接上使用 `CONNECT_DEFERRED` 标志，确保信号处理延迟到下一帧，避免触发"Object was freed"错误和 HP 血条显示重叠的问题
- **实现流程**：
  1. 若当前英雄已选技能，从技能配置中提取 `target_type` 和 `target_positions`
  2. **英雄区**（左侧）：遍历所有英雄，为每个英雄调用 `_make_hero_slot()`
     - 传入 `target_type` 和 `target_positions`
     - 若是换位模式（`reposition_mode == true`），所有活着的英雄（除当前英雄外）都变成可点击的换位目标按钮
     - 若 `target_type == "single_ally"` 且该英雄在有效目标位置，则渲染为可点击 Button
     - 否则显示英雄名称或 ColorRect（SpinePlayer 锚点）
  3. **敌人区**（右侧）：遍历所有敌人，为每个敌人调用 `_make_monster_slot()`
     - 传入 `target_type` 和 `target_positions`
     - 若 `target_type == "single_enemy"` 且该敌人在有效目标位置，则渲染为可点击 Button
     - 否则显示敌人名称或 ColorRect
  4. **位置约束**：技能的 `target_positions` 为 [1,2,3,4] 位置编号；若为空数组，表示无位置限制
  5. **清理旧UI**：删除前一回合的 UI（`_clear_children()` 使用 `queue_free()` 延迟删除）
- **调用方**：`_update_ui()`
- **关键细节**：所有创建的按钮必须在 `pressed` 信号连接时添加 `CONNECT_DEFERRED`，这是本函数的核心安全措施

---

#### `_update_selected_text() -> void`
- **功能**：更新 `selected_label` 的状态描述文本
- **显示规则**：战斗结束 → Victory/Defeat；英雄选技能中 → 选目标/选友方/全体 提示；英雄待选技能 → choose skill；怪物行动 → attacking...

---

#### `_make_hero_slot(idx: int, target_type: String, target_positions: Array) -> Control`
- **功能**：为单个英雄单元绘制卡槽 UI面板（包含生命状态、速度姿态及全新**暗紫压力指示器**）
- **参数**：
  - `idx` — 英雄在 heroes 数组中的索引
  - `target_type` — 当前技能的目标类型（`"single_ally"` / `"all_allies"` / 其他）
  - `target_positions` — 当前技能可以命中的位置数组
- **返回值**：生成的 Control 节点，添加到英雄列表容器
- **逻辑流程**：
  - **位置与容器配置**（中心锚点，对应 hero_slots 预设位置）：
    ```
    位置 0: offset (-57, 88, -15, 111)
    位置 1: offset (-55, 88, -13, 111)
    位置 2: offset (-55, 88, -13, 111)
    位置 3: offset (-55, 88, -13, 111)
    ```
  - **UI 元素装配**（VBoxContainer 内呈纵向线性排开）：
    1. 速度标签：显示有效速度（`speed` + `speed_delta`），黄色前景色。
    2. 头像/按钮区：100×120像素。换位模式、被选目标模式下呈现交互按钮；有骨骼角色处作为 SpinePlayer 渲染所需的对齐锚点。
    3. 生命条：100×14像素，ProgressBar。
    4. HP 数值文本：形如 `"HP / Max_HP"`。
    5. **压力刻度条 (ProgressBar)**：
       - 尺寸结构：100×14像素。
       - 数值范围：`min_value = 0`，`max_value = 200`（上限200点）。
       - 纹理重设：动态注入 `StyleBoxFlat` 主题框，将前置填充色彩填充为**深暗神秘色调的紫色**（`Color(0.6, 0.2, 0.7, 1.0)`），忠实重现暗黑地牢风格。
    6. **压力数值文本 (Label)**：
       - 格式化输出：`"Stress: N/200"`。
       - 主题配色：选用淡粉紫色偏冷色调字体颜色（`Color(0.9, 0.4, 0.9, 1)`），便于用户追踪。
    7. 选中指示器：若为当前行动者则显示 ▲ 指针。
- **关联信号**：
  - **换位模式** && 英雄活着 && 不是当前行动者：创建可点击 Button，连接 `_on_hero_reposition_target(idx)` 信号，使用 `CONNECT_DEFERRED`
  - **技能模式** && `target_type == "single_ally"` && 英雄位置有效 && 英雄活着：创建可点击 Button，连接 `_on_ally_pressed(idx)` 信号，使用 `CONNECT_DEFERRED`
  - 其他情况：创建信息标签或 ColorRect（用于放置 SpinePlayer 节点）
- **关键点**：所有 Button 的 `pressed` 信号都必须使用 `CONNECT_DEFERRED` 以确保内存安全性与生命期防御。

---

#### `_make_monster_slot(idx: int, target_type: String, target_positions: Array) -> Control`
- **功能**：为单个敌人生成 UI 节点（Button 或信息展示）
- **参数**：
  - `idx` — 敌人在 monsters 数组中的索引
  - `target_type` — 当前技能的目标类型（`"single_enemy"` / `"all_enemies"` 等）
  - `target_positions` — 当前技能可以命中的位置数组；空数组表示无限制
- **返回值**：生成的 Control 节点，添加到敌人列表容器
- **逻辑**：
  - **技能模式** && `target_type == "single_enemy"` && 敌人位置有效 && 敌人活着：创建可点击 Button，连接 `_on_monster_pressed(idx)` 信号，使用 `CONNECT_DEFERRED`
  - 其他情况：创建敌人名称标签或 ColorRect
- **关键点**：所有 Button 的 `pressed` 信号都必须使用 `CONNECT_DEFERRED`

---

#### `_update_character_portrait() -> void`
- **功能**：动态加载并显示当前行动英雄的头像（guild_header.png）
- **实现流程**：
  1. 检查当前行动者是否为英雄，否则返回
  2. 获取英雄名字，构造头像路径：`res://characters/{hero_name}/{hero_name}_guild_header.png`
  3. 清空旧头像（`_clear_children(portrait_box)`）
  4. 若资源存在，加载纹理并创建 TextureRect：
     - `expand_mode = TextureRect.EXPAND_IGNORE_SIZE`（完整填满100×80框）
     - `layout_mode = 1`，anchors_preset = 15（全填充）
     - 添加到 `portrait_box`
  5. 若文件不存在，portrait_box 保持空白
- **调用方**：`_update_ui()`
- **关键参数**：portrait_box（ColorRect，100×80，位置 offset_left=100, offset_top=-80）

---

#### `_update_skill_buttons() -> void`
- **功能**：根据技能选择状态动态生成技能图标或选择提示，并同步更新按钮的启用/禁用状态
- **关键优化**：所有按钮信号连接使用 `CONNECT_DEFERRED` 标志，确保信号处理延迟到下一帧执行，避免在 UI 清理期间引发信号处理异常。这是防止"Object was freed or unreferenced while signal is being emitted from it"崩溃和血条显示重叠的关键
- **按钮启用/禁用逻辑**：
  - 非英雄行动时（`current_actor.get("unit_type") != "hero"`）：禁用 `skip_button` 和 `reposition_button`，清空技能框
  - 英雄行动时：启用 `skip_button` 和 `reposition_button`
- **实现流程**：

##### 未选技能模式（hero_skill_selected=false）
1. 遍历当前英雄的技能列表（`heroes[current_actor["index"]]["skills"]`）
2. 对每个技能，构造图标路径：`res://characters/{hero_name}/{hero_name}.ability.{number}.png`（number="one"~"eight"）
3. 若文件存在，创建 Button：
   - `layout_mode = 1`, `anchors_preset = 15`
   - `icon = icon_texture`，`icon_alignment = HORIZONTAL_ALIGNMENT_CENTER`
   - 完全填满 `skill_icon_boxes[skill_idx]`（50×50）
   - `btn.pressed.connect(_on_skill_pressed.bind(skill_id))`
4. 若文件不存在，该技能位置不显示任何内容

##### 已选技能模式（hero_skill_selected=true）
根据技能的 `target_type` 显示对应 UI：

- **all_enemies**：在 `skill_icon_boxes[0]` 显示"Attack (pos X, Y, ...)"按钮
  - 若技能无 target_positions 约束，显示"Attack\nAll"
  - 否则显示实际命中位置，如"Attack\n(1, 2)"
  - 点击连接 `_on_attack_all_enemies()`

- **single_ally**：在 `skill_icon_boxes[0]` 显示"Select\nAlly"黄色标签
  - Color(1.0, 0.9, 0.2, 1)，font_size=10，居中对齐
  - 表示用户应点击友方英雄进行选择

- **single_enemy**：在 `skill_icon_boxes[0]` 显示"Select\nEnemy"红色标签
  - Color(0.8, 0.3, 0.3, 1)，font_size=10，居中对齐
  - 表示用户应点击敌人进行选择

- **取消按钮**（始终显示）：在 `skill_icon_boxes[1]` 显示"X"按钮
  - font_size=12，点击连接 `_on_cancel_skill()`
  - 允许用户退出技能选择

- **清空其他技能框**：skill_icon_boxes[2] 及以后的框清空内容

- **调用方**：`_update_ui()`
- **依赖**：SkillConfig.get_skill()、skill_icon_boxes（Array[ColorRect]，4个50×50框）

---

#### `_clear_children(node: Node) -> void`
- **功能**：删除 `node` 的所有子节点，为 UI 重建做准备
- **实现方式**：调用 `queue_free()` 而非 `free()`，将节点删除延迟到当前帧末尾
- **重要性**：使用 `queue_free()` 可以防止在 UI 清理期间发出的信号尝试访问已被 `free()` 的节点，从而避免崩溃；结合 `CONNECT_DEFERRED` 标志，确保新 UI 节点完全创建后才执行信号回调
- **时序**：
  1. 帧 N：`_update_ui()` 调用 `_clear_children()`，旧节点被标记为删除
  2. 帧 N：新节点被创建，按钮信号连接使用 `CONNECT_DEFERRED`
  3. 帧 N 末：旧节点被实际删除
  4. 帧 N+1：信号回调执行，此时新节点已完全存在
- **用途**：主要用于 `_update_list_ui()` 清理英雄列表和敌人列表

---

#### 新增成员变量（v3.0）

| 变量 | 类型 | 说明 |
|------|------|------|
| `_fx_zoom_multiplier` | float | 特效缩放倍率（1.0 或 ATTACK_ZOOM_FACTOR），联动 FX 与角色同步放大 |
| `_floating_text_layer` | CanvasLayer | 浮字/压力图标专属渲染层（layer=50） |
| `monster_current_skill_id` | String | 当前怪物释放的技能 ID，用于动画路由 |

#### 新增常量（v3.0）

| 常量 | 值 | 说明 |
|------|-----|------|
| `ATTACK_ZOOM_FACTOR` | `2.0` | 攻击镜头放大倍数 |
| `ATTACK_ZOOM_DURATION` | `1.0` | 放大/特效/数字统一持续时间（秒） |
| `SKELETON_ARBALIST_ANIM_BASE` ~ `SKELETON_SPEAR_ANIM_BASE` | 各怪物路径 | 6 种骷髅怪物的 Spine 动画路径常量 |
| `SKELETON_ARBALIST_ANIM_MAP` ~ `SKELETON_SPEAR_ANIM_MAP` | Dictionary | 6 种骷髅的状态→动画文件映射 |

#### 新增函数（v3.0）

**放大系统**：

| 函数 | 职责 |
|------|------|
| `_zoom_combatant(unit, zoom_in)` | 单个单位 SpinePlayer 缩放，保存/恢复原始 scale + z_index |
| `_zoom_attack_scene(attacker, defenders, zoom_in)` | 批量缩放，设置 `_fx_zoom_multiplier`，自动去重 |

**浮字与图标系统**：

| 函数 | 职责 |
|------|------|
| `_snap_unit(unit)` | 记录 hp/stress 快照 |
| `_show_floating_number(unit, amount)` | 浮字标签生成+渐隐 tween |
| `_show_stress_seal(unit, is_heroic)` | 延迟显示压力图标 |
| `_show_stress_seal_delayed(at_pos, icon_path)` | 实际创建压力图标 TextureRect |
| `_emit_feedback(targets, snapshots)` | 比对快照差值，路由到浮字/图标 |

**怪物动画加载**（6 个骷髅分支已添加至 `_load_monster_anim` 和 `_create_spine_player_for_monster`）。

---

### 4.11 battle/TurnQueue.gd

**类名**：`TurnQueue`  
**类继承**：`extends Node`  
**职责**：战斗行动队列的完整实现——构建、排序、弹出、状态查询。由 `BattleController` 以 `TurnQueue.new()` 实例化使用。

**成员变量**：

| 变量 | 类型 | 说明 |
|------|------|------|
| `_queue` | Array[Dictionary] | 当前队列，元素格式 `{"unit_type": "hero"/"monster", "index": int}` |

---

#### `build(heroes: Array[Dictionary], monsters: Array[Dictionary]) -> void`
- **功能**：清空队列，将所有 `hp > 0` 且 `actions_remaining > 0` 的单位加入队列，然后调用 `sort_by_speed()`
- **调用方**：`BattleController._start_new_round()`、回合内队列重建时

---

#### `sort_by_speed(heroes: Array[Dictionary], monsters: Array[Dictionary]) -> void`
- **功能**：按有效速度（`speed + speed_delta`）对队列进行降序排序（快者先行动）
- **实现**：`_queue.sort_custom()` + lambda，内部调用 `_effective_speed()`

---

#### `pop_next_alive(heroes: Array[Dictionary], monsters: Array[Dictionary]) -> Dictionary`
- **返回值**：弹出队列头部第一个存活单位的条目；队列耗尽返回 `{}`
- **功能**：自动跳过战斗过程中已死亡的队列条目（`while not _queue.is_empty()` 循环）

---

#### `is_empty() -> bool`
- **返回值**：`_queue` 是否为空

---

#### `has_remaining_actions(heroes: Array[Dictionary], monsters: Array[Dictionary]) -> bool`
- **返回值**：英雄或怪物中是否仍有存活单位的 `actions_remaining > 0`
- **用途**：`BattleController._get_next_actor()` 判断是否需要开始新轮或仅重建队列

---

#### `_effective_speed(entry, heroes, monsters) -> int` *(private)*
- **功能**：返回队列条目对应单位的有效速度 = `unit["speed"] + unit["speed_delta"]`

---

#### `_is_alive(entry, heroes, monsters) -> bool` *(private)*
- **功能**：返回队列条目对应单位是否存活（`hp > 0`）

---

### 4.12 battle/ActionResolver.gd

**类名**：`ActionResolver`  
**类继承**：`extends Node`  
**模式**：全静态方法类（无实例变量）  
**职责**：封装所有伤害与治疗的数值计算和应用逻辑，与 UI 层完全解耦。

---

#### `static calculate_damage(actor: Dictionary, skill_data: Dictionary) -> int`
- **参数**：`actor` — 行动单位；`skill_data` — 技能数据
- **返回值**：整型伤害值
- **公式**：`int(actor["attack"] × skill_data["attack_ratio"])`

---

#### `static apply_damage(target: Dictionary, amount: int) -> void`
- **功能**：对目标扣血，结果不低于 0
- **实现**：`target["hp"] = max(target["hp"] - amount, 0)`；`target` 为空字典时安全返回

---

#### `static apply_heal(target: Dictionary, amount: int) -> void`
- **功能**：对目标回血，结果不超过 `max_hp`
- **实现**：`target["hp"] = min(target["hp"] + amount, target["max_hp"])`；`target` 为空字典时安全返回

---

#### `static apply_stress(target: Dictionary, amount: int) -> void`
- **功能**：对目标施加并累积压力伤害（最高上限为 200 点限制）
- **触发机制**：
  1. 属性兜底校验：检查目标是否存在 `"stress"` 字段。若无（非英雄或初始化缺失）但在 `hp` 有效时原地初始化为 `0`。
  2. 累加与夹逼：将目标压力值累加相应点数后调用 `clamp(stress + amount, 0, 200)`。
  3. **满爆即死惩罚（Instant Death）**：
     - 如果压力值在此次技能伤害后累加至 `200`（或以上），则进入溢出爆发结算。
     - 立即将此角色的压力值**重置归零**（`target["stress"] = 0`）。
     - 随之通过调用 `apply_damage(target, 999)` 对其造成 **999 点致死性斩杀伤害**。

---

#### `static resolve_on_target(actor: Dictionary, skill_data: Dictionary, target: Dictionary) -> void`
- **功能**：单体执行多重路由技能，根据 `skill_data["effect_type"]` 自动路由并附加压力和二次位移：
  - `"damage"` → 调用 `apply_damage(target, calculate_damage(actor, skill_data))`。
  - `"heal"` → 调用 `apply_heal(target, skill_data["heal_amount"])`。
  - **压力技能解析**：
     - 完成伤害或恢复分发后，校验技能属性字典是否包含 `"stress_damage"` 的整型属性。
     - 若其中 `stress_damage > 0`，则立即呼叫 `apply_stress(target, stress_damage)` 累加玩家对应目标英雄的压力指标。
- **调用方**：`BattleController._on_monster_pressed()`、`_on_ally_pressed()`、`_execute_monster_action()` 中的 AI 智能施法块

---

#### `static resolve_on_all(actor: Dictionary, skill_data: Dictionary, targets: Array[Dictionary]) -> void`
- **功能**：对 `targets` 中所有 `hp > 0` 的单位依次调用 `resolve_on_target()`
- **用途**：`all_enemies` / `all_allies` 类型技能的执行入口
- **调用方**：`BattleController._on_attack_all_enemies()`

---

### 4.13 battle/LLMClient.gd

**类名**：`LLMClient`  
**类继承**：`extends Node`  
**职责**：大模型（LLM）对话客户端。支持任何与 OpenAI 标准 REST 接口兼容的云端大语言模型 API（例如 DeepSeek, Kimi, 通义千问等）进行异步、非阻塞式通信；内置本地极速 Mock 高保真降级机制，保证离线及网络瞬断情况下的生存沉浸代入感。

#### 成员变量

| 变量 | 类型 | 说明 |
|------|------|------|
| `api_key` | String | 用户配置的 API Key（若留空则自动降级采用 offline Mock） |
| `api_url` | String | REST 接口地址（默认 `https://api.deepseek.com/v1/chat/completions`） |
| `model` | String | 调用模型型号（默认 `deepseek-chat`） |

#### 降级语料库

- **`MOCK_CRUSADER_RESPONSES`** / **`MOCK_HIGHWAYMAN_RESPONSES`**：
  在断网、请求异常或大模型应答超时时，基于角色生命状态（高血量/高压力/低血量濒死）自动路由匹配对应的高质量沉浸式中文台词。

#### 关键方法

##### `get_hero_reply(hero_name: String, personality: String, player_input: String, hero_hp: int, hero_max_hp: int, hero_stress: int, monsters_count: int, parent_node: Node) -> String`
- **功能**：拼装大模型 Prompt 并向外部服务器发起异步并行的 HTTP POST 请求。
- **流程与保护保障机制**：
  1. **系统预设Prompt构造**：将英雄名称、性格模组、玩家激励输入的文字、血量、英雄阈值、怪物多段包围重压等融合成极写实的文字上下文。
  2. **异步线程请求**：使用 `http_request.set_use_threads(true)` 进行多线程并发 IO 操作，绝不卡死 Godot 渲染主线程。
  3. **基于协程 `await` 的超时看门狗**：使用定制的 `get_tree().create_timer(3.5)`。如果请求网络迟滞等原因在 3.5 秒内无法完全收包，看门狗会立即取消 HTTP 事务，优雅释放请求节点，并退回离线缓存库，彻底杜绝出现高网络延迟而让界面等待或卡死的缺陷。
  4. **并发并列引用闭包**：使用 GDScript 字典 `req_state = {"is_completed": false, "response_data": []}` 传递信号引用，避开变量捕获循环冲突。

##### `_generate_mock_reply(is_crusader: bool, hp: int, stress: int) -> String` *(private)*
- **功能**：根据角色的低血量、高压力状态，自动路由并返回一句精准贴合语境的高质量暗黑地牢风格台词。

---

### 4.14 town/TownController.gd

**类继承**：`extends Node`  
**挂载场景**：`scenes/town/Town.tscn`  
**职责**：城镇场景的 UI 控制器（预留，核心功能待实现）。

**信号**：

| 信号名 | 说明 |
|--------|------|
| `start_battle` | 从城镇进入战斗时发出 |

**节点引用**（`@onready`）：

| 变量 | 节点路径 |
|------|---------|
| `start_button` | `$TownUI/StartBattleButton` |

---

#### `_ready() -> void`
- **功能**：连接 `start_button.pressed` → `request_start_battle()`

---

#### `request_start_battle() -> void`
- **功能**：发出 `start_battle` 信号
- **信号接收方**：`GameState._wire_scene_events()` 捕获后调用 `_goto_battle()`

---

### 4.15 ui/HudController.gd

**类继承**：`extends Control`  
**挂载场景**：`scenes/ui/Hud.tscn`  
**职责**：HUD 界面控制器（预留，当前为空实现）。

---

#### `_ready() -> void`
- **功能**：占位，无实际逻辑
- **状态**：预留，待 HUD 功能实现时填充

---

### 4.16 data/MonsterConfig.gd

**类名**：`MonsterConfig`  
**类继承**：`extends Node`  
**模式**：静态变量单例（与 `HeroConfig` 对称）  
**职责**：集中管理所有怪物模板数据，以及当前关卡的遭遇怪物配置。

**静态变量**：

```gdscript
static var MONSTERS: Dictionary = {
    "cutthroat": { "name": "Cutthroat", "max_hp": 40, "attack": 5, "speed": 4,
                    "skills": ["cutthroat_strike", "temptation"] },
    "troll":    { "name": "Troll",     "max_hp": 60, "attack": 5, "speed": 3,
                    "skills": ["troll_smash"] },
    "skeleton_arbalist": { "name": "Bone Arbalist",  "max_hp": 27, "attack": 7, "speed": 5,
                    "skills": ["arbalist_crossbow", "arbalist_bayonet"] },
    "skeleton_courtier": { "name": "Bone Courtier",  "max_hp": 22, "attack": 4, "speed": 6,
                    "skills": ["courtier_goblet", "courtier_dagger"] },
    "skeleton_common":   { "name": "Bone Soldier",   "max_hp": 32, "attack": 5, "speed": 4,
                    "skills": ["skeleton_melee"] },
    "skeleton_defender": { "name": "Bone Defender",  "max_hp": 45, "attack": 3, "speed": 2,
                    "skills": ["defender_axe", "defender_shield"] },
    "skeleton_militia":  { "name": "Bone Militia",   "max_hp": 30, "attack": 5, "speed": 4,
                    "skills": ["militia_slash"] },
    "skeleton_spear":    { "name": "Bone Spearman",  "max_hp": 30, "attack": 6, "speed": 5,
                    "skills": ["spear_thrust"] },
}
static var CURRENT_ENCOUNTER: Array[String] = ["skeleton_common", "skeleton_defender", "skeleton_arbalist", "skeleton_courtier"]
```

> `speed_delta` 现由 `BattleController._start_new_round()` 每轮随机生成，`speed_delta_base` 字段已废弃。当前遭遇为 4 只骷髅系怪物（勇士+盾卫+弩手+酒杯），用于测试 4v4 战斗与站位机制。

---

#### `static get_monster_template(monster_id: String) -> Dictionary`
- **参数**：`monster_id` — 怪物唯一标识符（如 `"goblin"`）
- **返回值**：怪物数据的深拷贝 Dictionary（附加 `id` 与 `hp` 字段）；不存在时返回 `{}`

---

#### `static get_encounter_monsters() -> Array[Dictionary]`
- **返回值**：按 `CURRENT_ENCOUNTER` 顺序构建的怪物模板数组
- **调用方**：`BattleController._setup_battle()`

---

#### `static monster_exists(monster_id: String) -> bool`
- **返回值**：怪物 ID 是否存在于 `MONSTERS` 字典

---

#### `static get_all_monster_ids() -> Array[String]`
- **返回值**：所有已注册怪物的 ID 列表


---

## 5. 数据文件说明

### data/characters.json
由 `Database.get_characters()` 加载，供 `CharacterData` 资源使用。当前游戏运行时英雄数据由 `HeroConfig.gd` 静态管理，此文件预留用于未来的数据驱动扩展。

### data/skills.json
由 `Database.get_skills()` 加载。当前游戏运行时技能数据由 `SkillConfig.gd` 静态管理。

### data/statuses.json
由 `Database.get_statuses()` 加载。状态效果系统尚未实现，此文件预留。

### data/towns.json
由 `Database.get_towns()` 加载。城镇系统尚未实现，此文件预留。

---

## 6. 已知问题与解决方案

### 问题 1：血条显示重叠
**症状**：英雄受伤后，HP 血条显示多个重叠的进度条  
**根本原因**：UI 节点清理使用 `free()` 立即删除，但新节点在同一帧创建，信号处理会尝试访问已删除节点  
**解决方案**：
- 改用 `queue_free()` 延迟节点删除至帧末尾
- 所有按钮信号连接使用 `CONNECT_DEFERRED` 标志，延迟信号处理至下一帧
- 这样可保证旧节点删除 → 新节点创建 → 信号回调执行，顺序无误

### 问题 2：信号处理期间的节点删除崩溃
**症状**：运行时出现"Object was freed or unreferenced while signal is being emitted from it"错误并崩溃  
**根本原因**：在信号回调中使用 `free()` 删除仍有活跃信号的节点  
**解决方案**：
- 所有 UI 节点清理改用 `queue_free()`
- 所有动态生成的按钮信号连接使用 `CONNECT_DEFERRED`
- 位置：_update_list_ui()、_update_skill_buttons()、_make_hero_slot()、_make_monster_slot() 中的所有 button.pressed.connect()

### 问题 3：换位后人物模型错乱
**症状**：英雄换位后，人物动画状态与位置不匹配  
**根本原因**：SpinePlayer 节点的索引需与 heroes 数组索引保持一致；位置交换后忘记更新映射  
**解决方案**：
- 在 _on_hero_reposition_target() 中，位置交换后立即重建 _spine_players 和 _spine_current_state 字典
- 根据循环移位方向（左移或右移）准确计算新索引映射
- 重建队列确保队列中的索引也与新位置对齐

---

## 7. 核心系统设计

### 7.1 行动队列系统

每一轮战斗开始时，游戏会为当前场上所有的英雄与怪物重新构建行动队列，并附加一个随机的速度浮动值：
$$\text{有效速度} = \text{基础速度 (speed)} + \text{速度浮动值 (speed\_delta)}$$
其中速度浮动范围可以通过配置自定义。所有活着的目标将按照有效速度从高到低排列。速度相同的情况下，英雄位置靠前者优先行动，实现了非常具有战术深度的博弈轮转。

### 7.2 Spine 动画运行机制

本项目集成了一套基于 Godot 运行时的 Spine 2.1.27 自定义二进制和图集解析渲染架构：
- **`SpineSkel.gd`**：以二进制流解算骨骼层次结构、动画变形、网格顶点、权重数据等。
- **`SpineAtlas.gd`**：解析文本格式图集关系。
- **`SpinePlayer.gd`**：派生自 `Node2D`。在准备载入角色骨骼时：
  1. 通过新设置的逻辑：如果下发载入的动画骨骼 `.skel` 文件与当前 `current_skel_path` 路径一致且缓存处于 `_loaded = true` 态，**坚决不重新初始化并清除 Sprite**。直接调用 `play()` 刷新时间轴。这大幅度消除了内存重建抖动和重新挂载骨架导致的零帧白白闪烁，并彻底解决了怪物的多轮动作卡死和失效 Bug。
  2. 首帧零迟延绘制：调用 `play()` 时强制执行一次 `_update_pose()`，杜绝出现一帧的空白骨骼或零位姿闪耀。

### 7.3 特效与受击痛苦反馈机制

1. **施法蓄力与普通选择解耦**：
   英雄在普通选择目标、备战、战斗待机期间，全部呈现充满张力的备战动作 (`"combat"`)。当玩家释放技能或怪物自动攻击触发，中枢标记 `_in_fx_pause = true` 并解析配置专属的个性化施法动画 `"caster_anim"`：
   - Crusader 的圣矛（Holy Spear）：呈现 `attack_charge` (冲锋准备姿势) ＋ `holy_lance` 冲锋特效。
   - Highwayman 的切开（Cut）：呈现 `attack2` (切骨斩击动作) ＋ `wicked_slice` 斩裂特效。
   
2. **多源多向的 Defend 反馈触发**：
   当任意方向伤害数值落地对撞前，所有被攻击的目标都会被设置 `is_defending = true`。对应的 UI 渲染底层会立即调取播放专属的受击动作防守文件 `defend.skel`/`defend.atlas`，展现痛苦后仰格挡，并与伤害数值特效同步展现，结束后顺滑切换回正常呼吸待机态，打击反馈在画面表达上力量感极强。

3. **双重变量锁保护**：
   在单体、AOE、友系等分支中加入了局部 `pre_current_skill` 缓存，以及对怪物 Spine 实体缓存字典的主动迁移防丢失拷贝，保证在高频拉扯、变档换位重构映射的同时，保证动作状态永远在主控制槽中连贯解析。

按钮启用规则：
  - 英雄行动时：技能按钮、跳过按钮、换位按钮都启用
  - 非英雄行动时：所有这些按钮都禁用
  - 换位模式与技能选择互斥
```

### 7.4 暗黑地牢风格镜头放大系统

**设计目标**：所有技能释放时，攻击方和目标方 Spine 骨骼角色同步放大至 200%，配合特效形成特写镜头，重现 Darkest Dungeon 的视觉冲击力。

#### 全局控制常量

```gdscript
const ATTACK_ZOOM_FACTOR := 2.0    # 放大倍数
const ATTACK_ZOOM_DURATION := 1.0  # 放大/特效/数字统一持续时间（秒）
```

#### 核心函数

| 函数 | 职责 |
|------|------|
| `_zoom_combatant(unit, zoom_in)` | 对单个单位 SpinePlayer 执行放大/恢复。放大时保存原始 scale 和 z_index 到 unit 字典（保留 x 符号以维持怪物镜像），恢复时还原 |
| `_zoom_attack_scene(attacker, defenders, zoom_in)` | 批量缩放攻击方 + 所有防御方。自动去重（`is_same` 检查），防止自指技能导致双倍缩放。同步设置 `_fx_zoom_multiplier` 联动特效缩放 |

#### 缩放时序（所有 6 条技能执行路径统一）

```
zoom in (×2) → FX 特效生成 → 伤害结算 → 浮字/图标 → timer(ATTACK_ZOOM_DURATION) → zoom out (×1)
```

- 伤害/治疗数字与压力图标在放大状态下生成，字体和标签 scale 自动适配放大倍率
- 总持续时间由 `ATTACK_ZOOM_DURATION` 统一控制（默认 1 秒）

#### 适用范围

所有技能类型均触发放大效果，不限于伤害技能：治疗、buff、self 技能同样享有放大特写。

### 7.5 浮字伤害/治疗数字系统

**设计目标**：被攻击人员旁边显示鲜红伤害数字，被治疗人员显示翠绿治疗数字，渐隐上升消失。

#### CanvasLayer 架构

- `_floating_text_layer`：专属 CanvasLayer (layer=50)，高于角色（z_index=10~25）低于 UI 弹窗（layer=100+）
- 所有浮字和图标作为其子节点，不受角色缩放变换影响

#### 核心函数

| 函数 | 职责 |
|------|------|
| `_snap_unit(unit)` | 记录单位 `{hp, stress}` 快照，供结算后比对差值 |
| `_show_floating_number(unit, amount)` | 在单位胸口位置（Y=-70）生成 Label。负数红色 `-X`，正数绿色 `+X`。放大时字体 28px + scale 1.6，正常时 18px + scale 1.0。Tween 渐隐上升持续 `ATTACK_ZOOM_DURATION` |
| `_emit_feedback(targets, snapshots)` | 比对结算前后差值，自动生成浮字和压力图标 |

#### 缩放适配

| 属性 | 正常 | 放大 (×2) |
|------|------|-----------|
| 字号 | 18px | 28px |
| Label scale | 1.0 | 1.6 |
| 轮廓宽度 | 4px | 4px |

### 7.6 压力光环图标系统

**设计目标**：压力变化时在角色头顶显示独立图标——压力下降显示金黄 `seal.heroic.png`（振奋），压力上升显示暗红 `seal.affliction.png`（折磨）。

#### 核心函数

| 函数 | 职责 |
|------|------|
| `_show_stress_seal(unit, is_heroic)` | 捕获当前 SpinePlayer 位置，延迟 `ATTACK_ZOOM_DURATION` 秒后调用实际显示函数 |
| `_show_stress_seal_delayed(at_pos, icon_path)` | 在角色头顶（Y=-160）创建 40×40 TextureRect，1 秒渐隐上升消失 |

#### 设计要点

- **延迟显示**：压力图标在放大特效结束后才出现，不与伤害数字争夺视觉焦点
- **头顶独立定位**：Y=-160（远高于伤害数字的 Y=-70），水平居中，悬挂于头顶上方约 94px
- **battle_cry 群减压**：`_on_ally_pressed` 快照全体英雄 hp/stress，`resolve_on_target` 后比对差值，受影响者头顶逐一显示 heroic 图标

### 7.7 技能特效映射系统 (SKILL_FX_MAP)

每个技能可配置独立的施法特效（`caster_fx`）、受击特效（`target_fx`）和个性化骨骼动作（`caster_anim`）。配置结构：

```gdscript
const SKILL_FX_MAP := {
    "skill_id": {
        "caster_fx": "res://path/to/caster_fx",    # 施法者特效 .skel/.atlas 路径前缀
        "target_fx": "res://path/to/target_fx",    # 受击者特效路径前缀（可选）
        "caster_anim": "attack",                    # 施法动画状态名（对应 ANIM_MAP 键）
        "caster_offset": Vector2(50, -80),          # 施法特效偏移（可选，默认 ZERO）
        "target_offset": Vector2(0, -60),           # 受击特效偏移（可选，默认躯干中央）
        "caster_scale": 1.0,                        # 施法特效缩放（可选）
        "target_scale": 1.0,                        # 受击特效缩放（可选）
    }
}
```

**骷髅怪物特效映射**（各技能使用自身 `fx/` 目录下的专属 .skel/.atlas/.png）：

| 技能 | caster_fx | target_fx | caster_anim |
|------|-----------|-----------|-------------|
| `arbalist_crossbow` | `crossbow_shot` | `crossbow_shot_target` | `attack` |
| `arbalist_bayonet` | `bayonet_jab` | — | `attack2` |
| `courtier_goblet` | `tempting_goblet` | — | `attack` |
| `courtier_dagger` | `dagger_jab` | — | `attack2` |
| `skeleton_melee` | `cudgel` | — | `attack` |
| `defender_axe` | `axe_strike` | — | `attack` |
| `defender_shield` | `shield_bash` | — | `attack2` |
| `militia_slash` | `sword_strike` | — | `attack` |
| `spear_thrust` | `spear_thrust` | — | `attack` |

### 速度浮动系统


```
有效速度 = 基础速度 (speed) + 速度浮动值 (speed_delta)

每轮开始时（_start_new_round）：
  所有存活单位（英雄 & 怪物）各自独立随机：
  speed_delta = randi_range(-4, 4)   ← SPEED_DELTA_RANGE = 4
  speed 基础值保持不变，不累加

示例（每轮结果随机，以下为某一轮可能的结果）：
  英雄 0 (Crusader)：speed=4, speed_delta=+3, 有效速度=7
  英雄 1 (Highwayman)：speed=5, speed_delta=-1, 有效速度=4
  英雄 2 (Crusader)  ：speed=4, speed_delta=+4, 有效速度=8
  英雄 3 (Highwayman)：speed=5, speed_delta= 0, 有效速度=5
  Goblin           ：speed=4, speed_delta=+2, 有效速度=6
  Troll            ：speed=3, speed_delta=-3, 有效速度=0

行动顺序（每轮不固定，按随机有效速度排序）
```

### 伤害计算公式

```
单体伤害 = ActionResolver.calculate_damage(actor, skill_data)
         = int(actor["attack"] × skill_data["attack_ratio"])
群体伤害 = 对每个存活目标分别调用 calculate_damage（ActionResolver.resolve_on_all）
怪物伤害 = monsters[idx]["attack"]（来自 MonsterConfig 模板，由 apply_damage 直接扣血）
治疗量   = skill_data["heal_amount"]（ActionResolver.apply_heal）

英雄伤害示例：
  Crusader (ATK=10) + Slash   (ratio=1.0) → 10 伤害
  Highwayman (ATK=12) + Cut     (ratio=1.0) → 12 伤害
  Highwayman (ATK=12) + Shotgun (ratio=0.5) → 6 伤害（每个怪物）
Goblin 伤害示例：
  Goblin (ATK=10) 攻击英雄 → apply_damage(target, 10)
```

### 行动队列驱动模型

```
while 循环驱动（在 _get_next_actor() 内）：

  [队列为空？]
      ↓ 是
  [有单位有剩余行动次数？]
      ↓ 是           ↓ 否
  重建队列 →→→→   开始新轮 (_start_new_round)
  continue          continue
      ↓
  [弹出行动者]
      ↓
  [行动者存活？]
      ↓ 否        ↓ 是
  continue     [是英雄？]
                   ↓ 是           ↓ 否（怪物）
               等待玩家输入    自动执行攻击
               return          continue
```

---

## 8. 扩展指南

### 添加新英雄
在 `scripts/data/HeroConfig.gd` 的 `HEROES` 字典中添加条目：
```gdscript
"warrior": {
    "name": "Warrior",
    "max_hp": 60,
    "attack": 8,
    "speed": 4,
    "skills": ["heavy_strike", "taunt"]
}
```
同时在 `SkillConfig.gd` 中添加对应技能。

### 添加新技能
在 `scripts/data/SkillConfig.gd` 的 `SKILLS` 字典中添加条目：
```gdscript
"heavy_strike": {
    "name": "Heavy Strike",
    "effect_type": "damage",
    "target_type": "single_enemy",
    "attack_ratio": 1.5,
    "description": "A powerful slow strike",
    "use_positions": [1, 2],   # 仅前排可用
    "target_positions": [1, 2] # 仅打前排敌人
}
```
`use_positions` 和 `target_positions` 均可省略（或设为空数组 `[]`），表示无站位限制。无需修改 `BattleController`，技能系统自动适配。

### 添加新技能效果类型
1. 在 `SkillConfig` 中为技能添加新的 `effect_type`（如 `"stun"`）
2. 在 `BattleController._on_monster_pressed()` / `_on_ally_pressed()` 中添加对应的 `match` 分支
3. 在英雄/怪物字典中添加对应的状态字段

### 添加新怪物
在 `scripts/data/MonsterConfig.gd` 的 `MONSTERS` 字典中添加条目：
```gdscript
"skeleton": {
    "name": "Skeleton",
    "max_hp": 30,
    "attack": 8,
    "speed": 5,
    "speed_delta_base": 0
}
```
再将 ID 加入 `CURRENT_ENCOUNTER`（或在关卡切换时覆盖该数组）。`BattleController` 无需修改。

> **注意**：怪物站位由其在 `CURRENT_ENCOUNTER` 数组中的下标决定（下标 0 = 1号位）。英雄技能的 `target_positions` 将基于此下标+1进行过滤。

### 调整遭遇配置
```gdscript
MonsterConfig.CURRENT_ENCOUNTER = ["goblin", "troll", "skeleton"]
```
在进入战斗场景前动态设置即可。

### 添加新技能效果类型
1. 在技能数据中设置新的 `effect_type`（如 `"stun"`、`"poison"`）
2. 在 `ActionResolver.resolve_on_target()` 的 `match` 中添加对应分支
3. 在英雄/怪物字典中添加必要的状态字段（如 `"stunned": bool`）
4. `BattleController` 中仅需处理 UI 反馈，计算逻辑保留在 `ActionResolver`

### 扩展 ActionResolver
所有战斗数值逻辑集中在 `ActionResolver.gd`（纯静态方法），在此添加：
- `apply_status(target, status_id)` — 施加状态
- `tick_statuses(unit)` — 回合结束时结算 DoT 等持续效果
- `calculate_crit(actor, skill_data)` — 暴击判定

---

---

### 4.16 battle/spine/SpineAtlas.gd

**类名**：`SpineAtlas`  
**类继承**：`class_name SpineAtlas`（GDScript 静态工具类）  
**职责**：解析 Spine 2.x 文本格式的 `.atlas` 文件，将每个 region 的位置、尺寸、旋转信息提取为 `Region` 对象字典，供 `SpinePlayer` 裁剪 PNG 纹理使用。

### 内部类 `Region`

| 属性 | 类型 | 说明 |
|------|------|------|
| `texture_path` | String | PNG 在 res:// 下的完整路径（`base_dir/filename.png`） |
| `x`, `y` | int | region 在图集 PNG 中的左上角像素坐标 |
| `width`, `height` | int | region 的原始像素尺寸（未旋转） |
| `rotate` | bool | 该 region 在图集中是否被顺时针旋转了 90° |
| `orig_w`, `orig_h` | int | 原始未裁剪帧尺寸（用于偏移补偿，预留） |
| `offset_x`, `offset_y` | int | 裁剪偏移（预留） |

### `static parse(text: String, base_dir: String) -> Dictionary`
- **参数**：
  - `text` — `.atlas` 文件的完整文本内容
  - `base_dir` — PNG 文件所在的 `res://...` 目录路径
- **返回值**：`Dictionary`，键为 region 名称字符串，值为 `Region` 对象
- **解析规则**：
  - 无缩进无冒号行：PNG 文件名（新页） 或 region 名称
  - 无缩进有冒号行（`size:`, `filter:` 等）：页属性，跳过
  - 2 空格缩进有冒号行：region 属性（`rotate`, `xy`, `size`, `orig`, `offset`）
  - `rotate: true` 时，`xy`/`size` 行存储的是旋转后尺寸，`width`/`height` 在代码内交换回原始方向

---

### 4.17 battle/spine/SpineSkel.gd

**类名**：`SpineSkel`  
**类继承**：`class_name SpineSkel`（GDScript 静态工具类）  
**职责**：解析 Spine 2.1.27 二进制 `.skel` 文件，提取骨骼层次结构、槽位信息、默认皮肤 Region 附件和骨骼动画时间线，返回供 `SpinePlayer` 使用的数据字典。

### 二进制文件格式（Spine 2.1.27）

```
1. hash string           — varint 长度前缀字符串
2. version string        — "2.1.27"
3. width, height float   — 画布尺寸（大端序 IEEE 754）
4. nonEssential bool     — 1 字节；若为 true 则跟随 fps(float) + imagesPath(string)
5. bone_count varint     — 骨骼数量（idle.skel = 49）
   每根骨骼: name, parent_raw(varint,0=root), x,y,sx,sy,rotation,length(6 floats), flip_x,flip_y,inherit_scale,inherit_rotation(4 bools)
6. ik_count varint       — IK 约束数量（Darkest Dungeon = 0）
7. slot_count varint     — 槽位数量（idle.skel = 31）
   每个槽位: name(string), bone_index(varint), color(4 bytes), attachment(string), blendMode(1 byte)
8. default skin:
   skin_slot_count varint — 皮肤槽位数
   每个槽位: slot_idx(varint), att_count(varint), [att_name(string), att_type(varint), ...fields...]
   - **Region (type=0)**：path(rs,null) + rotate(bool) + x,y,sx,sy,rotation,width,height(7 floats) + color(4 bytes)
   - **Mesh (type=2)**：inner_path(rs,null) + uvc(rv) + uvc×float(UV坐标0-1) + tric(rv) + tric×2字节 + vc(rv,=顶点数×2个float) + vc floats(x,y对) + **哨兵0xFFFFFFFF(4字节)** + hull(rv)
   - **SkinnedMesh (type=3)**：inner_path(rs,null) + uvc(rv) + uvc×float + tric(rv) + tric×2字节 + vc(rv,总float数) + vc floats(boneCount+bc×(boneIdx+x+y+weight)) + **哨兵0xFFFFFFFF(4字节)** + hull(rv)
   - **BoundingBox (type=1)**：inner_path(rs) + vc(rv) + vc×4字节
9. animations
   每段动画:
     anim_name (varint+bytes string)
     slot_tl_count (LEB128 varint)     — 槽位时间线数量（先于骨骼）
     [slot timelines — 跳过，不参与渲染]
     bone_tl_count (LEB128 varint)     — 骨骼时间线条目数
     每条骨骼时间线:
       bone_idx (LEB128 varint)
       tl_count (LEB128 varint)
       每条 timeline:
         raw_type (1 byte): 0=缩放, 1=旋转, 2=平移   ← Spine 2.1.27 实际编码
         frame_cnt (LEB128 varint)
         每帧: time(float) + values + curve(1 byte，最后帧除外；=2时追加16字节贝塞尔)
```

> **关键注意**：
> - 每个槽位末尾有 1 字节 `blendMode`，必须 `r.skip(1)` 跳过，否则皮肤起始位置偏移 31 字节，导致皮肤槽位数量读为 0。
> - Region (type=0) **无** inner_path 字段，直接读 rotate bool。
> - Mesh/SkinnedMesh 末尾有 4 字节哨兵 `0xFFFFFFFF`，必须跳过。
> - 动画段中**槽位时间线 (slot_tl_count) 先于骨骼时间线 (bone_tl_count)**，顺序不可颠倒。
> - varint 使用完整 **LEB128** 编码（每字节 7 位，高位为延续标志），不限于 2 字节。
> - **骨骼时间线原始类型映射**：0=缩放、1=旋转、2=平移（与直觉相反）；代码解析时统一重映射为内部约定（0=旋转,1=平移,2=缩放）。

### 内部数据类

| 类 | 关键字段 |
|----|----------|
| `BoneData` | `name`, `parent_index`(-1=根), `x`, `y`, `scale_x`, `scale_y`, `rotation`(度), `length` |
| `SlotData` | `name`, `bone_index`, `attachment`(默认附件名) |
| `RegionAttachment` | `slot_index`, `name`, `path`(atlas region名), `rotate`(bool), `x`,`y`,`scale_x`,`scale_y`,`rotation`,`width`,`height` |
| `BoneTimeline` | `bone_index`, `timeline_type`(**内部约定** 0=旋转,1=平移,2=缩放；原始文件编码 0=缩放,1=旋转,2=平移，解析时已重映射), `keyframes` |
| `RotateKeyframe` | `time`, `value`(度), `curve`(0=线性,1=步进,2=贝塞尔) |
| `TranslateKeyframe` | `time`, `tx`, `ty`, `curve` |
| `SpineAnimation` | `name`, `bone_timelines`, `duration` |

### `static parse(file_path: String) -> Dictionary`
- **返回值**：包含以下键的字典：
  - `"bones"` — `Array[BoneData]`
  - `"slots"` — `Array[SlotData]`
  - `"attachments"` — `Dictionary[int → RegionAttachment]`（键为槽位下标，**全部 31 个槽位**均有数据，含 Mesh/SkinnedMesh 代理）
  - `"animations"` — `Array[SpineAnimation]`
  - `"version"` — String
- **Mesh 附件处理（type=2）**：解析全部顶点坐标，计算重心作为附件偏移 (x, y)；用 **Procrustes UV→顶点旋转对齐**算法计算图像旋转角（= 图像 U 轴在骨骼 Spine Y-up 空间中的角度），以 `RegionAttachment` 代理写入 `attachments[slot_idx]`
- **SkinnedMesh 附件处理（type=3）**：解析权重混合顶点，按权重加权平均计算世界重心，`rotation=0.0`（蒙皮网格不需要额外旋转），以 `RegionAttachment` 代理写入 `attachments[slot_idx]`
- **Mesh/SkinnedMesh scale**：`scale_x = scale_y = 0.5`，与 Region 附件保持一致（1骨骼单位 = 2像素）
- **动画定位**：通过搜索法（`_find_and_parse_animations`）在剩余字节中定位动画段

---

### 4.18 battle/spine/SpinePlayer.gd

**类名**：`SpinePlayer`  
**类继承**：`extends Node2D`  
**职责**：以 `Sprite2D` 子节点渲染 Spine 2.1.27 骨骼动画角色。每个槽位对应一个 `Sprite2D`，每帧通过骨骼正向运动学计算世界变换并赋给对应 sprite。

### 关键成员变量

| 变量 | 类型 | 说明 |
|------|------|------|
| `skel_data` | Dictionary | `SpineSkel.parse()` 返回值 |
| `atlas_regions` | Dictionary | `SpineAtlas.parse()` 返回值 |
| `current_anim` | SpineAnimation | 当前播放的动画对象 |
| `anim_time` | float | 当前动画时间（秒） |
| `looping` | bool | 是否循环播放 |
| `_sprites` | Array | 按槽序排列的 Sprite2D 节点 |
| `_bone_world` | Array | 每根骨骼的世界变换 Transform2D |
| `_atlas_rot_corrections` | Array[bool] | 各槽位是否需要 +90° CW atlas 旋转补偿 |

### 坐标变换公式

Spine 使用 Y 轴向上，Godot 使用 Y 轴向下。骨骼/附件 Transform2D 构建公式：

```
cos_r = cos(rotation_rad)
sin_r = sin(rotation_rad)
Transform2D(
    x_axis = Vector2(cos_r × sx,  -sin_r × sx),   # Godot Y-down 翻转
    y_axis = Vector2(sin_r × sy,   cos_r × sy),
    origin = Vector2(x, -y)                        # Y 坐标取反
)
```

### Atlas 旋转补偿

当 atlas `region.rotate = true` 时，像素在 PNG 中被顺时针旋转 90° 打包。渲染时需乘以 +90° CW 补偿矩阵（后乘）：

```gdscript
Transform2D(Vector2(0, 1), Vector2(-1, 0), Vector2.ZERO)  # +90° CW
```

### 主要方法

#### `load_character(skel_path, atlas_path, png_dir) -> void`
- 解析 skel 和 atlas 文件，调用 `_build_sprites()` 创建所有 Sprite2D 子节点

#### `play(anim_name: String, loop: bool = true) -> void`
- 切换当前动画，重置 `anim_time`

#### `_process(delta) -> void`
- 累加 `anim_time`（含循环处理），每帧调用 `_update_pose()`

---

#### `_update_pose() -> void`
**职责**：计算所有骨骼的世界变换并更新精灵位置

**流程**：

1. **计算局部变换**（含动画时间线采样）：
   - 遍历所有骨骼 `bones[i]`
   - 初始化局部旋转：`local_rot = bones[i].rotation (度 → 弧度)`
   - 初始化局部位置：`local_x = bones[i].x`, `local_y = -bones[i].y` (Spine Y-up → Godot Y-down)
   - 若当前正在播放动画 (`current_anim != null`)，采样该骨骼的时间线：
     - **旋转时间线** (timeline_type=0)：采样关键帧 → 累加到 `local_rot`
       - 特殊处理：两帧之间夹角差做 **[-180, 180] 归一化** (`fmod(diff + 540, 360) - 180`)，避免跨越 ±180° 时出现反向绕圈
     - **平移时间线** (timeline_type=1)：采样关键帧 (tx, ty) → 累加到 `(local_x, local_y)`
       - y 分量取反：`local_y += -sample_ty`
     - **缩放时间线** (timeline_type=2)：暂不处理，骨骼缩放保持模板值
   - 构建局部 **Transform2D**（Godot Y-down 公式）：
     ```
     cos_r = cos(local_rot)
     sin_r = sin(local_rot)
     sx = bones[i].scale_x  (默认 1.0)
     sy = bones[i].scale_y  (默认 1.0)
     
     local_t = Transform2D(
         x_axis = (cos_r × sx,  -sin_r × sx),    # Godot Y 翻转
         y_axis = (sin_r × sy,   cos_r × sy),
         origin = (local_x, local_y)
     )
     ```

2. **累积世界变换**（正向运动学，骨骼树传播）：
   - 遍历所有骨骼
   - 若 `parent_index < 0`（根骨骼）：`world_t[i] = local_t[i]`
   - 否则（子骨骼）：`world_t[i] = world_t[parent_index] × local_t[i]`
   - 结果：每根骨骼的世界坐标系变换存入 `_bone_world[]` 数组

3. **更新精灵渲染**：
   - 遍历所有槽位 `slots[si]`
   - 跳过无附件的槽位 (`attachments[si] == null`)
   - **网格槽**（Mesh 或 SkinnedMesh）：调用 `_update_mesh_poly()`
   - **Region 槽**（单骨骼简单纹理）：
     - 获取附件的世界变换：
       ```
       bone_t = world_t[slots[si].bone_index]
       
       att_x = ra.x
       att_y = -ra.y   # Spine Y-up → Godot Y-down
       att_r = deg_to_rad(ra.rotation)
       att_sx = ra.scale_x (默认 0.5)
       att_sy = ra.scale_y (默认 0.5)
       
       cos_a = cos(att_r)
       sin_a = sin(att_r)
       att_t = Transform2D(
           x_axis = (cos_a × att_sx, -sin_a × att_sx),
           y_axis = (sin_a × att_sy,  cos_a × att_sy),
           origin = (att_x, att_y)
       )
       ```
     - 合成最终变换：`world_t = bone_t × att_t`
     - **Atlas 旋转补偿**：若 `region.rotate = true`，后乘 +90° CW 补偿矩阵
       ```
       world_t = world_t × Transform2D(Vector2(0, 1), Vector2(-1, 0), Vector2.ZERO)
       ```
     - 赋值给精灵：`sprite.transform = world_t`

---

#### `_update_mesh_poly(si: int, poly: Polygon2D, sd: SlotData, ra: RegionAttachment) -> void`
**职责**：计算网格附件（Mesh 或 SkinnedMesh）每个顶点的世界位置，更新 Polygon2D

**关键参数**：
- `si` — 槽位索引
- `poly` — Polygon2D 节点（已创建，准备更新顶点）
- `sd` — 槽位数据（包含 bone_index）
- `ra` — 附件数据（包含 att_type、mesh_vertices、mesh_bones、mesh_uvs）

**流程**：

1. **获取 Atlas Region**（用于 UV 映射）：
   ```
   region = _slot_region[si]
   if region == null:
       poly.visible = false
       return
   ```

2. **计算顶点世界位置**：
   - **若 `ra.att_type == 2`（Mesh，单骨骼）**：
     ```
     bone_t = world_t[sd.bone_index]
     verts = ra.mesh_vertices  # [x0, y0, x1, y1, ...]
     for each vertex (vx, vy):
         local_pt = Vector2(vx, -vy)  # Spine Y-up → Godot Y-down
         world_pt = bone_t × local_pt
         pts.append(world_pt)
     ```
   
   - **若 `ra.att_type == 3`（SkinnedMesh，多骨骼加权）**：
     ```
     mesh_bones = ra.mesh_bones  # Array[Array[int,float,float,float]]
     # 格式：[[bone0_idx, x0, y0, weight0], [bone1_idx, x1, y1, weight1], ...]
     
     for each bone_binding in mesh_bones:  # 每个顶点
         world_pt = Vector2.ZERO
         for each bone_info [bi, bx, by, bw] in bone_binding:
             bone_t = world_t[bi]
             local_pt = Vector2(bx, -by)  # Spine Y-up → Godot Y-down
             world_pt += (bone_t × local_pt) × bw  # 加权求和
         pts.append(world_pt)
     ```
     **关键机制**：多个骨骼对同一顶点的贡献通过权重 `bw` 线性混合，权重和通常 = 1.0

3. **安全检查**：
   ```
   if pts.size() < 3:
       poly.visible = false
       return
   ```

4. **UV 映射**（纹理坐标 → 图集像素坐标）：
   ```
   src = ra.mesh_uvs  # [u0, v0, u1, v1, ...] (归一化 0..1)
   
   for each uv (u, v):
       px, py = atlas_pixel_coords
       if region.rotate == true:
           # 旋转区域：原图 width 高 × height 宽被顺时针旋转 90°
           # u 沿原图宽 → 页面竖直方向
           # v 沿原图高 → 页面水平方向（反向）
           px = region.x + v × region.height
           py = region.y + (1.0 - u) × region.width
       else:
           # 未旋转区域：直接线性映射
           px = region.x + u × region.width
           py = region.y + v × region.height
       uvs.append(Vector2(px, py))
   ```
   **设计目的**：Polygon2D 的 `uv` 数组中的坐标是图集页的像素坐标（非 0..1 归一化），用于 AtlasTexture 的纹理采样

5. **更新 Polygon2D**：
   ```
   poly.polygon = pts
   poly.uv = uvs
   poly.visible = true
   ```

**关键设计**：
- **Mesh vs SkinnedMesh** 的唯一差异是顶点计算方式：前者用单个骨骼变换，后者用多个骨骼的加权平均
- **加权混合保证连续性**：即使骨骼之间有大角度变换，权重平均也能产生平滑的过渡
- **旋转区域 UV 补偿**：应对 Spine 编辑器的纹理打包优化（顺时针旋转 90° 节省空间）

---

#### `_sample_rotate(bt, t) -> float`
- 旋转角度线性插值时，对两帧角度差做 **[-180, 180] 归一化** (`fmod(diff + 540, 360) - 180`)，避免跨越 ±180° 边界时出现反向绕圈旋转

#### `_build_sprites() -> void`
- 为每个槽位创建 Sprite2D，调用 `_apply_region_texture()` 设置 AtlasTexture
- 记录 `_atlas_rot_corrections[si]` = `region.rotate`
- 若 `attachments` 字典中无对应 `RegionAttachment`（`ra == null`），则用 `SlotData.attachment` 名创建 fallback（x=0, y=0, rotation=0, scale=0.5），以骨骼中心为原点显示

#### `_apply_region_texture(sprite, ra) -> bool`
- 查找 atlas region，创建 `AtlasTexture`（`rotate=true` 时 Rect2 交换 width/height）
- 返回 `region.rotate`（供 `_build_sprites` 记录旋转补偿标志）

### BattleController 集成方式

```gdscript
# 常量
const CRUSADER_ANIM_BASE := "res://characters/crusader/anim/crusader.sprite."
const CRUSADER_PNG_DIR   := "res://characters/crusader/crusader_A/anim"

# 创建
var sp := SpinePlayer.new()
sp.scale = Vector2(0.5, 0.5)   # 有效尺寸 = 0.5(node) × 0.5(attachment) = 0.25
add_child(sp)

# 加载并播放
sp.load_character(
    "res://characters/crusader/anim/crusader.sprite.idle.skel",
    "res://characters/crusader/anim/crusader.sprite.idle.atlas",
    "res://characters/crusader/crusader_A/anim"
)
sp.play("idle")
```

动画状态到文件名的映射由 `CRUSADER_ANIM_MAP` 字典管理（`BattleController` 内）。

---

**文档版本**：v3.0  
**最后更新**：2026 年 6 月 24 日  
**引擎版本**：Godot 4.6  
