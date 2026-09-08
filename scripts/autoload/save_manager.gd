extends Node
## Persistent per-class level/XP, saved as JSON to user:// (IndexedDB on the
## Web export). Loaded once at startup; saved immediately on every XP gain -
## writes are tiny and infrequent (per kill/wave-clear, not per-frame), so
## there's no need to debounce yet.

const SAVE_PATH := "user://save.json"

signal leveled_up(class_id: String, new_level: int)

const MAX_RANK := 5

var _data: Dictionary = {"current_class_id": "", "classes": {}, "credits": 0, "gems": 0, "inventory": [], "artifact_inventory": [], "consumable_inventory": {}, "owned_weapons": {}, "owned_skills": {}, "gacha_pity_counter": 0, "quest_progress": {}, "quest_claimed": {}, "job_slots": []}

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

func add_credits(amount: int) -> void:
	_data["credits"] = int(_data.get("credits", 0)) + amount
	_save()

func get_credits() -> int:
	return int(_data.get("credits", 0))

func add_gems(amount: int) -> void:
	_data["gems"] = int(_data.get("gems", 0)) + amount
	_save()

func get_gems() -> int:
	return int(_data.get("gems", 0))

func add_to_inventory(piece: GearPieceData) -> void:
	var inventory: Array = _data["inventory"]
	inventory.append(piece.to_dict())
	_save()

func get_inventory() -> Array[GearPieceData]:
	var pieces: Array[GearPieceData] = []
	for entry in _data.get("inventory", []):
		pieces.append(GearPieceData.from_dict(entry))
	return pieces

func remove_from_inventory(index: int) -> void:
	var inventory: Array = _data["inventory"]
	if index >= 0 and index < inventory.size():
		inventory.remove_at(index)
		_save()

func add_artifact_to_inventory(piece: ArtifactPieceData) -> void:
	var inventory: Array = _data["artifact_inventory"]
	inventory.append(piece.to_dict())
	_save()

func get_artifact_inventory() -> Array[ArtifactPieceData]:
	var pieces: Array[ArtifactPieceData] = []
	for entry in _data.get("artifact_inventory", []):
		pieces.append(ArtifactPieceData.from_dict(entry))
	return pieces

func remove_artifact_from_inventory(index: int) -> void:
	var inventory: Array = _data["artifact_inventory"]
	if index >= 0 and index < inventory.size():
		inventory.remove_at(index)
		_save()

func add_consumable(id: String) -> void:
	var consumables: Dictionary = _data["consumable_inventory"]
	consumables[id] = int(consumables.get(id, 0)) + 1
	_save()

func get_consumable_count(id: String) -> int:
	var consumables: Dictionary = _data.get("consumable_inventory", {})
	return int(consumables.get(id, 0))

func remove_consumable(id: String, amount: int) -> void:
	var consumables: Dictionary = _data["consumable_inventory"]
	var remaining: int = int(consumables.get(id, 0)) - amount
	if remaining > 0:
		consumables[id] = remaining
	else:
		consumables.erase(id)
	_save()

## Free grant (class starters) - idempotent, never ranks up an already-owned
## item. Paid pulls use pull_weapon()/pull_skill() instead, which do rank up.
func grant_weapon(id: String) -> void:
	var owned: Dictionary = _data["owned_weapons"]
	if not owned.has(id):
		owned[id] = 1
		_save()

func grant_skill(id: String) -> void:
	var owned: Dictionary = _data["owned_skills"]
	if not owned.has(id):
		owned[id] = 1
		_save()

## Paid-pull grant: rank 1 if unowned, otherwise fuses the duplicate into a
## rank-up (capped at MAX_RANK). Returns the new rank.
func pull_weapon(id: String) -> int:
	var owned: Dictionary = _data["owned_weapons"]
	var new_rank: int = mini(int(owned.get(id, 0)) + 1, MAX_RANK)
	owned[id] = new_rank
	_save()
	return new_rank

func pull_skill(id: String) -> int:
	var owned: Dictionary = _data["owned_skills"]
	var new_rank: int = mini(int(owned.get(id, 0)) + 1, MAX_RANK)
	owned[id] = new_rank
	_save()
	return new_rank

func owns_weapon(id: String) -> bool:
	return _data["owned_weapons"].has(id)

func get_weapon_rank(id: String) -> int:
	return int(_data["owned_weapons"].get(id, 0))

func owns_skill(id: String) -> bool:
	return _data["owned_skills"].has(id)

func get_skill_rank(id: String) -> int:
	return int(_data["owned_skills"].get(id, 0))

func add_gacha_pity() -> void:
	_data["gacha_pity_counter"] = int(_data.get("gacha_pity_counter", 0)) + 1
	_save()

func reset_gacha_pity() -> void:
	_data["gacha_pity_counter"] = 0
	_save()

func get_gacha_pity() -> int:
	return int(_data.get("gacha_pity_counter", 0))

func get_quest_progress(id: String) -> int:
	return int(_data["quest_progress"].get(id, 0))

func add_quest_progress(id: String, amount: int) -> void:
	var progress: Dictionary = _data["quest_progress"]
	progress[id] = int(progress.get(id, 0)) + amount
	_save()

func is_quest_claimed(id: String) -> bool:
	return _data["quest_claimed"].has(id)

func mark_quest_claimed(id: String) -> void:
	_data["quest_claimed"][id] = true
	_save()

func get_job_slots() -> Array:
	return _data["job_slots"]

func set_job_slots(slots: Array) -> void:
	_data["job_slots"] = slots
	_save()

func add_job_progress(index: int, amount: int) -> void:
	var slots: Array = _data["job_slots"]
	if index < 0 or index >= slots.size():
		return
	var job: Dictionary = slots[index]
	job["progress"] = int(job.get("progress", 0)) + amount
	_save()

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
		if not _data.has("credits"):
			_data["credits"] = 0
		if not _data.has("inventory"):
			_data["inventory"] = []
		if not _data.has("artifact_inventory"):
			_data["artifact_inventory"] = []
		if not _data.has("gems"):
			_data["gems"] = 0
		if not _data.has("consumable_inventory"):
			_data["consumable_inventory"] = {}
		if not _data.has("owned_weapons"):
			_data["owned_weapons"] = {}
		if not _data.has("owned_skills"):
			_data["owned_skills"] = {}
		if not _data.has("gacha_pity_counter"):
			_data["gacha_pity_counter"] = 0
		if not _data.has("quest_progress"):
			_data["quest_progress"] = {}
		if not _data.has("quest_claimed"):
			_data["quest_claimed"] = {}
		if not _data.has("job_slots"):
			_data["job_slots"] = []

func _save() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify(_data))
