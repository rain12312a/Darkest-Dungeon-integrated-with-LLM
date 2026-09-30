# Dark Dungeon · 暗黑地牢风格战斗原型

基于 **Godot 4.6** 的回合制战斗原型：自研 **Spine 2.1.27** 骨骼动画运行时、**LLM 驱动的英雄激励喊话**，以及随机生成的地牢地图。

> **游戏流程**：`Start`（闪屏 → 主菜单）→ `Map`（随机地牢，逐房探索）→ `Battle`（回合制战斗）→ 胜利返回 `Map` / 击败首领通关返回 `Start`

## 亮点 Features

- 🧠 **LLM 英雄激励喊话**：向当前行动的英雄喊话，模型结合战况（血量 / 压力）与**你原话的语气**判定四种结果 —— ① 减压 ② 攻击增益 ③ 加压 ④ 精神崩溃、倒戈攻击队友。**发布版内置直连 Key，玩家双击即用（0 点击）**；未配置 / 网络不可达时自动降级为**离线 Mock**（同一套权重逻辑，离线也能完整游玩），也可在开始界面「LLM 设置」里换成自己的 Key
- 🦴 **自研 Spine 运行时**（纯 GDScript，**不需要**官方 Spine 插件）：解析 `.skel` / `.atlas`，支持 Region / Mesh / SkinnedMesh 附件，逐顶点按骨骼权重蒙皮（Polygon2D）
- ⚔️ **回合制战斗**：速度浮动 + 行动队列驱动；4 名英雄（十字军 / 强盗 / 神秘学者 / 训犬师）对抗骷髅军团与「门前恶狼」首领战
- 🩸 **暗黑地牢核心机制**：死门（Death's Door）、压力 / 折磨 / 美德、DoT（流血 / 腐蚀）、晕眩、标记、守护、消耗品、战利品结算
- 🗺️ **随机地牢地图**：小 / 中 / 大三级（5×5 / 7×7 / 9×9），扩散倾向可调，**当前房间永远居中**
- 🔊 **音频系统**：BGM 交叉淡入淡出（前奏 → 循环）+ 技能 / 命中 / UI 音效轮转池（素材从 FMOD bank 提取）
- ⚙️ **数据驱动**：新增英雄 / 怪物 / 技能 / 状态只需改配置表，不必改战斗逻辑

## 快速开始 Quick Start

### 环境要求

- Godot **4.6**（推荐 Vulkan Forward+ 渲染器）
- 无第三方插件、无需编译

### 运行

1. 用 Godot 打开本目录（含 `project.godot`）
2. 首次运行前先导入资源（仓库忽略了 `*.import`，见下文「关于 `.import`」）
3. 按 `F5` 运行，主场景 `scenes/main/Main.tscn`

### 全屏 / 分辨率适配

- 游戏中按 **`F11`** 或 **`Alt+Enter`** 切换全屏（全屏下按 `Esc` 退回窗口）
- 采用 `canvas_items` + `keep` **等比缩放**：逻辑分辨率固定 1280×720，全屏时整幅放大并居中，非 16:9 屏幕（16:10 / 21:9）补黑边；因此战场底图、地图视口、开始界面等全部既有布局无需改动
- 想让程序启动即全屏：把 `project.godot` 中 `[display] window/size/mode` 改为 `3`（全屏）或 `4`（独占全屏）
- 已验证尺寸：1280×720 / 1600×900 / 1920×1080 / 1280×800(16:10) / 2560×1440 全屏，逻辑可见区恒为 1280×720（`tools/_probe_fullscreen.gd`，19 条断言全通过）

### 战斗内操作

| 操作 | 说明 |
| --- | --- |
| 选择目标 | 点击敌方 / 友方卡槽（可选范围由技能的 `target_type` 决定） |
| 释放技能 | 点击技能按钮；图标与描述由 `SkillConfig` 驱动 |
| 激励喊话 | 点 `Inspire` → 输入一句话 → LLM 判定（3.5 秒超时自动降级 Mock）→ 点「确定」结算并推进回合 |
| 使用消耗品 | 食物（回血 2）/ 绷带（解除流血）/ 狗粮（伤害 +20%，持续 1 回合），**不占行动次数** |
| 战后结算 | 胜利时右侧战利品面板结算补给，确认后回到地图 |

