extends Control

@onready var class_label: Label = $CenterContainer/VBoxContainer/ClassLabel
@onready var start_button: Button = $CenterContainer/VBoxContainer/StartButton
@onready var armory_button: Button = $CenterContainer/VBoxContainer/ArmoryButton
@onready var skills_button: Button = $CenterContainer/VBoxContainer/SkillsButton
@onready var gear_button: Button = $CenterContainer/VBoxContainer/GearButton
@onready var change_class_button: Button = $CenterContainer/VBoxContainer/ChangeClassButton

func _ready() -> void:
	if GameState.current_class == null:
		# Reached directly without picking a class (e.g. mid-development
		# testing) - send back to Class Select rather than crashing on a
		# null current_class everywhere below. Deferred: changing scene
		# during _ready() while the tree is still assembling this node
		# throws "Parent node is busy".
		get_tree().call_deferred("change_scene_to_file", "res://scenes/main/ClassSelectMenu.tscn")
		return

	var progress := SaveManager.get_class_progress(GameState.current_class.id)
	class_label.text = "%s - Lv. %d" % [GameState.current_class.display_name, progress["level"]]

	start_button.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/main/Arena.tscn"))
	armory_button.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/main/ArmoryMenu.tscn"))
	skills_button.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/main/SkillsMenu.tscn"))
	gear_button.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/main/GearMenu.tscn"))
	change_class_button.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/main/ClassSelectMenu.tscn"))
