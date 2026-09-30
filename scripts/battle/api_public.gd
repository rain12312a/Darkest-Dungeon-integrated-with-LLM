# ============================================================
# 公开版 LLM 配置（**可随导出包发布，禁止放任何真实密钥**）
#
# 作用：让玩家解压即用在线 LLM，而 true Key 只存在自建代理（Cloudflare Worker 等）的
#       环境变量里，永不下发到玩家机器。部署步骤见 worker/README.md。
#
# 填法（部署完 Worker 后把两行填上即可）：
#   API_URL：你的 Worker 地址，例如 "https://darkdungeon-llm.xxx.workers.dev"
#   API_KEY：Worker 的客户端令牌（对应 Worker 环境变量 CLIENT_TOKEN 的值）
#
# 留空 = 自动使用内置离线 Mock 引擎（四种结果逻辑完整，纯离线也能玩）。
# 玩家若想用自己的 DeepSeek Key，把 api_config.json 放到 exe 同目录即可覆盖本文件。
# ============================================================

const API_URL := ""
const API_KEY := ""
const MODEL := "deepseek-chat"
