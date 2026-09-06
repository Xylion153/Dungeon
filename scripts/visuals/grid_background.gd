extends Node2D
## Floor grid for the test arena. Gives movement and dashes a readable frame
## of reference, which flat colour does not.

@export var cell := 120.0
@export var extent := Vector2(3600, 2600)
@export var background_color := Color(0.085, 0.095, 0.09)
@export var line_color := Color(1, 1, 1, 0.05)
@export var major_line_color := Color(1, 1, 1, 0.1)

func _draw() -> void:
	var half: Vector2 = extent * 0.5
	draw_rect(Rect2(-half, extent), background_color)

	var index := 0
	var x: float = -half.x
	while x <= half.x:
		draw_line(Vector2(x, -half.y), Vector2(x, half.y), major_line_color if index % 5 == 0 else line_color, 2.0)
		x += cell
		index += 1

	index = 0
	var y: float = -half.y
	while y <= half.y:
		draw_line(Vector2(-half.x, y), Vector2(half.x, y), major_line_color if index % 5 == 0 else line_color, 2.0)
		y += cell
		index += 1
