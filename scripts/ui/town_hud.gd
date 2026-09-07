extends CanvasLayer
## Minimal Town HUD: movement joystick + a credits readout. No combat
## buttons - self-binds to the TownPlayer the same way hud.gd binds to
## Player, and polls credits each frame since there's no changed signal.

@onready var joystick: Control = $VirtualJoystick
@onready var credits_label: Label = $CreditsLabel

func _ready() -> void:
	call_deferred("_bind_player")

func _process(_delta: float) -> void:
	credits_label.text = "Credits: %d" % SaveManager.get_credits()

func _bind_player() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		return
	joystick.vector_changed.connect(player.player_input.set_joystick_vector)
