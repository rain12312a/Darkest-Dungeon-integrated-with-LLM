# LLM 代理部署指南

想让玩家「双击就玩上在线 LLM」，而**你的 DeepSeek Key 又不会出现在 exe 里** —— 靠的就是这一层代理：

```
玩家 exe（只有公开的客户端令牌）
      │  POST /   Authorization: Bearer <CLIENT_TOKEN>
      ▼
你的 Worker（环境变量里存真 Key）  ← 真 Key 只在这里
      │  POST https://api.deepseek.com/v1/chat/completions
      ▼
DeepSeek API
```

为什么必须这样：导出包 `pck` 里的脚本只是 **zstd 压缩**（`encrypt_pck=false`），任何解包器都能还原明文；就算开了加密，游戏运行时也要拿 Key 去发请求，抓包一样看得到。**打进 exe 的 Key 等于公开的 Key**。

---

## 三步走（玩家 **无需配置** 路线）

> 本工程**不内置任何 Key**（早前那套「内置直连 Key」已废弃：打进 exe 的 Key 等价于公开的 Key）。
> 代理方案是「玩家双击即用」与「不暴露真 Key」兼得的做法：
> **只要 `api_public.gd` 里填了代理地址，游戏就自动用它**，玩家不必手填任何东西。

| # | 做什么 | 命令 / 位置 |
| --- | --- | --- |
| 1 | 部署 Worker，并设两个 Secret：`DEEPSEEK_API_KEY`（真 Key）、`CLIENT_TOKEN`（自拟随机串） | 见下方「方案一」（网页版，不用装东西） |
| 2 | 把 Worker 地址 + `CLIENT_TOKEN` 写回游戏 | `powershell -ExecutionPolicy Bypass -File worker\set_public_config.ps1 -Url "https://xxx.workers.dev" -Token "dd-xxxx"` |
| 3 | 重新导出并自动校验 | `powershell -ExecutionPolicy Bypass -File tools\export_release.ps1` |

完成后玩家只需：**双击 exe → 点 START → 直接开局**。因为 `api_public.gd` 已有可用配置，开始界面**不会**弹首次引导面板（`StartController._needs_llm_setup()`）；主菜单右上角的「LLM 设置」仍然在，想换成自己的 Key 的玩家才需要点它。

导出日志若出现「OK 发布模式：不内置任何 Key —— 玩家在开始界面右上角「LLM 设置」自行填 Key」的提示，说明第 2 步还没做。

---

## 方案一：网页控制台部署（推荐，不用装任何东西）

1. 打开 <https://dash.cloudflare.com> → 注册/登录（免费）
2. **建一个 Worker**（新版控制台在 **Build → Compute** 下；旧版直接叫 Workers & Pages）：
   - 路径 A：左侧 **Build** → **Compute** → **Workers & Pages** → **Create** → 选 **Worker**（选 *Start with Hello World*，不要 Git）
   - 路径 B：首页卡片 **Create app** → 选 **Worker**
   - 起个名字（如 `darkdungeon-llm`）→ **Deploy**
3. 部署完进入该 Worker → 右上角 **Edit code**（部分界面叫 **Quick edit**）→ 全选删掉模板内容，把本目录 `llm_proxy.js` 的内容整段粘进去 → **Deploy**（按钮若拆成 *Save* / *Save and Deploy*，先保存再部署）
4. Worker → **Settings** → **Variables and Secrets** → **+ Add**，逐个添加下面两个——**类型必须选 `Secret`**（不是 Text，Secret 添加后不可回显）：

   | Name | Value | 说明 |
   | --- | --- | --- |
   | `DEEPSEEK_API_KEY` | `sk-...` | 你的真实 DeepSeek Key，**只存在这里** |
   | `CLIENT_TOKEN` | 如 `dd-7f3a91c2e5b4` | 自己随手编的随机串 = 玩家 exe 里的「公开令牌」 |

   可选再加 `MAX_PER_HOUR`（普通变量即可，单 IP 每小时上限，默认 60）。
   加完设置后，**按页面提示再点一次 Deploy**，否则 Secret 不会生效。
