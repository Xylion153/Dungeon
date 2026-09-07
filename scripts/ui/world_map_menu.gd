extends Control
## Level-select seam between Town and actual runs. Only one destination
## exists today (the Dungeon Arena), but this is where world bosses, raids,
## and guild battles get their own cards later - Town's Travel station
## points here once, so none of those additions touch Town itself.

@onready var card_list: VBoxContainer = $VBoxContainer/ScrollContainer/CardList
@onready var back_button: Button = $VBoxContainer/BackButton

func _ready() -> void:
	back_button.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/main/Town.tscn"))
	_populate()

func _populate() -> void:
	for child in card_list.get_children():
		child.queue_free()

	var button := Button.new()
	button.custom_minimum_size = Vector2(0, 130)
	button.add_theme_font_size_override("font_size", 30)
	button.text = "Dungeon Raid\nFight through escalating waves to a boss."
	button.pressed.connect(func():
		GameState.apply_run_buffs()
		get_tree().change_scene_to_file("res://scenes/main/Arena.tscn")
	)
	card_list.add_child(button)

	var raid_button := Button.new()
	raid_button.custom_minimum_size = Vector2(0, 130)
	raid_button.add_theme_font_size_override("font_size", 30)
	raid_button.text = "The Brute (Raid)\nDefeat a powerful boss for guaranteed Gems."
	raid_button.pressed.connect(func():
		GameState.apply_run_buffs()
		get_tree().change_scene_to_file("res://scenes/main/RaidArena.tscn")
	)
	card_list.add_child(raid_button)
