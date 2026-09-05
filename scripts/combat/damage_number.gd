extends Node2D

@onready var label: Label = $Label

func setup(amount: float, is_crit: bool) -> void:
	label.text = str(int(round(amount)))
	if is_crit:
		label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
		label.add_theme_font_size_override("font_size", 28)
	else:
		label.add_theme_color_override("font_color", Color.WHITE)
		label.add_theme_font_size_override("font_size", 18)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "position:y", position.y - 40.0, 0.6).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, 0.6).set_delay(0.2)
	tween.chain().tween_callback(queue_free)
