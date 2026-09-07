extends Node2D

const KILL_XP := 5.0
const WAVE_CLEAR_XP := 25.0

@onready var wave_spawner: WaveSpawner = $WaveSpawner
@onready var game_over_screen: CanvasLayer = $GameOverScreen
@onready var loot_offer_screen := $LootOfferScreen

var current_wave := 0

func _ready() -> void:
	EventBus.wave_started.connect(func(w: int) -> void: current_wave = w)
	EventBus.enemy_killed.connect(_on_enemy_killed)
	EventBus.wave_cleared.connect(_on_wave_cleared)
	call_deferred("_bind_player")

func _on_enemy_killed(_attacker: Node, _enemy: Node, _killing_blow_damage: float) -> void:
	if GameState.current_class:
		SaveManager.add_xp(GameState.current_class.id, KILL_XP)

func _on_wave_cleared(_wave_number: int) -> void:
	if GameState.current_class:
		SaveManager.add_xp(GameState.current_class.id, WAVE_CLEAR_XP)
	loot_offer_screen.show_offer(GearRoller.roll_piece())

func _bind_player() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player:
		player.died.connect(_on_player_died)

func _on_player_died() -> void:
	wave_spawner.set_physics_process(false)
	game_over_screen.show_result(current_wave)
