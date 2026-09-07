extends Control
## Lists the current class's allowed weapons as a pickable card. Weapon
## restriction per class isn't curated yet (every class currently ships
## with all 4 weapons in ClassData) - this just reads whatever the class
## data says, so tightening that later is a data edit, not a code change.

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

	for weapon in GameState.current_class.allowed_weapons:
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
