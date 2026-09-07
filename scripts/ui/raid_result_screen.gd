extends CanvasLayer
## Raid win/lose screen - built separately from GameOverScreen rather than
## retrofitted with branches, matching this project's preference for
## parallel structure over conditionally-branching one screen into two.
## Retry re-enters the SAME raid; the other button goes back to the World
## Map (not Town) since that's where raids are reached from.

@onready var title_label: Label = $CenterContainer/VBoxContainer/Title
@onready var reward_label: Label = $CenterContainer/VBoxContainer/RewardLabel
@onready var retry_button: Button = $CenterContainer/VBoxContainer/RetryButton
@onready var world_map_button: Button = $CenterContainer/VBoxContainer/WorldMapButton

func _ready() -> void:
	visible = false
	retry_button.pressed.connect(func():
		GameState.apply_run_buffs()
		get_tree().change_scene_to_file("res://scenes/main/RaidArena.tscn")
	)
	world_map_button.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/main/WorldMapMenu.tscn"))

func show_victory(gems_earned: int) -> void:
	title_label.text = "Victory!"
	reward_label.text = "+%d Gems" % gems_earned
	reward_label.visible = true
	visible = true

func show_defeat() -> void:
	title_label.text = "Defeat"
	reward_label.visible = false
	visible = true
