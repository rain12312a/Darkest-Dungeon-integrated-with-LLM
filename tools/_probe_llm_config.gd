extends SceneTree

# ============================================================
# LLM 配置加载优先级验证（无头可跑）
# 运行：godot --headless --path . --script res://tools/_probe_llm_config.gd
#
# 校验配置来源的行为（本工程**不内置任何 Key**）：
#   ① 无 api_config.json 时：默认「离线 Mock」，地址 / 模型回到默认值
#   ② api_config.json 全字段 → 生效
#   ③ JSON 只写部分字段 → 其余字段保留默认值
#   ④ JSON 不合法 → 安全忽略，回落到默认值
#   ⑤ JSON 里是空串/空白 → 不覆盖已有配置
# 注：游戏内「LLM 设置」写入的 user://llm_config.json 优先级最高，探针会先把它移开再跑。
# ============================================================

const JSON_PATH := "res://api_config.json"
const USER_CFG := "user://llm_config.json"
const USER_BACKUP := "user://llm_config.probe_backup"

var _checks := 0
var _fails := 0
var _done := false
var _had_user_cfg := false


func _process(_delta: float) -> bool:
	if _done:
		return true
	_done = true
	_run()
	print("[LLMCFG] ===== PASS=", _checks - _fails, " FAIL=", _fails, " (共 ", _checks, " 条) =====")
	quit(0 if _fails == 0 else 1)
	return true


# ⚠️ 游戏内设置面板会写 user://llm_config.json（优先级高于本探针覆盖的 gd/exe 侧配置），
# 为保证断言确定性：先移开、跑完再放回去。
func _isolate_user_cfg() -> void:
	_had_user_cfg = FileAccess.file_exists(USER_CFG)
	if _had_user_cfg:
		DirAccess.copy_absolute(USER_CFG, USER_BACKUP)
		DirAccess.remove_absolute(USER_CFG)


func _restore_user_cfg() -> void:
	if FileAccess.file_exists(USER_CFG):
		DirAccess.remove_absolute(USER_CFG)
	if _had_user_cfg:
		DirAccess.copy_absolute(USER_BACKUP, USER_CFG)
	if FileAccess.file_exists(USER_BACKUP):
		DirAccess.remove_absolute(USER_BACKUP)


func _run() -> void:
	_isolate_user_cfg()
	_cleanup()

	# ① 无任何外置配置：不内置 Key → 离线 Mock，地址 / 模型为默认值
	var base := LLMClient.new()
	_check("① 默认无在线配置（离线 Mock）", not base.has_online_config())
	var base_key := base.api_key
	var base_url := base.api_url
	var base_model := base.model
	_check("① 默认地址为 DeepSeek 官方端点", base_url == LLMClient.DEFAULT_API_URL)
	_check("① 默认模型", base_model == LLMClient.DEFAULT_MODEL)
	base.free()

	# ② 外置 JSON 全字段生效
	_write_json('{"API_KEY":"ext-key-123","API_URL":"https://example.workers.dev","MODEL":"ext-model"}')
	var c2 := LLMClient.new()
	_check("② Key 来自外置 JSON", c2.api_key == "ext-key-123")
	_check("② URL 来自外置 JSON", c2.api_url == "https://example.workers.dev")
	_check("② MODEL 来自外置 JSON", c2.model == "ext-model")
	_check("② has_online_config 变 true", c2.has_online_config())
	c2.free()

	# ③ 只写 URL：Key 不应被凭空造出来
	_write_json('{"API_URL":"https://proxy-only.example"}')
	var c3 := LLMClient.new()
	_check("③ 只改 URL 时 Key 仍为空", c3.api_key == base_key)
	_check("③ URL 来自外置 JSON", c3.api_url == "https://proxy-only.example")
	c3.free()

	# ④ 非法 JSON
	_write_json('{ this is not json')
	var c4 := LLMClient.new()
	_check("④ 非法 JSON 不破坏配置", c4.api_key == base_key and c4.api_url == base_url)
	c4.free()

	# ⑤ 空值 / 空白值
	_write_json('{"API_KEY":"   ","API_URL":""}')
	var c5 := LLMClient.new()
	_check("⑤ 空值不覆盖已有配置", c5.api_key == base_key and c5.api_url == base_url and c5.model == base_model)
	c5.free()

	_cleanup()
	_restore_user_cfg()


func _write_json(text: String) -> void:
	var f := FileAccess.open(JSON_PATH, FileAccess.WRITE)
	if f == null:
		_check("写入 " + JSON_PATH + " 成功", false)
		return
	f.store_string(text)
	f.close()


func _cleanup() -> void:
	if FileAccess.file_exists(JSON_PATH):
		DirAccess.remove_absolute(JSON_PATH)


func _check(label: String, ok: bool) -> void:
	_checks += 1
	if not ok:
		_fails += 1
	print("[LLMCFG] ", "PASS " if ok else "FAIL ", label)
