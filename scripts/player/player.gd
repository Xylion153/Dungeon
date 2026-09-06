class_name Player
extends CombatActor

@export var move_speed := 260.0
@export var dash_speed := 700.0
@export var dash_duration := 0.18
@export var dash_cooldown := 0.9

const SlashEffectScene := preload("res://scenes/combat/SlashEffect.tscn")

@onready var player_input: PlayerInput = $PlayerInput
@onready var player_combat: PlayerCombat = $PlayerCombat
@onready var sprite: ActorShape = $Shape
@onready var weapon_pivot: Node2D = $WeaponPivot
@onready var weapon_visual: WeaponVisual = $WeaponPivot/WeaponVisual
@onready var camera: Camera2D = $Camera2D

var stat_sheet := StatSheet.new()
var facing_direction := Vector2.DOWN

var _is_dashing := false
var _dash_timer := 0.0
var _dash_cooldown_timer := 0.0
var _dash_direction := Vector2.ZERO

func _ready() -> void:
	super._ready()
	add_to_group("player")
	collision_layer = PhysicsLayers.PLAYER
	collision_mask = PhysicsLayers.WORLD

	stat_sheet.set_base("move_speed", move_speed)
	stat_sheet.set_base("crit_chance", 0.05)
	stat_sheet.set_base("crit_damage", 1.5)

	player_combat.setup(self, GameState.equipped_weapon)
	player_combat.step_started.connect(_on_step_started)
	weapon_visual.visible = GameState.equipped_weapon.kind == WeaponData.Kind.MELEE

	camera.make_current()
	CombatFeel.register_camera(camera)

func _on_step_started(index: int, step: WeaponComboStepData) -> void:
	var steps: Array[WeaponComboStepData] = GameState.equipped_weapon.steps
	# Alternate the swing side per step so a combo doesn't look like one
	# motion repeated, and give the final step the heavier animation.
	weapon_visual.play_swing(step, index % 2 == 1, index == steps.size() - 1)

func _physics_process(delta: float) -> void:
	_handle_dash_input()

	if _dash_cooldown_timer > 0.0:
		_dash_cooldown_timer -= delta

	if _is_dashing:
		_dash_timer -= delta
		velocity = _dash_direction * dash_speed
		if _dash_timer <= 0.0:
			_end_dash()
	else:
		var move_vector: Vector2 = player_input.move_vector
		if move_vector.length() > 1.0:
			move_vector = move_vector.normalized()
		velocity = move_vector * stat_sheet.get_stat("move_speed") + consume_knockback(delta)
		if move_vector != Vector2.ZERO:
			facing_direction = move_vector

	if player_input.is_mouse_aiming() and not _is_dashing:
		var to_mouse: Vector2 = get_global_mouse_position() - global_position
		if to_mouse.length() > 4.0:
			facing_direction = to_mouse.normalized()

	move_and_slide()
	var facing_rotation := facing_direction.angle() + PI / 2.0
	sprite.rotation = facing_rotation
	weapon_pivot.rotation = facing_rotation

	if player_input.consume_attack():
		player_combat.request_attack()

func _handle_dash_input() -> void:
	if _is_dashing:
		return
	if player_input.consume_dash() and _dash_cooldown_timer <= 0.0:
		var dash_dir := player_input.move_vector
		if dash_dir == Vector2.ZERO:
			dash_dir = facing_direction
		_start_dash(dash_dir.normalized())

func _start_dash(direction: Vector2) -> void:
	if player_combat.can_dash_cancel():
		player_combat.cancel_into_dash()

	_is_dashing = true
	_dash_timer = dash_duration
	_dash_cooldown_timer = dash_cooldown
	_dash_direction = direction
	set_invulnerable(true)
	EventBus.dash_started.emit(self)

func _end_dash() -> void:
	_is_dashing = false
	set_invulnerable(false)
	EventBus.dash_ended.emit(self)

func perform_step_hit(step: WeaponComboStepData) -> void:
	if GameState.equipped_weapon.kind == WeaponData.Kind.MELEE:
		_do_melee_hit(step)
	else:
		_do_ranged_hit(step)

func _do_melee_hit(step: WeaponComboStepData) -> void:
	_spawn_slash(step)

	var space_state := get_world_2d().direct_space_state
	var query := PhysicsShapeQueryParameters2D.new()
	var shape := CircleShape2D.new()
	shape.radius = step.range
	query.shape = shape
	query.transform = Transform2D(0, global_position)
	query.collision_mask = PhysicsLayers.ENEMY
	query.collide_with_bodies = true
	query.collide_with_areas = false

	var half_arc := deg_to_rad(step.arc_degrees) * 0.5
	for result in space_state.intersect_shape(query, 16):
		var body: Node = result.collider
		if not (body is CombatActor):
			continue
		var to_target: Vector2 = body.global_position - global_position
		if to_target.length() <= 0.01 or abs(facing_direction.angle_to(to_target)) <= half_arc:
			_apply_step_damage(body, step)

func _spawn_slash(step: WeaponComboStepData) -> void:
	var parent: Node = get_tree().current_scene
	if parent == null:
		return # Mid scene-change; the swing itself still resolves.
	var slash := SlashEffectScene.instantiate()
	slash.setup(step.arc_degrees, step.range)
	parent.add_child(slash)
	slash.global_position = global_position
	slash.rotation = facing_direction.angle()

func _do_ranged_hit(_step: WeaponComboStepData) -> void:
	pass # No ranged weapon is wired up in this pass; Gun/Wand arrive as data + this branch later.

func _apply_step_damage(target: Node, step: WeaponComboStepData) -> void:
	var params := {
		"damage": step.damage,
		"knockback": step.knockback,
		"crit_chance": stat_sheet.get_stat("crit_chance"),
		"crit_multiplier": stat_sheet.get_stat("crit_damage"),
	}
	if step.hitstop >= 0.0:
		params["hitstop"] = step.hitstop
	if step.shake >= 0.0:
		params["shake"] = step.shake
	DamageResolver.resolve_hit(self, target, params)
