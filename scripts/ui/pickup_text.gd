extends Node2D
## Floating text feedback for a loot pickup ("+15 Credits", "+Rare Chest").
## Same tween-and-free pattern as damage_number.gd, but takes a string and
## color directly instead of formatting a damage number.

@onready var label: Label = $Label

func setup(text: String, color: Color) -> void:
	label.text = text
	label.add_theme_color_override("font_color", color)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "position:y", position.y - 40.0, 0.7).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, 0.7).set_delay(0.3)
	tween.chain().tween_callback(queue_free)
