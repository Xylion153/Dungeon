extends Node
## Passively tracks progress on unlocked quests and accepted Job Board slots
## by listening to EventBus itself - same precedent as GearManager/
## ArtifactManager reacting to combat events on their own, rather than every
## combat scene having to call into this manually. Claiming (reward
## granting, marking claimed) is menu-driven logic that lives in
## quest_menu.gd instead, matching how ShopMenu/GachaMenu own their own
## purchase/pull logic directly.

func _ready() -> void:
	EventBus.enemy_killed.connect(_on_enemy_killed)
	EventBus.content_cleared.connect(_on_content_cleared)

func _on_enemy_killed(_attacker: Node, _enemy: Node, _killing_blow_damage: float) -> void:
	_advance(QuestData.ObjectiveType.KILL_COUNT, "")

func _on_content_cleared(content_id: String) -> void:
	_advance(QuestData.ObjectiveType.CLEAR_CONTENT, content_id)

func _advance(objective_type: QuestData.ObjectiveType, target: String) -> void:
	for quest: QuestData in DataFolder.list_resources("res://data/quests"):
		if not is_quest_unlocked(quest) or SaveManager.is_quest_claimed(quest.id):
			continue
		if quest.objective_type == objective_type and quest.objective_target == target:
			SaveManager.add_quest_progress(quest.id, 1)

	if objective_type != QuestData.ObjectiveType.KILL_COUNT:
		return
	var slots: Array = SaveManager.get_job_slots()
	for i in slots.size():
		var job: Dictionary = slots[i]
		if job.get("accepted", false) and not job.get("claimed", false):
			SaveManager.add_job_progress(i, 1)

func is_quest_unlocked(quest: QuestData) -> bool:
	return quest.requires_quest_id == "" or SaveManager.is_quest_claimed(quest.requires_quest_id)
