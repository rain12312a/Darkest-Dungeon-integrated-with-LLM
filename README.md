# Dark Dungeon · 暗黑地牢风格战斗原型

基于 **Godot 4.6** 的回合制战斗原型：自研 **Spine 2.1.27** 骨骼动画运行时、**LLM 驱动的英雄激励喊话**，以及随机生成的地牢地图。

> **游戏流程**：`Start`（闪屏 → 主菜单）→ `Map`（随机地牢，逐房探索）→ `Battle`（回合制战斗）→ 胜利返回 `Map` / 击败首领通关返回 `Start`

## 下载 Download

> ⚠️ 旧的 `v1.0-demo` 发布包（内置 Key 版本）**已下架删除**，正在重新打包。
> 想现在玩，请按下方「快速开始」从源码运行。

**在线 AI 可选**：想用真模型喊话，在开始界面右上角「LLM 设置」填入自己的 API Key 即可（只存本机，不上传）；不配置 / 网络不通时自动改用内置离线引擎（判定逻辑一致，一样能完整游玩）。

**想改代码 / 自己构建**：见下方「快速开始」。

## 亮点 Features

- 🧠 **LLM 英雄激励喊话**：向当前行动的英雄喊话，模型结合战况（血量 / 压力）与**你原话的语气**判定四种结果 —— ① 减压 ② 攻击增益 ③ 加压 ④ 精神崩溃、倒戈攻击队友。**发布包不内置任何 Key**：想用真模型，在开始界面右上角「LLM 设置」填入自己的 Key 即可（只存本机）；未配置 / 网络不可达时自动降级为**离线 Mock**（同一套权重逻辑，离线也能完整游玩）
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

**发布包不内置任何 API Key**，默认走内置离线 Mock 引擎（四种结果逻辑完整，纯离线也能玩）。
想用真模型，在开始界面**右上角「LLM 设置」**里填自己的 Key 就行：

1. 打开游戏 → 主界面**右上角**点 **「LLM 设置 · 离线」**
2. 填入 **API 地址**（已预填 `https://api.deepseek.com/v1/chat/completions`）、**API Key**、**模型**（默认 `deepseek-chat`）
3. 点 **「保存并测试」** → 面板先测试连通性（8 秒超时），通过即生效，**无需重启、无需重新打包**

设置只写入本机 `%APPDATA%\Godot\app_userdata\darkdungeon\llm_config.json`，不会上传，也不影响存档。
（填错了随时点「清除（改用离线）」即可回落。）

首次点 `START` 时若完全没有可用在线配置，会自动弹一次同一个面板（`离线开始` / `保存并开始` 二选一）。

**配置优先级**（低 → 高，后写入的非空字段覆盖前者）：

| 优先级 | 来源 | 用途 |
| --- | --- | --- |
| ① | `scripts/battle/api_public.gd` | 可选的**自建代理**地址 + 公开令牌（可入库；真 Key 只存在 Worker 环境变量里，最安全） |
| ② | exe 同目录 `api_config.json` | 便携覆盖，免让玩家手填（适合批量分发预置配置） |
| ③ | `user://llm_config.json` | 开始界面右上角「LLM 设置」面板写入（玩家自己的 Key） |

> 🔐 **本仓库不内置任何 Key**。打进 exe / pck 的 Key 等价于公开的 Key（pck 只是 zstd 压缩，XOR+Base64 混淆也一解就出），
> 因此早前那套「Key 随包发布」的做法已废弃。想让玩家无需填 Key 又不想暴露真 Key，请用 [worker/README.md](worker/README.md) 的 Cloudflare Worker 代理方案。

## 发布 Release

```powershell
powershell -ExecutionPolicy Bypass -File tools\export_release.ps1   # ① 导出 + 自动校验
# ② 打包与上传：dist\release.ps1（建/复用 Release）+ dist\upload_asset.ps1（curl 上传 zip）
```

`tools/export_release.ps1` 会自动校验四件事：

| 校验项 | 说明 |
| --- | --- |
| 包内清单 | `pck` 文件表里不得出现 `api_config.*` / `tools/` / `worker/`（不内置任何 Key） |
| 发布模式 | 判定「自建代理 / 玩家自行配置」并给出对应提醒；`api_public.gd` 里若混入 `sk-` 真 Key 直接报错 |
| Spine 数据 | `.skel` / `.atlas` 必须全部随包（漏了英雄 / 怪物会整体不可见） |
| 日志读取 | Godot 是 GUI 子系统程序：变量捕获为空、管道又会被控制台编码（GBK）吞字符 → 脚本改用 `cmd` 字节级重定向 + UTF-8 读日志 |

> ⚠️ 测导出包请**复制到工程目录之外**再运行：模板 exe 的 `res://` 在包里找不到文件时会回落到 exe 同目录的真实文件系统，
> 放在工程目录里会读到本地的 `api_config.json`，容易误判成「包内带上了本地配置」。

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
├── tools/                    # 验证探针（_probe_*.gd）与截图脚本（_shot_*.gd）
│   └── export_release.ps1    # 导出 + 发布包自动校验
│
├── worker/                   # 可选的 Cloudflare Worker 代理方案（真 Key 不落玩家机器）
├── dist/                     # 本地发布产物 / 打包上传脚本（.gitignore，不入库）
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
