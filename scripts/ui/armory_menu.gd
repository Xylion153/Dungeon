extends Control
## Lists every WeaponData found in res://data/weapons as a pickable card.
## Ready for Spear/Gun/Wand later without any changes here — see DataFolder.

@onready var card_list: VBoxContainer = $VBoxContainer/ScrollContainer/CardList
@onready var back_button: Button = $VBoxContainer/BackButton

func _ready() -> void:
	back_button.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/main/MainMenu.tscn"))
	_populate()

func _populate() -> void:
	for child in card_list.get_children():
		child.queue_free()

	for weapon in DataFolder.list_resources("res://data/weapons"):
		var is_equipped: bool = weapon == GameState.equipped_weapon
		var button := Button.new()
		button.custom_minimum_size = Vector2(0, 130)
		button.add_theme_font_size_override("font_size", 30)
		button.text = "%s%s\n%s" % [weapon.weapon_name, " (equipped)" if is_equipped else "", weapon.description]
		button.disabled = is_equipped
		button.pressed.connect(_on_weapon_selected.bind(weapon))
		card_list.add_child(button)

func _on_weapon_selected(weapon: WeaponData) -> void:
	GameState.equipped_weapon = weapon
	_populate()
