extends Control
## Reusable Skill/Attack/Dash button.
##
## Input is handled here rather than by the inner Button node. Godot's Button
## only responds to InputEventMouseButton and ignores raw InputEventScreenTouch,
## so on a phone the tap landed on the button and was silently dropped. This
## handles touch and mouse directly, and fires on PRESS rather than release,
## which is what an action game wants.
##
## CooldownFill is a textureless TextureProgressBar left ready for a real
## radial-fill texture; it renders nothing until then.

signal pressed_action

@export var disable_while_on_cooldown := true

@onready var button: Button = $Button
@onready var cooldown_fill: TextureProgressBar = $CooldownFill
@onready var cooldown_label: Label = $CooldownLabel

var _cooldown_duration := 0.0
var _cooldown_remaining := 0.0
var _touch_index := -1
var _mouse_held := false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.focus_mode = Control.FOCUS_NONE
	cooldown_label.visible = false

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and _touch_index == -1:
			_touch_index = event.index
			_press()
		elif not event.pressed and event.index == _touch_index:
			_touch_index = -1
			_release()
		accept_event()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		# Touch also arrives as an emulated mouse event; ignore the duplicate
		# while a real touch owns the button.
		if _touch_index == -1:
			if event.pressed and not _mouse_held:
				_mouse_held = true
				_press()
			elif not event.pressed and _mouse_held:
				_mouse_held = false
				_release()
		accept_event()

func _notification(what: int) -> void:
	# Insurance against a release that never arrives (app backgrounded, touch
	# cancelled), which would otherwise leave the button stuck held.
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_touch_index = -1
		_mouse_held = false
		_release()

func _press() -> void:
	button.set_pressed_no_signal(true)
	if not (disable_while_on_cooldown and _cooldown_remaining > 0.0):
		pressed_action.emit()

func _release() -> void:
	button.set_pressed_no_signal(false)

func _process(delta: float) -> void:
	if _cooldown_remaining <= 0.0:
		return

	_cooldown_remaining = maxf(_cooldown_remaining - delta, 0.0)
	var fraction: float = _cooldown_remaining / _cooldown_duration if _cooldown_duration > 0.0 else 0.0
	cooldown_fill.value = fraction * cooldown_fill.max_value

	if _cooldown_remaining > 0.0:
		modulate.a = lerpf(1.0, 0.6, fraction)
		cooldown_label.text = "%.1f" % _cooldown_remaining
		cooldown_label.visible = true
	else:
		modulate.a = 1.0
		cooldown_label.visible = false
		cooldown_fill.value = 0.0

func start_cooldown(duration: float) -> void:
	_cooldown_duration = maxf(duration, 0.001)
	_cooldown_remaining = _cooldown_duration

func set_label(text: String) -> void:
	button.text = text
