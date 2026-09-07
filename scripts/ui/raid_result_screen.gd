extends CanvasLayer
## Shared win/lose screen for any boss-ending combat scene (Raids,
## DungeonLevel) - built separately from GameOverScreen rather than
## retrofitted with branches, matching this project's preference for
## parallel structure over conditionally-branching one screen into two.
## Retry re-enters whichever scene called show_victory()/show_defeat()
## (defaults to RaidArena.tscn so existing Raid call sites need no
## changes); the other button always goes back to the World Map, since
## that's where every caller of this screen is reached from.

const DEFAULT_RETRY_SCENE := "res://scenes/main/RaidArena.tscn"

@onready var title_label: Label = $CenterContainer/VBoxContainer/Title
@onready var reward_label: Label = $CenterContainer/VBoxContainer/RewardLabel
@onready var retry_button: Button = $CenterContainer/VBoxContainer/RetryButton
@onready var world_map_button: Button = $CenterContainer/VBoxContainer/WorldMapButton

var _retry_scene_path := DEFAULT_RETRY_SCENE

func _ready() -> void:
	visible = false
	retry_button.pressed.connect(func():
		GameState.apply_run_buffs()
		get_tree().change_scene_to_file(_retry_scene_path)
	)
	world_map_button.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/main/WorldMapMenu.tscn"))

func show_victory(gems_earned: int, retry_scene_path: String = DEFAULT_RETRY_SCENE) -> void:
	_retry_scene_path = retry_scene_path
	title_label.text = "Victory!"
	reward_label.text = "+%d Gems" % gems_earned
	reward_label.visible = true
	visible = true

func show_defeat(retry_scene_path: String = DEFAULT_RETRY_SCENE) -> void:
	_retry_scene_path = retry_scene_path
	title_label.text = "Defeat"
	reward_label.visible = false
	visible = true