5. 拿地址 + 自测：
   - 地址形如 `https://darkdungeon-llm.<你的账号>.workers.dev`，在 Worker 详情页顶部 / 部署完成页可看到
   - **最省事的自测**：浏览器直接打开这个地址（GET）→ 应看到 `{"ok":true,"service":"darkdungeon-llm-proxy"}`
   - **POST 自测**（验证真 Key / 令牌是否配对）：

   ```powershell
   curl.exe -X POST "https://darkdungeon-llm.你的账号.workers.dev" `
     -H "Authorization: Bearer dd-7f3a91c2e5b4" `
     -H "Content-Type: application/json" `
     -d '{\"model\":\"deepseek-chat\",\"messages\":[{\"role\":\"user\",\"content\":\"hi\"}],\"max_tokens\":20}'
   ```

   返回 DeepSeek 的 JSON（含 `choices`）= 成功；返回 `401 unauthorized` = 令牌对不上；`500 server not configured` = `DEEPSEEK_API_KEY` 没设；`429` = 被限流。

## 方案二：wrangler 命令行部署（可选）

```powershell
npm install -g wrangler
cd worker
wrangler login
wrangler secret put DEEPSEEK_API_KEY   # 粘贴真 Key
wrangler secret put CLIENT_TOKEN       # 粘贴客户端令牌
wrangler deploy
```

---

## 把地址填回游戏

推荐用脚本（会自动拒绝把 `sk-` 开头的真 Key 写进去）：

```powershell
powershell -ExecutionPolicy Bypass -File worker\set_public_config.ps1 `
  -Url "https://darkdungeon-llm.你的账号.workers.dev" -Token "dd-7f3a91c2e5b4"
```

它改的是 `scripts/battle/api_public.gd`（这个文件会随包发布，所以**只能放公开信息**）：

```gdscript
const API_URL := "https://darkdungeon-llm.你的账号.workers.dev"
const API_KEY := "dd-7f3a91c2e5b4"   # 与 Worker 的 CLIENT_TOKEN 一致
```

然后重新导出即可。**留空则玩家自动使用内置离线 Mock 引擎**（四种结果逻辑完整，纯离线也能玩）。

## ⚠️ 三个必须知道的点

1. **国内访问 `*.workers.dev` 往往不通**。如果你的玩家主要在国内，建议：
   - 给 Worker 绑一个自有域名（Cloudflare 面板 → Worker → Settings → Domains & Routes → Add → Custom Domain），或
   - 改用国内云函数（阿里云函数计算 / 腾讯云 SCF）+ 自己的域名，代码逻辑与 `llm_proxy.js` 一致（把 `export default { fetch }` 换成对应平台的入口函数即可）
2. **一定要给真 Key 设消费上限**：DeepSeek 后台 → 充值/额度设置里限额。公开的令牌虽然挡得住随手乱扫，但拦不住有心人。
3. **限流是尽力而为的**：`llm_proxy.js` 里的计数只在单个 Worker 实例内存中有效。要严格限制，请在 Cloudflare 面板给该 Worker 加 **Rate limiting** 规则，或把计数挪到 KV / Durable Objects。

## 玩家侧：想用自己的 Key 怎么办

**游戏内直接填**（推荐）：开始界面右上角 **「LLM 设置」** → 填 API 地址 + Key → **「保存并测试」**，连通性通过即生效，**无需重新打包**，也不用重启游戏。设置存在 `user://llm_config.json`（`%APPDATA%\Godot\app_userdata\darkdungeon\llm_config.json`），只在自己机器上，不会上传；优先级**高于**下面的 `api_config.json`，也高于 `api_public.gd` 里的代理配置。

**或放文件**：在 `darkdungeon.exe` 同目录放一个 `api_config.json`（适合批量分发预置配置）：

```json
{
  "API_KEY": "sk-玩家自己的Key",
  "API_URL": "https://api.deepseek.com/v1/chat/completions",
  "MODEL": "deepseek-chat"
}
```

可只写其中一项（例如只填 `API_KEY` 直连 DeepSeek）。字段留空或写错都不会破坏原有配置。
