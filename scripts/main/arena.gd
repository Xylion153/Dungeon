extends Node2D

@onready var wave_spawner: WaveSpawner = $WaveSpawner
@onready var game_over_screen: CanvasLayer = $GameOverScreen

var current_wave := 0

func _ready() -> void:
	EventBus.wave_started.connect(func(w: int) -> void: current_wave = w)
	call_deferred("_bind_player")

func _bind_player() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player:
		player.died.connect(_on_player_died)

func _on_player_died() -> void:
	wave_spawner.set_physics_process(false)
	game_over_screen.show_result(current_wave)