### 可选：启用在线 LLM

**玩家侧（双击 exe 就能用）**：开始界面右上角有 **「LLM 设置」** 按钮（显示当前是在线 / 离线）。**发布版只要把代理地址填进 `api_public.gd`（见 [worker/README.md](worker/README.md) 的三步走），玩家连这个按钮都不用点** —— 开局直接就是在线 LLM。

只有在**完全没有可用在线配置**时，首次点 `START` 才会自动弹一次引导面板，二选一：

- **离线开始** — 不填任何东西，用内置离线 Mock 引擎，四种结果逻辑完整
- **保存并开始** — 填入 API Key（或自建代理地址 + 代理令牌），面板会先**测试连通性**再开局

设置写入本机 `%APPDATA%\Godot\app_userdata\darkdungeon\llm_config.json`，随时可改，不影响存档。

**配置优先级**（低 → 高，后写入的非空字段覆盖前者）：

| 优先级 | 来源 | 用途 |
| --- | --- | --- |
| ① | `scripts/battle/api_config.gd` | **内置直连 Key**（`.gitignore` 忽略，**随包发布**；建议用 `tools/embed_key.ps1` 混淆存放） |
| ② | `scripts/battle/api_public.gd` | 自建代理地址 + 公开令牌（可入库；**填了就优先于 ①**，真 Key 只存在 Worker 里，最安全） |
| ③ | exe 同目录 `api_config.json` | 便携覆盖，免重新打包 |
| ④ | `user://llm_config.json` | 开始界面「LLM 设置」面板写入 |

**开发者侧**：`scripts/battle/api_config.gd` 已被 `.gitignore` 忽略，克隆后自行创建：

```gdscript
const API_KEY := ""                       # 明文（本地调试用）；留空且 OBF 也为空 = 离线 Mock
const API_KEY_OBF := ""                   # 混淆形式（推荐），由 tools\embed_key.ps1 生成
const API_URL := "https://api.deepseek.com/v1/chat/completions"
const MODEL := "deepseek-chat"
```

> 🚀 **发布版是「内置直连 Key」模式（0 点击）**：
> ```powershell
> powershell -ExecutionPolicy Bypass -File tools\embed_key.ps1      # 明文 Key → 混淆形式
> powershell -ExecutionPolicy Bypass -File tools\export_release.ps1 # 导出 + 自动校验
> ```
> - **好处**：玩家双击 exe → 点 START 直接开局，不用配任何东西；也不用买域名/搭代理。
> - **代价**：Key 随包发布，拿到 exe 且愿意动手的人理论上能还原出来（脚本已把它混淆成 Base64，包里搜不到 `sk-` 明文，挡掉 GitHub 密钥扫描 / 自动化爬虫 / `strings` 批量扫描）。
> - **必做**：① 在 DeepSeek 控制台给这个 Key **设消费上限**；② 用**独立于日常使用的 Key**，被盗用就去控制台**吊销**它 —— 旧 exe 会自动降级为离线 Mock，不会坏掉。
> - ⚠️ 千万不要把 `api_config.gd` 手动 `git add`（它默认被忽略；`tools/embed_key.ps1` 会帮你确认这一点）。
> - 想改用「真 Key 不落玩家机器」的自建代理方案，见 [worker/README.md](worker/README.md)。

## 关于 `.import` 与首次导入

`.godot/`、`*.import`、`*.uid`、`export_presets.cfg`、`*.bank`、`*.py` 均在 `.gitignore` 内（项目约定，不入库）。克隆后资源需要重新导入：

```bash
godot --headless --path . --import
```

> **音频素材说明**：仓库只保留**提取后**的 `audio/bgm/*.ogg` 与 `audio/sfx/*.ogg`（约 8.5MB）。原版 FMOD bank（600MB+，RIFF 容器内的 FSB5，Godot 无法直接播放）已移除。若要重新提取，需自备游戏原始的 `.bank` 文件，并使用 `tools/extract_fmod_bank.py`（`*.py` 同样不入库）。

## 文档 Documentation

