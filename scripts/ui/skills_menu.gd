extends Control
## Lists the GLOBAL skill pool as a pickable card, gated by
## SaveManager.owns_skill() - only Gacha (or a class's own free starter)
## grants ownership. Same shape as armory_menu.gd's Weapons tab.

@onready var card_list: VBoxContainer = $VBoxContainer/ScrollContainer/CardList
@onready var back_button: Button = $VBoxContainer/BackButton

func _ready() -> void:
	back_button.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/main/Town.tscn"))
	_populate()

func _populate() -> void:
	for child in card_list.get_children():
		child.queue_free()

	for skill: SkillData in DataFolder.list_resources("res://data/skills"):
		var owned: bool = SaveManager.owns_skill(skill.id)
		var is_equipped: bool = skill == GameState.equipped_skill
		var button := Button.new()
		button.custom_minimum_size = Vector2(0, 130)
		button.add_theme_font_size_override("font_size", 30)
		if owned:
			var rank_text: String = " ★%d" % SaveManager.get_skill_rank(skill.id)
			button.text = "%s%s%s\n%s" % [skill.skill_name, rank_text, " (equipped)" if is_equipped else "", skill.description]
			button.disabled = is_equipped
			button.pressed.connect(_on_skill_selected.bind(skill))
		else:
			var rarity_text: String = "Rare" if skill.rarity == SkillData.Rarity.RARE else "Common"
			button.text = "%s (Locked - %s)\nUnlock via Gacha" % [skill.skill_name, rarity_text]
			button.disabled = true
		card_list.add_child(button)

func _on_skill_selected(skill: SkillData) -> void:
	GameState.equipped_skill = skill
	_populate()
