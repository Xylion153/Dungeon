extends CanvasLayer
## Wires the touch controls to whichever Player is in the scene. Self-binds
## on ready rather than requiring the Arena to orchestrate it.

@onready var joystick: Control = $VirtualJoystick
@onready var attack_button: Control = $AttackButton
@onready var skill_button: Control = $SkillButton
@onready var dash_button: Control = $DashButton

var _player: Node = null

func _ready() -> void:
	call_deferred("_bind_player")
	EventBus.dash_started.connect(_on_dash_started)

func _bind_player() -> void:
	_player = get_tree().get_first_node_in_group("player")
	if _player == null:
		return
	joystick.vector_changed.connect(_player.player_input.set_joystick_vector)
	attack_button.pressed_action.connect(_player.player_input.request_attack)
	skill_button.pressed_action.connect(_player.player_input.request_skill)
	dash_button.pressed_action.connect(_player.player_input.request_dash)
	attack_button.set_label(GameState.equipped_weapon.weapon_name)

func _on_dash_started(actor: Node) -> void:
	if actor == _player:
		dash_button.start_cooldown(_player.dash_cooldown)
