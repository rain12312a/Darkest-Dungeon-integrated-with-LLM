extends Node

const DATA_DIR := "res://data"

func load_json(path: String) -> Dictionary:
    var file := FileAccess.open(path, FileAccess.READ)
    if file == null:
        return {}
    var text := file.get_as_text()
    var result := JSON.parse_string(text)
    if typeof(result) == TYPE_DICTIONARY:
        return result
    return {}

func get_characters() -> Dictionary:
    return load_json(DATA_DIR + "/characters.json")

func get_skills() -> Dictionary:
    return load_json(DATA_DIR + "/skills.json")

func get_statuses() -> Dictionary:
    return load_json(DATA_DIR + "/statuses.json")

func get_towns() -> Dictionary:
    return load_json(DATA_DIR + "/towns.json")
