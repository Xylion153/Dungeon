class_name WaveSpawner
extends Node2D
## Spawns an escalating count of enemies in a ring around the player,
## waits for the wave to clear, gives a breather, then starts the next one.
## A configured boss_wave spawns the boss instead of a normal pack, as the
## Phase 1 "boss fight test."

@export var enemy_scenes: Array[PackedScene] = []
@export var boss_scene: PackedScene
@export var boss_wave := 5
@export var spawn_radius_min := 500.0
@export var spawn_radius_max := 700.0
@export var breather_duration := 3.0
@export var base_enemies_per_wave := 3
@export var enemies_added_per_wave := 1
@export var health_scale_per_wave := 0.15
@export var damage_scale_per_wave := 0.1

var current_wave := 0

var _alive_enemies: Array = []
var _player: Node2D
var _breather_timer := 0.0
var _in_breather := false
var _started := false

func _ready() -> void:
	_player = get_tree().get_first_node_in_group("player")
	call_deferred("_start_next_wave")

func _physics_process(delta: float) -> void:
	if not _started:
		return

	if _in_breather:
		_breather_timer -= delta
		if _breather_timer <= 0.0:
			_start_next_wave()
		return

	_alive_enemies = _alive_enemies.filter(func(e): return is_instance_valid(e))
	if _alive_enemies.is_empty():
		_in_breather = true
		_breather_timer = breather_duration
		EventBus.wave_cleared.emit(current_wave)

func _start_next_wave() -> void:
	_started = true
	_in_breather = false
	current_wave += 1
	EventBus.wave_started.emit(current_wave)

	if boss_scene != null and current_wave == boss_wave:
		_spawn_one(boss_scene)
		return

	var count: int = base_enemies_per_wave + (current_wave - 1) * enemies_added_per_wave
	for i in count:
		_spawn_random_enemy()

func _spawn_random_enemy() -> void:
	if enemy_scenes.is_empty():
		return
	_spawn_one(enemy_scenes[randi() % enemy_scenes.size()])

func _spawn_one(scene: PackedScene) -> void:
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player")
	if _player == null:
		return

	var enemy = scene.instantiate()
	var angle := randf() * TAU
	var dist := randf_range(spawn_radius_min, spawn_radius_max)
	enemy.position = _player.global_position + Vector2(cos(angle), sin(angle)) * dist
	get_parent().add_child(enemy)

	var wave_index: int = current_wave - 1
	if "max_health" in enemy:
		enemy.max_health *= 1.0 + wave_index * health_scale_per_wave
		enemy.health = enemy.max_health
	if enemy.has_method("scale_difficulty"):
		enemy.scale_difficulty(1.0 + wave_index * damage_scale_per_wave)

	_alive_enemies.append(enemy)
