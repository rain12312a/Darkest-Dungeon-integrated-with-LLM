/**
 * Dark Dungeon · LLM 代理（Cloudflare Worker）
 *
 * 作用：游戏客户端只持有一个「可公开的客户端令牌」，真正的 DeepSeek API Key
 *       保存在本 Worker 的加密环境变量里，永不下发到玩家机器。
 *
 * 环境变量（在 Cloudflare 面板 Settings → Variables and Secrets 里配置）：
 *   DEEPSEEK_API_KEY  (Secret) 你的真实 DeepSeek Key，如 sk-xxxx
 *   CLIENT_TOKEN      (Secret) 客户端令牌，自己随便生成一串随机字符；
 *                              与 scripts/battle/api_public.gd 的 API_KEY 保持一致
 *
 * 可选变量：
 *   UPSTREAM_URL      默认 https://api.deepseek.com/v1/chat/completions
 *   MAX_PER_HOUR      单 IP 每小时最大请求数，默认 60
 *
 * 游戏侧配置：api_public.gd 里
 *   API_URL = "https://<你的-worker>.workers.dev"
 *   API_KEY = "<CLIENT_TOKEN 的值>"
 */

const DEEPSEEK_URL = "https://api.deepseek.com/v1/chat/completions";
const ALLOWED_MODEL = "deepseek-chat";

// 尽力而为的限流（每个 isolate 独立计数，跨实例不共享；要严格限制请在
// Cloudflare 面板给该 Worker 增加 Rate limiting 规则，或改用 KV/Durable Objects）
const hits = new Map();

function rateLimited(ip, maxPerHour) {
  const now = Date.now();
  const windowMs = 3600 * 1000;
  if (hits.size > 5000) hits.clear(); // 简单的内存保护
  const rec = hits.get(ip);
  if (!rec || now - rec.start > windowMs) {
    hits.set(ip, { start: now, count: 1 });
    return false;
  }
  rec.count += 1;
  return rec.count > maxPerHour;
}

function json(obj, status) {
  return new Response(JSON.stringify(obj), {
    status,
    headers: { "Content-Type": "application/json; charset=utf-8" },
  });
}

export default {
  async fetch(request, env) {
    if (request.method === "GET") {
      return json({ ok: true, service: "darkdungeon-llm-proxy" }, 200);
    }
    if (request.method !== "POST") {
      return json({ error: "method not allowed" }, 405);
    }

    // 客户端令牌校验（令牌会随 exe 公开，仅用于挡住随手乱扫的脚本）
    const token = (request.headers.get("authorization") || "").replace(/^Bearer\s+/i, "").trim();
    if (!env.CLIENT_TOKEN || token !== env.CLIENT_TOKEN) {
      return json({ error: "unauthorized" }, 401);
    }
    if (!env.DEEPSEEK_API_KEY) {
      return json({ error: "server not configured" }, 500);
    }

    // 限流
    const ip = request.headers.get("CF-Connecting-IP") || "unknown";
    const maxPerHour = Number(env.MAX_PER_HOUR) || 60;
    if (rateLimited(ip, maxPerHour)) {
      return json({ error: "rate limited" }, 429);
    }

    let body;
    try {
      body = await request.json();
    } catch {
      return json({ error: "invalid json" }, 400);
    }

    const messages = Array.isArray(body.messages) ? body.messages.slice(-8) : [];
    if (messages.length === 0) {
      return json({ error: "messages required" }, 400);
    }

    // 约束上游请求，避免被改成昂贵模型或超长上下文
    const payload = {
      model: ALLOWED_MODEL,
      messages,
      temperature: Math.min(Math.max(Number(body.temperature) || 0.7, 0), 1.5),
      max_tokens: Math.min(Number(body.max_tokens) || 100, 300),
      stream: false,
    };

    const upstream = await fetch(env.UPSTREAM_URL || DEEPSEEK_URL, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Authorization": `Bearer ${env.DEEPSEEK_API_KEY}`,
      },
      body: JSON.stringify(payload),
    });

    const text = await upstream.text();
    return new Response(text, {
      status: upstream.status,
      headers: { "Content-Type": "application/json; charset=utf-8" },
    });
  },
};
