extends Node2D
## Small floating health bar + number, drawn above whatever CombatActor this
## is a child of. Procedurally drawn (draw_rect), matching how the rest of
## the project's placeholder visuals work - no texture assets needed.

@export var bar_width := 70.0
@export var bar_height := 10.0
@export var offset_y := -48.0

@onready var label: Label = $Label

var _target: CombatActor

func _ready() -> void:
	_target = get_parent() as CombatActor
	position = Vector2(0, offset_y)

func _process(_delta: float) -> void:
	if _target == null or not is_instance_valid(_target):
		visible = false
		return
	label.text = "%d/%d" % [int(ceil(_target.get_health())), int(_target.max_health)]
	queue_redraw()

func _draw() -> void:
	if _target == null:
		return
	var max_health: float = maxf(_target.max_health, 1.0)
	var fraction: float = clampf(_target.get_health() / max_health, 0.0, 1.0)

	var half_width := bar_width * 0.5
	var half_height := bar_height * 0.5
	var bg_rect := Rect2(-half_width, -half_height, bar_width, bar_height)
	draw_rect(bg_rect, Color(0.0, 0.0, 0.0, 0.6))

	var fill_color := Color(0.3, 0.85, 0.35) if fraction > 0.3 else Color(0.9, 0.3, 0.25)
	draw_rect(Rect2(-half_width, -half_height, bar_width * fraction, bar_height), fill_color)
	draw_rect(bg_rect, Color(1.0, 1.0, 1.0, 0.6), false, 1.5)
