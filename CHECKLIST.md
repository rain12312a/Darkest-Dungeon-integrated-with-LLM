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
  - [ ] 游戏启动 → 把新英雄 hero_id 填进 `StartController.FIXED_TEAM` → 进入战斗
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
  - [ ] 游戏启动 → 点 START（固定编队）→ 进入战斗
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

## 技能特效与音效

新增技能时，**特效**与**音效**是两张独立的表，都要登记（漏登记不会报错，只会“有动作没声音”或“有声音没画面”）：

- [ ] **特效**：`BattleController.SKILL_FX_MAP` 增加 `"skill_id": { "caster_fx", "target_fx", "caster_anim" }`
- [ ] **施法音**：`SfxManager` 里二选一
  - [ ] 英雄技能 → `HERO_SKILL_SFX["<hero_id>"]["<skill_id>"] = "char_al_<英雄缩写>_<技能>"`
  - [ ] 怪物技能 → `MONSTER_SKILL_SFX["<skill_id>"] = "enemy/char_en_<怪缩写>_<技能>"`（`enemy/` 前缀表示去 `audio/sfx/enemy/`）
- [ ] **命中层**：`SKILL_IMPACT["<skill_id>"] = "sword" | "axe" | "hammer" | "knife" | "shield" | "gun" | "arrow" | "magic_light" | "magic_dark"`
  - 治疗 / 增益 / 召唤类**不要**加，留空即静音（这是刻意的：打不死人的招式不该响打击音）
- [ ] **挥空音（可选）**：`HERO_SKILL_MISS_SFX` / `MONSTER_SKILL_MISS_SFX`（该技能零伤害时播）
- [ ] **音效素材**：从 bank 提取
  ```powershell
  python tools/extract_fmod_bank.py --list audio/secondary_banks/hero_<hero>.bank       # 先查名字
  python tools/extract_fmod_bank.py --bank audio/secondary_banks/hero_<hero>.bank --out audio/sfx --track char_al_<子串>
  ```
  怪物音效源：骸骨系 → `en_crypts.bank`，强盗系 → `en_shared.bank`，输出目录加 `--out audio/sfx/enemy`
  （Vorbis bank 需要 `--codebooks tools/_vgmstream/vorbis_codebooks_fsb.h`，工具的默认值已指向它）
- [ ] **验证**：`godot --headless --path . --script res://tools/_probe_sfx_battle.gd`
  - 探针会逐条比对“表里登记的文件是否都存在”以及“`SKILL_FX_MAP` 里每个技能是否都有施法音”，漏登记会直接 FAIL 并打印缺失项

---

## 结算界面（胜利 / 远征终结 / 战败）

三种结局共用一张卡片，改文案或徽记只需动 `BattleController` 的两处：

- [ ] **文案与按钮**：`_refresh_end_battle_content()` 的 `match _end_state` 分支（`victory` / `run_complete` / `defeat`）
- [ ] **徽记素材**：`END_ART_BY_STATE` 常量（`victory` → `overlays/quest_complete.png`；`run_complete` → `panels/quest_return_to_hamlet.png`；`defeat` → `panels/seal.affliction.png`）
- [ ] **战绩行**：`_fill_end_stats()`（目前是回合数 / 存活英雄 / 剩余生命 / 平均压力）
- [ ] **卡片尺寸**：`END_CARD_SIZE`（改宽了要同步检查与右侧战利品面板 `x=980~1260` 是否还错得开）
- [ ] **层级**：结算卡片固定在 `CanvasLayer(105)`。**不要**为了"盖住角色"去调 `z_index` —— 角色的 SpinePlayer 挂在 Battle 根节点且 `z_index = 10`，只有独立 CanvasLayer 才盖得住
- [ ] **验证**：`godot --headless --path . --script res://tools/_probe_end_battle.gd`（`PASS=80`）
- [ ] 想改视觉：`godot --path . --script res://tools/_shot_end_battle.gd` 会生成三种结局的截图

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
- `scripts/battle/BattleController.gd` — 添加动画映射与 `SKILL_FX_MAP` 特效
- `scripts/core/SfxManager.gd` — 添加施法音 / 命中层（见「技能特效与音效」）

---

## 常见错误速查

| 错误 | 检查清单 |
|------|---------|
| 英雄不出现在队伍里 | ✓ HeroConfig 中已注册 ✓ 已加入 `StartController.FIXED_TEAM` ✓ 拼写无误 ✓ 脚本已保存 |
| 技能图标不显示 | ✓ 文件名正确（`hero.ability.one.png`） ✓ 文件存在 ✓ SkillConfig 中已定义 |
| 动画不播放 | ✓ 文件路径正确 ✓ BattleController 中已映射 ✓ 动画名称拼写无误 |
| 技能有画面没声音 | ✓ `SfxManager.HERO_SKILL_SFX` / `MONSTER_SKILL_SFX` 中已登记 ✓ 音效文件已提取到 `audio/sfx/`（怪物在 `audio/sfx/enemy/`） ✓ 跑 `_probe_sfx_battle.gd` 看是哪条缺失 |
| 打中了却没有打击声 | ✓ `SKILL_IMPACT` 中该技能已指定武器类型（治疗/增益类故意留空） |
| 治疗技却响了打击音 | ✓ `SKILL_IMPACT` 里该技能应该**没有**条目 |
| 怪物不出现 | ✓ MonsterConfig 中已注册 ✓ CURRENT_ENCOUNTER 中已添加 ✓ 动画文件存在 |
| 按钮无法点击 | ✓ 信号连接正确（`.bind()` 和 `CONNECT_DEFERRED`） ✓ 回调函数存在 |

---

## 详细文档链接

- 完整指南：[TECH_GUIDE.md](TECH_GUIDE.md)
- 系统架构：[PROJECT_DOCUMENTATION.md](PROJECT_DOCUMENTATION.md)
- 项目概述：[README.md](README.md)

