extends EnemyBase
## "Orbiting enemy" archetype (brief section 6.3): circles the player while
## firing spread patterns, forcing repositioning.

@export var orbit_radius := 300.0
@export var orbit_angular_speed := 1.4 # radians/sec
@export var shot_cooldown := 2.2
@export var shot_damage := 6.0
@export var shot_speed := 380.0
@export var shot_radius := 7.0
@export var spread_count := 3
@export var spread_degrees := 40.0

const ProjectileScene := preload("res://scenes/combat/Projectile.tscn")

var _orbit_angle := 0.0
var _orbit_direction := 1.0
var _shot_timer := 0.0

func _ready() -> void:
	super._ready()
	_orbit_angle = randf() * TAU
	_orbit_direction = 1.0 if randi() % 2 == 0 else -1.0

func scale_difficulty(multiplier: float) -> void:
	shot_damage *= multiplier

func _update_behavior(delta: float) -> void:
	if _shot_timer > 0.0:
		_shot_timer -= delta

	_orbit_angle += orbit_angular_speed * _orbit_direction * delta
	var orbit_point: Vector2 = _player.global_position + Vector2(cos(_orbit_angle), sin(_orbit_angle)) * orbit_radius
	var to_orbit_point: Vector2 = orbit_point - global_position
	velocity = to_orbit_point * 3.0
	var max_speed := effective_move_speed()
	if velocity.length() > max_speed:
		velocity = velocity.normalized() * max_speed

	if _shot_timer <= 0.0:
		_shot_timer = shot_cooldown
		start_telegraph(0.35)

func _on_telegraph_finished() -> void:
	if _player == null or not is_instance_valid(_player):
		return
	var parent := get_tree().current_scene
	if parent == null:
		return
	var base_direction: Vector2 = (_player.global_position - global_position).normalized()
	var half_spread := deg_to_rad(spread_degrees) * 0.5
	var count := maxi(spread_count, 1)
	for i in count:
		var t: float = 0.5 if count <= 1 else float(i) / float(count - 1)
		var angle_offset: float = lerp(-half_spread, half_spread, t) if count > 1 else 0.0
		var direction: Vector2 = base_direction.rotated(angle_offset)
		var projectile := ProjectileScene.instantiate()
		parent.add_child(projectile)
		projectile.global_position = global_position
		projectile.setup({
			"direction": direction,
			"speed": shot_speed,
			"radius": shot_radius,
			"damage": shot_damage,
			"knockback": 70.0,
			"target_mask": PhysicsLayers.PLAYER,
			"color": Color(0.7, 0.4, 1.0),
		}, self)
