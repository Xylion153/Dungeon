extends Control
## Reusable Skill/Attack/Dash button: dims while on cooldown and shows the
## remaining seconds. CooldownFill is a textureless TextureProgressBar left
## ready for a real radial-fill texture once art exists — it renders nothing
## until then, so this works fine as a placeholder today.

signal pressed_action

@export var disable_while_on_cooldown := true

@onready var button: Button = $Button
@onready var cooldown_fill: TextureProgressBar = $CooldownFill
@onready var cooldown_label: Label = $CooldownLabel

var _cooldown_duration := 0.0
var _cooldown_remaining := 0.0

func _ready() -> void:
	button.pressed.connect(_on_button_pressed)
	cooldown_label.visible = false

func _process(delta: float) -> void:
	if _cooldown_remaining <= 0.0:
		return
	_cooldown_remaining = max(_cooldown_remaining - delta, 0.0)
	var fraction := _cooldown_remaining / _cooldown_duration if _cooldown_duration > 0.0 else 0.0
	cooldown_fill.value = fraction * cooldown_fill.max_value
	modulate.a = lerp(1.0, 0.6, fraction)
	cooldown_label.text = "%.1f" % _cooldown_remaining
	cooldown_label.visible = true
	if disable_while_on_cooldown:
		button.disabled = true

	if _cooldown_remaining <= 0.0:
		modulate.a = 1.0
		cooldown_label.visible = false
		button.disabled = false

func start_cooldown(duration: float) -> void:
	_cooldown_duration = max(duration, 0.001)
	_cooldown_remaining = _cooldown_duration

func _on_button_pressed() -> void:
	pressed_action.emit()
