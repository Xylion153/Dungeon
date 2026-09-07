class_name EnemyBase
extends CombatActor
## Shared enemy behavior: player-tracking, telegraph flash/timer, knockback,
## facing-toward-player animation, and slow-status handling. Archetypes
## (MeleeChaser, RangedEnemy, OrbitingEnemy, BossEnemy) implement movement
## and attacks via the two virtual hooks below rather than duplicating any
## of this.

@export var move_speed := 90.0
@export var telegraph_duration := 0.35

const STOPPED_SPEED := 5.0 # below this the walk cycle reads as sliding, so idle instead

@onready var sprite: AnimatedSprite2D = $Shape

var _player: Node2D
var _telegraphing := false
var _telegraph_timer := 0.0
var _slow_multiplier := 1.0
var _slow_timer := 0.0
var _burn_damage_per_tick := 0.0
var _burn_tick_interval := 1.0
var _burn_tick_timer := 0.0
var _burn_ticks_remaining := 0

func _ready() -> void:
	super._ready()
	add_to_group("enemy")
	collision_layer = PhysicsLayers.ENEMY
	collision_mask = PhysicsLayers.WORLD
	_player = get_tree().get_first_node_in_group("player")

func _physics_process(delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player")
		velocity += consume_knockback(delta)
		move_and_slide()
		return

	if _slow_timer > 0.0:
		_slow_timer -= delta
		if _slow_timer <= 0.0:
			_slow_multiplier = 1.0

	if _burn_ticks_remaining > 0:
		_burn_tick_timer -= delta
		if _burn_tick_timer <= 0.0:
			_burn_tick_timer += _burn_tick_interval
			_burn_ticks_remaining -= 1
			# Direct damage, not DamageResolver - a burn tick must never itself
			# crit and re-trigger the proc that applied the burn.
			take_damage(_burn_damage_per_tick)

	if _telegraphing:
		_telegraph_timer -= delta
		if sprite:
			sprite.modulate = Color(1.0, 0.4, 0.4).lerp(Color.WHITE, sin(_telegraph_timer * 30.0) * 0.5 + 0.5)
		velocity = Vector2.ZERO
		if _telegraph_timer <= 0.0:
			_telegraphing = false
			if sprite:
				sprite.modulate = Color.WHITE
			_on_telegraph_finished()
	else:
		_update_behavior(delta)

	velocity += consume_knockback(delta)
	move_and_slide()
	_update_sprite_animation()

func _update_sprite_animation() -> void:
	if sprite == null or _player == null or not is_instance_valid(_player):
		return

	# Direction comes from where the player IS, not from where this enemy is
	# heading - an orbiting enemy strafes sideways but should still face you,
	# which is what the old free-rotating placeholder shape conveyed.
	if velocity.length() < STOPPED_SPEED:
		if sprite.animation != "idle":
			sprite.play("idle")
		return

	var to_player: Vector2 = _player.global_position - global_position
	var anim_name: String
	if absf(to_player.x) > absf(to_player.y):
		anim_name = "walk_right" if to_player.x > 0.0 else "walk_left"
	else:
		anim_name = "walk_down" if to_player.y > 0.0 else "walk_up"

	if sprite.animation != anim_name:
		sprite.play(anim_name)

func effective_move_speed() -> float:
	return move_speed * _slow_multiplier

func apply_slow(multiplier: float, duration: float) -> void:
	_slow_multiplier = minf(_slow_multiplier, multiplier)
	_slow_timer = maxf(_slow_timer, duration)

func apply_burn(damage_per_tick: float, tick_interval: float, ticks: int) -> void:
	_burn_damage_per_tick = damage_per_tick
	_burn_tick_interval = tick_interval
	_burn_tick_timer = tick_interval
	_burn_ticks_remaining = ticks

func start_telegraph(duration: float = -1.0) -> void:
	_telegraphing = true
	_telegraph_timer = duration if duration >= 0.0 else telegraph_duration

func scale_difficulty(_multiplier: float) -> void:
	pass # overridden by archetypes that deal damage

func _update_behavior(_delta: float) -> void:
	pass # overridden by archetypes: movement + deciding when to start_telegraph()

func _on_telegraph_finished() -> void:
	pass # overridden by archetypes: what the telegraphed attack actually does
