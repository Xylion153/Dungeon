extends Control
## Lists every SkillData found in res://data/skills as a pickable card.
## Casting a skill has no gameplay effect yet — this only wires up selection.

@onready var card_list: VBoxContainer = $VBoxContainer/ScrollContainer/CardList
@onready var back_button: Button = $VBoxContainer/BackButton

func _ready() -> void:
	back_button.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/main/MainMenu.tscn"))
	_populate()

func _populate() -> void:
	for child in card_list.get_children():
		child.queue_free()

	for skill in DataFolder.list_resources("res://data/skills"):
		var is_equipped: bool = skill == GameState.equipped_skill
		var button := Button.new()
		button.custom_minimum_size = Vector2(0, 90)
		button.text = "%s%s\n%s" % [skill.skill_name, " (equipped)" if is_equipped else "", skill.description]
		button.disabled = is_equipped
		button.pressed.connect(_on_skill_selected.bind(skill))
		card_list.add_child(button)

func _on_skill_selected(skill: SkillData) -> void:
	GameState.equipped_skill = skill
	_populate()