- **[TECH_GUIDE.md](TECH_GUIDE.md)** ⭐ — **如何添加英雄 / 怪物 / 技能 / UI / 动画**，含全部字段说明与踩坑清单
- **[PROJECT_DOCUMENTATION.md](PROJECT_DOCUMENTATION.md)** — 系统架构、逐函数说明与核心机制设计
- **[MONSTER_IMPORT_GUIDE.md](MONSTER_IMPORT_GUIDE.md)** — 怪物素材导入与接线 6 步流程
- **[CHECKLIST.md](CHECKLIST.md)** — 添加英雄 / 怪物的勾选式快速清单

## 项目结构 Project Structure

```
darkdungeon/
├── scenes/                   # 场景（.tscn）
│   ├── main/Main.tscn        # 启动入口（仅负责加载 Start）
│   ├── start/Start.tscn      # 闪屏 + 主菜单（全代码构建 UI）
│   ├── map/Map.tscn          # 随机地牢地图
│   ├── battle/Battle.tscn    # 战斗场景
│   └── test/SpineTest.tscn   # Spine 解析单测场景
│
├── scripts/
│   ├── battle/               # BattleController / TurnQueue / ActionResolver / LLMClient
│   │   └── spine/            # SpineAtlas / SpineSkel / SpinePlayer（自研运行时）
│   ├── data/                 # 配置表：Hero / Skill / Monster / Status / Stress / Consumable
│   ├── core/                 # BgmManager / SfxManager（Autoload）、GameState、Database
│   ├── map/                  # DungeonMap（地图生成）+ MapController（地图 UI）
│   └── main/                 # StartController
│
├── characters/               # 英雄素材（Spine：.skel/.atlas/.png + 技能图标 + 头像）
│   ├── crusader/  highwayman/  occultist/  houndmaster/
│
├── monsters/                 # 怪物素材（骨架 + 特效）
│   ├── brigand_cutthroat/  skeleton_*/  brigand_sapper|barrel|fuseman|cannon/
│
├── audio/                    # bgm/ + sfx/（提取后的 ogg）+ 原版 load_order json
├── overlays/  panels/  crypts/  fe_flow/  assets/   # 图标 / 面板 / 场景图 / 前端素材
├── tools/                    # 无头验证探针（_probe_*.gd）与截图脚本（_shot_*.gd）
│
└── *.md                      # 文档（见上）
```

## 内容配置 Data-Driven Configs

| 配置 | 内容 |
| --- | --- |
| `HeroConfig.gd` | 4 名英雄：Crusader(50/17/4)、Highwayman(40/20/5)、Occultist(30/25/3)、Houndmaster(45/18/4)；含死门概率与 LLM 人格设定 |
| `MonsterConfig.gd` | 11 种敌人：Cutthroat、骷髅 6 种（Bone Soldier/Defender/Arbalist/Courtier/Militia/Spearman）、首领战 4 单位（Vvulf / 弹药桶 / 点火员 / 大炮），支持 `inert`、`life_link` |
| `SkillConfig.gd` | 全部英雄 / 怪物技能：`target_type`、`use_positions`、`effect_type`（damage / heal / guard / composite_heal / apply_status / summon）、`status_effects`、`target_move_forward`、`skill_priority`、使用条件（`requires_*`） |
| `StatusConfig.gd` | 状态表：bleed / blight / stun / mark / guard / bomb_mark / cannon_loaded / afflicted / virtuous / virtue_buff / inspired / dogfood_buff |
| `StressConfig.gd` | 压力系统数值：上限 200、折磨阈值 100、折磨 75% / 美德 25%、失控概率与行为参数 |
| `ConsumableConfig.gd` | 消耗品与背包：食物（回血）/ 绷带（治愈流血）/ 狗粮（伤害增益） |
| `DungeonMap.gd` | 地图尺寸（`set_size`）、扩散倾向（`set_branchiness`）、遭遇池 `ENCOUNTER_POOL`、首领编队 `BOSS_ENCOUNTER` |

## 系统总览 Key Systems

### 战斗流程

```
回合开始（重掷速度浮动）→ 按有效速度构建行动队列 →
  英雄回合 → 选择技能 → 选择目标 → 结算伤害/治疗/状态 →（可选）使用消耗品 / 激励喊话 →
  怪物回合 → 按条件筛选技能 → 自动选目标 → 结算 →
队列耗尽 → 下一回合（或胜利 / 战败）
```

### 核心机制

