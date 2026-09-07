extends Control
## The game's true entry point (no back button - Class Select comes before
## everything else). Lists every ClassData found in res://data/classes, same
## auto-discovery pattern as Armory/Skills - a new class later needs zero
## changes here.

@onready var card_list: VBoxContainer = $VBoxContainer/ScrollContainer/CardList

func _ready() -> void:
	_populate()

func _populate() -> void:
	for child in card_list.get_children():
		child.queue_free()

	for class_data: ClassData in DataFolder.list_resources("res://data/classes"):
		var progress := SaveManager.get_class_progress(class_data.id)
		var button := Button.new()
		button.custom_minimum_size = Vector2(0, 140)
		button.add_theme_font_size_override("font_size", 28)
		button.text = "%s (Lv. %d)\n%s\nPassive: %s" % [
			class_data.display_name,
			progress["level"],
			class_data.description,
			class_data.passive_description,
		]
		button.pressed.connect(_on_class_selected.bind(class_data))
		card_list.add_child(button)

func _on_class_selected(class_data: ClassData) -> void:
	GameState.select_class(class_data)
	get_tree().change_scene_to_file("res://scenes/main/Town.tscn")
