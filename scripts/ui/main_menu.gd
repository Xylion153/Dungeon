extends Control

@onready var start_button: Button = $CenterContainer/VBoxContainer/StartButton
@onready var armory_button: Button = $CenterContainer/VBoxContainer/ArmoryButton
@onready var skills_button: Button = $CenterContainer/VBoxContainer/SkillsButton

func _ready() -> void:
	start_button.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/main/Arena.tscn"))
	armory_button.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/main/ArmoryMenu.tscn"))
	skills_button.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/main/SkillsMenu.tscn"))
