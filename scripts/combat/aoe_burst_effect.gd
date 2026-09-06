extends Node2D
## Expanding, fading ring for skill AoE feedback — mirrors slash_effect.gd's
## self-contained tween-and-free pattern.

var _radius := 100.0
var _color := Color(1.0, 0.6, 0.25, 0.85)
var _progress := 0.0

func setup(radius: float, color: Color) -> void:
	_radius = radius
	_color = color

func _ready() -> void:
	var tween := create_tween()
	tween.tween_method(_set_progress, 0.0, 1.0, 0.28).set_ease(Tween.EASE_OUT)
	tween.chain().tween_callback(queue_free)

func _set_progress(value: float) -> void:
	_progress = value
	queue_redraw()

func _draw() -> void:
	var current_radius: float = _radius * (0.3 + 0.7 * _progress)
	var alpha: float = _color.a * (1.0 - _progress)
	draw_arc(Vector2.ZERO, current_radius, 0.0, TAU, 48, Color(_color.r, _color.g, _color.b, alpha), 6.0, true)
