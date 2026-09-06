extends EnemyBase
## "Ranged enemy" archetype (brief section 6.2): keeps its distance and fires
## projectiles rather than closing to melee range.

@export var preferred_distance := 380.0
@export var retreat_margin := 60.0
@export var shot_cooldown := 1.4
@export var shot_damage := 8.0
@export var shot_speed := 420.0
@export var shot_radius := 7.0

const ProjectileScene := preload("res://scenes/combat/Projectile.tscn")

var _shot_timer := 0.0

func scale_difficulty(multiplier: float) -> void:
	shot_damage *= multiplier

func _update_behavior(delta: float) -> void:
	if _shot_timer > 0.0:
		_shot_timer -= delta

	var to_player: Vector2 = _player.global_position - global_position
	var distance := to_player.length()

	if distance < preferred_distance - retreat_margin:
		velocity = -to_player.normalized() * effective_move_speed()
	elif distance > preferred_distance + retreat_margin:
		velocity = to_player.normalized() * effective_move_speed()
	else:
		velocity = Vector2.ZERO

	if _shot_timer <= 0.0:
		_shot_timer = shot_cooldown
		start_telegraph(0.3)

func _on_telegraph_finished() -> void:
	if _player == null or not is_instance_valid(_player):
		return
	var parent := get_tree().current_scene
	if parent == null:
		return
	var direction: Vector2 = (_player.global_position - global_position).normalized()
	var projectile := ProjectileScene.instantiate()
	parent.add_child(projectile)
	projectile.global_position = global_position
	projectile.setup({
		"direction": direction,
		"speed": shot_speed,
		"radius": shot_radius,
		"damage": shot_damage,
		"knockback": 90.0,
		"target_mask": PhysicsLayers.PLAYER,
		"color": Color(1.0, 0.55, 0.3),
	}, self)
