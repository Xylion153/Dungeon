extends Node2D
## Sweeping arc VFX for a melee swing. Drawn to match the weapon step's own
## arc and range, so the visual and the actual hit region always agree — and
## so a whiffed swing still reads as a swing.

var arc_radians := deg_to_rad(100.0)
var reach := 60.0
var color := Color(1.0, 0.97, 0.85, 0.9)

var _progress := 0.0

func setup(arc_degrees: float, range_px: float) -> void:
	arc_radians = deg_to_rad(arc_degrees)
	reach = range_px

func _ready() -> void:
	var tween := create_tween()
	tween.tween_method(_set_progress, 0.0, 1.0, 0.16).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.16).set_delay(0.05)
	tween.chain().tween_callback(queue_free)

func _set_progress(value: float) -> void:
	_progress = value
	queue_redraw()

func _draw() -> void:
	# A bright band sweeping from one edge of the arc to the other.
	var band: float = arc_radians * 0.45
	var start: float = -arc_radians * 0.5 - band + (arc_radians + band) * _progress
	var inner: float = reach * 0.4
	var outer: float = reach
	var steps := 16

	var points := PackedVector2Array()
	for i in range(steps + 1):
		var angle: float = start + band * (float(i) / steps)
		points.append(Vector2(cos(angle), sin(angle)) * outer)
	for i in range(steps, -1, -1):
		var angle: float = start + band * (float(i) / steps)
		points.append(Vector2(cos(angle), sin(angle)) * inner)

	draw_colored_polygon(points, color)
