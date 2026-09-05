extends Node
## Shared "juice" system: hitstop, screen shake, knockback. Every magnitude
## here is a runtime-tunable knob (see FeelKnobsPanel) rather than a
## hardcoded constant, since these values are much faster to dial in by
## feel than by guessing numbers.

@export var hitstop_normal := 0.03
@export var hitstop_crit := 0.08
@export var shake_normal := 4.0
@export var shake_crit := 9.0
@export var shake_kill := 12.0
@export var knockback_multiplier := 1.0

var _shake_camera: Camera2D = null
var _shake_strength := 0.0
var _shake_time := 0.0
var _hitstop_timer := 0.0

func register_camera(camera: Camera2D) -> void:
	_shake_camera = camera

func apply_hitstop(strength: float = -1.0) -> void:
	var duration: float = strength if strength >= 0.0 else hitstop_normal
	_hitstop_timer = max(_hitstop_timer, duration)
	Engine.time_scale = 0.05

func apply_shake(strength: float) -> void:
	_shake_strength = max(_shake_strength, strength)
	_shake_time = max(_shake_time, 0.15)

func apply_knockback(target: Node, direction: Vector2, strength: float) -> void:
	if target.has_method("apply_knockback"):
		var safe_direction := direction
		if safe_direction.length() < 0.01:
			safe_direction = Vector2.DOWN
		target.apply_knockback(safe_direction.normalized() * strength * knockback_multiplier)

func _process(delta: float) -> void:
	var real_delta := delta / Engine.time_scale

	if _hitstop_timer > 0.0:
		_hitstop_timer -= real_delta
		if _hitstop_timer <= 0.0:
			Engine.time_scale = 1.0

	if _shake_time > 0.0:
		_shake_time -= real_delta
		if _shake_camera:
			_shake_camera.offset = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * _shake_strength
		if _shake_time <= 0.0:
			_shake_strength = 0.0
			if _shake_camera:
				_shake_camera.offset = Vector2.ZERO
