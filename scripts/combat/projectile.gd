extends Area2D
## Shared projectile for every ranged source (Gun/Wand steps, ranged/orbiting
## enemy shots, boss burst). Area2D rather than CharacterBody2D since it only
## needs overlap detection, not physics response. Splash damage folds the
## direct hit and the AoE into one query at the impact point rather than two
## separate code paths.

@onready var shape: CollisionShape2D = $CollisionShape2D
@onready var visual: Polygon2D = $Visual

var direction := Vector2.RIGHT
var speed := 400.0
var damage := 10.0
var knockback := 60.0
var pierce := false
var splash_radius := 0.0
var target_mask := PhysicsLayers.ENEMY
var crit_chance := 0.0
var crit_multiplier := 1.5
var max_lifetime := 2.5

var _attacker: Node
var _hit_bodies: Array = []

func setup(params: Dictionary, attacker: Node = null) -> void:
	direction = (params.get("direction", direction) as Vector2).normalized()
	speed = params.get("speed", speed)
	damage = params.get("damage", damage)
	knockback = params.get("knockback", knockback)
	pierce = params.get("pierce", pierce)
	splash_radius = params.get("splash_radius", splash_radius)
	target_mask = params.get("target_mask", target_mask)
	crit_chance = params.get("crit_chance", crit_chance)
	crit_multiplier = params.get("crit_multiplier", crit_multiplier)
	_attacker = attacker
	rotation = direction.angle()

	# _ready() already ran (add_child() calls it synchronously, before this),
	# so it locked collision_mask to the class-default target_mask. Re-apply
	# it here now that target_mask reflects what the caller actually asked
	# for - otherwise an enemy's own shot (target_mask=PLAYER) keeps the
	# stale ENEMY-layer mask and detects the shooter itself on spawn.
	collision_mask = target_mask | PhysicsLayers.WORLD

	var radius: float = params.get("radius", 6.0)
	if shape and shape.shape is CircleShape2D:
		shape.shape.radius = radius
	if visual:
		visual.scale = Vector2.ONE * (radius / 6.0)
		var color: Variant = params.get("color", null)
		if color != null:
			visual.color = color

func _ready() -> void:
	collision_layer = 0
	collision_mask = target_mask | PhysicsLayers.WORLD
	monitoring = true
	body_entered.connect(_on_body_entered)
	get_tree().create_timer(max_lifetime).timeout.connect(_on_lifetime_expired)

func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta

func _on_lifetime_expired() -> void:
	if is_instance_valid(self):
		queue_free()

func _on_body_entered(body: Node) -> void:
	if body is CombatActor:
		if body in _hit_bodies:
			return
		_hit_bodies.append(body)
		_resolve_hit()
		if not pierce:
			queue_free()
	elif body is StaticBody2D:
		queue_free() # hit a wall/obstacle

func _resolve_hit() -> void:
	if splash_radius > 0.0:
		_splash_damage()
	else:
		var closest: Node = _hit_bodies[_hit_bodies.size() - 1]
		DamageResolver.resolve_hit(_attacker_or_null(), closest, _damage_params())

func _splash_damage() -> void:
	var space_state := get_world_2d().direct_space_state
	var query := PhysicsShapeQueryParameters2D.new()
	var circle := CircleShape2D.new()
	circle.radius = splash_radius
	query.shape = circle
	query.transform = Transform2D(0, global_position)
	query.collision_mask = target_mask
	query.collide_with_bodies = true
	query.collide_with_areas = false
	var attacker := _attacker_or_null()
	for result in space_state.intersect_shape(query, 16):
		var body = result.collider
		if body is CombatActor:
			DamageResolver.resolve_hit(attacker, body, _damage_params())

func _attacker_or_null() -> Node:
	# The enemy/player that fired this can die before the shot lands (e.g.
	# the player kills a ranged enemy right after it shoots) - resolve_hit()
	# would otherwise be called with a freed reference and crash the typed
	# argument check.
	return _attacker if is_instance_valid(_attacker) else null

func _damage_params() -> Dictionary:
	return {
		"damage": damage,
		"knockback": knockback,
		"crit_chance": crit_chance,
		"crit_multiplier": crit_multiplier,
	}