- **速度与队列**：基础速度固定，每回合叠加浮动值后排序；每单位每回合行动 1 次
- **死门**：HP 归零不立即死亡，进入濒死；濒死期间**受到伤害**时按其 `death_blow_chance` 掷骰（治疗等非伤害结算不掷骰）
- **压力**：越阈后 75% 折磨 / 25% 美德；折磨者行动时有 30% 概率失控（跳过 / 攻击队友 / 全队加压 / 随机行动）
- **状态结算时机**：全部挂在**携带者自己行动开始时**（`_tick_current_actor_statuses`），回合开始不结算
- **伤害公式**：`int(攻击力 × 攻击加算乘区 × attack_ratio × 伤害乘算乘区)`（如 `inspired` 与 `virtue_buff` 加算 = ×1.4，`dogfood_buff` 乘算）
- **首领战**：投弹 → 次回合引爆、哑弹解除、大炮装填 / 开火 / 召唤、生命链接（弹药桶随首领阵亡、点火员随大炮阵亡）

### Spine 动画系统

- `SpineAtlas.gd` — 解析 `.atlas` 纹理区域
- `SpineSkel.gd` — 解析 `.skel` 二进制（骨骼 / 插槽 / 附件 / 网格 / 动画 / IK 约束）
- `SpinePlayer.gd` — 以 Sprite2D（Region 附件）+ Polygon2D（Mesh / SkinnedMesh）渲染，并播放动画

### 地图 / 音频 / LLM

- `DungeonMap.gd` + `MapController.gd` — 随机生成房间并绘制走廊，仅相邻且非当前房间可点，已清除房间不再刷怪，Boss 房胜利即通关
- `BgmManager.gd`（Autoload `Bgm`）— 双播放器交叉淡入淡出 +「前奏 → 循环」两段式曲目
- `SfxManager.gd`（Autoload `Sfx`）— 技能 / 命中 / UI 音效，多播放器轮转 + 音高音量随机
- `LLMClient.gd` — DeepSeek Chat API（3.5 秒超时降级）+ 离线 Mock 引擎 + 玩家语气打分（`evaluate_input_tone`）

## 验证探针 Probes

仓库内 `tools/_probe_*.gd` 是无头断言脚本，覆盖死门、压力、BOSS 战、战利品、地图居中、BGM / SFX、Spine 解析完整性等；`tools/_shot_*.gd` 用于渲染截图人工复核。

```bash
godot --headless --path . --script tools/_probe_stress.gd     # 打印 PASS/FAIL 统计
godot --headless --path . --script tools/_probe_skel_integrity.gd  # 全量 .skel 体检
```

`tools/_probe_fullscreen.gd` 需要真实窗口（**不能**加 `--headless`），会校验窗口缩放、全屏切换与逻辑坐标，并输出 `shot_fullscreen_*.png` 供人工核对：

```bash
godot --path . --script res://tools/_probe_fullscreen.gd
```

## Technology

| Component | Details |
|-----------|---------|
| **Engine** | Godot 4.6 |
| **Language** | GDScript |
| **Rendering** | Vulkan Forward+ |
| **Display** | 逻辑分辨率 1280×720，`canvas_items` + `keep` 等比缩放，`F11` / `Alt+Enter` 全屏切换 |
| **Animation** | 自研 Spine 2.1.27 运行时（无需官方插件） |
| **UI System** | 运行时由 GDScript 动态构建（无需手工搭场景） |
| **LLM** | DeepSeek Chat API，可离线 Mock 降级 |
| **Audio** | 原版 FMOD bank 提取为 OGG（BGM 交叉淡化 / 音效轮转池） |

## Notes

- 美术与音频素材取自 *Darkest Dungeon*，版权归 **Red Hook Studios** 所有，本项目**仅供学习与研究**，请勿用于商业用途
- 自研 Spine 运行时**不依赖**官方 Spine Godot 插件
- 全部 UI 在运行时动态生成，无需手工构建节点
- 项目开启了「警告即错误」，从 Variant 推断类型（`clamp()` / `Dictionary.get()` 等）必须显式标注类型
- 无头探针环境下没有真实渲染（视口尺寸可能只有 64px），动画断言需按时间而非帧数

## Getting Help

优先查阅 [TECH_GUIDE.md](TECH_GUIDE.md)：
- 故障排查与常见报错（Section 7）
- 快速参考清单
- 文件位置索引
