extends Control
## Spends Gems: single/x10 pulls from the combined weapon+skill pool, with a
## hard-pity guarantee and duplicate pulls fusing into a rank-up rather than
## being wasted. Same Control/VBoxContainer shape as every other menu; the
## pull result is a plain text log, not an animated reveal, matching this
## project's placeholder-first approach everywhere else.

const SINGLE_PULL_COST := 100
const MULTI_PULL_COST := 900
const MULTI_PULL_COUNT := 10

@onready var gems_label: Label = $VBoxContainer/GemsLabel
@onready var pity_label: Label = $VBoxContainer/PityLabel
@onready var pull_single_button: Button = $VBoxContainer/ButtonRow/PullSingleButton
@onready var pull_multi_button: Button = $VBoxContainer/ButtonRow/PullMultiButton
@onready var result_list: VBoxContainer = $VBoxContainer/ScrollContainer/ResultList
@onready var back_button: Button = $VBoxContainer/BackButton

func _ready() -> void:
	back_button.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/main/Town.tscn"))
	pull_single_button.pressed.connect(_on_pull_single)
	pull_multi_button.pressed.connect(_on_pull_multi)
	_update_header()

func _update_header() -> void:
	gems_label.text = "Gems: %d" % SaveManager.get_gems()
	pity_label.text = "Pity: %d/%d pulls to guaranteed Rare" % [SaveManager.get_gacha_pity(), GachaRoller.HARD_PITY_THRESHOLD]
	pull_single_button.text = "Pull x1 — %d Gems" % SINGLE_PULL_COST
	pull_single_button.disabled = SaveManager.get_gems() < SINGLE_PULL_COST
	pull_multi_button.text = "Pull x%d — %d Gems" % [MULTI_PULL_COUNT, MULTI_PULL_COST]
	pull_multi_button.disabled = SaveManager.get_gems() < MULTI_PULL_COST

func _on_pull_single() -> void:
	if SaveManager.get_gems() < SINGLE_PULL_COST:
		return
	SaveManager.add_gems(-SINGLE_PULL_COST)
	_do_pull()
	_update_header()

func _on_pull_multi() -> void:
	if SaveManager.get_gems() < MULTI_PULL_COST:
		return
	SaveManager.add_gems(-MULTI_PULL_COST)
	for i in MULTI_PULL_COUNT:
		_do_pull()
	_update_header()

func _do_pull() -> void:
	var item: Variant = GachaRoller.roll(SaveManager.get_gacha_pity())
	if GachaRoller.is_rare(item):
		SaveManager.reset_gacha_pity()
	else:
		SaveManager.add_gacha_pity()

	var item_name: String
	var rarity_text: String
	var new_rank: int
	var was_owned: bool
	if item is WeaponData:
		item_name = item.weapon_name
		rarity_text = "Rare" if item.rarity == WeaponData.Rarity.RARE else "Common"
		was_owned = SaveManager.owns_weapon(item.id)
		new_rank = SaveManager.pull_weapon(item.id)
	else:
		item_name = item.skill_name
		rarity_text = "Rare" if item.rarity == SkillData.Rarity.RARE else "Common"
		was_owned = SaveManager.owns_skill(item.id)
		new_rank = SaveManager.pull_skill(item.id)

	var outcome_text: String = ("Rank up! (now Rank %d)" % new_rank) if was_owned else "New!"
	_log_result("%s (%s) — %s" % [item_name, rarity_text, outcome_text])

func _log_result(text: String) -> void:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", 24)
	label.text = text
	result_list.add_child(label)
	result_list.move_child(label, 0) # newest on top
