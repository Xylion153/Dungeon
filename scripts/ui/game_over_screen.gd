extends CanvasLayer
## Death screen (brief section 7): shows the wave reached, then either
## retries with the same loadout (reload Arena - GameState.equipped_weapon/
## skill already persist across scene changes) or returns to loadout
## selection.

@onready var wave_label: Label = $CenterContainer/VBoxContainer/WaveLabel
@onready var retry_button: Button = $CenterContainer/VBoxContainer/RetryButton
@onready var change_loadout_button: Button = $CenterContainer/VBoxContainer/ChangeLoadoutButton

func _ready() -> void:
	visible = false
	retry_button.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/main/Arena.tscn"))
	change_loadout_button.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/main/MainMenu.tscn"))

func show_result(wave_reached: int) -> void:
	wave_label.text = "Wave Reached: %d" % wave_reached
	visible = true
