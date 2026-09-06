class_name PlayerInput
extends Node
## Unifies touch UI (VirtualJoystick/ActionButton signals) and a keyboard
## fallback for fast in-editor iteration. Both funnel into the same state
## so Player never needs to know which source drove it.

var move_vector := Vector2.ZERO
var attack_requested := false
var skill_requested := false
var dash_requested := false

var _keyboard_active := false

func _physics_process(_delta: float) -> void:
	var keyboard_vector := Vector2.ZERO
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		keyboard_vector.x -= 1
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		keyboard_vector.x += 1
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		keyboard_vector.y -= 1
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		keyboard_vector.y += 1

	if keyboard_vector != Vector2.ZERO:
		move_vector = keyboard_vector.normalized()
		_keyboard_active = true
	elif _keyboard_active:
		# All movement keys just released - stop, instead of drifting in the
		# last held direction. Only touches move_vector while keyboard was
		# the active source, so it never fights the joystick's own signal.
		move_vector = Vector2.ZERO
		_keyboard_active = false

	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		attack_requested = true
	if Input.is_key_pressed(KEY_K):
		skill_requested = true
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		dash_requested = true

func set_joystick_vector(value: Vector2) -> void:
	move_vector = value

func request_attack() -> void:
	attack_requested = true

func request_skill() -> void:
	skill_requested = true

func request_dash() -> void:
	dash_requested = true

func consume_attack() -> bool:
	var value := attack_requested
	attack_requested = false
	return value

func consume_skill() -> bool:
	var value := skill_requested
	skill_requested = false
	return value

func consume_dash() -> bool:
	var value := dash_requested
	dash_requested = false
	return value
