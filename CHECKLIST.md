# 添加英雄/怪物快速清单

## 添加新英雄

- [ ] **文件准备**
  - [ ] 创建目录 `characters/{hero_id}/anim/`
  - [ ] 导出 Spine 动画文件（.skel / .atlas / .png）
  - [ ] 准备头像 `{hero_id}_guild_header.png` (256×256px 推荐)
  - [ ] 准备技能图标 `{hero_id}.ability.{one|two|three|...}.png` (64×64px 推荐)

- [ ] **HeroConfig.gd 配置**
  ```gdscript
  "new_hero": {
      "id": "new_hero",
      "name": "NewHero",
      "max_hp": 60,
      "attack": 12,
      "speed": 5,
      "skills": ["skill_new_hero_1", "skill_new_hero_2", ...],
  }
  ```

- [ ] **SkillConfig.gd 配置**
  - [ ] 为每个技能添加定义
  ```gdscript
  "skill_new_hero_1": {
      "name": "Skill Name",
      "target_type": "single_enemy",  # 或 "single_ally" / "all_enemies" / "self"
      "skill_type": "damage",         # 或 "heal" / "buff" / "debuff"
      "damage_multiplier": 1.2,       # 伤害倍数（攻击力 × 倍数）
      "use_positions": [1, 2, 3, 4],
  }
  ```

- [ ] **BattleController.gd 动画设置**
  - [ ] 添加动画常量：
    ```gdscript
    const NEW_HERO_ANIM_BASE := "res://characters/new_hero/anim/new_hero.sprite."
    const NEW_HERO_PNG_DIR   := "res://characters/new_hero/new_hero_A/anim"
    const NEW_HERO_ANIM_MAP  := {
        "idle": "idle",
        "attack": "attack",
        "defend": "defend",
        "combat": "combat",
        "heroic": "heroic",
        "walk": "walk",
    }
    ```
  - [ ] 在 `_load_hero_anim()` 中添加 `elif hero_id == "new_hero"` 分支
  - [ ] 在 `_create_spine_player_for_hero()` 中调用 `_load_hero_anim()`

- [ ] **测试**
  - [ ] 游戏启动 → 编队选择 → 新英雄出现在列表中
  - [ ] 选择新英雄 → 进入战斗 → 头像、技能图标、动画正常显示
  - [ ] 选择技能 → 伤害计算正确

---

## 添加新怪物

- [ ] **文件准备**
  - [ ] 创建目录 `monsters/{monster_id}/anim/`
  - [ ] 导出 Spine 动画文件（.skel / .atlas / .png）

- [ ] **MonsterConfig.gd 配置**
  - [ ] 添加怪物模板：
    ```gdscript
    "new_monster": {
        "id": "new_monster",
        "name": "NewMonster",
        "max_hp": 50,
        "attack": 8,
        "speed": 3,
        "speed_delta_base": -1,
    }
    ```
  - [ ] 在 `CURRENT_ENCOUNTER` 中添加新怪物（最多 4 个位置）

- [ ] **BattleController.gd 动画设置**
  - [ ] 添加动画常量：
    ```gdscript
    const NEW_MONSTER_ANIM_BASE := "res://monsters/new_monster/anim/new_monster.sprite."
    const NEW_MONSTER_PNG_DIR   := "res://monsters/new_monster/anim"
    const NEW_MONSTER_ANIM_MAP  := {
        "idle": "combat",
        "attack": "attack_1",
        "attack2": "attack_2",
        "defend": "combat",
        "combat": "combat",
        "heroic": "combat",
        "walk": "combat",
    }
    ```
  - [ ] 在 `_load_monster_anim()` 中添加 `if monster_id == "new_monster"` 分支
  - [ ] 在 `_create_spine_player_for_monster()` 中调用 `_load_monster_anim()`

- [ ] **测试**
  - [ ] 游戏启动 → 编队选择 → 进入战斗
  - [ ] 新怪物在右侧对应位置显示
  - [ ] 动画正常播放，血条显示正确

