extends Node2D
## A single boss-only encounter, no wave escalation - deliberately NOT using
## WaveSpawner (see scripts/spawn/wave_spawner.gd's header: its
## _start_next_wave() unconditionally spawns another regular-enemy pack once
## a wave clears, which is exactly the "runs forever" behavior a raid must
## not have). The boss is instantiated directly instead.

const KILL_XP := 5.0
const BOSS_SCENE := preload("res://scenes/enemies/BossEnemy.tscn")
const SPAWN_OFFSET := Vector2(600.0, 0.0) # roughly matches WaveSpawner's 500-700px spawn radius

@onready var player: Player = $Player
@onready var result_screen: CanvasLayer = $RaidResultScreen
@onready var wave_label: Label = $Hud/WaveLabel

func _ready() -> void:
	wave_label.text = "The Brute"
	EventBus.enemy_killed.connect(_on_enemy_killed)

	var boss := BOSS_SCENE.instantiate()
	boss.global_position = player.global_position + SPAWN_OFFSET
	add_child(boss)
	boss.died.connect(_on_boss_died)

	player.died.connect(_on_player_died)

func _on_enemy_killed(_attacker: Node, _enemy: Node, _killing_blow_damage: float) -> void:
	if GameState.current_class:
		SaveManager.add_xp(GameState.current_class.id, KILL_XP)

func _bank_run_loot() -> void:
	for piece in GameState.run_loot:
		SaveManager.add_to_inventory(piece)
	GameState.run_loot.clear()
	for piece in GameState.run_artifact_loot:
		SaveManager.add_artifact_to_inventory(piece)
	GameState.run_artifact_loot.clear()

func _on_boss_died() -> void:
	const REWARD_GEMS := 50
	_bank_run_loot()
	SaveManager.add_gems(REWARD_GEMS)
	result_screen.show_victory(REWARD_GEMS)

func _on_player_died() -> void:
	_bank_run_loot()
	result_screen.show_defeat()
