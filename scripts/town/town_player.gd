class_name TownPlayer
extends CharacterBody2D
## Movement-only sibling of scripts/player/player.gd for the Town hub - no
## combat, so none of Player's weapon/health/skill machinery applies here.

@export var move_speed := 260.0

@onready var player_input: PlayerInput = $PlayerInput
@onready var sprite: AnimatedSprite2D = $Shape
@onready var camera: Camera2D = $Camera2D

func _ready() -> void:
	add_to_group("player")
	collision_layer = PhysicsLayers.PLAYER
	collision_mask = PhysicsLayers.WORLD
	camera.make_current()

func _physics_process(_delta: float) -> void:
	var move_vector: Vector2 = player_input.move_vector
	if move_vector.length() > 1.0:
		move_vector = move_vector.normalized()
	velocity = move_vector * move_speed
	move_and_slide()
	_update_sprite_animation(move_vector)

func _update_sprite_animation(move_vector: Vector2) -> void:
	if move_vector == Vector2.ZERO:
		if sprite.animation != "idle":
			sprite.play("idle")
		return

	var anim_name: String
	if absf(move_vector.x) > absf(move_vector.y):
		anim_name = "walk_right" if move_vector.x > 0.0 else "walk_left"
	else:
		anim_name = "walk_down" if move_vector.y > 0.0 else "walk_up"

	if sprite.animation != anim_name:
		sprite.play(anim_name)
