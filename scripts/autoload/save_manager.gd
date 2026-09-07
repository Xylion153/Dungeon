extends Node
## Persistent per-class level/XP, saved as JSON to user:// (IndexedDB on the
## Web export). Loaded once at startup; saved immediately on every XP gain -
## writes are tiny and infrequent (per kill/wave-clear, not per-frame), so
## there's no need to debounce yet.

const SAVE_PATH := "user://save.json"

signal leveled_up(class_id: String, new_level: int)

var _data: Dictionary = {"current_class_id": "", "classes": {}}

func _ready() -> void:
	_load()

func get_class_progress(class_id: String) -> Dictionary:
	var classes: Dictionary = _data["classes"]
	if not classes.has(class_id):
		classes[class_id] = {"level": 1, "xp": 0.0}
	return classes[class_id]

func add_xp(class_id: String, amount: float) -> void:
	var progress := get_class_progress(class_id)
	progress["xp"] = float(progress["xp"]) + amount

	var leveled := false
	while float(progress["xp"]) >= xp_to_next_level(int(progress["level"])):
		progress["xp"] = float(progress["xp"]) - xp_to_next_level(int(progress["level"]))
		progress["level"] = int(progress["level"]) + 1
		leveled = true

	_save()
	if leveled:
		leveled_up.emit(class_id, int(progress["level"]))

func xp_to_next_level(level: int) -> float:
	return 50.0 + float(level - 1) * 25.0

func set_current_class_id(class_id: String) -> void:
	_data["current_class_id"] = class_id
	_save()

func get_current_class_id() -> String:
	return _data.get("current_class_id", "")

func _load() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		_data = parsed
		if not _data.has("classes"):
			_data["classes"] = {}

func _save() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify(_data))
