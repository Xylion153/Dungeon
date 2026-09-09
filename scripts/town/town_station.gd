extends Area2D
## A Town building: solid (a StaticBody2D blocks the player from walking
## through it) and interactive (this Area2D, sized slightly larger than the
## solid footprint, opens target_scene_path on overlap - "touching" the
## building). One node now covers what used to be two separate pieces: an
## invisible trigger-only Area2D plus a free-floating, walk-through-able
## visual sprite with no collision at all.

@export var target_scene_path: String
@export var station_label: String # editor-only identifier, not rendered
@export var texture: Texture2D
@export var visual_scale := 1.0
@export var visual_offset := Vector2.ZERO ## lets the sprite be nudged relative to the collision/trigger center, since art isn't always centered on its own canvas
@export var collision_size := Vector2(300.0, 200.0) ## the building's solid footprint; the trigger zone is this plus a margin

const TRIGGER_MARGIN := 80.0

var _triggered := false

@onready var visual: Sprite2D = $Visual
@onready var body_shape: CollisionShape2D = $StaticBody2D/CollisionShape2D
@onready var trigger_shape: CollisionShape2D = $TriggerShape

func _ready() -> void:
	collision_layer = 0
	collision_mask = PhysicsLayers.PLAYER
	monitoring = true
	body_entered.connect(_on_body_entered)

	visual.texture = texture
	visual.scale = Vector2(visual_scale, visual_scale)
	visual.position = visual_offset

	var body_rect := RectangleShape2D.new()
	body_rect.size = collision_size
	body_shape.shape = body_rect

	var trigger_rect := RectangleShape2D.new()
	trigger_rect.size = collision_size + Vector2(TRIGGER_MARGIN, TRIGGER_MARGIN) * 2.0
	trigger_shape.shape = trigger_rect

func _on_body_entered(body: Node) -> void:
	if _triggered or not body.is_in_group("player"):
		return
	_triggered = true
	get_tree().change_scene_to_file(target_scene_path)
