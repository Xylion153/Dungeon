extends Control
## Lists the current class's starter skills as a pickable card. The broader
## gacha-unlockable skill pool doesn't exist yet (Phase 6) - this is just
## the guaranteed starter set for now.

@onready var card_list: VBoxContainer = $VBoxContainer/ScrollContainer/CardList
@onready var back_button: Button = $VBoxContainer/BackButton

func _ready() -> void:
	back_button.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/main/Town.tscn"))
	_populate()

func _populate() -> void:
	for child in card_list.get_children():
		child.queue_free()

	if GameState.current_class == null:
		return

	for skill in GameState.current_class.starter_skills:
		var is_equipped: bool = skill == GameState.equipped_skill
		var button := Button.new()
		button.custom_minimum_size = Vector2(0, 130)
		button.add_theme_font_size_override("font_size", 30)
		button.text = "%s%s\n%s" % [skill.skill_name, " (equipped)" if is_equipped else "", skill.description]
		button.disabled = is_equipped
		button.pressed.connect(_on_skill_selected.bind(skill))
		card_list.add_child(button)

func _on_skill_selected(skill: SkillData) -> void:
	GameState.equipped_skill = skill
	_populate()
