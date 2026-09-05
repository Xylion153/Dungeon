extends CanvasLayer
## Dev-only live-tunable panel for CombatFeel magnitudes. The brief calls
## this out as genuinely worth keeping during development, not just a
## nice-to-have, since these values are much faster to dial in by feel than
## by guessing numbers. Toggle with F1.

@onready var container: VBoxContainer = $Panel/VBoxContainer

func _ready() -> void:
	visible = OS.is_debug_build()
	_add_slider("Hitstop (normal)", 0.0, 0.2, CombatFeel.hitstop_normal, func(v): CombatFeel.hitstop_normal = v)
	_add_slider("Hitstop (crit)", 0.0, 0.3, CombatFeel.hitstop_crit, func(v): CombatFeel.hitstop_crit = v)
	_add_slider("Shake (normal)", 0.0, 20.0, CombatFeel.shake_normal, func(v): CombatFeel.shake_normal = v)
	_add_slider("Shake (crit)", 0.0, 30.0, CombatFeel.shake_crit, func(v): CombatFeel.shake_crit = v)
	_add_slider("Shake (kill)", 0.0, 30.0, CombatFeel.shake_kill, func(v): CombatFeel.shake_kill = v)
	_add_slider("Knockback mult.", 0.0, 3.0, CombatFeel.knockback_multiplier, func(v): CombatFeel.knockback_multiplier = v)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F1:
		visible = not visible

func _add_slider(label_text: String, min_v: float, max_v: float, initial: float, on_change: Callable) -> void:
	var label := Label.new()
	label.text = label_text
	container.add_child(label)

	var slider := HSlider.new()
	slider.min_value = min_v
	slider.max_value = max_v
	slider.step = (max_v - min_v) / 100.0
	slider.value = initial
	slider.value_changed.connect(on_change)
	container.add_child(slider)
