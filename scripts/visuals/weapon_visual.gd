class_name WeaponVisual
extends Node2D
## The held sword, drawn procedurally and swung by rotating around the
## player's centre. Swing timing is driven by the combo step's own windup /
## active / recovery durations, so the animation and the hit always agree:
## the blade starts its sweep on the exact frame the hit resolves.

@export var blade_length := 44.0
@export var blade_width := 8.0
@export var hilt_offset := 16.0
@export var rest_angle_degrees := 42.0

@export var blade_color := Color(0.82, 0.87, 0.95)
@export var edge_color := Color(1, 1, 1, 0.9)
@export var guard_color := Color(0.75, 0.6, 0.28)
@export var grip_color := Color(0.28, 0.2, 0.16)

var _swing_tween: Tween
var _rest_sign := 1.0

func _ready() -> void:
	rotation = deg_to_rad(rest_angle_degrees)

func _draw() -> void:
	var guard_y := -hilt_offset
	var tip_y := guard_y - blade_length
	var half := blade_width * 0.5

	# Grip below the guard.
	draw_line(Vector2(0, guard_y + 11.0), Vector2(0, guard_y), grip_color, 5.0)
	# Crossguard.
	draw_line(Vector2(-9.0, guard_y), Vector2(9.0, guard_y), guard_color, 4.0)

	# Tapered blade.
	draw_colored_polygon(PackedVector2Array([
		Vector2(-half, guard_y),
		Vector2(half, guard_y),
		Vector2(half * 0.5, tip_y + 8.0),
		Vector2(0, tip_y),
		Vector2(-half * 0.5, tip_y + 8.0),
	]), blade_color)
	# Edge highlight.
	draw_line(Vector2(0, guard_y), Vector2(0, tip_y + 4.0), edge_color, 1.5, true)

func play_swing(step: WeaponComboStepData, mirrored: bool, is_finisher: bool) -> void:
	if _swing_tween and _swing_tween.is_valid():
		_swing_tween.kill()

	_rest_sign = -1.0 if mirrored else 1.0
	var rest := deg_to_rad(rest_angle_degrees) * _rest_sign
	var pull_back := deg_to_rad(58.0 if is_finisher else 34.0) * _rest_sign
	var sweep := deg_to_rad(step.arc_degrees) * (1.05 if is_finisher else 0.9) * _rest_sign

	rotation = rest
	scale = Vector2.ONE

	_swing_tween = create_tween()
	_swing_tween.tween_property(self, "rotation", rest + pull_back, maxf(step.windup, 0.01)) \
		.set_ease(Tween.EASE_OUT)
	_swing_tween.tween_property(self, "rotation", rest - sweep, maxf(step.active, 0.01)) \
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	_swing_tween.tween_property(self, "rotation", rest, maxf(step.recovery, 0.01)) \
		.set_ease(Tween.EASE_OUT)

	if is_finisher:
		# Separate tween so the pop overlaps the swing rather than following it.
		var scale_tween := create_tween()
		scale_tween.tween_property(self, "scale", Vector2(1.2, 1.2), maxf(step.windup, 0.01))
		scale_tween.tween_property(self, "scale", Vector2.ONE, maxf(step.active + step.recovery, 0.01))
