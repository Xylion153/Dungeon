extends CanvasLayer
## Wires the touch controls to whichever Player is in the scene. Self-binds
## on ready rather than requiring the Arena to orchestrate it.

@onready var joystick: Control = $VirtualJoystick
@onready var attack_button: Control = $AttackButton
@onready var skill_button: Control = $SkillButton
@onready var dash_button: Control = $DashButton
@onready var wave_label: Label = $WaveLabel
@onready var level_label: Label = $LevelLabel
@onready var mana_label: Label = $ManaLabel

var _player: Node = null

func _ready() -> void:
	call_deferred("_bind_player")
	EventBus.dash_started.connect(_on_dash_started)
	EventBus.skill_cast.connect(_on_skill_cast)
	EventBus.wave_started.connect(_on_wave_started)
	SaveManager.leveled_up.connect(_on_leveled_up)

	if GameState.current_class:
		var progress := SaveManager.get_class_progress(GameState.current_class.id)
		level_label.text = "Lv. %d" % progress["level"]

func _process(_delta: float) -> void:
	# Mana regenerates continuously, so this is polled rather than
	# event-driven - there's no natural "mana changed" signal to hook.
	if _player and is_instance_valid(_player):
		mana_label.text = "Mana: %d/%d" % [int(_player.mana), int(_player.max_mana)]

func _bind_player() -> void:
	_player = get_tree().get_first_node_in_group("player")
	if _player == null:
		return
	joystick.vector_changed.connect(_player.player_input.set_joystick_vector)
	attack_button.pressed_action.connect(_player.player_input.request_attack)
	skill_button.pressed_action.connect(_player.player_input.request_skill)
	dash_button.pressed_action.connect(_player.player_input.request_dash)
	if GameState.equipped_weapon:
		attack_button.set_label(GameState.equipped_weapon.weapon_name)

func _on_leveled_up(class_id: String, new_level: int) -> void:
	if GameState.current_class and class_id == GameState.current_class.id:
		level_label.text = "Lv. %d" % new_level

func _on_dash_started(actor: Node) -> void:
	if actor == _player:
		dash_button.start_cooldown(_player.dash_cooldown)

func _on_skill_cast(actor: Node, cooldown: float) -> void:
	if actor == _player:
		skill_button.start_cooldown(cooldown)

func _on_wave_started(wave_number: int) -> void:
	wave_label.text = "Wave %d" % wave_number
