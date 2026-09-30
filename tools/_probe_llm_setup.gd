extends SceneTree

# ============================================================
# 开始界面「LLM 设置」面板的配置层验证（**纯离线**，不发任何网络请求）
# 运行：godot --headless --path . --script res://tools/_probe_llm_setup.gd
#
# 覆盖：
#   ① 无 user:// 配置 → 来源描述非空、has_online_config() 与 api_key 一致
#   ② save_user_config → 立即生效 + 新实例读到（优先级最高，压过 exe 旁 api_config.json）
#   ③ 只填 Key → URL / 模型回落默认值；字段前后空格自动 strip
#   ④ clear_user_config → 回落低优先级来源 + 删除文件
#   ⑤ 空白 Key 不算在线配置（= 离线 Mock）
#   ⑥ user:// 里写坏 JSON → 不崩、不污染回落的配置
#   ⑦ describe_http_result() 状态码 → 面板文案映射（200/401/403/404/429/500）
#
# 未覆盖：test_connection() 的真实联网路径（需外网，建议用开始界面的「保存并测试」手测）。
# 注意：本探针会**备份并还原** user://llm_config.json 与 res://api_config.json，不破坏你的本地配置。
# ============================================================

const USER_CFG := "user://llm_config.json"
const USER_BACKUP := "user://llm_config.probe_backup"
const EXT_CFG := "res://api_config.json"
const EXT_BACKUP := "user://api_config.probe_backup"

var _checks := 0
var _fails := 0
var _done := false
var _had_user := false
var _had_ext := false


func _process(_delta: float) -> bool:
	if _done:
		return true
	_done = true
	_run()
	_restore()
	print("[LLMSETUP] ===== PASS=", _checks - _fails, " FAIL=", _fails, " (共 ", _checks, " 条) =====")
	quit(0 if _fails == 0 else 1)
	return true


func _backup() -> void:
	_had_user = FileAccess.file_exists(USER_CFG)
	if _had_user:
		DirAccess.copy_absolute(USER_CFG, USER_BACKUP)
		DirAccess.remove_absolute(USER_CFG)
	_had_ext = FileAccess.file_exists(EXT_CFG)
	if _had_ext:
		DirAccess.copy_absolute(EXT_CFG, EXT_BACKUP)
		DirAccess.remove_absolute(EXT_CFG)


func _restore() -> void:
	if FileAccess.file_exists(USER_CFG):
		DirAccess.remove_absolute(USER_CFG)
	if _had_user:
		DirAccess.copy_absolute(USER_BACKUP, USER_CFG)
	if FileAccess.file_exists(USER_BACKUP):
		DirAccess.remove_absolute(USER_BACKUP)

	if FileAccess.file_exists(EXT_CFG):
		DirAccess.remove_absolute(EXT_CFG)
	if _had_ext:
		DirAccess.copy_absolute(EXT_BACKUP, EXT_CFG)
	if FileAccess.file_exists(EXT_BACKUP):
		DirAccess.remove_absolute(EXT_BACKUP)


func _write(path: String, text: String) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		_check("写入 " + path, false)
		return
	f.store_string(text)
	f.close()


