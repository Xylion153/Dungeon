extends Node2D
## A blinking floor marker that telegraphs an enemy about to spawn there -
## purely visual. DungeonLevel owns the actual timing and is responsible for
## freeing this node itself once the telegraph completes (so it can check
## is_instance_valid() to detect "the room was already left" and skip a
## spawn into a stale room).

@onready var shape_visual: Polygon2D = $Visual

func _ready() -> void:
	shape_visual.polygon = _diamond_polygon(16.0)
	shape_visual.color = Color(0.9, 0.2, 0.2, 0.85)
	var tween := create_tween().set_loops()
	tween.tween_property(shape_visual, "modulate:a", 0.15, 0.35).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(shape_visual, "modulate:a", 1.0, 0.35).set_ease(Tween.EASE_IN_OUT)

func _diamond_polygon(size: float) -> PackedVector2Array:
	return PackedVector2Array([Vector2(0, -size), Vector2(size, 0), Vector2(0, size), Vector2(-size, 0)])
