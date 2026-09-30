extends SceneTree

# 临时截图脚本（人工核对激励回应窗口用，非游戏运行时代码）
# 运行：godot --path <项目> --script res://tools/_shot_inspire_reply.gd
# 产物：res://shot_inspire_reply.png

class StubLLM extends LLMClient:
	func get_hero_reply(_hero_name: String, _personality: String, _player_input: String, _hp: int, _max_hp: int, _stress: int, _monsters: int, _parent: Node) -> Dictionary:
		return {"reply": "\u201c力量涌上来了……我会让他们见识见识。\u201d", "outcome": LLMClient.Outcome.BUFF}

var _battle: Node = null
var _frame := 0

func _initialize() -> void:
	HeroConfig.reset_party_state()
	MonsterConfig.CURRENT_ENCOUNTER = ["skeleton_common", "skeleton_defender"]
	var packed := load("res://scenes/battle/Battle.tscn") as PackedScene
	_battle = packed.instantiate()
	root.add_child(_battle)

func _process(_delta: float) -> bool:
	_frame += 1
	if _battle == null:
		quit(1)
		return true
	if _frame == 3:
		_battle.set("battle_over", true)
		_battle.set("llm_client", StubLLM.new())
		_battle.set("current_actor", {"unit_type": "hero", "index": 0})
		_battle.set("battle_over", false)
		_battle.call("_execute_llm_inspiration", "我一直相信你，你是我们最勇敢的英雄！")
		_battle.set("battle_over", true)
		return false
	if _frame >= 12:
		var panel: Panel = _battle.get("reply_modal").get_child(0) as Panel
		var btn: Button = _battle.get("reply_confirm_button")
		print("[SHOT] reply panel rect=", str(panel.get_global_rect()))
		if btn:
			print("[SHOT] confirm button rect=", str(btn.get_global_rect()), " visible=", str(btn.visible))
			print("[SHOT] confirm button text=", btn.text)
		var img := root.get_texture().get_image()
		img.save_png("res://shot_inspire_reply.png")
		print("[SHOT] saved res://shot_inspire_reply.png size=", img.get_size())
		quit(0)
		return true
	return false
