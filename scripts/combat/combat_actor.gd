class_name CombatActor
extends CharacterBody2D
## Shared health/knockback/hit-flash behavior for anything DamageResolver
## can hit (Player, EnemyBase). Keeps that logic in one place instead of
## duplicating it per actor type.

signal died

@export var max_health := 100.0

var health: float
var _invulnerable := false
var _knockback_velocity := Vector2.ZERO
var _sprite: CanvasItem

func _ready() -> void:
	health = max_health
	_sprite = get_node_or_null("Shape")

func get_health() -> float:
	return health

func is_invulnerable() -> bool:
	return _invulnerable

func set_invulnerable(value: bool) -> void:
	_invulnerable = value

func take_damage(amount: float) -> void:
	health = max(health - amount, 0.0)
	if health <= 0.0:
		die()

func heal(amount: float) -> void:
	health = minf(health + amount, max_health)

func apply_knockback(impulse: Vector2) -> void:
	_knockback_velocity = impulse

func consume_knockback(delta: float) -> Vector2:
	var current := _knockback_velocity
	_knockback_velocity = _knockback_velocity.move_toward(Vector2.ZERO, 1200.0 * delta)
	return current

func flash_hit() -> void:
	if _sprite == null:
		return
	_sprite.modulate = Color(1.6, 1.6, 1.6)
	var tween := create_tween()
	tween.tween_property(_sprite, "modulate", Color.WHITE, 0.12)

func die() -> void:
	died.emit()
	queue_free()
