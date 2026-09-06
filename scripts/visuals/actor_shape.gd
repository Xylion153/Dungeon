class_name ActorShape
extends Node2D
## Circular actor body with a facing wedge, drawn procedurally so it stays
## crisp at any zoom and needs no art assets. The parent sets this node's
## rotation to point the wedge at the actor's facing direction.

@export var radius := 20.0
@export var body_color := Color(0.30, 0.68, 1.0)
@export var rim_color := Color(0.85, 0.94, 1.0, 0.95)
@export var show_facing := true

func _ready() -> void:
	queue_redraw()

func _draw() -> void:
	draw_circle(Vector2.ZERO, radius, body_color.darkened(0.35))
	draw_circle(Vector2.ZERO, radius * 0.82, body_color)
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 48, rim_color, 2.5, true)

	if not show_facing:
		return

	# Nose points along -Y so a parent rotation of facing.angle() + PI/2 aims it.
	var tip := Vector2(0.0, -radius - 9.0)
	var left := Vector2(-radius * 0.5, -radius * 0.62)
	var right := Vector2(radius * 0.5, -radius * 0.62)
	draw_colored_polygon(PackedVector2Array([tip, left, right]), rim_color)
