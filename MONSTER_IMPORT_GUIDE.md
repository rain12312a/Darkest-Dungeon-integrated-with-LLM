# 怪物素材导入完整教程 — 以 Cutthroat 为例

## 📋 概述

本教程展示如何导入怪物的 Spine 骨骼动画素材到 Dark Dungeon 项目中。我们以 **Cutthroat（盗匪）** 为例，详细讲解每一步。

---

## 🗂️ 第一部分：文件夹结构

### 标准怪物素材目录结构

```
monsters/
└── brigand_cutthroat/                           # 怪物素材包（来自Darkest Dungeon）
    ├── anim/
    │   ├── brigand_cutthroat.sprite.combat.skel
    │   ├── brigand_cutthroat.sprite.combat.atlas
    │   ├── brigand_cutthroat.sprite.combat.png
    │   ├── brigand_cutthroat.sprite.attack_lunge.skel
    │   ├── brigand_cutthroat.sprite.attack_lunge.atlas
    │   ├── brigand_cutthroat.sprite.attack_lunge.png
    │   ├── brigand_cutthroat.sprite.attack_uppercut.skel
    │   ├── brigand_cutthroat.sprite.attack_uppercut.atlas
    │   ├── brigand_cutthroat.sprite.attack_uppercut.png
    │   ├── brigand_cutthroat.sprite.defend.skel
    │   ├── brigand_cutthroat.sprite.defend.atlas
    │   ├── brigand_cutthroat.sprite.defend.png
    │   ├── brigand_cutthroat.sprite.dead.skel
    │   ├── brigand_cutthroat.sprite.dead.atlas
    │   └── brigand_cutthroat.sprite.dead.png
    ├── brigand_cutthroat_A/
    │   ├── brigand_cutthroat_A.art.darkest    # 原版Darkest Dungeon数据
    │   ├── brigand_cutthroat_A.info.darkest
    │   └── tint.png                            # 皮肤纹理
    ├── brigand_cutthroat_B/                    # 其他皮肤变种
    ├── brigand_cutthroat_C/
    └── fx/                                      # 特效资源（可选）
```

### 在项目中的实际位置
- **素材源**: `monsters/brigand_cutthroat/`（不复制到其他位置）
- **动画引用**: 直接通过代码路径 `res://monsters/brigand_cutthroat/anim/` 引用

---

## 🔧 第二部分：代码配置

### 1️⃣ 步骤1 —— MonsterConfig.gd 配置怪物模板

在 [scripts/data/MonsterConfig.gd](scripts/data/MonsterConfig.gd) 中配置怪物数据：

```gdscript
static var MONSTERS: Dictionary = {
	"cutthroat": {
		"name": "Cutthroat",
		"max_hp": 40,
		"attack": 10,
		"speed": 4,
		"speed_delta_base": -1,  # 负数让怪物比英雄慢一点
	},
	# ... 其他怪物
}

static var CURRENT_ENCOUNTER: Array[String] = [
	"cutthroat", "cutthroat", "troll", "troll"  # 设置当前战斗的遭遇怪物
]
```

**关键字段说明**：

| 字段 | 说明 | 示例 |
|------|------|------|
| `name` | 怪物显示名称 | `"Cutthroat"` |
| `max_hp` | 最大血量 | `40` |
| `attack` | 攻击力（固定值） | `10` |
| `speed` | 基础速度 | `4` |
| `speed_delta_base` | 速度浮动基础值（已废弃，现由BattleController随机生成） | `-1` |

---

### 2️⃣ 步骤2 —— BattleController.gd 添加动画配置

#### 2.1 添加怪物动画路径常量

