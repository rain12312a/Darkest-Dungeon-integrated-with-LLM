extends SceneTree

# ============================================================
# LLM 配置加载优先级验证（无头可跑）
# 运行：godot --headless --path . --script res://tools/_probe_llm_config.gd
#
# 校验三级配置来源的行为：
#   ① 无外置 JSON → api_config.gd（本地开发，含真 Key）生效
#   ② api_config.json 全字段 → 覆盖 gd 配置（免重新打包换 Key / 换代理）
#   ③ JSON 只写部分字段 → 其余字段保留原值
#   ④ JSON 不合法 → 安全忽略，回落到 gd
#   ⑤ JSON 里是空串/空白 → 不覆盖已有配置
# 注：导出包中 api_config.gd 已被 export_presets.cfg 的 exclude_filter 排除，
#     因此导出后 ① 不成立，会自然降级为 api_public.gd 或离线 Mock。
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

	# ① 本地开发配置
	var base := LLMClient.new()
	_check("① 无外置 JSON 时载入 api_config.gd 的 Key", not base.api_key.strip_edges().is_empty())
	var dev_key := base.api_key
	var dev_url := base.api_url
	var dev_model := base.model
	base.free()

	# ② 外置 JSON 全字段覆盖
	_write_json('{"API_KEY":"ext-key-123","API_URL":"https://example.workers.dev","MODEL":"ext-model"}')
	var c2 := LLMClient.new()
	_check("② Key 被外置 JSON 覆盖", c2.api_key == "ext-key-123")
	_check("② URL 被外置 JSON 覆盖", c2.api_url == "https://example.workers.dev")
	_check("② MODEL 被外置 JSON 覆盖", c2.model == "ext-model")
	c2.free()

	# ③ 只写 URL，Key 应保留 gd 的值
	_write_json('{"API_URL":"https://proxy-only.example"}')
	var c3 := LLMClient.new()
	_check("③ 只改 URL 时 Key 仍来自 gd", c3.api_key == dev_key)
	_check("③ URL 来自外置 JSON", c3.api_url == "https://proxy-only.example")
	c3.free()

	# ④ 非法 JSON
	_write_json('{ this is not json')
	var c4 := LLMClient.new()
	_check("④ 非法 JSON 不破坏配置", c4.api_key == dev_key and c4.api_url == dev_url)
	c4.free()

	# ⑤ 空值 / 空白值
	_write_json('{"API_KEY":"   ","API_URL":""}')
	var c5 := LLMClient.new()
	_check("⑤ 空值不覆盖已有配置", c5.api_key == dev_key and c5.api_url == dev_url and c5.model == dev_model)
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