---

## 添加新技能

- [ ] **SkillConfig.gd 配置**
  - [ ] 在 `SKILLS` 字典中添加技能定义
  - [ ] 设置 `target_type` 和 `skill_type`
  - [ ] 设置 `damage_multiplier` 或 `heal_amount`
  - [ ] 设置 `use_positions`

- [ ] **HeroConfig.gd 分配**
  - [ ] 将技能 ID 添加到英雄的 `skills` 数组

- [ ] **UI 素材**
  - [ ] 准备技能图标 `{hero_id}.ability.{number}.png`
  - [ ] 图标尺寸 64×64px，编号从 `one` 开始

- [ ] **测试**
  - [ ] 进入战斗，当该英雄行动时查看技能按钮
  - [ ] 点击技能 → 目标选择正常显示
  - [ ] 选择目标 → 伤害/治疗计算正确

---

## 修改 UI 布局

| 要修改的元素 | 位置 | 字段 |
|-------------|------|------|
| 英雄槽 Y 位置 | `_make_hero_slot()` | `offset_top` (目前 88) |
| 怪物槽 Y 位置 | `_make_monster_slot()` | `offset_top` (目前 40) |
| 英雄槽 X 位置 | `_make_hero_slot()` | `offset_left` / `offset_right` |
| 怪物槽 X 位置 | `_make_monster_slot()` | `offset_left` / `offset_right` |
| 技能图标尺寸 | `_update_skill_buttons()` | `custom_minimum_size` |
| HP 条高度 | `_make_hero_slot()` / `_make_monster_slot()` | ProgressBar `custom_minimum_size` |
| SPD 标签字体 | 同上 | Label `font_size` |

---

## 文件清单

### 必需的新文件

```
characters/new_hero/
├─ anim/
│  ├─ new_hero.sprite.idle.skel
│  ├─ new_hero.sprite.idle.atlas
│  ├─ new_hero.sprite.idle.png
│  ├─ new_hero.sprite.attack.skel
│  ├─ new_hero.sprite.attack.atlas
│  ├─ new_hero.sprite.attack.png
│  └─ [其他动作文件...]
├─ new_hero_guild_header.png
├─ new_hero.ability.one.png
├─ new_hero.ability.two.png
└─ [更多技能图标...]

monsters/new_monster/
└─ anim/
   ├─ new_monster.sprite.combat.skel
   ├─ new_monster.sprite.combat.atlas
   ├─ new_monster.sprite.combat.png
   └─ [其他动作文件...]
```

### 需要修改的脚本

- `scripts/data/HeroConfig.gd` — 添加英雄
- `scripts/data/SkillConfig.gd` — 添加技能
- `scripts/data/MonsterConfig.gd` — 添加怪物
- `scripts/battle/BattleController.gd` — 添加动画映射

---

## 常见错误速查

| 错误 | 检查清单 |
|------|---------|
| 英雄不出现在编队选择 | ✓ HeroConfig 中已注册 ✓ 拼写无误 ✓ 脚本已保存 |
| 技能图标不显示 | ✓ 文件名正确（`hero.ability.one.png`） ✓ 文件存在 ✓ SkillConfig 中已定义 |
| 动画不播放 | ✓ 文件路径正确 ✓ BattleController 中已映射 ✓ 动画名称拼写无误 |
| 怪物不出现 | ✓ MonsterConfig 中已注册 ✓ CURRENT_ENCOUNTER 中已添加 ✓ 动画文件存在 |
| 按钮无法点击 | ✓ 信号连接正确（`.bind()` 和 `CONNECT_DEFERRED`） ✓ 回调函数存在 |

---

## 详细文档链接

- 完整指南：[TECH_GUIDE.md](TECH_GUIDE.md)
- 系统架构：[PROJECT_DOCUMENTATION.md](PROJECT_DOCUMENTATION.md)
- 项目概述：[README.md](README.md)

