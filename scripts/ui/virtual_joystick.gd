extends Control
## Bottom-left drag joystick: outputs a Vector2 in [-1,1] per axis, snaps
## back to center on release.

signal vector_changed(value: Vector2)

@export var max_distance := 60.0

@onready var base: Control = $Base
@onready var knob: Control = $Base/Knob

var _touch_index := -1
var _base_center := Vector2.ZERO

func _ready() -> void:
	_base_center = base.size * 0.5
	_reset_knob()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			_touch_index = event.index
			_update_knob(base.get_local_mouse_position())
		elif event.index == _touch_index:
			_touch_index = -1
			_reset_knob()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_touch_index = 0
			_update_knob(base.get_local_mouse_position())
		else:
			_touch_index = -1
			_reset_knob()
	elif event is InputEventScreenDrag:
		if event.index == _touch_index:
			_update_knob(base.get_local_mouse_position())
	elif event is InputEventMouseMotion:
		if _touch_index == 0:
			_update_knob(base.get_local_mouse_position())

func _update_knob(local_pos: Vector2) -> void:
	var offset: Vector2 = local_pos - _base_center
	if offset.length() > max_distance:
		offset = offset.normalized() * max_distance
	knob.position = _base_center + offset - knob.size * 0.5
	vector_changed.emit(offset / max_distance)

func _reset_knob() -> void:
	knob.position = _base_center - knob.size * 0.5
	vector_changed.emit(Vector2.ZERO)