在 [scripts/battle/BattleController.gd](scripts/battle/BattleController.gd#L20) 的顶部常量区添加：

```gdscript
# Cutthroat 怪物动画配置
const CUTTHROAT_ANIM_BASE := "res://monsters/brigand_cutthroat/anim/brigand_cutthroat.sprite."
const CUTTHROAT_PNG_DIR   := "res://monsters/brigand_cutthroat/brigand_cutthroat_A"
const CUTTHROAT_ANIM_MAP  := {
	"idle":    "combat",           # 待机状态 → combat 动画
	"attack":  "attack_lunge",     # 攻击状态 → attack_lunge 动画
	"attack2": "attack_uppercut",  # 第二种攻击 → attack_uppercut
	"defend":  "defend",           # 防守状态
	"combat":  "combat",           # 战斗状态
	"heroic":  "combat",           # 英雄状态（不使用，映射到combat）
	"walk":    "combat",           # 移动状态（不使用，映射到combat）
}
```

**文件名映射规则**：
- `.skel` 和 `.atlas` 文件对应同一个动画名
- 例：`attack_lunge` 对应 `brigand_cutthroat.sprite.attack_lunge.skel` 和 `.atlas`

---

#### 2.2 在 _setup_battle() 中创建怪物 SpinePlayer

找到 [BattleController.gd 的 _setup_battle 方法](scripts/battle/BattleController.gd#L173)，修改怪物初始化部分：

```gdscript
# 初始化怪物 SpinePlayer（cutthroat 等）
for i in range(monsters.size()):
	var monster_id: String = monsters[i].get("id", "")
	if monster_id == "cutthroat":
		_create_spine_player_for_monster(i)
```

---

#### 2.3 添加怪物 SpinePlayer 创建方法

在 BattleController.gd 中，在 `_load_crusader_anim()` 方法之后添加：

```gdscript
# 为怪物创建 SpinePlayer 节点
func _create_spine_player_for_monster(monster_index: int) -> void:
	var sp := SpinePlayer.new()
	sp.name = "MonsterSpinePlayer_%d" % monster_index
	sp.scale = Vector2(0.5, 0.5)  # 缩放因子
	add_child(sp)
	# 使用 "monster_0", "monster_1" 等作为缓存键
	_spine_players["monster_%d" % monster_index] = sp
	_spine_current_state["monster_%d" % monster_index] = ""
	_load_monster_anim(monster_index, "idle")

# 为怪物加载并播放动画
func _load_monster_anim(monster_index: int, state: String) -> void:
	var key = "monster_%d" % monster_index
	if not _spine_players.has(key):
		return
	if _spine_current_state.get(key, "") == state:
		return  # 已加载，无需重复
	
	var sp: SpinePlayer = _spine_players[key]
	var monster_id: String = monsters[monster_index].get("id", "")
	var anim_file: String
	var skel_path: String
	var atlas_path: String
	
	if monster_id == "cutthroat":
		anim_file  = CUTTHROAT_ANIM_MAP.get(state, "combat")
		skel_path  = CUTTHROAT_ANIM_BASE + anim_file + ".skel"
		atlas_path = CUTTHROAT_ANIM_BASE + anim_file + ".atlas"
		sp.load_character(skel_path, atlas_path, CUTTHROAT_PNG_DIR)
	
	sp.play(anim_file)
	_spine_current_state[key] = state
```

---

#### 2.4 添加怪物动画更新方法

在 `_update_crusader_animations()` 方法之后添加：

```gdscript
# 根据怪物行动状态切换动画
func _update_monster_animations() -> void:
	for i in range(monsters.size()):
		var key = "monster_%d" % i
		if not _spine_players.has(key):
			continue
		
		var monster := monsters[i]
		var is_current: bool = (current_actor.get("unit_type") == "monster" and current_actor.get("index") == i)
		
		if monster["hp"] <= 0:
			_load_monster_anim(i, "combat")  # 死亡显示 combat（或可改为 "dead"）
		elif is_current:
			_load_monster_anim(i, "attack")  # 当前行动中 → 攻击动画
		else:
			_load_monster_anim(i, "idle")    # 待机 → idle/combat
```

---

#### 2.5 在 _update_ui() 中调用怪物动画更新

修改 `_update_ui()` 方法，添加对 `_update_monster_animations()` 的调用：

```gdscript
func _update_ui() -> void:
	_update_crusader_animations()
	_update_monster_animations()  # ← 添加这一行
	_update_list_ui()
	_update_selected_text()
	_update_character_portrait()
	_update_skill_buttons()
```

---

## 📝 第三部分：完整配置清单

### ✅ 必做步骤

1. **准备素材文件** ✓
   - [ ] 确认 `monsters/brigand_cutthroat/anim/` 文件夹存在
   - [ ] 确认包含 `.skel` 和 `.atlas` 文件对
   - [ ] 确认 `.png` 纹理文件位于相应目录

2. **配置 MonsterConfig.gd** ✓
   - [ ] 在 `MONSTERS` 字典中添加 `"cutthroat"` 条目
   - [ ] 设置正确的 `max_hp`、`attack`、`speed` 值
   - [ ] 在 `CURRENT_ENCOUNTER` 中指定战斗中的怪物组合

3. **配置 BattleController.gd** ✓
   - [ ] 添加 `CUTTHROAT_ANIM_BASE` 常量（路径前缀）
   - [ ] 添加 `CUTTHROAT_PNG_DIR` 常量（纹理目录）
   - [ ] 添加 `CUTTHROAT_ANIM_MAP` 字典（状态→动画映射）
   - [ ] 在 `_setup_battle()` 中添加怪物 SpinePlayer 创建逻辑
   - [ ] 实现 `_create_spine_player_for_monster()` 方法
   - [ ] 实现 `_load_monster_anim()` 方法
   - [ ] 实现 `_update_monster_animations()` 方法
   - [ ] 在 `_update_ui()` 中调用 `_update_monster_animations()`

---

## 🎮 第四部分：测试与验证

### 测试步骤

1. **启动游戏**
   - 打开 Godot 编辑器
   - 按 F5 或点击"Play"按钮
   - 选择 Start Battle 进入战斗

2. **验证怪物显示**
   - [ ] Cutthroat 怪物出现在敌人区域
   - [ ] 怪物显示正确的名称和血量
   - [ ] 怪物的 Spine 骨骼动画加载成功

3. **验证动画切换**
   - [ ] 怪物待机时显示 `combat` 动画
   - [ ] 怪物攻击时显示 `attack_lunge` 动画
   - [ ] 怪物被击败时显示正确状态

4. **验证战斗逻辑**
   - [ ] 怪物能正常攻击英雄
   - [ ] 英雄攻击能正确击中怪物
   - [ ] 血量显示和扣血逻辑正常

---

## ❌ 常见问题排查

### 问题1：Spine 动画不显示

**症状**：战斗中怪物区域为空或显示错误

**排查步骤**：
1. 检查文件路径是否正确：
   ```
   res://monsters/brigand_cutthroat/anim/brigand_cutthroat.sprite.combat.skel
   ```
2. 验证 `.skel` 和 `.atlas` 文件同时存在
3. 检查 `CUTTHROAT_ANIM_BASE` 常量的拼写

### 问题2：找不到怪物模板

**症状**：运行时报错 "Unknown monster id: cutthroat"

**排查步骤**：
1. 确认 MonsterConfig.gd 中 `MONSTERS` 字典包含 `"cutthroat"` 键
2. 确认怪物 ID 在所有地方保持一致（大小写敏感）
3. 检查 `CURRENT_ENCOUNTER` 中的怪物 ID

### 问题3：动画映射错误

**症状**：怪物始终显示同一个动画

**排查步骤**：
1. 检查 `CUTTHROAT_ANIM_MAP` 中的键值对
2. 验证映射的动画文件确实存在：
   ```
   brigand_cutthroat.sprite.attack_lunge.skel ✓
   brigand_cutthroat.sprite.attack_lunge.atlas ✓
   ```
3. 确认 `_update_monster_animations()` 被正确调用

### 问题4：SpinePlayer 缓存冲突

**症状**：英雄和怪物动画相互干扰

**解决方案**：
- 使用不同的缓存键：
  - 英雄：直接用 `index`（整数）
  - 怪物：用 `"monster_%d" % index`（字符串前缀）

---

## 🔄 扩展：添加新的怪物类型

如果要添加 **Troll** 或其他怪物，遵循相同流程：

### 1. 准备素材
```
monsters/
└── brigand_troll/
    ├── anim/
    │   ├── brigand_troll.sprite.idle.skel
    │   ├── brigand_troll.sprite.attack.skel
    │   └── ... 其他动画
    ├── brigand_troll_A/
    │   └── tint.png
    └── ...
```

### 2. 在 BattleController.gd 中添加常量
```gdscript
const TROLL_ANIM_BASE := "res://monsters/brigand_troll/anim/brigand_troll.sprite."
const TROLL_PNG_DIR   := "res://monsters/brigand_troll/brigand_troll_A"
const TROLL_ANIM_MAP  := {
	"idle":   "idle",
	"attack": "attack",
	# ...
}
```

### 3. 修改 _load_monster_anim() 和 _setup_battle()
```gdscript
elif monster_id == "troll":
	anim_file  = TROLL_ANIM_MAP.get(state, "idle")
	skel_path  = TROLL_ANIM_BASE + anim_file + ".skel"
	atlas_path = TROLL_ANIM_BASE + anim_file + ".atlas"
	sp.load_character(skel_path, atlas_path, TROLL_PNG_DIR)
```

---

## 📊 配置对比表

| 配置项 | Crusader（英雄） | Cutthroat（怪物） |
|--------|---------|---------|
| 文件位置 | `characters/crusader/anim/` | `monsters/brigand_cutthroat/anim/` |
| 常量名 | `CRUSADER_ANIM_BASE` | `CUTTHROAT_ANIM_BASE` |
| 缓存键 | `hero_index`（整数） | `"monster_%d" % index`（字符串） |
| 创建方法 | `_create_spine_player_for_hero()` | `_create_spine_player_for_monster()` |
| 加载方法 | `_load_hero_anim()` | `_load_monster_anim()` |
| 更新方法 | `_update_crusader_animations()` | `_update_monster_animations()` |

---

## 🎯 总结

导入怪物素材的核心步骤：

1. **文件准备** → 素材放在 `monsters/` 目录
2. **数据配置** → MonsterConfig.gd 中定义怪物属性
3. **动画配置** → BattleController.gd 中配置路径和映射
4. **代码实现** → 实现创建、加载、更新动画的方法
5. **集成调用** → 在 _setup_battle() 和 _update_ui() 中调用

按照本教程，你可以轻松导入任何来自 Darkest Dungeon 的怪物素材！

