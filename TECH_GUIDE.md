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
│       └── MonsterConfig.gd            # 怪物配置脚本
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

#### 2.2.5 检查编队选择中的英雄列表

打开 `scripts/main/TeamSelectController.gd`，确认 `_update_available_heroes()` 函数能正确读取英雄：

```gdscript
func _update_available_heroes() -> void:
	var all_ids := HeroConfig.get_all_hero_ids()  # 从 HeroConfig 读取所有英雄
	for hero_id in all_ids:
		# 动态生成英雄选择按钮
		var template := HeroConfig.get_hero_template(hero_id)
		# ...
```

> 如果已正确在 HeroConfig 中注册，TeamSelectController 会自动显示新英雄。

### 2.3 测试新英雄

1. **启动游戏** → 开始→编队选择
2. **选择新英雄** → 应出现在可用英雄列表中
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
| `speed_delta_base` | int | 每轮速度浮动的基准（通常为负数，让怪物比英雄慢） |

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

> 最多 4 个怪物位置（与英雄位置对应）。

#### 3.2.4 在 BattleController.gd 中设置动画

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

在 `_load_monster_anim()` 函数中添加新怪物分支：

```gdscript
func _load_monster_anim(monster_index: int, state: String) -> void:
	var key = "monster_%d" % monster_index
	if not _spine_players.has(key):
		return
	if _spine_current_state.get(key, "") == state:
		return
	var sp: SpinePlayer = _spine_players[key]
	var monster_id: String = monsters[monster_index].get("id", "")
	
	var anim_file: String
	var skel_path: String
	var atlas_path: String
	
	if monster_id == "new_monster":                   # 新怪物分支
		anim_file  = NEW_MONSTER_ANIM_MAP.get(state, "combat")
		skel_path  = NEW_MONSTER_ANIM_BASE + anim_file + ".skel"
		atlas_path = NEW_MONSTER_ANIM_BASE + anim_file + ".atlas"
		sp.load_character(skel_path, atlas_path, NEW_MONSTER_PNG_DIR)
		sp.play(anim_file)
	elif monster_id == "cutthroat":
		# 既有逻辑...
	
	_spine_current_state[key] = state
```

### 3.3 测试新怪物

1. **启动游戏** → 开始→编队选择→进入战斗
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
		"effect_type": "damage",             # 效果类型: "damage" (伤害) 或 "heal" (治疗)
		"target_type": "single_enemy",       # 目标形式: "single_enemy" | "single_ally" | "all_enemies" | "all_allies" | "self"
		"attack_ratio": 1.2,                 # 攻击系数（基于施法者基础 attack）
		"heal_amount": 0,                    # 固定的治疗量（仅在 effect_type 为 "heal" 时有效）
		
		# 位置约束选项
		"use_positions": [2, 3, 4],          # 施法者可用位置（1~4，1为排头即前排，4为排尾）
		"target_positions": [2, 3, 4],       # 技能可以命中的有效目标站位（1~4，留空数组 [] 视为不限）
		
		# 【高阶核心机制：主动位移】
		"move_forward": 1,                   # 结算后位移值: 正数指排头方向(如1为前进一位); 负数指排尾方向(如-1为退后一位)
		
		# 【高阶核心机制：压力伤害】
		"stress_damage": 15,                 # 造成的精神压力累加值（满200秒杀）
		
		# 【高阶核心机制：怪物AI索敌控制】
		"target_priority": "highest_stress"  # AI单体目标选择规则: "lowest_hp" | "highest_stress" | "random"
	}
}
```

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

#### 6.2.2 压力与一击必杀机制 (`stress_damage`)
压力数值的变化在战斗数值分发器 [scripts/battle/ActionResolver.gd](scripts/battle/ActionResolver.gd) 的静态方法 `apply_stress` 被严密监控：
1. **暗紫地牢风格指示条**：
   - 每一个英雄卡槽的底部，都通过 `_make_hero_slot()` 的 ProgressBar 进行实时渲染。
   - 该样式不仅配有 `"Stress: N/200"` 的冷淡淡粉紫色字体外，更重设了 `StyleBoxFlat` 纯平样式盒将核心刻度填充色彩修正为**神秘而暗黑的暗紫色** (`Color(0.6, 0.2, 0.7)`)。
2. **狂热濒死死亡规则**：
   - 当怪物使用附带 `"stress_damage"` 属性的技能导致英雄压力上升时，在 `apply_stress()` 函数里判定累加值。
   - **一旦突破或达到阈值界限 200**：角色的当前 `stress` 立即**全额重置清零**。
   - 伴随清零，系统向该角色发出高额致死指令 `apply_damage(target, 999)`，达成原本地牢模式在压力绝境下当场心脏骤停的极致体验。

#### 6.2.3 怪物智能AI施法限制与索敌筛选规则
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
2. **`caster_scale` / `target_scale`**:
   * 类型：`float`。
   * 默认值：`1.0`。此值会乘算底层 Spine 渲染模板的系统对齐缩放 (Spineplayer 系统默认缩放是 `0.5`)，通过此变量可微调最终显示的像素画面。

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
| 怪物不显示 | 未在 BattleController 中添加加载逻辑 | 在 `_create_spine_player_for_monster()` 中添加新怪物 |

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
   大模型回复或本地 Mock 降级短语将自上而下通过淡入气泡弹出。同时，该英雄身上会爆发出璀璨夺目的专属 `"battle_cry"` 法术闪光动态粒子束，血量上方的精神压力条（Stress Bar）累积值直接**缩减 30 点**，同时弹出 `STRESS -30` 粒子跳字。

### 8.2 多层级 CanvasLayers 遮挡优化

由于本作为自定义 Spine 运行时开发，Spine 人物是以多个动态多边形实体（Sprite2D、Polygon2D）形式直接渲染在主场景 2D 画布中的。这些骨骼实体极易在一些具有动画更新的帧下穿透或盖在普通的控制和文本输入组件上层，造成输入栏被手臂或怪物尾巴遮盖的恶性 UI Bug。

**金标准解决方案（层级前置架构）**：
- **`BattleController._parent_ui_layer` (CanvasLayer, layer=100)**：专门用于放置玩家输入弹窗（包含文本框、发送按钮、取消按钮）。通过高优先级的 CanvasLayer 将其直接渲染在引擎的高级重画栈，彻底跟 Spine 节点视口隔离开。
- **`BattleController._bubble_layer` (CanvasLayer, layer=101)**：专门承载并渲染大模型的回复对话框气泡。它比输入框还要更高一层，能杜绝在输入框关闭瞬间的最后一像素渲染闪烁，从而保证了完美的观感体验。

### 8.3 画面缩放及布局提升

为了防止新增的“神圣激励”表单和英雄面板把底部的普通战斗选项按钮占领，我们将所有英雄与怪物的世界坐标槽位整体**向上高位平移了 140 像素**：
* 边界扩展：槽位统一扩大到 `110x220` 宽高限额，以容纳大型动画剪影。
* 状态可视化：在每个人物正上方挂载了高对比度的 HP 进度条，以及代表疯狂指标、以深紫原色填充的压力进度条（Stress Bar），让战场形势和神圣激励前后的效果对比极其清晰直观。

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
2. 导出 Spine 动画到该目录
3. 在 MonsterConfig.gd 中添加怪物模板
4. 修改 CURRENT_ENCOUNTER 以包含该怪物
5. 在 BattleController.gd 中添加动画映射
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

---

**版本**：1.0  
**最后更新**：2026-06-05