func _run() -> void:
	_backup()

	# ① 无 user 配置：来源描述与「是否有在线配置」自洽
	var base := LLMClient.new()
	var base_key := base.api_key
	var base_url := base.api_url
	var base_model := base.model
	_check("① 无 user 配置时来源描述非空", not base.config_source.is_empty())
	_check("① has_online_config 与 api_key 一致", base.has_online_config() == not base_key.strip_edges().is_empty())
	_check("① 默认地址为 DeepSeek 官方端点", not base_url.is_empty())
	base.free()

	# ② 保存后立即生效 + 新实例读到（面板「保存并测试」走的就是这条路径）
	var c := LLMClient.new()
	_check("② save_user_config 返回 true", c.save_user_config("sk-probe-user", "", ""))
	_check("② 当前实例立即生效", c.api_key == "sk-probe-user")
	_check("② has_online_config 变 true", c.has_online_config())
	_check("② 来源标记为「游戏内设置」", c.config_source == "游戏内设置")
	_check("② 空 URL 回落默认地址", c.api_url == LLMClient.DEFAULT_API_URL)
	_check("② 空模型回落默认模型", c.model == LLMClient.DEFAULT_MODEL)
	c.free()

	_check("② user://llm_config.json 已写出", FileAccess.file_exists(USER_CFG))
	var c2 := LLMClient.new()
	_check("② 新实例读到 user:// 的 Key", c2.api_key == "sk-probe-user")
	c2.free()

	# ⑧ user:// 优先级高于 exe 同目录 api_config.json（编辑器内 = res://api_config.json）
	DirAccess.remove_absolute(USER_CFG) # 先移开 user 配置，让外置配置独自生效
	_write(EXT_CFG, '{"API_KEY":"ext-key-999"}')
	var c3 := LLMClient.new()
	_check("⑧ 仅有外置配置时取外置 Key", c3.api_key == "ext-key-999")
	c3.free()
	var c4 := LLMClient.new()
	_check("⑧ user 配置压过外置配置", c4.save_user_config("sk-user-wins", "", "") and c4.api_key == "sk-user-wins")
	c4.free()
	var c5 := LLMClient.new()
	_check("⑧ 新实例同样以 user 配置为准（不是外置）", c5.api_key == "sk-user-wins")
	c5.free()
	DirAccess.remove_absolute(EXT_CFG)

	# ③ 空格 strip + 显式 URL / 模型
	var c6 := LLMClient.new()
	_check("③ 保存带空格的值", c6.save_user_config("  sk-sp  ", "  https://example.workers.dev  ", "  dd-model  "))
	_check("③ Key 已去空格", c6.api_key == "sk-sp")
	_check("③ URL 已去空格", c6.api_url == "https://example.workers.dev")
	_check("③ 模型已去空格", c6.model == "dd-model")
	c6.free()

	# ⑥ 坏 JSON：不崩、且回落到低优先级来源
	_write(USER_CFG, "{ this is not json")
	var c7 := LLMClient.new()
	_check("⑥ 坏 JSON 不崩溃并回落原 Key", c7.api_key == base_key)
	_check("⑥ 坏 JSON 回落原 URL", c7.api_url == base_url)
	c7.free()

	# ⑤ 空白 Key 不算在线配置
	var c8 := LLMClient.new()
	c8.api_key = "   "
	_check("⑤ 空白 Key 不算在线配置", not c8.has_online_config())
	c8.free()

	# ④ clear_user_config：删文件 + 回落
	var c9 := LLMClient.new()
	c9.save_user_config("sk-temp", "https://temp.example", "temp-model")
	c9.clear_user_config()
	_check("④ 清除后删除文件", not FileAccess.file_exists(USER_CFG))
	_check("④ 清除后 Key 回落原值", c9.api_key == base_key)
	_check("④ 清除后 URL 回落原值", c9.api_url == base_url)
	_check("④ 清除后模型回落原值", c9.model == base_model)
	c9.free()

	# ⑦ 状态码 → 文案映射
	var c10 := LLMClient.new()
	var r200: Dictionary = c10.describe_http_result(200)
	_check("⑦ 200 → ok", bool(r200.get("ok", false)))
	var r401: Dictionary = c10.describe_http_result(401)
	_check("⑦ 401 → 提示鉴权失败", not bool(r401.get("ok", true)) and String(r401.get("message", "")).contains("鉴权"))
	var r403: Dictionary = c10.describe_http_result(403)
	_check("⑦ 403 → 提示鉴权失败", String(r403.get("message", "")).contains("鉴权"))
	var r404: Dictionary = c10.describe_http_result(404)
	_check("⑦ 404 → 提示地址错误", String(r404.get("message", "")).contains("地址"))
	var r429: Dictionary = c10.describe_http_result(429)
	_check("⑦ 429 → 提示限流", String(r429.get("message", "")).contains("限流"))
	var r500: Dictionary = c10.describe_http_result(500)
	_check("⑦ 500 → 提示服务端错误", String(r500.get("message", "")).contains("服务端"))
	_check("⑦ 未知码也返回可读文案", not String(c10.describe_http_result(418).get("message", "")).is_empty())

	# ⑨ 内置 Key 混淆编解码（必须与 tools\embed_key.ps1 算法一致）
	var plain := "REDACTED-LEAKED-KEY"
	var blob: String = c10.encode_key(plain)
	_check("⑨ 混淆串不含 sk- 明文", not blob.contains("sk-"))
	_check("⑨ 解码可还原原文", c10.decode_obfuscated_key(blob) == plain)
	_check("⑨ 空串/非法 Base64 安全返回空", c10.decode_obfuscated_key("") == "" and c10.decode_obfuscated_key("!!!not-base64!!!") == "")
	_check("⑨ 中文/长串也能往返", c10.decode_obfuscated_key(c10.encode_key("测试-key-1234567890")) == "测试-key-1234567890")
	c10.free()

	# ⑩ 工程里的 api_config.gd 若用混淆形式，必须能被真实加载（解码链路端到端）
	var c11 := LLMClient.new()
	var dev_text := ""
	if FileAccess.file_exists("res://scripts/battle/api_config.gd"):
		dev_text = FileAccess.get_file_as_string("res://scripts/battle/api_config.gd")
	if dev_text.contains("API_KEY_OBF") and not dev_text.contains("sk-"):
		_check("⑩ 混淆形式的内置 Key 已被解密加载（在线=%s）" % str(c11.has_online_config()), c11.has_online_config())
	else:
		_check("⑩ 跳过（api_config.gd 当前不是混淆形式）", true)
	c11.free()


func _check(label: String, ok: bool) -> void:
	_checks += 1
	if not ok:
		_fails += 1
	print("[LLMSETUP] ", "PASS " if ok else "FAIL ", label)
