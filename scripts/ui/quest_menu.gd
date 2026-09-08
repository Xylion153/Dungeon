extends Control
## Quest Log (Tutorial/Side/Main tabs - hand-authored QuestData, unlocked via
## requires_quest_id chains, tracked passively by QuestManager) + Job Board
## (a 4th tab - procedural JobGenerator bounties, accepted here, tracked the
## same way once accepted). Same TabContainer + code-generated Button/Label
## list pattern as ArmoryMenu.

const JOB_SLOT_COUNT := 3

@onready var balance_label: Label = $VBoxContainer/BalanceLabel
@onready var tutorial_list: VBoxContainer = $VBoxContainer/TabContainer/Tutorial/ScrollContainer/List
@onready var side_list: VBoxContainer = $VBoxContainer/TabContainer/Side/ScrollContainer/List
@onready var main_list: VBoxContainer = $VBoxContainer/TabContainer/Main/ScrollContainer/List
@onready var job_list: VBoxContainer = $"VBoxContainer/TabContainer/Job Board/ScrollContainer/List"
@onready var back_button: Button = $VBoxContainer/BackButton

func _ready() -> void:
	back_button.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/main/Town.tscn"))
	if SaveManager.get_job_slots().is_empty():
		SaveManager.set_job_slots(JobGenerator.roll_batch(JOB_SLOT_COUNT))
	_populate()

func _populate() -> void:
	balance_label.text = "Credits: %d   Gems: %d" % [SaveManager.get_credits(), SaveManager.get_gems()]
	_populate_category(QuestData.Category.TUTORIAL, tutorial_list)
	_populate_category(QuestData.Category.SIDE, side_list)
	_populate_category(QuestData.Category.MAIN, main_list)
	_populate_job_board()

func _populate_category(category: QuestData.Category, list: VBoxContainer) -> void:
	for child in list.get_children():
		child.queue_free()

	for quest: QuestData in DataFolder.list_resources("res://data/quests"):
		if quest.category != category or not QuestManager.is_quest_unlocked(quest):
			continue
		list.add_child(_build_quest_row(quest))

func _build_quest_row(quest: QuestData) -> Control:
	var row := VBoxContainer.new()
	row.add_theme_constant_override("separation", 6)

	var claimed := SaveManager.is_quest_claimed(quest.id)
	var progress: int = mini(SaveManager.get_quest_progress(quest.id), quest.target_count)

	var label := Label.new()
	label.add_theme_font_size_override("font_size", 24)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD
	var status := "Completed" if claimed else "%d/%d" % [progress, quest.target_count]
	label.text = "%s\n%s\nReward: %d Credits, %d Gems — %s" % [quest.display_name, quest.description, quest.reward_credits, quest.reward_gems, status]
	row.add_child(label)

	if not claimed and progress >= quest.target_count:
		var claim_button := Button.new()
		claim_button.custom_minimum_size = Vector2(0, 80)
		claim_button.text = "Claim"
		claim_button.pressed.connect(_on_claim_quest.bind(quest))
		row.add_child(claim_button)

	return row

func _on_claim_quest(quest: QuestData) -> void:
	if SaveManager.is_quest_claimed(quest.id):
		return
	SaveManager.add_credits(quest.reward_credits)
	SaveManager.add_gems(quest.reward_gems)
	SaveManager.mark_quest_claimed(quest.id)
	_populate()

func _populate_job_board() -> void:
	for child in job_list.get_children():
		child.queue_free()

	var slots: Array = SaveManager.get_job_slots()
	for i in slots.size():
		job_list.add_child(_build_job_row(slots[i], i))

	if slots.all(func(job): return job.get("claimed", false)):
		SaveManager.set_job_slots(JobGenerator.roll_batch(JOB_SLOT_COUNT))
		_populate_job_board()

func _build_job_row(job: Dictionary, index: int) -> Control:
	var row := VBoxContainer.new()
	row.add_theme_constant_override("separation", 6)

	var accepted: bool = job.get("accepted", false)
	var claimed: bool = job.get("claimed", false)
	var target: int = job.get("target_count", 0)
	var progress: int = mini(job.get("progress", 0), target)

	var label := Label.new()
	label.add_theme_font_size_override("font_size", 24)
	var status: String
	if claimed:
		status = "Completed"
	elif accepted:
		status = "%d/%d" % [progress, target]
	else:
		status = "Not accepted"
	label.text = "Bounty: Defeat %d enemies\nReward: %d Credits, %d Gems — %s" % [target, job.get("reward_credits", 0), job.get("reward_gems", 0), status]
	row.add_child(label)

	if not accepted:
		var accept_button := Button.new()
		accept_button.custom_minimum_size = Vector2(0, 80)
		accept_button.text = "Accept"
		accept_button.pressed.connect(_on_accept_job.bind(index))
		row.add_child(accept_button)
	elif not claimed and progress >= target:
		var claim_button := Button.new()
		claim_button.custom_minimum_size = Vector2(0, 80)
		claim_button.text = "Claim"
		claim_button.pressed.connect(_on_claim_job.bind(index))
		row.add_child(claim_button)

	return row

func _on_accept_job(index: int) -> void:
	var slots: Array = SaveManager.get_job_slots()
	if index < 0 or index >= slots.size():
		return
	slots[index]["accepted"] = true
	SaveManager.set_job_slots(slots)
	_populate()

func _on_claim_job(index: int) -> void:
	var slots: Array = SaveManager.get_job_slots()
	if index < 0 or index >= slots.size():
		return
	var job: Dictionary = slots[index]
	if job.get("claimed", false):
		return
	SaveManager.add_credits(job.get("reward_credits", 0))
	SaveManager.add_gems(job.get("reward_gems", 0))
	job["claimed"] = true
	SaveManager.set_job_slots(slots)
	_populate()
