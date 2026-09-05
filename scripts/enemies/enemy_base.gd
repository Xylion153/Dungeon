class_name EnemyBase
extends CombatActor
## Reference "melee chaser" archetype (brief section 6.1): walks straight at
## the player, telegraphs briefly before its attack lands. Ranged/orbiting
## archetypes will extend this rather than duplicate the shared bits
## (movement toward player, telegraph timing, DamageResolver call).

@export var move_speed := 90.0
@export var contact_damage := 8.0
@export var attack_range := 40.0
@export var attack_cooldown := 1.0
@export var telegraph_duration := 0.35

@onready var sprite: Polygon2D = $Shape

var _player: Node2D
var _attack_timer := 0.0
var _telegraphing := false
var _telegraph_timer := 0.0

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

	if _attack_timer > 0.0:
		_attack_timer -= delta

	if _telegraphing:
		_telegraph_timer -= delta
		if sprite:
			sprite.modulate = Color(1.0, 0.4, 0.4).lerp(Color.WHITE, sin(_telegraph_timer * 30.0) * 0.5 + 0.5)
		velocity = Vector2.ZERO
		if _telegraph_timer <= 0.0:
			_telegraphing = false
			if sprite:
				sprite.modulate = Color.WHITE
			_try_hit_player()
	else:
		_chase()

	velocity += consume_knockback(delta)
	move_and_slide()

func _chase() -> void:
	var to_player := _player.global_position - global_position
	var distance := to_player.length()

	if distance <= attack_range and _attack_timer <= 0.0:
		_start_telegraph()
		return

	if distance > attack_range * 0.8:
		velocity = to_player.normalized() * move_speed
	else:
		velocity = Vector2.ZERO

func _start_telegraph() -> void:
	_telegraphing = true
	_telegraph_timer = telegraph_duration
	_attack_timer = attack_cooldown

func _try_hit_player() -> void:
	if _player == null or not is_instance_valid(_player):
		return
	var distance := global_position.distance_to(_player.global_position)
	if distance > attack_range * 1.3:
		return # player escaped the telegraph
	DamageResolver.resolve_hit(self, _player, {
		"damage": contact_damage,
		"knockback": 220.0,
	})
