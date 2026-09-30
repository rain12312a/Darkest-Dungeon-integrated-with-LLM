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
   - [4.7 data/ConsumableConfig.gd](#47-dataconsumableconfiggd)
   - [4.8 main/StartController.gd](#48-mainstartcontrollergd)
   - [4.9 固定编队（原编队选择功能已移除）](#49-固定编队原编队选择功能已移除)
   - [4.10 battle/BattleController.gd](#410-battlebattlecontrollergd)
   - [4.11 battle/TurnQueue.gd](#411-battleturnqueuegd)
   - [4.12 battle/ActionResolver.gd](#412-battleactionresolvergd)
   - [4.13 battle/LLMClient.gd](#413-battlellmclientgd)
   - [4.14 town/TownController.gd](#414-towntowncontrollergd)
   - [4.15 ui/HudController.gd](#415-uihudcontrollergd)
   - [4.16 battle/spine/SpineAtlas.gd](#416-battlespinespineatlasgd)
   - [4.17 battle/spine/SpineSkel.gd](#417-battlespinespineskelgd)
   - [4.18 battle/spine/SpinePlayer.gd](#418-battlespinespineplayergd)
   - [4.19 map/DungeonMap.gd](#419-mapdungeonmapgd)
   - [4.20 map/MapController.gd](#420-mapmapcontrollergd)
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
   - [7.8 消耗品背包系统](#78-消耗品背包系统)
   - [7.9 技能 / 消耗品悬浮提示系统](#79-技能--消耗品悬浮提示系统)
   - [7.10 状态异常（Buff / Debuff）系统](#710-状态异常buff--debuff系统)
   - [7.11 训犬师（Houndmaster）配置](#711-训犬师houndmaster配置)
   - [7.12 门前恶狼 BOSS 战（Brigand 火器小队）](#712-门前恶狼-boss-战brigand-火器小队)
   - [7.13 死门（Death's Door / 濒死）机制](#713-死门deaths-door--濒死机制)
   - [7.14 压力系统：折磨（Affliction）/ 美德（Virtue）](#714-压力系统折磨affliction--美德virtue)
   - [7.15 怪物尸体视觉与卡槽（补位 / 布局）](#715-怪物尸体视觉与卡槽补位--布局)
   - [7.16 战斗结算（战利品）步骤](#716-战斗结算战利品步骤)
   - [7.17 背景音乐（BGM）系统](#717-背景音乐bgm系统)
   - [7.18 战斗音效（SFX）系统](#718-战斗音效sfx系统)
   - [7.19 战斗结算界面（胜利 / 远征终结 / 战败）](#719-战斗结算界面胜利--远征终结--战败)
8. [扩展指南](#8-扩展指南)
9. [暗黑地牢原版地图系统](#9-暗黑地牢原版地图系统)

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
- **LLM 大模型激励喊话系统**：支持 OpenAI 标准兼容协议（DeepSeek 等多源大模型），英雄能根据场上形势、血量、精神压力、敌人数量与自身性格，生动回应领主的训示，并触发**四种结果之一**（减压 / 增益 / 加压 / 精神崩溃倒戈攻击队友）；喊话会**占用该英雄本回合的行动点**
- **暗黑地牢风格镜头放大系统**：所有技能释放时攻击方与目标同步放大至 200%，配合 Spine 骨骼特效形成特写镜头
- **浮字伤害/治疗数字系统**：鲜红伤害数字与翠绿治疗数字在放大状态下弹出并渐隐
- **压力光环图标系统**：压力上升显示 `seal.affliction.png`，压力下降显示 `seal.heroic.png`，悬挂于角色头顶
- **暗黑地牢原版地图系统**：小/中/大三级随机生成地图（房间 + 走廊），初始界面选尺寸；已清除房间不刷怪，击败最远 Boss 房通关

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
├── audio/                               # 音频素材
│   ├── secondary_banks/                 # 原版 FMOD Studio 音效库（.bank）
│   │   ├── music.bank                   #   全部音乐（FADPCM）——64 首曲目
│   │   ├── ambience.bank                #   环境音（FADPCM）
│   │   ├── title_screen.bank            #   标题界面 UI 音效（VORBIS）
│   │   ├── en_*.bank / hero_*.bank      #   怪物 / 英雄音效与语音（VORBIS）
│   │   └── ...
│   ├── master_banks/                    # 主库（事件 / 字符串表）
│   ├── bgm/                             # ★ 从 music.bank 提取出的 BGM（ogg，游戏实际播放）
│   └── sfx/                             # ★ 技能/UI 音效 91 个 ogg（5.6MB）
│       ├── char_al_*.ogg                #   英雄技能 + 通用命中层（54 个）
│       ├── enemy/                       #   怪物技能（31 个）
│       └── ui/                          #   结算弹窗 / 按钮音（6 个）
│
│
├── data/                                # JSON 数据文件目录
│   ├── characters.json                  # 角色静态数据（由 Database.gd 加载）
│   ├── skills.json                      # 技能静态数据（由 Database.gd 加载）
│   ├── statuses.json                    # 状态效果数据（由 Database.gd 加载）
│   └── towns.json                       # 城镇数据（由 Database.gd 加载）
│
├── scenes/                              # Godot 场景文件目录（.tscn）
│   ├── main/
│   │   └── Main.tscn                    # 根场景，挂载 GameState.gd，作为场景管理容器
│   │
│   ├── start/
│   │   └── Start.tscn                   # 游戏开始画面（闪屏 + 主菜单），挂载 StartController.gd
│   │
│   ├── fe_flow/                         # 《暗黑地牢》原版前端素材（标题背景/宅邸/流云/按钮/DEMO 图）
│   │
│   ├── battle/
│   │   ├── Battle.tscn                  # 战斗主场景，挂载 BattleController.gd
│   │   └── TurnQueue.tscn              # 行动队列可视化场景，挂载 TurnQueue.gd（预留）
│   │
│   ├── map/
│   │   └── Map.tscn                     # 地图场景，挂载 MapController.gd
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
    │   ├── StartController.gd           # 开始界面（闪屏 + 原版风格主菜单 + 固定编队开局）
    │   └── StartController.gd.uid
    │
    ├── map/
    │   ├── DungeonMap.gd                # 地图静态单例：小/中/大三级随机生成（房间/走廊/遭遇）
    │   └── MapController.gd             # 地图场景 UI 控制器（房间方块与走廊渲染）
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
│  → 闪屏 demo_splash.png（点击/按键/2.4s 跳过）   │
│  → 主菜单：辉光 + 宅邸剪影 + 流云 + DEMO 标志   │
│  → 选择地图尺寸 Small / Medium / Large         │
│  → 点击 START：写入固定编队 + 重置补给/关卡     │
│     → change_scene_to_file(Map.tscn)            │
└─────────────────────┬────────────────────────────┘
                      │ 保存固定编队并生成地图
┌─────────────────────▼────────────────────────────┐
│  Map.tscn (MapController.gd)                     │
│  → 渲染随机生成的房间 + 走廊                     │
│  → 点击相邻房间：                                │
│     已清除 → 直接移动（不刷怪）                  │
│     未清除 → 掷遭遇 → change_scene(Battle)       │
└─────────────────────┬────────────────────────────┘
                      │ 进入房间
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
│  普通胜利 → Return to Map（回到地图继续探索）    │
│  Boss 房胜利 → Run Complete! → 返回 Start（通关）│
│  失败 → Back to Start                            │
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
    "crusader":   { "name": "Crusader",   "max_hp": 50, "attack": 17, "speed": 4,
                    "skills": ["slash", "heal", "holy spear", "battle_cry"],
                    "death_blow_chance": 0.5 },
    "highwayman": { "name": "Highwayman", "max_hp": 40, "attack": 20, "speed": 5,
                    "skills": ["shotgun", "cut", "Close-range shooting", "pistol_shot"],
                    "death_blow_chance": 0.5 }
}

# 死门（Death's Door）默认死亡概率：角色未单独配置时使用
const DEFAULT_DEATH_BLOW_CHANCE := 0.5

static var CURRENT_TEAM: Array[String] = ["crusader", "highwayman", "occultist", "crusader"]
```

> `death_blow_chance`（0.0~1.0）写在**每个角色自己的条目里**，含义见 §7.13「死门（Death's Door）机制」。

---

#### `static get_hero_template(hero_id: String) -> Dictionary`
- **参数**：`hero_id` — 英雄唯一标识符（如 `"crusader"`）
- **返回值**：英雄数据的深拷贝 Dictionary；不存在时返回 `{}`
- **功能**：获取英雄的初始模板，附加两个字段：`id`（英雄 ID）和 `hp`（初始值等于 `max_hp`）
- **用途**：`HeroConfig.get_all_hero_ids()` 列出全部英雄 id（数据层/调测用）；BattleController 通过 `get_team_heroes()` 间接调用

---

#### `static get_team_heroes() -> Array[Dictionary]`
- **返回值**：按 `CURRENT_TEAM` 顺序排列的英雄模板数组
- **功能**：根据当前编队配置构建英雄数据列表，供 BattleController 初始化战斗数据
- **流程**：遍历 `CURRENT_TEAM`，对每个 hero_id 调用 `get_hero_template()`，跳过空字符串和不存在的 ID

---

#### `static get_death_blow_chance(hero_id: String) -> float`
- **参数**：`hero_id` — 英雄唯一标识符
- **返回值**：该角色的死门死亡概率（0.0~1.0），已做 `clampf` 夹逼
- **功能**：读取 `HEROES[hero_id]["death_blow_chance"]`；未配置或角色不存在时回落到 `DEFAULT_DEATH_BLOW_CHANCE`（0.5）
- **用途**：`BattleController._death_blow_chance_of()` 在 `_setup_battle()` 构建英雄运行时字典时取该值

---

#### `static hero_exists(hero_id: String) -> bool`
- **参数**：`hero_id` — 英雄唯一标识符
- **返回值**：英雄是否存在于 `HEROES` 字典中

---

#### `static set_team(team: Array[String]) -> void`
- **参数**：`team` — 包含 4 个 hero_id 字符串的数组（空位用 `""` 表示）
- **功能**：更新全局编队配置 `CURRENT_TEAM`
- **调用方**：`StartController._on_start_pressed()`（写入 `FIXED_TEAM`）

---

#### `static get_all_hero_ids() -> Array[String]`
- **返回值**：所有已注册英雄的 ID 列表（如 `["crusader", "highwayman", "occultist", "houndmaster"]`）
- **功能**：提供可用英雄 id 列表（供数据层/调测使用；编队选择界面已移除）

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
| `cutthroat_strike` | Cutthroat Strike | damage | single_enemy | ATK × 0.9~1.1, 流血 2层/3回合 | [1, 2, 3] | [1, 2] |
| `temptation` | Temptation | damage | all_enemies | ATK × 0.45~0.55, stress+15~25 | [3, 4] | [1, 2, 3, 4] |
| `arbalist_crossbow` | Crossbow Shot | damage | single_enemy | ATK × 1.2~1.4（后排远程） | [3, 4] | [1, 2, 3, 4] |
| `arbalist_bayonet` | Bayonet Jab | damage | single_enemy | ATK × 0.6~0.8（前排近战） | [1, 2] | [1, 2] |
| `courtier_goblet` | Goblet Toss | damage | all_enemies | ATK × 0.25~0.35, stress+35~45 | [3, 4] | [1, 2, 3, 4] |
| `courtier_dagger` | Poisoned Dagger | damage | single_enemy | ATK × 0.5~0.7 | [1, 2] | [1, 2, 3] |
| `skeleton_melee` | Rusty Blade | damage | single_enemy | ATK × 0.9~1.1 | [1, 2, 3, 4] | [1, 2] |
| `defender_axe` | Axe Cleave | damage | single_enemy | ATK × 0.7~0.9 | [1, 2] | [1, 2] |
| `defender_shield` | Shield Bash | damage | single_enemy | ATK × 0.35~0.45, 晕眩 1 回合 | [1, 2] | [1, 2] |
| `militia_slash` | Militia Slash | damage | single_enemy | ATK × 0.9~1.1, 流血 3层/3回合 | [1, 2] | [1, 2, 3] |
| `militia_ranged` | Militia Ranged | damage | single_enemy | ATK × 0.5~0.7（后排远程） | [3, 4] | [1, 2] |
| `spear_thrust` | Spear Thrust | damage | single_enemy | ATK × 0.9~1.1（穿刺后排） | [1, 2, 3] | [2, 3, 4] |
| `spear_pierce` | Spear Pierce | damage | all_enemies | ATK × 0.8~1.0（贯穿） | [1, 2, 3] | [1, 2, 3, 4] |

**门前恶狼 BOSS 战技能**（详见 §7.12）：

| ID | 名称 | 类型 | 目标 | 效果 / 使用条件 | use_positions | target_positions |
|----|------|------|------|------------------|--------------|------------------|
| `sapper_throw` | Bomb Toss | apply_status | single_enemy | 不给伤害，只挂 `bomb_mark`；需弹药桶存活 | [1, 2, 3, 4] | [1, 2, 3, 4] |
| `sapper_summon` | Haul in a Barrel | summon | self | 召回 `brigand_barrel`；需弹药桶不在场 | [1, 2, 3, 4] | [1, 2, 3, 4] |
| `sapper_barrage` | Barrage | damage | all_enemies | ATK × 0.5~0.7 + stress 3~6，只打前两位；需弹药桶不在场 | [1, 2, 3, 4] | [1, 2] |
| `cannon_fire` | Fire! | damage | all_enemies | ATK × 0.9~1.2 + stress 3~5；需自身 `cannon_loaded`，开火后卸弹 | [1, 2, 3, 4] | [1, 2, 3, 4] |
| `cannon_summon` | Press Gang | summon | self | 召回 `brigand_fuseman`；需点火员不在场 | [1, 2, 3, 4] | [1, 2, 3, 4] |
| `cannon_blast` | Scattershot | damage | single_enemy | ATK × 0.6~0.8；需点火员在场且自身未装填 | [1, 2, 3, 4] | [1, 2, 3, 4] |
| `fuseman_light_fuse` | Light the Fuse | apply_status | single_ally | 给大炮挂 `cannon_loaded`（仅未装填的大炮）；`skill_priority = 1` 保证优先装填 | [1, 2, 3, 4] | [1, 2, 3, 4] |
| `fuseman_hot_shot` | Hot Shot | damage | single_enemy | ATK × 0.7~0.9（备选攻击） | [1, 2, 3, 4] | [1, 2, 3] |
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

### 4.7 data/ConsumableConfig.gd

**类名**：`ConsumableConfig`  
**类继承**：`extends Node`  
**职责**：集中管理消耗品（食物 Food / 绷带 Bandage / 狗粮 Dog Food）的静态配置、背包存储与增减逻辑。背包在战斗场景的左下方面板中以 16 格网格渲染，左键点击使用。

**静态变量**：

| 变量 | 类型 | 说明 |
|------|------|------|
| `ITEMS` | Dictionary | 消耗品模板字典，键为 `item_id`。字段：`name`（显示名）、`icon`（图标路径）、`heal`（回复生命值，恢复类）、`cure_status`（要治愈的状态 id 数组，治愈类）、`buff_status` + `buff_duration`（要附加的状态 id 与持续回合数，增益类）、`description`（悬浮提示描述） |
| `INVENTORY` | Array[Dictionary] | 消耗品背包，最多 16 格；每项 `{"item_id": String, "count": int}`；同种消耗品无限堆叠 |
| `MAX_SLOTS` | const int | `16`，背包槽位上限 |

**当前消耗品**：

| item_id | name | 效果字段 | 说明 |
|---------|------|----------|------|
| `food` | Food | `heal: 2` | 为当前行动的英雄恢复少量生命 |
| `bandage` | Bandage | `cure_status: ["bleed"]` | 为当前行动的英雄治愈流血 |
| `dogfood` | Dog Food | `buff_status: "dogfood_buff"`, `buff_duration: 1` | 使当前行动的英雄伤害提高 20%，持续 1 回合 |

**方法**：

| 方法 | 说明 |
|------|------|
| `static reset_inventory(initial_food=4, initial_bandage=2, initial_dogfood=2)` | 开新局时清空背包并发放初始补给（食物 + 绷带 + 狗粮） |
| `static add_item(item_id, amount) -> bool` | 添加消耗品；同种堆叠，新种类占用新格（受 16 格上限约束），失败返回 false |
| `static get_count(item_id) -> int` | 返回指定消耗品的持有数量 |
| `static consume_item(item_id, amount=1) -> bool` | 消耗指定数量；数量不足或不存在返回 false |
| `static get_item(item_id) -> Dictionary` | 返回消耗品模板的深拷贝（不存在返回空字典） |

---

### 4.8 main/StartController.gd

**类继承**：`extends Node`  
**挂载场景**：`scenes/start/Start.tscn`（场景文件极简，全部 UI 由代码构建）  
**职责**：复刻《暗黑地牢》原版前端的游戏开始界面 —— **闪屏 → 主菜单 → 开局**，素材全部取自 `res://fe_flow/`。

**素材与版式**：

| 常量 | 值 | 用途 |
|------|-----|------|
| `SPLASH_IMAGE` | `fe_flow/demo_splash.png` | 闪屏整图；同时用 `AtlasTexture` 裁出 logo 当标题 |
| `TITLE_BG_IMAGE` | `fe_flow/title_bg.png` | 1920×2160 的前端背景，取**下半屏**（黑天 + 红色辉光）当底板 |
| `TITLE_HOUSE_IMAGE` | `fe_flow/title_house.png` | 宅邸黑色剪影（压在辉光之上） |
| `SKY_FAR_IMAGE` / `SKY_NEAR_IMAGE` | `fe_flow/sky01.png` / `sky02.png` | 两层流云，半透明 + 极缓慢横向漂移 |
| `BUTTON_ART` | `fe_flow/start_button.png` | 深色描金按钮底图，作为 `StyleBoxTexture` 九宫格用于所有按钮 |
| `LOGO_REGION` | `Rect2(510,199,962,550)` | `demo_splash` 中 logo 的实测包围盒 |
| `DESIGN_SIZE` / `PAGE_SCROLL` | `1920×1080` / `1080` | 版式设计尺寸与折算偏移 |
| `FIXED_TEAM` | `crusader / highwayman / occultist / houndmaster` | 固定初始编队 |
| `MAP_SIZES` | `small` / `medium` / `large` | 地图尺寸三档 |
| `SPLASH_DURATION` / `SPLASH_FADE` | `2.4` / `0.45` | 闪屏停留与淡出时长（秒） |

> **坐标来源**：`fe_flow/fe_flow.layout.darkest` 的原始数值是 1920×2160 虚拟空间，主菜单页 = 该空间的下半屏，故「页面内 y = 布局 y − 1080」：宅邸 `1486 → 406`、流云 `1450/1600 → 370/520`、START 按钮中心 `2070 → 990`（左上 944）。整套页面画在 1920×1080 的 `DesignRoot` 上，由 `_layout_design_root()` 按窗口等比缩放并居中。
> **⚠️ Godot 4 的 `TextureRect` 没有 `region_enabled` / `region_rect`**，裁图要用 `AtlasTexture`（见 `_atlas()`）。

**节点结构**（运行时）：`Start` → `MenuLayer`（黑底 + `DesignRoot`）与 `SplashLayer`。

---

#### `_ready() -> void`
- **功能**：构建菜单 → 监听窗口 `size_changed` → 应用版式缩放；若本次运行尚未播过闪屏，则构建 `SplashLayer` 并 `_play_splash()`

---

#### `_layout_design_root() -> void`
- **功能**：`DesignRoot.scale = min(vw/1920, vh/1080)` 后居中；窗口尺寸变化时自动重排

---

#### `_build_menu()` 及 `_add_*()`（私有）
- `_add_title_glow()`：`AtlasTexture(title_bg, Rect2(0,1080,1920,1080))` 铺满设计区
- `_add_house()`：宅邸剪影放在 `y = 406`（尺寸 1920×674）
- `_add_clouds()`：`SkyFar` / `SkyNear` 两层流云，`_drift()` 做往返漂移
- `_add_logo()`：`AtlasTexture(demo_splash, LOGO_REGION)` 居中置于顶部
- `_add_size_row()`：`SMALL / MEDIUM / LARGE` 三个按钮 + 说明文字（默认 `medium`）
- `_add_start_button()`：`START` 按钮（372×92，位置沿用布局值）
- `_add_build_label()`：左下角版本信息（对应原版 `.build_num_pos`）
- `_style_banner_button()`：把 `start_button.png` 包成 `StyleBoxTexture`（normal / hover / pressed / disabled）

---

#### `_on_size_pressed(size_key: String) -> void`
- **功能**：记录所选地图尺寸，刷新按钮高亮与说明文字（`_refresh_size_row()`）

---

#### `_input(event)` / `_play_splash()` / `_dismiss_splash()`
- **功能**：闪屏跳过逻辑 —— 鼠标点击或任意按键立即 `_dismiss_splash()`（0.45s 淡出后 `queue_free`）；否则 `SPLASH_DURATION` 秒后自动跳过
- **`static var _splash_played`**：只在本次运行**首次**进入开始界面时播放闪屏（失败 / 通关返回 Start 时不再闪）

---

#### `_on_start_pressed() -> void`
- **触发时机**：点击 `START`
- **功能**：写入固定编队 → 重置队伍状态与补给 → 按所选尺寸重置关卡 → 进入地图
- **实现**：`HeroConfig.set_team(FIXED_TEAM)` → `HeroConfig.reset_party_state()` → `ConsumableConfig.reset_inventory()` → `DungeonMap.set_size()` + `DungeonMap.reset_run()` → `change_scene_to_file("res://scenes/map/Map.tscn")`
- **防重**：点击后立即 `disabled = true`

---

### 4.9 固定编队（原编队选择功能已移除）

**编队选择功能已删除**：`scenes/main/TeamSelect.tscn` 与 `scripts/main/TeamSelectController.gd` 均已移除，开局队伍固定为 **十字军 · 强盗 · 神秘学者 · 训犬师**。

| 位置 | 说明 |
|------|------|
| `StartController.FIXED_TEAM` | 固定编队常量 `["crusader","highwayman","occultist","houndmaster"]`，**要改初始编队只需改这里** |
| `HeroConfig.DEFAULT_TEAM` / `CURRENT_TEAM` | 默认值与运行时队伍，均为同一组合（与 `FIXED_TEAM` 保持一致） |
| `StartController._on_start_pressed()` | 开新局唯一入口（详见 §4.8） |

> 若要恢复“可选编队”，从 git 历史取回上述两个文件，并把 `_on_start_pressed()` 的跳转改回 `TeamSelect.tscn` 即可。

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
| `battle_ui` | `$BattleUI` | 全屏 UI 根容器（Control）；消耗品槽位挂载于此，避免命中测试越界 |
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
| `panel_inventory` | `$BattleUI/BattleContainer/LeftArea/BottomLeftPanel/BottomPanelsContainer/PanelInventory` | 消耗品背包面板容器 (Control) |
| `panel_inventory_bg` | `$BattleUI/BattleContainer/LeftArea/BottomLeftPanel/BottomPanelsContainer/PanelInventory/PanelInventoryBg` | 消耗品背景贴图 (TextureRect)，其全局矩形作为槽位定位基准 |
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
| `_inventory_slots_root` | Control | 消耗品槽位容器（挂载于 `battle_ui`，每次重建时替换） |
| `_inventory_initialized` | bool | 消耗品背包是否已在首帧构建完成（防止重复构建） |

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
- **首帧构建消耗品背包**：当 `_inventory_initialized == false` 且 `panel_inventory` / `panel_inventory_bg` / `battle_ui` 均有效时，置位标记并调用一次 `_build_inventory_panel()`（放在 `_process` 中而非 `call_deferred`，确保容器布局已稳定后取到的全局矩形准确）

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
  5. **目标强制位移的收尾（`target_move_forward`）**：若本回合技能对敌方目标施加了强制位移（`_target_reposition_applied == true`），说明 `monsters` 数组与 Spine 映射已在打击动画结束时重排完毕。此时需与位移分支保持一致：先 `heroes[current_actor["index"]]["actions_remaining"] -= 1` 扣除行动点，再 `turn_queue.build()` 重建行动队列，最后 `_get_next_actor()` 推进。**若在扣点前重建队列，施法者会带着 1 点行动力被重新入队，造成同一回合重复行动**。该标记在函数末尾统一清零，并在 `_setup_battle()` 中重置。

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

#### `_apply_monster_reposition_position(src_idx: int, target_idx: int) -> void`
- **功能**：怪物版换位矩阵处理器，实现敌方单位在 `monsters` 数组与 `"monster_%d"` Spine 映射中的同步位移，供「拉前/推后」类技能调用
- **核心逻辑**：
  1. **边界夹逼**：`clamp(target_idx, 0, monsters.size() - 1)`，同索引直接返回。
  2. **缓存槽位**：按索引顺序把 `"monster_%d"` 对应的 SpinePlayer 与动画状态取成数组。
  3. **物理重排**：`monsters.remove_at(src_idx)` + `insert(target_idx, ...)`，并刷新每个怪物的 `index` 键；槽位数组以同样的 `remove_at/insert` 规则重排，保证渲染与数据一一对应。
  4. **键重建**：仅清除 `"monster_"` 前缀的字符串键，保留英雄的 `int` 键，然后按新顺序写回 `"monster_%d"`。
  5. **只刷 UI、不建队列**：调用 `_update_ui()` 重建锚点与站位。**行动队列的重建必须延后到行动点扣除之后**（见 `_finish_hero_action`），否则施法者会重复行动。

---

#### `_apply_skill_target_reposition(target_idx: int, skill_data: Dictionary) -> void`
- **功能**：读取技能 `target_move_forward` 字段，把指定怪物向排头方向拉前（正数）或向排尾方向推后（负数）
- **规则**：字段为 0 / 已死亡 / 尸体 时直接跳过，避免把尸体拖到排头；实际发生位移时置位 `_target_reposition_applied`。
- **调用点**：`_on_monster_pressed()` 中，`await ATTACK_ZOOM_DURATION` 与 `_clear_focus()` 之后结算（先演完打击动画，避免视觉瞬移）。

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
- **越界防护**：访问 `heroes[current_actor["index"]]` / `monsters[current_actor["index"]]` 前先校验 `index` 是否在数组范围内，越界则直接返回（防止单位被移除后下标失效导致 `Out of bounds` 崩溃）

---

#### `_update_character_portrait() -> void`
- **功能**：加载并显示当前行动英雄的头像
- **路径格式**：`res://characters/{hero_name}/{hero_name}_guild_header.png`
- **清理**：若文件不存在，portrait_box 保持空白

---

#### `_update_skill_buttons() -> void`
- **功能**：根据技能选择状态生成技能图标或选择提示
- **未选技能模式**：显示技能图标（加载 `{hero}.ability.{one|two|...}.png`），并挂载 `_build_skill_tooltip(sd)` 生成的悬浮提示
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
| `_emit_feedback(targets, snapshots)` | 比对快照差值，路由到浮字/图标（含快照长度越界防护） |

**怪物动画加载**（6 个骷髅分支已添加至 `_load_monster_anim` 和 `_create_spine_player_for_monster`）。

**消耗品背包系统**（v3.2）：

| 函数 | 职责 |
|------|------|
| `_build_inventory_panel()` | 重建 16 格消耗品槽位容器；挂载到全屏 `battle_ui` 并按 `panel_inventory_bg.get_global_rect()` 定位 |
| `_add_inventory_slot(root, slot_index, ax0..ay1)` | 创建单个消耗品格子（Button，左键触发），含图标、数量角标与悬浮提示 |
| `_get_inventory_item_at(slot_index)` | 返回指定槽位的 item_id（越界返回空串） |
| `_try_use_consumable(slot_index)` | 左键使用消耗品：校验英雄回合/目标状态，按类别回血（`heal`）或治愈状态（`cure_status`），并刷新 UI 与背包 |
| `_show_toast(text)` | 在视口上部居中显示一条短暂渐隐提示（使用失败反馈） |

**悬浮提示系统**（v3.2）：

| 函数 | 职责 |
|------|------|
| `_build_skill_tooltip(sd)` | 组装技能悬浮提示：名称 + 描述 + 使用/目标位置 + 位移 + 效果数值 |
| `_format_positions(positions)` | 将站位数组格式化为 `"1, 2, 3"` 文本 |
| `_number_to_word(num)` | 数字转英文单词（用于技能图标路径 `one/two/three/...`） |

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
- **公式**：`int(actor["attack"] × get_attack_multiplier(actor) × attack_ratio × get_damage_multiplier(actor))`
- **两个增益乘区**（详见 §7.10）：
  - `attack_mult`（攻击力加成，如"美德激励"/"战意高涨"）：**彼此加算**，`1.0 + Σ(mult - 1)`（例：1.2 + 1.2 = ×1.4）
  - `damage_mult`（伤害加成，如"狗粮"）：**彼此乘算**，乘在最后（例：×1.4 × 1.2 = ×1.68）

---

#### `static get_attack_multiplier(unit: Dictionary) -> float`
- **功能**：把该单位身上所有 `attack_mult` 状态的加成**加算**后返回总倍率（无则 `1.0`），供 `calculate_damage` 使用
- **当前使用**：美德激励 `virtue_buff`（1.2，持续 5 回合）、战意高涨 `inspired`（1.2，持续 3 回合）——两者同时存在时为 ×1.4
- **浮点处理**：`1.2 - 1.0` 的误差在加算时会累积，函数内用 `snappedf(total, 0.0001)` 抹平，避免 `int()` 截断平白少 1 点伤害（20 × 1.4 = 28 而非 27）

---

#### `static get_damage_multiplier(unit: Dictionary) -> float`
- **功能**：把该单位身上所有 `damage_mult` 状态**连乘**后返回总倍率（无则 `1.0`）
- **当前使用**：狗粮 `dogfood_buff`（1.2，持续 1 回合）

---

#### `static get_stress_taken_multiplier(unit: Dictionary) -> float`
- **功能**：取该单位身上所有 `stress_taken_mult` 状态的最大值（无则 `1.0`），在 `apply_stress` 中**只放大加压**（`amount > 0`）
- **当前使用**：折磨 `afflicted`（`stress_taken_mult = 1.2`，受到压力 +20%）

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
- **功能**：对目标施加并累积压力（上限 `StressConfig.MAX_STRESS = 200`），并处理阈值与满值结算
- **触发机制**：
  1. 属性兜底校验：检查目标是否存在 `"stress"` 字段。若无（非英雄或初始化缺失）但在 `hp` 有效时原地初始化为 `0`。
  2. **折磨加成**：加压时（`amount > 0`）按 `get_stress_taken_multiplier()` 放大 —— 处于折磨状态的目标受到的压力 +20%；减压不受影响。
  3. **越阈掷骰（新增）**：压力越过 `AFFLICTION_THRESHOLD = 100` 且该英雄**当前既无折磨也无美德**时，
     先把压力**钳制到 100** 并打上 `stress_resolve_pending = true`，随后由战斗层
     `BattleController._resolve_pending_stress_states()` 掷骰：75% 折磨 / 25% 美德（详见 §7.14）。
  4. **压力归零 / 满值收尾**：压力归零 → 清除折磨；压力达 200 → 清除美德 + 压力清零（连带清折磨）+ `apply_damage(target, 999)`；
     若此时为折磨且已在濒死，则额外打上 `instant_death` 标记，由 `BattleController._handle_hero_damage_aftermath()` 直接处决（无视死门死扛）。
     （折磨 / 美德与压力一起跨战斗保留，因此不存在"每场战斗只掷一次"的战斗内标记）

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

- **`MOCK_*_POSITIVE` / `MOCK_*_BUFF` / `MOCK_*_NEGATIVE` / `MOCK_*_BETRAY`**（Crusader / Highwayman 两套）：
  在断网、请求异常或大模型应答超时时，按四种行为分别路由匹配高质量沉浸式中文台词。

#### 四种激励结果（`LLMClient.Outcome`）

| 标签 | Outcome | 结算效果 |
|------|---------|----------|
| `[RELIEVE]` | `RELIEVE` | ① 减压：压力 `-35` |
| `[BUFF]` | `BUFF` | ② 增益：为英雄附加 `inspired`（战意高涨），攻击力 `+20%`，持续 `INSPIRE_BUFF_ROUNDS = 3` 回合 |
| `[STRESS]` | `STRESS` | ③ 加压：压力 `+20` |
| `[BETRAY]` | `BETRAY` | ④ 攻击队友：随机一名存活队友，受 `攻击力 × 0.5` 伤害 |

- **标签解析**：`_parse_outcome_reply(raw, player_input)` 优先读标签；无标签时交给 `_keyword_outcome()` 关键词兜底（倒戈需明确暴力/背叛措辞才成立）；**若领主原话明显贬低（语气 ≤ -2）且台词又无姿态，则不会给出减压，至少按加压处理**。
- **领主语气分析（2026-09 新增）**：`evaluate_input_tone(text)` 给出整数评分（负=贬低/敌意，正=鼓舞/信任）。词表分四档：重贬 `-3`（废物/蠢/没用/懦弱/不如狗/滚/闭嘴…）、轻度负面 `-1`（必须/少废话/赶紧/失望/活该…）、高度鼓舞 `+3`（相信你/佩服/英雄/谢谢你/以你为荣…）、轻度正面 `+1`（勇敢/坚持/圣光/感激…）；**每档只取首个命中（`break`）**，避免“蠢货”同时命中“蠢”与“蠢货”而重复扣分。评分区间为 `[-4, +4]`。
- **Mock 分布权重**：`_generate_mock_result(is_crusader, hp, stress, player_input)` 先按 `stress/200` 与血量算基权重，再用语气评分修正——负面时长 `w_stress ×(1 + 严重度×2)`、`w_relieve` 几乎归零、`w_betray += max(严重度-0.5, 0)×0.5`（上限 0.35）；正面时反过来。
- **Prompt 引导**：把语气评分与可读标签（`input_tone_label()`）写进 System Prompt，并把判定尺度改为**“领主原话是首要依据、战场形势是次要依据”**：真诚鼓舞→减压/增益；质疑轻蔑→加压；明确贬低/辱骂/威胁抛弃→必须偏向加压、极端恶劣时可直接倒戈。

#### 关键方法

##### `get_hero_reply(...) -> Dictionary`
- **功能**：拼装大模型 Prompt 并向外部服务器发起异步并行的 HTTP POST 请求。
- **返回值**：`{"reply": String, "outcome": int}`（`outcome` 为 `LLMClient.Outcome` 四值之一）。
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
    "skeleton_arbalist": { "name": "Bone Arbalist",  "max_hp": 27, "attack": 7, "speed": 5,
                    "skills": ["arbalist_crossbow", "arbalist_bayonet"] },
    "skeleton_courtier": { "name": "Bone Courtier",  "max_hp": 22, "attack": 4, "speed": 6,
                    "skills": ["courtier_goblet", "courtier_dagger"] },
    "skeleton_common":   { "name": "Bone Soldier",   "max_hp": 32, "attack": 5, "speed": 4,
                    "skills": ["skeleton_melee"] },
    "skeleton_defender": { "name": "Bone Defender",  "max_hp": 45, "attack": 3, "speed": 2,
                    "skills": ["defender_axe", "defender_shield"] },
    "skeleton_militia":  { "name": "Bone Militia",   "max_hp": 30, "attack": 5, "speed": 4,
                    "skills": ["militia_slash", "militia_ranged"] },
    "skeleton_spear":    { "name": "Bone Spearman",  "max_hp": 30, "attack": 6, "speed": 5,
                    "skills": ["spear_thrust", "spear_pierce"] },
    # === 门前恶狼 BOSS 战（Brigand 火器小队）===
    "brigand_sapper":     { "name": "Brigand Vvulf",   "max_hp": 80, "attack": 7, "speed": 5,
                    "skills": ["sapper_throw", "sapper_summon", "sapper_barrage"] },
    "brigand_barrel":     { "name": "Brigand Barrel",  "max_hp": 50, "attack": 0, "speed": 0,
                    "skills": [], "inert": true, "life_link": "brigand_sapper" },
    "brigand_fuseman":    { "name": "Brigand Fuseman", "max_hp": 16, "attack": 4, "speed": 3,
                    "skills": ["fuseman_light_fuse", "fuseman_hot_shot"], "life_link": "brigand_cannon" },
    "brigand_cannon":     { "name": "Brigand Cannon",  "max_hp": 60, "attack": 6, "speed": 2,
                    "skills": ["cannon_fire", "cannon_summon", "cannon_blast"] },
}
static var CURRENT_ENCOUNTER: Array[String] = ["skeleton_common", "skeleton_defender", "skeleton_arbalist", "skeleton_courtier"]
```

> `speed_delta` 现由 `BattleController._start_new_round()` 每轮随机生成，`speed_delta_base` 字段已废弃。
> 新增可选字段：`skills`（技能 id 数组，空数组 = 永不行动）、`inert`（惰性单位，如弹药桶，永不进入行动队列）、`life_link`（生命链接：该怪阵亡时，`life_link` 指向它的怪物一同倒下）。当前遭遇为 4 只骷髅系怪物（勇士+盾卫+弩手+酒杯）。

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

### 问题 4：消耗品按钮左/右键都点不到
**症状**：消耗品格子（食物）能看见，但左键、右键点击均无反应  
**根本原因**：格子按钮最初挂载在 `PanelInventory`（仅 280×130）下，而背景贴图通过 `offset_left = 370` 画在父控件范围之外；Godot 的 GUI 命中测试（`has_point`）在父控件矩形外直接失败，不再向下递归到子按钮  
**解决方案**：
- 把槽位容器改挂到全屏的 `battle_ui`（`$BattleUI`）下
- 用 `panel_inventory_bg.get_global_rect()` 计算背景贴图的全局矩形作为槽位定位基准，使按钮命中区域与可见区域完全一致
- 首帧（布局稳定后）在 `_process` 中调用一次 `_build_inventory_panel()`（`_inventory_initialized` 标记防重入）
- 顺带把按钮触发改为左键（`MOUSE_BUTTON_MASK_LEFT`），并为「非英雄回合」「满血」等失败场景增加 `_show_toast()` 屏幕提示

### 问题 5：地图生成越界（Invalid assignment of index '5'）
**症状**：点击「开始战斗」进入地图生成时报 `_set_cell: Invalid assignment of index '5' (on base: 'Array')`  
**根本原因**：`_cell_kind()` 对空格与地图外都返回 `""`，`_empty_neighbors()` 未先判边界，把地图外格子（小地图第 5 行/列）当成可用空格写入候选，随后 `_set_cell()` 越界写入  
**解决方案**：在 `DungeonMap._empty_neighbors()` 中显式校验 `nr` / `nc` 是否在 `MAP_GRID` 范围内，越界邻居直接 `continue` 跳过

### 问题 6：新怪物贴图乱码 / 模型残缺（Unicode NUL 报错）
**症状**：控制台刷屏 `Unicode parsing error ... Unexpected NUL character`，且该怪物的插槽名变乱码、`attachments=0`、`anims=0`，模型不可见（实测：`brigand_fuseman`）  
**根本原因**：`.skel` 的 **IK 约束段**中 `bendDirection` 是**单字节有符号值**，而 `SpineSkel` 误用 varint 读取：`bend=+1` 写作 `01`（两种读法同为 1 字节，因此长期隐形），但 `bend=-1` 写作 `FF`，varint 因高位为 1 而**多吃 1 字节**，导致后续所有段落整体错位  
**解决方案**：新增 `_Reader.read_byte()`（单字节有符号）并在 IK 段使用。体检工具：`tools/_probe_skel_integrity.gd`（递归解析全部 `.skel`，当前基线 168 个中仅 `crusader.sprite.walk.skel` 为历史遗留 `anims=0`）；字节级定位：`tools/_diag_skel.py`

### 问题 7：BOSS 战尸体直立在场上 / 打掉尸体后补位错乱
**症状**：① 首领、大炮、点火员、弹药桶阵亡后尸体**笔直站着**，与活体无法区分；② 打掉尸体后前方怪物前移，但末位（4 号）卡槽仍残留旧血条与旧图标，看起来像补位错乱  
**根本原因**：  
① 这些骨架**没有独立 dead 动画**，`MONSTER_ANIM_CONFIG[id]["map"]["dead"]` 只是回落到 `"combat"`，所以播 dead 实际播的是站立动作。  
② `_update_list_ui()` 只遍历到 `heroes.size()` / `monsters.size()`，单位被移除后**尾部槽位没有被清理**。  
**解决方案**：  
- `_load_monster_anim()` 对"无真实 dead 动画"的骨架把资源整体换成**普通小怪残骸**（`CORPSE_REMAINS_DEFAULT`，默认 `brigand_cutthroat.sprite.dead`，与 BOSS 同属强盗阵营）；有真实 dead 动画的骨架不受影响；可在 `MONSTER_ANIM_CONFIG` 条目里用 `"corpse"` 字段单独指定。`_summon_monster()` 重建 SpinePlayer 时自然换回自身骨架。  
- `_update_list_ui()` 改为遍历**全部**槽位：先 `_clear_children()`，再按数组长度决定是否填内容。  
- 顺带补防守：`_update_character_portrait()` / `_update_skill_buttons()` 里 `heroes[current_actor["index"]]` 加下标范围校验（补位瞬间可能失效），否则会抛 `Invalid access of index '3' on ... 'Array[Dictionary]'`。

### 问题 8：英雄状态栏/死门提示被下方 UI 遮挡
**症状**：英雄卡槽里的状态异常图标行、`DEATH'S DOOR xx%` 行被左下角技能面板/背包面板盖住看不见  
**根本原因**：卡槽内容行累计高度约 293px（从槽顶 +70 到 +363），而下方不透明区域 `BottomPanelsContainer` 从 **y≈278** 开始 → 状态行（292~314）与死门行（318~336）整行落在遮挡区内  
**解决方案**：  
- 血条/压力条数值**内嵌到条上**（`_make_bar_value_label()`，`PRESET_FULL_RECT` + 居中 + 描边），省掉两行文本；条高 14→12，VBox `separation` 4→2、`alignment` 改为 `BEGIN`  
- 状态图标行、死门行、尸体标记行改挂**卡槽顶部悬浮区**（`TOP_OVERLAY_HEIGHT = 42`，锚在内容顶部、`alignment = END`），落在卡槽上方 `≈28~70` 的空闲带，既不遮挡也不挤压角色  
- "▲ 当前行动者"并入速度标签文本，省掉一整行  
- 结果：最低一行 237 ≤ 278，角色脚底仍 197（目标 200±8）；验证：`tools/_probe_corpse_ui.gd`，肉眼复核：`tools/_shot_check.gd`

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

### 7.8 消耗品背包系统

消耗品（食物 Food / 绷带 Bandage / 狗粮 Dog Food）在战斗界面左下角以 16 格网格渲染，左键点击即可使用。

**渲染与命中（`_build_inventory_panel()` / `_add_inventory_slot()`）**：
- 槽位容器挂载到全屏的 `battle_ui`（`$BattleUI`）下，而非 `PanelInventory`——后者仅 280×130，背景贴图通过 `offset_left = 370` 画在其矩形之外，会导致子按钮的命中测试（`has_point`）失效，表现为「能看到却点不到」。
- 定位基准：`panel_inventory_bg.get_global_rect()`，使槽位与背景可见区域完全重合。
- 16 格几何：主网格 7×2（左侧）+ 右侧独立列 2 格；每个格子是 `Button`（`flat`，`button_mask = MOUSE_BUTTON_MASK_LEFT`），显示图标 + 数量角标 `xN`。

**使用逻辑（`_try_use_consumable()`）**：
- 前置条件：非战斗结束、非特效暂停、当前行动者为英雄。
- 回血类（如食物）：英雄已满血时拒绝使用且不消耗；否则 `ActionResolver.apply_heal()` 回血（自动截断到 `max_hp`）。
- **治愈类（如绷带）**：由 `_use_cure_consumable()` 处理——仅当英雄身上确实带有 `cure_status` 中任一状态时才允许使用（否则提示且不消耗），逐个 `ActionResolver.remove_status()` 移除，并用 `_show_status_popup()` 弹出被治愈状态的图标。
- **增益类（如狗粮）**：由 `_use_buff_consumable()` 处理——`ActionResolver.apply_status()` 附加 `buff_status` 状态（持续 `buff_duration` 回合），`_show_status_popup()` 弹出增益图标并弹出提示。使用消耗品**不占用行动次数**，因此英雄可以先吃狗粮再出手，当次攻击即享受 +20% 伤害。
- 收尾：`_update_ui()` + `_build_inventory_panel()` 刷新（状态徽标同步消失/出现）。
- 失败反馈：`_show_toast()` 在视口上部居中显示「当前不是英雄行动回合，无法使用消耗品」/「生命已满，无需使用」/「没有可被绷带治愈的状态」。

**背包数据（`ConsumableConfig`）**：
- `INVENTORY`：`Array[Dictionary]`，最多 `MAX_SLOTS = 16` 格，同种无限堆叠。
- 增删接口：`add_item()` / `consume_item()` / `get_count()` / `get_item()`；开新局由 `StartController` 调用 `reset_inventory()` 发放初始补给（4 食物 + 2 绷带 + 2 狗粮），战斗胜利后由结算步骤继续补充。

### 7.9 技能 / 消耗品悬浮提示系统

鼠标悬浮在技能图标或消耗品格子上时，显示多行描述（名称 + 描述 + 可用位置 + 效果）。

**技能提示（`_build_skill_tooltip(sd)`）**：
- 名称、`description`、`use_positions`（使用位置）、`target_positions`（目标位置）。
- 位置说明「1=最前，4=最后」；有 `move_forward` 时显示「位移：前进/后退 N」；有 `target_move_forward` 时显示「目标位移：拉前 N 位 / 推后 N 位」。
- 效果：`damage` 显示「伤害 X% 攻击力」；`heal` 显示「治疗 X 点生命」；`composite_heal`（battle_cry）显示「回复 X 生命、X 压力；其他队友 -X 压力」。

**消耗品提示**：名称 + `description` + 「可用位置：无限制（对当前行动英雄使用）」+ 「效果：…」，效果行由配置驱动——有 `heal` 显示「回复 X 点生命」，有 `cure_status` 显示「治愈<状态名>」（如绷带显示「治愈流血」），有 `buff_status` 显示「附加<状态名>（N 回合）」（如狗粮显示「附加狗粮（1 回合）」）。

**实现**：直接赋值 `Button.tooltip_text`（多行用 `\n` 拼接）；技能图标按钮在 `_update_skill_buttons()` 创建时挂载，消耗品格子在 `_add_inventory_slot()` 创建时挂载。位置格式化由 `_format_positions()` 完成（`[1,2,3]` → `"1, 2, 3"`）。

### 7.10 状态异常（Buff / Debuff）系统

**数据定义（`StatusConfig.STATUSES`）**：

| 状态 | id | 关键字段 | 效果 |
|------|----|----------|------|
| 流血 | `bleed` | `dot = true` | 每回合扣除当前层数点生命 |
| 腐蚀 | `blight` | `dot = true` | 每回合扣除当前层数点生命 |
| 晕眩 | `stun` | `skip_turn = true` | 该单位行动时跳过一次行动，跳过即解除 |
| 标记 | `mark` | `damage_taken_mult = 1.3` | 承受伤害 +30%（不含流血/腐蚀等 DoT） |
| 守护 | `guard` | 携带 `guardian_id` / `guardian_slot` | 被敌人单体攻击时伤害转移给守护者 |
| 爆破标记 | `bomb_mark` | `manual_duration = true`, `detonate_damage = [14,20]` | 首领投弹锁定：下一回合开始时引爆造成 14~20 伤害（摧毁弹药桶可解除） |
| 装填完毕 | `cannon_loaded` | 大炮携带 | 大炮下次行动时向全体英雄开火（高额 AoE + 压力），开火后消耗 |
| 折磨 | `afflicted` | `stress_taken_mult = 1.2`, `manual_duration = true` | 精神崩溃：受到的压力 +20%，每次行动 30% 概率失控（详见 §7.14） |
| 美德 | `virtuous` | `manual_duration = true` | 压力清空并成为全队精神支柱（数值增益由 `virtue_buff` 承担） |
| 美德激励 | `virtue_buff` | `attack_mult = 1.2`（攻击力乘区，加算） | 攻击力 +20%，持续 5 回合（美德触发时施加给全体英雄；与战意高涨**加算**） |
| 狗粮 | `dogfood_buff` | `damage_mult = 1.2`（伤害乘区，乘算） | 最终伤害 +20%，持续 1 回合（消耗品「狗粮」使用后附加；与攻击力加成**乘算**） |
| 战意高涨 | `inspired` | `attack_mult = 1.2`（攻击力乘区，加算） | 攻击力 +20%，持续 3 回合（AI 激励喊话的 ② 增益结果；与美德激励**加算**） |

> **`manual_duration`**：存续回合数**不参与** `tick_statuses()` 的按回合衰减，完全由战斗逻辑显式移除（`bomb_mark` 在引爆或解除时由 `BattleController` 清除）。新增“寿命由事件掌握”的状态时务必加上该字段，否则它会在事件发生前自行消失。

**技能挂载**：`SkillConfig` 中为技能配置 `status_effects` 数组即可：

```gdscript
"status_effects": [{"status_id": "stun", "stacks": 1, "duration": 1}]
```

由 `ActionResolver.resolve_on_target()` 末尾统一调用 `apply_status()` 施加到目标（`resolve_on_all()` 会对每个存活目标逐个调用）。

**结算时机（重要）**：所有状态（DoT 伤害 + 持续时间/层数衰减）**都在该状态的携带者自己行动时结算**；回合开始（`_start_new_round()`）**不做任何统一结算**。唯一调用点是 `BattleController._tick_current_actor_statuses()`，由 `_get_next_actor()` 在弹出行动者后调用——因此 A 行动时不会消耗 B 身上的状态。验证结果（探针实测）：

| 动作 | 携带者 hp | 携带者状态 |
|------|-----------|-------------|
| 初始（bleed 3层/5回合、mark 1层/5回合） | 50 | `{bleed:3/5, mark:1/5}` |
| `_start_new_round()`（回合开始） | 50（不变） | 不变（不结算） |
| 携带者自己行动 | 47（-3） | `{bleed:3/4, mark:1/4}`（各 -1） |
| 队友行动 | 47（不受影响） | 不变 |

**DoT 结算**：`ActionResolver.tick_statuses(unit)` 扣血值 = 层数，随后 `duration - 1`，到期移除。对 `skip_turn = true` 的控制类状态**跳过 duration 递减**，交由行动判定处理。

**晕眩（`stun`）判定在单位行动时进行**（`BattleController._tick_current_actor_statuses()`，由 `_get_next_actor()` 在弹出行动者后立即调用）：

1. `ActionResolver.consume_skip_turn(unit)`：判定是否处于控制状态，命中则**立即移除**并返回 `true`（`has_skip_turn()` 为纯查询版本）。
2. 继续执行常规 DoT 结算（`tick_statuses`）与死亡/尸体处理。
3. 若单位仍存活且被晕眩 → `_skip_turn_by_stun(unit)`：
   - `unit["actions_remaining"] = max(0, ... - 1)` —— **真正消耗掉该次行动**。这一点很关键：若不扣点，队列耗尽时 `has_remaining_actions()` 会让它被重新 `build()` 入队，只是"延后"而非"跳过"。
   - `_show_status_popup()` 在头顶弹出 `res://overlays/tray_stun.png` 图标（复用 `_show_stress_seal_delayed()` 的上浮淡出）。
   - `_update_ui()` 刷新，使状态徽标同步消失。
4. 函数返回 `false` → `_get_next_actor()` 的 `continue` 直接取下一个行动者（随后照常执行 `_check_victory()` / `_check_defeat()` 判定）。

**UI**：
- `_make_status_row(unit)` 在血条（怪物）/ 压力条（英雄）下方渲染状态图标；**只有 `dot` 状态显示层数角标**。
- `_build_status_tooltip()` 对 `skip_turn` 状态只显示名称 + 描述；其余显示「剩余回合」，仅 `dot` 追加「层数」。
- `_build_skill_tooltip()` 中 `skip_turn` 状态显示为「跳过下一次行动（跳过即解除）」。

**易伤（`mark`）结算**：
- `ActionResolver.get_damage_taken_multiplier(target)` 取目标身上所有 `damage_taken_mult` 的最大值。
- `apply_damage(target, amount, apply_mark_mult := true)` 在扣血前按倍率放大；**DoT 结算显式传 `apply_mark_mult = false`**，保证流血/腐蚀不吃标记加成。
- 浮字伤害由 `_emit_feedback()` 对比结算前后 hp 差值生成，因此标记放大后的数字会自动正确显示。

**守护（`guard`）伤害转移**：
- 施加：`ActionResolver.apply_guard(guardian, target, duration)`，不叠加层数、重复施放直接覆盖；守护者身份用 `(guardian_id, guardian_slot)` 记录（英雄换位会改变 `heroes` 下标，但 `id`/`slot` 始终跟随本人）。
- 转移：`BattleController._resolve_guard(unit)` 在**敌人单体攻击**选中目标后调用——命中被守护者时改为打守护者；守护者阵亡/濒死之外不转移、指向自己也不转移。挂接点在 `_execute_monster_action()` 的 `single_enemy` 分支，**群体技能（`all_enemies`）不受影响**。
- 持续：`duration` 在被守护者自己的行动回合递减（与其他非 DoT 状态一致）。

### 7.11 训犬师（Houndmaster）配置

英雄模板位于 `HeroConfig.HEROES["houndmaster"]`（HP 45 / ATK 18 / SPD 4），4 个技能定义在 `SkillConfig.SKILLS`，动画与特效分别接入 `BattleController` 的 `HOUNDMASTER_ANIM_MAP` / `SKILL_FX_MAP`。

| 技能 | 效果类型 | 机制 | 动画 | 特效 |
|------|----------|------|------|------|
| 释放猎犬 | `damage` | 远程单体，可打任意站位（`use_positions [2,3,4]` / `target_positions [1,2,3,4]`） | `attack_rush` | `hounds_rush` |
| 标记弱点 | `damage` + `status_effects` | 小额伤害并附加 `mark`（承受伤害 +30%，持续 3 回合） | `attack_point` | `whistle` |
| 振奋犬吠 | `composite_heal` | 选中队友 -6~8 压力、其他队友 -2~3 压力（结构同 `battle_cry`） | `attack_howl` | `baleful_howl` |
| 守护队友 | `guard` | 为队友附加 `guard`，敌人单体攻击转移给训犬师，`guard_duration = 3` | `attack_guard` | `guard_dog` |

接线点：
- `BattleController.HERO_SPINE_IDS`（`["crusader","highwayman","occultist","houndmaster"]`）决定 `_setup_battle()` 为哪些英雄创建 SpinePlayer。
- `_load_hero_anim()` 中新增 `houndmaster` 分支，PNG 目录 `res://characters/houndmaster/houndmaster_A/anim`。
- 头像 `characters/houndmaster/houndmaster_guild_header.png`、技能图标 `houndmaster.ability.{one..four}.png` 均已就绪；`HeroConfig.get_all_hero_ids()` 可列出全部英雄 id（编队选择界面已移除，该接口仍供数据层使用）。

### 7.12 门前恶狼 BOSS 战（Brigand 火器小队）

地图 Boss 房遭遇固定为 `DungeonMap.BOSS_ENCOUNTER = ["brigand_sapper", "brigand_barrel", "brigand_fuseman", "brigand_cannon"]`（下标即站位）：

| 站位 | 怪物 | HP / ATK / SPD | 行为 |
|------|------|----------------|------|
| 1 | 首领 Brigand Vvulf (`brigand_sapper`) | 80 / 7 / 5 | 弹药桶在场时投弹标记；不在场时召回弹药桶或炮击前排两位 |
| 2 | 弹药桶 Brigand Barrel (`brigand_barrel`) | 50 / — / — | **惰性单位**（`inert`），永不行动，仅作为首领的“弹药” |
| 3 | 点火员 Brigand Fuseman (`brigand_fuseman`) | 16 / 4 / 3 | 为大炮装填引信；大炮阵亡时一同倒下 |
| 4 | 大炮 Brigand Cannon (`brigand_cannon`) | 60 / 6 / 2 | 装填完毕时全体轰击；点火员不在场时召回点火员 |

**四条联动规则**：

1. **投弹标记（`sapper_throw`）**：`effect_type: "apply_status"`，不给伤害，给英雄挂 `bomb_mark`（状态带 `manual_duration: true`，不参与 `tick_statuses` 的回合衰减）。
2. **下回合引爆（不占行动）**：投弹时 `_register_pending_bomb()` 把 `{"hero_slot", "due_round"}` 写入 `_pending_bombs`；下个回合开始时 `_start_new_round()` → `_resolve_pending_bombs()` 引爆，播放 `detonate_target` 特效并造成 `detonate_damage`（14~20）伤害。**属于 debuff 结算行为，不进行动队列、不扣任何人的 `actions_remaining`。**
3. **弹药桶决定投弹权限**：`sapper_throw` 带 `requires_alive_ally: ["brigand_barrel"]`；`sapper_summon` / `sapper_barrage` 带 `requires_absent_ally: ["brigand_barrel"]`，因此“桶在则投弹、桶亡则召回或炮击”由条件系统自动成立。
4. **大炮 ↔ 点火员**：`fuseman_light_fuse`（`target_ally_id: "brigand_cannon"` + `target_ally_status_absent: "cannon_loaded"` + `skill_priority: 1`）装填——只要大炮还需装填，点火员就**一定**点火而不会改用备选攻击；`cannon_fire`（`requires_self_status` + `consume_self_status: "cannon_loaded"`）装填后全体 AoE 并在开火后卸弹；`cannon_summon`（`requires_absent_ally: ["brigand_fuseman"]`）与 `cannon_blast`（需点火员在场且自身未装填）保证三招互斥。

**反制（可玩性）**：摧毁弹药桶 → `_disarm_pending_bombs()` 立即清除所有 `bomb_mark`（`_resolve_pending_bombs()` 还有“无桶则哑弹”的第二道保险）；杀死点火员 → 大炮当回合只能召回；**生命链接**（`life_link`）让大炮阵亡时点火员随之倒下、首领阵亡时弹药桶随之损毁。

**战斗内召唤（`_summon_monster()`）**：优先占用尸体槽位（直接替换 `monsters[slot]`，不改变其它单位索引），其次追加队尾，槽位满则放弃；新单位 `actions_remaining = 0`，登场当回合不行动；Spine 渲染按 `MONSTER_ANIM_CONFIG` 重建。

**验证**：`godot --headless --path <项目> --script res://tools/_probe_boss_battle.gd`（106 条断言：数据接线 / 投弹引爆 / 弹药桶解除 / 装填开火 / 召唤 / 生命链接，输出 `PASS=106 FAIL=0`）；`res://tools/_probe_boss_live.gd` 则逐只怪物真实跑 `_execute_monster_action()` 全程（含特效与召唤，`PASS=11 FAIL=0`）。

### 7.13 死门（Death's Door / 濒死）机制

死门是英雄独有的「濒死续命」机制，实现集中在 `BattleController._handle_hero_damage_aftermath(hero_idx, took_damage := true)`：

| 情形 | 处理 |
|------|------|
| 生命值首次降至 0 | **不会立刻死亡**，而是进入濒死状态（`is_death_door = true`、`hp = 0`），头顶弹出 `tray_deathsdoor.png` 图标 |
| 濒死状态下**受到伤害** | 按该角色自己的 `death_blow_chance` 掷一次死亡骰：命中则当场阵亡（`_kill_hero`），否则继续支撑并弹出 `poptext_death_avoided.png`（死里逃生） |
| 治疗等**非伤害结算**（`took_damage = false`） | 不掷骰；只要生命值回复到 0 以上就自动脱离濒死 |
| 濒死期间 | 仍可正常行动（`TurnQueue` 把濒死视为存活）、可被治疗/守护、也可被选为目标 |

**概率写在每个角色自己的配置里**：`HeroConfig.HEROES[hero_id]["death_blow_chance"]`（当前 4 名角色均为 `0.5`），未配置时回落到 `HeroConfig.DEFAULT_DEATH_BLOW_CHANCE`。战斗开始时由 `_death_blow_chance_of()` 写入英雄运行时字典，掷骰处再 `clampf` 夹逼一次。

**`took_damage` 参数（重要）**：只有「真的挨了伤害」才掷死亡骰，因此各调用点显式区分：

| 调用点 | 传参 | 说明 |
|--------|------|------|
| DoT 结算（`_tick_current_actor_statuses`） | `true` | 流血/腐蚀造成伤害时掷骰 |
| 怪物单体 / 群体技能（`_execute_monster_action`） | `is_dmg` | 仅 `effect_type == "damage"` 的技能才掷骰 |
| 首领炸药引爆（`_detonate_bomb`） | `true` | 爆炸是真实伤害 |
| 激励倒戈攻击队友（`_execute_inspire_betrayal`） | `true` | 真实伤害 |
| 治疗技能（`_on_ally_pressed`）/ 消耗品回血（`_try_use_consumable`） | `false` | 治疗不是伤害；**修掉了旧版「为队友治疗/治疗量掷出 0 时也会给濒死队友掷死亡骰」的误杀缺陷** |

**UI**：濒死英雄的卡槽在血条/压力条下方渲染 `_make_hero_slot()` 的死门行——`tray_deathsdoor.png` 图标 + `DEATH'S DOOR 50%` 文本，悬浮提示说明机制与本次角色自己的死亡概率。

**持久化**：`HeroConfig.PARTY_STATES` 已记录 `is_death_door`，跨房间战斗会延续濒死状态（0 HP 起手＝濒死）。

**验证**：`godot --headless --path <项目> --script res://tools/_probe_deaths_door.gd`（33 条断言：角色配置接线、归零不死、濒死仍可入队、0%/100% 概率边界、非伤害结算不掷骰、治疗后脱离濒死、卡片死门图标与概率提示渲染，输出 `PASS=33 FAIL=0`）。

### 7.14 压力系统：折磨（Affliction）/ 美德（Virtue）

数值与概率集中在 `scripts/data/StressConfig.gd`（均为 `static var`，方便探针脚本临时改写以确定性覆盖各分支）：

| 常量 | 默认值 | 含义 |
|------|--------|------|
| `MAX_STRESS` | 200 | 压力上限（满值触发心脏骤停） |
| `AFFLICTION_THRESHOLD` | 100 | 越阈掷骰的阈值 |
| `AFFLICTION_CHANCE` | 0.75 | 越阈后进入折磨的概率 |
| `VIRTUE_CHANCE` | 0.25 | 越阈后进入美德的概率 |
| `AFFLICTION_STRESS_TAKEN_MULT` | 1.2 | 折磨状态下受到的压力倍率 |
| `BREAKDOWN_CHANCE` | 0.3 | 折磨状态下每次行动的失控概率 |
| `BREAKDOWN_ATTACK_RATIO` | 0.5 | 失控"攻击队友"的伤害系数 |
| `BREAKDOWN_STRESS_AMOUNT` | [8, 14] | 失控"增加队友压力"的压力区间 |
| `VIRTUE_ATTACK_MULT` / `VIRTUE_BUFF_ROUNDS` | 1.2 / 5 | 美德激励的攻击力倍率与持续回合数 |

**结算流程**

1. **越阈掷骰（以状态为准，不按战斗重置）**：`ActionResolver.apply_stress()` 发现英雄压力越过 100、
   且**当前既没有折磨也没有美德**时，先**钳制到 100** 并打上 `stress_resolve_pending`；
   随后 `BattleController._resolve_pending_stress_states()`（由 `_emit_feedback()` 末尾与激励喊话路径调用）执行 `_resolve_stress_threshold()`：
   - **75% 折磨**：施加 `afflicted`，头顶弹出 `tray_afflicted.png` + `panels/seal.affliction.png`，Toast 提示；
   - **25% 美德**：压力清零 + 施加 `virtuous`，并给**全体英雄**施加 `virtue_buff`（`attack_mult = 1.2`，持续 5 回合）。
   - 掷出的状态会挂在身上，因此在持有期间**不会重复钳制/重掷**，压力可正常累到 200；
     状态被清掉（见下条）后再度越阈则会重新掷骰。
2. **三条清零 / 满值规则**：

   | 时机 | 行为 |
   |------|------|
   | 压力**归零** | 解除折磨（减压类效果如激励喊话、鼓舞犬吠、美德清空都能让英雄平静下来） |
   | 压力**达到 200** | 清除美德 → 压力清零（连带清除折磨）→ `apply_damage(999)`（心脏骤停） |
   | 200 **且折磨且已在濒死** | 额外打上 `instant_death` 标记，`_handle_hero_damage_aftermath()` 直接处决（不掷死门死亡骰） |

3. **跨战斗保留**：折磨 / 美德与压力一起持久化——`HeroConfig.persist_party_after_battle()` 把 `is_afflicted` / `is_virtuous` 写入 `PARTY_STATES`，
   `get_team_heroes()` 还原到编队模板，`BattleController._build_hero_runtime()` 再还原成状态。`virtue_buff` 是限时增益，不跨战斗。
4. **折磨失控（30%）**：`_get_next_actor()` 轮到英雄行动时调用 `_should_roll_breakdown()`，命中则本回合改由
   `_execute_affliction_breakdown()` 接管，四种行为等概率（`BREAKDOWN_OUTCOMES`）：

   | 行为 | 实现 |
   |------|------|
   | 跳过行动 | 直接消耗行动点（与晕眩跳过一致） |
   | 攻击队友 | 复用 `_execute_inspire_betrayal(actor, StressConfig.BREAKDOWN_ATTACK_RATIO)` |
   | 增加队友压力 | `_execute_breakdown_stress_ally()`：对随机队友加 8~14 压力（会连带触发对方的越阈结算） |
   | 自动随机行动 | `_auto_perform_random_action()`：随机挑一个站位可用、目标合法的技能，然后走**与玩家操作完全相同**的结算流程（特效/聚焦/数值/扣点/推进队列） |

   > 失控行为均会消耗该英雄本回合行动点（手动扣点 + `turn_queue.build()`）；"自动随机行动"因为走的是正常技能流程，内部已扣点并推进队列，因此 `_execute_affliction_breakdown()` 返回 `true` 让 `_get_next_actor()` 直接 `return`，避免双重推进。
   > 无可用技能/无队友可打时自动退化为"跳过行动"；濒死（HP = 0）英雄因 `_can_act()` 不通过也会退化为跳过。
3. **攻击力加成（两个乘区）**：`ActionResolver.calculate_damage()` 会乘上 `get_attack_multiplier()`（美德激励 / 战意高涨，**彼此加算**）与 `get_damage_multiplier()`（狗粮，**乘算**）——因此美德激励对**所有英雄**的伤害技能生效，且不会与战意高涨叠成 ×1.44。
6. **UI**：状态图标行显示折磨/美德/美德激励（带悬浮说明）；折磨状态下英雄的压力条填充色转为暗红作为警示。

**验证**：`godot --headless --path <项目> --script res://tools/_probe_stress.gd`（75 条断言：配置接线、越阈钳制与两种掷骰结果、以状态为准不重复掷骰、折磨加压 +20%、压力归零解除折磨、美德清空压力与全体 5 回合攻击加成、四种失控行为、200 的清美德/清折磨/濒死直接处决、跨战斗持久化、与 `_emit_feedback` 的集成，输出 `PASS=75 FAIL=0`）。

### 7.15 怪物尸体视觉与卡槽（补位 / 布局）

**尸体视觉（直接借用普通小怪残骸）**：怪物阵亡后 `_handle_monster_damage_aftermath()` 会把它标成尸体（`is_corpse = true`、`hp = 10`），
`_update_monster_animations()` 对尸体调 `_load_monster_anim(i, "dead")`。但首领/大炮/点火员/弹药桶的骨架**没有独立 dead 动画**（`map["dead"] == map["combat"]`），
因此 `_load_monster_anim()` 在加载时把这类尸体的资源整体换成**普通小怪的残骸**：

| 情况 | 表现 |
|------|------|
| 骨架有真实 dead 动画（强盗/骷髅系） | 照旧播自己的 `dead` |
| 骨架无真实 dead 动画 | 加载 `CORPSE_REMAINS_DEFAULT`（默认 `brigand_cutthroat.sprite.dead`，`base`/`dir`/`anim` 三字段）并 `play("dead")` |

- 需要单独指定时，在 `MONSTER_ANIM_CONFIG` 条目里加 `"corpse": {"base": ..., "dir": ..., "anim": ...}`（优先读它）。
- 残骸自带倒地姿态，且其几何底部与站立骨架脚底同高（实测屏幕上尸体矩形 `281~359` vs 站立单位脚底 `361`）→ 尸体正好躺在地面线上，无需再压暗/旋转。
- `_summon_monster()` 会销毁并重建该槽位的 SpinePlayer，因此召唤回尸体槽时自动换回自己的骨架。

**卡槽补位**：`_update_list_ui()` 遍历**全部** 4 个 `hero_slots` / `monster_slots`——先 `_clear_children()`，再按数组长度决定是否填内容，
这样单位被移除（清尸体、英雄阵亡）后尾部槽位不会残留旧的血条与图标。

**卡槽纵向布局预算**（720p 下 `BottomPanelsContainer` 顶边 ≈278，卡槽内容必须全部落在其上）：

| 行 | 全局 Y | 手法 |
|----|--------|------|
| 顶部悬浮区（状态图标 + 死门/尸体标记） | ≈28~70 | `TopOverlay` 锚在内容顶部、`offset_top = -TOP_OVERLAY_HEIGHT`、`alignment = END`，占用卡槽上方空闲带 |
| 速度标签（含 `▲` 当前行动者标记） | 70~87 | 字号 12；行动标记并入文本省一行 |
| 肖像锚点（SpinePlayer 定位基准） | 89~209 | 脚底 197≈200 |
| 血条 / 压力条（数值内嵌） | 211~223 / 225~237 | `_make_bar_value_label()` 铺满居中，条高 12、`separation = 2` |

**验证**：`godot --headless --path <项目> --script res://tools/_probe_corpse_ui.gd`（`PASS=28 FAIL=0`）；肉眼复核：`godot --path <项目> --script res://tools/_shot_check.gd` → `res://shot_check.png`。

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

### 7.16 战斗结算（战利品）步骤

每场战斗**胜利后**增加一步「结算」：在屏幕右侧弹出战利品面板，玩家点击确认后才把补给放入物品栏（失败没有战利品，直接放行）。

**战利品表（`BattleController.BATTLE_LOOT_TABLE`）**：

| 物品 | 数量 | 说明 |
|------|------|------|
| `food` | 1~4 | 必定掉落 |
| `bandage` | 0~1 | 概率掉落 |
| `dogfood` | 0~1 | 概率掉落 |

数量为 `[min, max]` 区间，由 `ActionResolver.roll_range_int()` 掷取；掷到 0 的条目不会出现在面板上（`_roll_battle_loot()` 只保留 `count > 0` 的条目）。

**流程（`_end_battle()`）**：
1. `battle_over = true`；顶部新增 `if battle_over: return` 守卫，避免胜负判定被重复触发时重复掷战利品。
2. 胜利 → `_begin_loot_step()`：掷战利品、`_show_loot_panel()` 弹出面板、`back_button.disabled = true`（未确认前不能离开战斗）。
3. 失败 → `_hide_loot_panel()` 并确保返回按钮可用。

**UI（`_create_loot_ui()`，代码构建，`_ready()` 中创建）**：
- 独立 `CanvasLayer`（`LootLayer`，`LOOT_LAYER = 110`，高于激励喊话层的 100），内含全屏半透明遮罩 `loot_modal`（同时用于屏蔽下层点击）与右侧 `loot_panel`。
- 面板锚点固定为屏幕右边缘（`anchor_left = anchor_right = 1.0`，`offset_left = -300`、`offset_right = -20`）→ 1280 宽下位于 `x = 980~1260`，与居中的胜利面板（`anchors 0.25~0.75`，`x = 320~960`）不重叠；垂直居中（`offset_top = -200`、`offset_bottom = 200`）。
- 内容：标题「战利品」+ 提示「点击确认将战利品放入物品栏」+ 动态生成的物品行（`_make_loot_row()`：图标 + 名称 + `xN`，悬浮显示道具描述）+ 「确认」按钮。

**确认（`_on_loot_confirm_pressed()`）**：逐条 `ConsumableConfig.add_item()` 入包 → 收起面板 → 解锁返回按钮 → `_build_inventory_panel()` 刷新背包（槽位已满时弹出 `_show_toast()` 提示）。背包右上角图标数量同步 +N，下一场战斗继续累积。

**验证**：`tools/_probe_loot_dogfood.gd`（42 条断言，`PASS=42 FAIL=0`：配置/初始数量/攻击力倍率/1 回合到期/300 次掷取范围/面板锚定与不重叠/结算流程与入包）；`tools/_shot_loot.gd` 非无头渲染一帧存 `res://shot_loot.png` 供肉眼核对。

---

### 7.17 背景音乐（BGM）系统

**素材来源**：游戏自带的 `audio/secondary_banks/music.bank`（原版《暗黑地牢》的 FMOD Studio 音效库，64 首曲目）。Godot **不能直接播放** FMOD bank，因此先用 `tools/extract_fmod_bank.py` 把需要的曲目解码导出成 `audio/bgm/*.ogg`（5 个文件、共约 2.9MB）。

**曲目表（`BgmManager.CUES`）**：

| cue | 前奏（只播一次） | 循环段 | 音量 | 使用场景 |
|-----|------------------|--------|------|----------|
| `title` | `mus_theme_intro_v2.ogg`（19.0s） | `mus_theme_loop.ogg`（12.2s） | -8 dB | 闪屏 / 开始菜单 |
| `map` | — | `Explore_Vaults_Level_1_Loop.ogg`（128s） | -10 dB | 地图探索 |
| `battle` | `Combat_Level1_Intro.ogg`（3.2s） | `Combat_Level1_Loop1.ogg`（51.2s） | -9 dB | 战斗 |

**管理器（`scripts/core/BgmManager.gd`，Autoload 名 `Bgm`）**：
- 注册方式：`project.godot` → `[autoload] Bgm="*res://scripts/core/BgmManager.gd"`。因为挂了 Autoload，`change_scene_to_file` 换场景**不会中断音乐**。
- **两个 `AudioStreamPlayer` 交叉淡入淡出**（`FADE_TIME = 0.8s`）：新曲目淡入、旧曲目淡出后 `stop()`，避免场景切换时硬切。
- **前奏 → 循环**：`play()` 时若 cue 定义了 `intro`，先播前奏并置 `_awaiting_intro`；`finished` 信号回调里换成 loop 段并 `play()`（原版标题/战斗音乐就是这个结构）。
- `_load_stream(file, looping)` 在**运行时**设置 `AudioStreamOggVorbis.loop`（OGG 的循环开关不需要改导入参数）。
- `process_mode = ALWAYS`：即使 `get_tree().paused` 也不停音乐；同 cue 重复 `play()` 不会重头播。

**接入点**：`StartController._ready()` → `title`、`MapController._ready()` → `map`、`BattleController._ready()` → `battle`。

**验证**：`tools/_probe_bgm.gd`（`PASS=42 FAIL=0`）：Autoload 存在、5 个音频都能加载且时长与 bank 内一致、循环标志正确、前奏结束自动接循环、切曲目换播放器、同曲重复调用不重头播、`stop()` 清空当前曲目。

---

### 7.18 战斗音效（SFX）系统

**素材来源**：`audio/secondary_banks/hero_*.bank`（英雄技能音效与通用命中层）、`en_crypts.bank`（骸骨系怪物）、`en_shared.bank`（强盗系怪物）、`ui_dungeon.bank` + `ui_shared.bank`（结算弹窗与按钮音）。这些库是 **FSB5-Vorbis**（与 BGM 的 FADPCM 不同），setup 头外置，提取时需要 `--codebooks tools/_vgmstream/vorbis_codebooks_fsb.h` 补全并重封装成 Ogg（详见 TECH_GUIDE 12.2）。

共提取 **91 个**（5.6MB）：

| 目录 | 内容 | 数量 |
|------|------|------|
| `audio/sfx/` | 英雄技能 `char_al_*`（含 `_miss` 挥空版）、通用命中层 `char_share_imp_*`、重击甜化层 | 54 / 3.7MB |
| `audio/sfx/enemy/` | 怪物技能 `char_en_skl*`（骸骨）/ `char_en_brig*`（强盗） | 31 / 1.7MB |
| `audio/sfx/ui/` | 结算弹窗 / 按钮音（`ui_dun_loot_popup_battle` 胜利、`ui_shr_window_popup` 战败、`ui_dun_loot_popup_chest` 领奖、`ui_shr_button_click` 点击） | 6 / 0.3MB |

**管理器（`scripts/core/SfxManager.gd`，Autoload 名 `Sfx`）**：

- **12 个 `AudioStreamPlayer` 轮转池** —— 同一帧叠多个音效（施法音 + 命中音、AoE 打多人）不会互相打断；池满时覆盖最旧的一个，比排队延迟手感好。
- **技能 id → 音效文件** 的表：`HERO_SKILL_SFX`（英雄两层索引 `hero_id → skill_id`）、`MONSTER_SKILL_SFX`（只按 `skill_id`）、`HERO_SKILL_MISS_SFX` / `MONSTER_SKILL_MISS_SFX`（挥空）、`IMPACT_SFX`（武器类型 → 打击层）、`SKILL_IMPACT`（技能 → 武器类型）。
- **运行时随机化**：每次播放 ±4% 音高、±1.5dB 音量，重复出招不会听起来像复读机。
- 文件缺失时静默返回 `false`，素材可以逐步补齐而不报错。
- `process_mode = ALWAYS`：暂停游戏时音效照常播放。

**接口**：

```gdscript
Sfx.play_skill_cast(skill_id, hero_id)  # 施法音
Sfx.play_skill_impact(skill_id)         # 命中层（治疗/增益类无条目 → 静音）
Sfx.play_impact("sword")               # 直接按武器类型播
Sfx.play_skill_miss(skill_id)           # 挥空音
Sfx.play("enemy/char_en_sklcom_cudgel", - 9.0)
```

**战斗接入点（集中两处，不散落到各个分支）**：

| 位置 | 行为 |
|------|------|
| `_play_skill_fx_v2()` 开头 | 播施法音，并记下 `_pending_impact_skill`。放在 `SKILL_FX_MAP` 校验**之前** —— 没配 Spine 特效的技能也要有声音 |
| `_emit_feedback()` 开头 | 用快照差值判断：真掉血 → 叠命中层（AoE 只响一次，命中数越多音量略高）；一点血没掉 → 挥空音；随后清空待结算状态 |
| `_execute_inspire_betrayal()` | 倒戈一击额外叠一句刀剑命中音 |
| `_detonate_bomb()` | 炸药引爆 = 重击甜化层 + 火器音 |

**命中层的意义**：英雄技能音本身就是“武器出招”的声音，但“打中了”需要一层统一的肉体/金属反馈才能听起来“落实”。因此每次成功掉血都会再叠一层 `char_share_imp_*`（刀/斧/锤/小刀/盾/枪/箭/光魔法/暗魔法/重击）。

**验证**：`tools/_probe_sfx_battle.gd`（`PASS=50 FAIL=0`）：表↔文件一致性、`SKILL_FX_MAP` 37 个技能全覆盖、战斗内真播到正确文件、掉血/零伤害分流、治疗不误响、池不扩容。

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
    "speed_delta_base": 0,
    "skills": ["skeleton_melee"]   # 技能 id 数组；空数组 = 永不行动（惰性单位）
}
```
然后在 `BattleController.MONSTER_ANIM_CONFIG` 中登记一条（`{base, dir, map}`）——渲染白名单与 `_load_monster_anim()` 都读这张表，**无需改函数分支**：
```gdscript
"skeleton": {"base": SKELETON_ANIM_BASE, "dir": SKELETON_PNG_DIR, "map": SKELETON_ANIM_MAP},
```
最后将 ID 加入 `CURRENT_ENCOUNTER`（或在关卡切换时覆盖该数组，Boss 房用 `DungeonMap.BOSS_ENCOUNTER`）。

> **注意**：怪物站位由其在遭遇数组中的下标决定（下标 0 = 1号位）。英雄技能的 `target_positions` 将基于此下标+1进行过滤。
> 可选字段：`inert`（惰性，永不进入行动队列）、`life_link`（生命链接：该怪阵亡时，`life_link` 指向它的怪物一同倒下）。
> 若新怪物的 PNG 尚未导入（控制台报 `No loader found for resource: ...png`），先跑一次 `godot --headless --path <项目> --import` 或打开一次编辑器。

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
- `tick_statuses(unit)` — 在**该单位自己行动时**结算 DoT 伤害与所有状态的持续时间（回合开始不结算，详见 §7.10）
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
6. ik_count varint       — IK 约束数量（十字军 = 0；训犬师 idle/walk = 5、combat = 4）
   每条约束: name(string) + bonesCount(varint) + bones[boneIdx...] + target(varint) + mix(float) + bendDirection(1 字节有符号)
   ⚠️ 详情块紧跟在名称之后，**必须完整消费**，否则后续 slot/skin/animation 全线错位
   ⚠️ bendDirection 是**单字节有符号值**，不能用 varint 读：bend=+1 写作 01（两种读法同为 1 字节，
      因此该 bug 长期隐形），但 bend=-1 写作 FF，varint 会因高位为 1 而多吃 1 字节 →
      后续全部段落偏移 1 字节（症状：插槽名乱码 + attachments=0 + anims=0 + 刷屏 NUL 报错）。
      实测受害者：brigand_fuseman.sprite.combat.skel（left_leg_IK 的 bend 为 -1）。
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
   - **越界防护**：`parent_index` 越界（`< 0` 或 `>= _bone_world.size()`）时回退为自身局部变换，避免骨骼数据异常导致 `Out of bounds` 崩溃

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
     - **越界防护**：`slots[si].bone_index` 越界时 `bone_t` 回退为 `Transform2D.IDENTITY`，保证异常骨骼索引不致崩溃
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

### 4.19 map/DungeonMap.gd

**类名**：`DungeonMap`  
**类继承**：`extends Node`  
**模式**：静态单例（class_name + static 变量/方法）  
**职责**：地图尺寸配置、随机地图生成、房间/走廊/遭遇数据管理。

**静态变量**：

| 变量 | 说明 |
|------|------|
| `MAP_SIZE` | 地图尺寸：`"small"` / `"medium"` / `"large"` |
| `BRANCHINESS` | 扩散倾向：0=一条路径，1=四通八达，默认 0.5 |
| `MAP_GRID` | 随机生成的二维数组（`"start"` / `"normal"` / `"boss"` / `""`） |
| `START_ROOM` / `BOSS_ROOM` | 起始房 / Boss 房 id |
| `current_room` / `cleared_rooms` | 当前房间 / 已清除房间列表 |
| `ENCOUNTER_POOL` / `BOSS_ENCOUNTER` | 随机遭遇池 / Boss 房遭遇 |

**关键方法**：

| 方法 | 职责 |
|------|------|
| `set_size(key)` | 设置地图尺寸 |
| `set_branchiness(value)` | 设置扩散倾向（0~1） |
| `reset_run()` | 重新随机生成一张当前尺寸的地图 |
| `roll_encounter(room_id)` | 为指定房间掷出随机遭遇（Boss 房返回 BOSS_ENCOUNTER） |
| `get_grid_cols()` / `get_grid_rows()` | 返回网格行列数 |
| `get_all_room_ids()` / `get_room(id)` | 供渲染层遍历房间 |
| `are_connected(a, b)` / `get_connected_rooms(id)` | 走廊连通查询 |
| `is_cleared(id)` / `mark_cleared(id)` | 已清除房间查询/标记 |
| `is_boss_room(id)` / `move_to(id)` | Boss 判定 / 移动当前房间 |

**生成算法（`_generate_map()`）**：
1. 全图随机选一个格子作为起点。
2. 从已有房间向四周扩散（线性/分支由 `BRANCHINESS` 决定），直到达到目标房间数（小 10 / 中 15 / 大 20）。
3. 用 BFS 计算各房间到起点的行走步数，选最远的房间作为 Boss。

**边界防护（`_empty_neighbors()`）**：`_cell_kind()` 对「空格」和「地图外」都返回 `""`，若 `_empty_neighbors()` 不先判边界，会把地图外格子当成可用空格，导致 `_set_cell()` 以越界下标（如小地图第 5 行/列）写入而报 `Invalid assignment of index '5'`。现已显式校验 `nr` / `nc` 是否在 `MAP_GRID` 范围内，越界邻居直接跳过。

---

### 4.20 map/MapController.gd

**类继承**：`extends Node`  
**挂载场景**：`scenes/map/Map.tscn`  
**职责**：渲染随机生成的地图（房间方块 + 走廊），处理房间点击与场景跳转。

**关键函数**：

| 函数 | 职责 |
|------|------|
| `_build_ui()` | 构建全屏 UI；地图内容放入带 `clip_contents` 的 `MapViewport`，其下 `MapRoot(Node2D)` 负责平移 |
| `_draw_corridors()` | 用 `Line2D` 绘制房间之间的走廊（挂到 `MapRoot`） |
| `_refresh_rooms(animate)` | 重建房间按钮层（移动已清房后刷新），末尾重新居中 |
| `_center_on_current_room(animate)` | 整张地图平移 `视口中心 - 当前房间中心`，使当前房间永远在视野正中（补间 0.28s） |
| `_create_room_button()` | 生成单个房间按钮（当前/已清/有敌/禁用样式） |
| `_update_status()` | 更新当前房间与相邻房间状态文本 |
| `_on_room_clicked(id)` | 已清房直接移动；未清房掷遭遇并跳转战斗 |
| `_on_abandon_pressed()` | 放弃本局，返回开始画面 |

**显示缩放**：固定 `ROOM_SIZE=76` / `STEP_X=150` / `STEP_Y=126`（不再按网格缩到刚好装下整张图）；中/大地图超出视口的部分被裁掉，靠平移查看（视野外的房间按钮本来就 `disabled`，而相邻房间必紧贴当前房间、永远可见）。窗口尺寸变化时视口宽度跟随并重新居中。

---

## 9. 暗黑地牢原版地图系统

### 9.1 设计目标

地图由一个个**正方形的房间**组成，房间之间由**走廊**相连。玩家在地图中只能点击「与当前房间相连且不是当前房间」的其它房间，点击后进入该房间并触发一场**新的随机战斗**。地图分为**小 / 中 / 大**三级，在初始界面选择，每局随机生成。

### 9.2 地图数据结构

- **地图尺寸**（`MAP_SIZE`）：`"small"`（5×5，10 房间）、`"medium"`（7×7，15 房间）、`"large"`（9×9，20 房间）。
- **`scripts/map/DungeonMap.gd`**（`class_name DungeonMap`，静态单例）：
  - `MAP_GRID`：随机生成的二维数组，元素为房间类型（`"start"` / `"normal"` / `"boss"`，空字符串表示无房间）。
  - 生成规则：全图随机选一个格子作为起点；从已有房间向四周扩散补齐到目标房间数；最后用 BFS 计算各房间到起点的行走步数，选最远的房间作为 Boss。
  - 扩散倾向 `BRANCHINESS`（可调，`set_branchiness()`）：`0`=一条路径（线性），`1`=四通八达（分支），默认 `0.5`。
  - 自动生成的 `_rooms`：每间房含 `name`（仅分「起始 / 战斗 / Boss」）、`kind`、`col`/`row`、`connections`（上下左右相邻即相连）。
  - `START_ROOM` / `BOSS_ROOM` / `current_room` / `cleared_rooms`：起始房间、Boss 房间、当前房间、已清除房间列表。
  - `ENCOUNTER_POOL` / `BOSS_ENCOUNTER`：随机遭遇池与 Boss 房固定遭遇。
  - 关键方法：`set_size()`、`set_branchiness()`、`get_grid_cols()`、`get_grid_rows()`、`get_all_room_ids()`、`get_room()`、`are_connected()`、`get_connected_rooms()`、`is_cleared()`、`mark_cleared()`、`is_boss_room()`、`move_to()`、`reset_run()`、`roll_encounter()`。

### 9.3 场景与流程

- **`scenes/start/Start.tscn` + `scripts/main/StartController.gd`**：开始界面先闪 `demo_splash.png`，再进入原版风格主菜单（辉光底板 + 宅邸剪影 + 流云 + DEMO 标志 + 「SMALL / MEDIUM / LARGE」尺寸选择 + START 按钮）；点 START 写入固定编队（十字军/强盗/神秘学者/训犬师）并直接进入地图（**不再经过编队选择**）。
- **`scenes/map/Map.tscn`** + **`scripts/map/MapController.gd`**：渲染房间方块（`Button`）与走廊（`Line2D`）；地图内容挂在可平移的 `MapRoot(Node2D)` 下、放在开启 `clip_contents` 的 `MapViewport` 里，**当前房间永远被平移到视野正中**（换房/窗口尺寸变化时重新居中，见 §4.20）；当前房间绿色高亮、相邻可探索房间橙色高亮、未连通房间灰色禁用。
- 流程变更：`开始界面（闪屏 → 主菜单选尺寸）→ Map → Battle → (胜利) Map / (失败·通关) 开始界面`。
- `MapController._on_room_clicked()`：点击相邻房间 → 已清除房间直接移动（不刷怪）；未清除房间掷出随机遭遇写入 `MonsterConfig.CURRENT_ENCOUNTER` → `DungeonMap.move_to(room_id)` → 跳转 `Battle.tscn`。
- `BattleController` 胜利后调用 `DungeonMap.mark_cleared(current_room)` 与 `HeroConfig.persist_party_after_battle(heroes)`；普通胜利 `back_button` 文案为 `Return to Map`，失败为 `Back to Start`，击败 Boss 房显示 `Run Complete!` 并返回开始画面（整局通关）。

### 9.4 队伍状态跨房间持久化

- `HeroConfig.PARTY_STATES`：按 `CURRENT_TEAM` 槽位对齐的持久状态数组，每项为 `{}`（空槽）、`{"dead": true}`（阵亡）或
  `{"hp", "stress", "is_death_door", "is_afflicted", "is_virtuous"}`（存活）——折磨 / 美德与压力一起跨战斗保留（见 §7.14）。
- 每次从开始界面点 START 开新局时调用 `HeroConfig.reset_party_state()` 与 `DungeonMap.reset_run()` 重置进度。
- `BattleController._setup_battle()` 从 `HeroConfig.get_team_heroes()` 读取持久化后的 hp/stress/is_death_door，实现跨房间连续探索。

---

**文档版本**：v4.1  
**最后更新**：2026 年 9 月 29 日  
**引擎版本**：Godot 4.6  

**v4.1 更新内容**：
- 新增**战斗结算界面**（§7.19）：胜利 / 远征终结 / 战败三种结局共用一张卡片（全屏暗幕 + 上下黑边 + 660×430 卡片），带徽记、结局描述、4 行战绩与入场动画
- 旧版只是一个素面 `Panel` + `Label` + `Button`；现改为 `EndLayer(CanvasLayer=105)` + `_create_end_battle_ui()` 代码构建，**解决了角色 SpinePlayer 盖住结算面板的问题**
- `Sfx` 新增 UI 音效表（`ui/` 子目录）：胜利 / 远征终结 / 战败 / 领奖 / 点击 各有专属音效；音效素材总数 85 → **91 个**
- 新探针 `tools/_probe_end_battle.gd`（`PASS=80 FAIL=0`）；15 个探针全量回归通过（580 条断言）

**v4.0 更新内容**：
- **新增战斗音效系统**（§7.18）：Autoload `Sfx`（`scripts/core/SfxManager.gd`）+ 12 个播放器轮转池 + 技能 id → 音效表
- 战斗挂点只有两处：`_play_skill_fx_v2()` 播施法音、`_emit_feedback()` 按真实掉血分流（掉血 → 命中层 / 零伤害 → 挥空音）；倒戈一击与炸药引爆另有专用音
- 音效素材扩到 **85 个 / 5.5MB**：通用命中层 10 个（`char_share_imp_*`）+ 怪物技能 31 个（骸骨系 `char_en_skl*` / 强盗系 `char_en_brig*`）
- 新增探针 `tools/_probe_sfx_battle.gd`（`PASS=50 FAIL=0`）；14 个探针全量回归通过

**v3.9 更新内容**：
- 提取工具支持 **FSB5-Vorbis**（音效库）：按 `setup_id` 从 vgmstream 的 codebook 表补全 setup 头，重建识别/注释头后**重封装为 Ogg**（不重新编码）
- 提取四个英雄的技能音效 44 个 → `audio/sfx/`（3.4MB，含 `_miss` 挥空版；与 16 个技能一一对应）
- 新增校验探针 `tools/_probe_sfx.gd`（`PASS=4 FAIL=0`）

**v3.8 更新内容**：
- **新增背景音乐系统**（§7.17）：Autoload `Bgm`（`scripts/core/BgmManager.gd`）+ 两个播放器交叉淡入淡出 + 前奏→循环编排；开始界面/地图/战斗各自切曲
- 新增提取工具 `tools/extract_fmod_bank.py`：解析 FMOD FSB5 bank（含纯 Python 的 FADPCM 解码），把 `audio/secondary_banks/music.bank` 中的曲目导出为 `audio/bgm/*.ogg`
- 提取了 5 个 BGM 文件（标题前奏/标题循环/地图探索/战斗前奏/战斗循环，共 ~2.9MB）

**v3.7 更新内容**：
- 激励回应窗口改为**玩家点击「确定」后才收起并推进回合**（新增 `reply_confirmed` 信号 + `_on_reply_confirm_pressed()`，不再 2.5s 自动散去；聆听阶段隐藏按钮）
- 激励结果**更看重玩家原话**：新增本地语气分析 `evaluate_input_tone()` / `input_tone_label()`（词表四档，评分 `[-4,+4]`），参与 Mock 权重修正并写入 System Prompt（§4.13 / TECH_GUIDE 8.4）
- 实测（hp45/stress0）：贬低 “你这废物…懦夫…闭嘴” → 加压 66%、倒戈 24%、减压仅 6%；真诚鼓舞 → 减压 75%、增益 21%、加压 4%
- 回应面板加高到 240，避免「确定」按钮溢出面板

**v3.6 更新内容**：
- 重做游戏开始界面（§4.8）：`demo_splash.png` 闪屏（点击/按键/2.4s 跳过）→ 复刻原版前端的主菜单（`title_bg` 下半屏辉光 + `title_house` 宅邸剪影 + `sky01/02` 流云 + DEMO 标志 + 描金按钮），素材全部取自 `res://fe_flow/`，版式沿用 `fe_flow.layout.darkest` 原始坐标
- **移除编队选择功能**：删除 `scenes/main/TeamSelect.tscn` 与 `scripts/main/TeamSelectController.gd`；开局固定为十字军 / 强盗 / 神秘学者 / 训犬师（`StartController.FIXED_TEAM`，§4.9）
- 流程变更：`开始界面（闪屏 → 菜单）→ Map → Battle → 胜利 Map / 失败 · 通关 开始界面`
- 新增探针 `tools/_probe_start_menu.gd`（`PASS=37 FAIL=0`）与截图工具 `tools/_shot_start.gd`

**v3.5 更新内容**：
- 伤害公式拆分为**两个增益乘区**：`attack_mult`（美德激励 / 战意高涨）**彼此加算**（1.2 + 1.2 = ×1.4），`damage_mult`（狗粮）**乘算**在最后（×1.4 × 1.2 = ×1.68）
- 新增 `ActionResolver.get_damage_multiplier()`；`get_attack_multiplier()` 由“取最大值”改为“加算求和”（并用 `snappedf` 抹平浮点误差，避免 int 截断少 1 点伤害）
- `dogfood_buff` 由 `attack_mult` 改为 `damage_mult`（狗粮 = 加伤害，属乘算乘区）
- 验证探针：`tools/_probe_buff_zones.gd`（`PASS=15 FAIL=0`）

**v3.4 更新内容**：
- 实装 AI 激励喊话的 ② `[BUFF]` 增益分支（此前为占位，会显示“分支暂未开放、本次不产生效果”）：现在为英雄附加新状态 `inspired`（战意高涨，攻击力 +20%，持续 3 回合）
- 新增 `INSPIRE_BUFF_STATUS` / `INSPIRE_BUFF_ROUNDS` 常量与 `StatusConfig.inspired`

**v3.3 更新内容**：
- 新增消耗品「狗粮 Dog Food」：使用后为当前行动英雄附加 `dogfood_buff`（伤害 +20%，持续 1 回合），初始发放 2 个（§4.7 / §7.8）
- 新增战斗结算（战利品）步骤：胜利后右侧面板展示 1~4 食物 / 0~1 绷带 / 0~1 狗粮，点击确认入包（§7.16）
- 消耗品配置新增 `buff_status` / `buff_duration` 字段，tooltip 效果行同步支持「附加<状态名>（N 回合）」

**v3.2 更新内容**：
- 新增消耗品背包系统（ConsumableConfig + 战斗内 16 格渲染/左键使用），修复消耗品按钮命中测试失效问题
- 新增技能 / 消耗品悬浮提示系统（描述 + 使用/目标位置 + 效果）
- 地图生成越界修复（`_empty_neighbors` 边界校验）
- SpinePlayer / `_update_selected_text` / `_emit_feedback` 数组越界防护
