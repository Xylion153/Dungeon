extends Area2D
## A walk-in door in Town: overlap navigates to target_scene_path, matching
## the overlap-trigger pattern scripts/combat/loot_pickup.gd already uses.

@export var target_scene_path: String
@export var station_label: String
@export var station_color: Color = Color(0.5, 0.5, 0.5)

@onready var shape_visual: Polygon2D = $Visual
@onready var label: Label = $Label

var _triggered := false

func _ready() -> void:
	collision_layer = 0
	collision_mask = PhysicsLayers.PLAYER
	monitoring = true
	body_entered.connect(_on_body_entered)
	shape_visual.color = station_color
	shape_visual.polygon = _square_polygon(48.0)
	label.text = station_label

func _square_polygon(half_size: float) -> PackedVector2Array:
	return PackedVector2Array([
		Vector2(-half_size, -half_size), Vector2(half_size, -half_size),
		Vector2(half_size, half_size), Vector2(-half_size, half_size),
	])

func _on_body_entered(body: Node) -> void:
	if _triggered or not body.is_in_group("player"):
		return
	_triggered = true
	get_tree().change_scene_to_file(target_scene_path)
