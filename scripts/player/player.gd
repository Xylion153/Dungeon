class_name Player
extends CombatActor

@export var move_speed := 260.0
@export var dash_speed := 700.0
@export var dash_duration := 0.18
@export var dash_cooldown := 0.9

const SlashEffectScene := preload("res://scenes/combat/SlashEffect.tscn")
const ProjectileScene := preload("res://scenes/combat/Projectile.tscn")
const AoeBurstEffectScene := preload("res://scenes/combat/AoeBurstEffect.tscn")

@onready var player_input: PlayerInput = $PlayerInput
@onready var player_combat: PlayerCombat = $PlayerCombat
@onready var sprite: AnimatedSprite2D = $Shape
@onready var weapon_pivot: Node2D = $WeaponPivot
@onready var weapon_visual: WeaponVisual = $WeaponPivot/WeaponVisual
@onready var camera: Camera2D = $Camera2D

var stat_sheet := StatSheet.new()
var facing_direction := Vector2.DOWN

var _is_dashing := false
var _dash_timer := 0.0
var _dash_cooldown_timer := 0.0
var _dash_direction := Vector2.ZERO
var _skill_cooldown_timer := 0.0
var _skill_invuln_timer := 0.0
var _pierce_timer := 0.0
var _base_max_health := 0.0
var mana := 0.0
var max_mana := 0.0

func _ready() -> void:
	super._ready()
	add_to_group("player")
	collision_layer = PhysicsLayers.PLAYER
	collision_mask = PhysicsLayers.WORLD

	_base_max_health = max_health
	stat_sheet.set_base("move_speed", move_speed)
	stat_sheet.set_base("crit_chance", 0.05)
	stat_sheet.set_base("crit_damage", 1.5)
	stat_sheet.set_base("max_health", _base_max_health)
	stat_sheet.set_base("damage_multiplier", 1.0)
	stat_sheet.set_base("attack_speed_multiplier", 1.0)
	stat_sheet.set_base("max_mana", 50.0)
	stat_sheet.set_base("mana_regen_per_second", 2.0)
	_refresh_stats() # first call: old_max == max_health, so this lands at full health/mana

	GearManager.gear_changed.connect(_refresh_stats)
	player_combat.setup(self, GameState.equipped_weapon)
	player_combat.step_started.connect(_on_step_started)
	# The real character sprite already shows a held sword in every frame, so
	# the procedural floating-blade visual would be redundant. It stays wired
	# up (attack animation frames aren't ready yet) for a possible future
	# weapon that needs its own held-weapon visual.
	weapon_visual.visible = false

	camera.make_current()
	CombatFeel.register_camera(camera)

func _refresh_stats() -> void:
	var modifiers: Array[StatModifierData] = []
	if GameState.current_class:
		modifiers.append_array(GameState.current_class.stat_modifiers)
	modifiers.append_array(GearManager.get_all_modifiers())
	stat_sheet.set_modifiers(modifiers)

	# A mid-run gear change must not full-heal or overkill on a max-health
	# swing - shift current health by the delta instead of resetting it.
	var old_max := max_health
	max_health = stat_sheet.get_stat("max_health")
	if old_max > 0.0:
		health = clampf(health + (max_health - old_max), 1.0, max_health)

	var old_max_mana := max_mana
	max_mana = stat_sheet.get_stat("max_mana")
	mana = clampf(mana + (max_mana - old_max_mana), 0.0, max_mana)

func get_attack_speed_multiplier() -> float:
	return stat_sheet.get_stat("attack_speed_multiplier")

func grant_temporary_pierce(duration: float) -> void:
	_pierce_timer = maxf(_pierce_timer, duration)

func restore_mana(amount: float) -> void:
	mana = minf(mana + amount, max_mana)

func _on_step_started(index: int, step: WeaponComboStepData) -> void:
	_acquire_attack_facing(step)

	var steps: Array[WeaponComboStepData] = GameState.equipped_weapon.steps
	# Alternate the swing side per step so a combo doesn't look like one
	# motion repeated, and give the final step the heavier animation.
	weapon_visual.play_swing(step, index % 2 == 1, index == steps.size() - 1)

func _acquire_attack_facing(step: WeaponComboStepData) -> void:
	# On touch there's no equivalent of mouse-aim, so a player who just holds
	# still and lets an enemy approach (a completely natural way to play)
	# would otherwise swing at whatever direction they last moved in - which
	# usually isn't where the enemy actually is. Re-aim at the nearest enemy
	# each step, matching the brief: "faces the direction of movement or the
	# current attack target." Deliberate PC mouse-aim is left alone.
	if player_input.is_mouse_aiming():
		return

	var nearest := _find_nearest_enemy(step.range * 1.6)
	if nearest:
		facing_direction = (nearest.global_position - global_position).normalized()

func _find_nearest_enemy(search_radius: float) -> Node2D:
	var space_state := get_world_2d().direct_space_state
	var query := PhysicsShapeQueryParameters2D.new()
	var shape := CircleShape2D.new()
	shape.radius = search_radius
	query.shape = shape
	query.transform = Transform2D(0, global_position)
	query.collision_mask = PhysicsLayers.ENEMY
	query.collide_with_bodies = true
	query.collide_with_areas = false

	var nearest: Node2D = null
	var nearest_dist := INF
	for result in space_state.intersect_shape(query, 16):
		var body = result.collider
		if not (body is CombatActor):
			continue
		var dist: float = global_position.distance_to(body.global_position)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest = body
	return nearest

func _physics_process(delta: float) -> void:
	_handle_dash_input()

	if _dash_cooldown_timer > 0.0:
		_dash_cooldown_timer -= delta
	if _skill_cooldown_timer > 0.0:
		_skill_cooldown_timer -= delta
	if _skill_invuln_timer > 0.0:
		_skill_invuln_timer -= delta
	if _pierce_timer > 0.0:
		_pierce_timer -= delta
	set_invulnerable(_is_dashing or _skill_invuln_timer > 0.0)

	mana = minf(mana + stat_sheet.get_stat("mana_regen_per_second") * delta, max_mana)

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
	weapon_pivot.rotation = facing_direction.angle() + PI / 2.0
	_update_sprite_animation(player_input.move_vector)

	if player_input.consume_attack():
		player_combat.request_attack()

	_try_cast_skill()

func _update_sprite_animation(move_vector: Vector2) -> void:
	# Driven by actual movement input, not facing_direction - facing can be
	# aimed at a target (mouse-aim, or the attack auto-target) independently
	# of which way the player is walking, and the sprite should show the
	# latter. The sheet only has one idle pose (facing down), so idling while
	# last facing another direction just returns to that - a known
	# simplification until more idle directions exist.
	if move_vector == Vector2.ZERO:
		if sprite.animation != "idle":
			sprite.play("idle")
		return

	var anim_name: String
	if absf(move_vector.x) > absf(move_vector.y):
		anim_name = "walk_right" if move_vector.x > 0.0 else "walk_left"
	else:
		anim_name = "walk_down" if move_vector.y > 0.0 else "walk_up"

	if sprite.animation != anim_name:
		sprite.play(anim_name)

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
	EventBus.dash_started.emit(self)

func _end_dash() -> void:
	_is_dashing = false
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

func _do_ranged_hit(step: WeaponComboStepData) -> void:
	var parent: Node = get_tree().current_scene
	if parent == null:
		return

	var count: int = max(step.projectile_count, 1)
	var half_spread := deg_to_rad(step.spread_degrees) * 0.5
	for i in count:
		var t: float = 0.5 if count <= 1 else float(i) / float(count - 1)
		var angle_offset: float = lerp(-half_spread, half_spread, t) if count > 1 else 0.0
		var direction: Vector2 = facing_direction.rotated(angle_offset)

		var projectile := ProjectileScene.instantiate()
		parent.add_child(projectile)
		projectile.global_position = global_position
		projectile.setup({
			"direction": direction,
			"speed": step.projectile_speed,
			"radius": step.projectile_radius,
			"damage": step.damage * stat_sheet.get_stat("damage_multiplier"),
			"knockback": step.knockback,
			"pierce": step.pierce or _pierce_timer > 0.0,
			"splash_radius": step.splash_radius,
			"target_mask": PhysicsLayers.ENEMY,
			"crit_chance": stat_sheet.get_stat("crit_chance"),
			"crit_multiplier": stat_sheet.get_stat("crit_damage"),
			"color": Color(0.5, 0.85, 1.0) if step.splash_radius <= 0.0 else Color(0.75, 0.4, 1.0),
		}, self)

func _apply_step_damage(target: Node, step: WeaponComboStepData) -> void:
	var params := {
		"damage": step.damage * stat_sheet.get_stat("damage_multiplier"),
		"knockback": step.knockback,
		"crit_chance": stat_sheet.get_stat("crit_chance"),
		"crit_multiplier": stat_sheet.get_stat("crit_damage"),
	}
	if step.hitstop >= 0.0:
		params["hitstop"] = step.hitstop
	if step.shake >= 0.0:
		params["shake"] = step.shake
	DamageResolver.resolve_hit(self, target, params)

func _try_cast_skill() -> void:
	if not player_input.consume_skill():
		return
	var skill: SkillData = GameState.equipped_skill
	if skill == null or _skill_cooldown_timer > 0.0 or mana < skill.mana_cost:
		return

	_skill_cooldown_timer = skill.cooldown
	mana -= skill.mana_cost

	if skill.dash_distance > 0.0:
		global_position += facing_direction * skill.dash_distance

	if skill.self_invulnerable_duration > 0.0:
		_skill_invuln_timer = maxf(_skill_invuln_timer, skill.self_invulnerable_duration)

	if skill.damage > 0.0 and skill.radius > 0.0:
		_cast_aoe(global_position, skill)

	EventBus.skill_cast.emit(self, skill.cooldown)

func _cast_aoe(cast_position: Vector2, skill: SkillData) -> void:
	var parent: Node = get_tree().current_scene
	if parent != null:
		var burst := AoeBurstEffectScene.instantiate()
		parent.add_child(burst)
		burst.global_position = cast_position
		burst.setup(skill.radius, _skill_color(skill))

	var space_state := get_world_2d().direct_space_state
	var query := PhysicsShapeQueryParameters2D.new()
	var shape := CircleShape2D.new()
	shape.radius = skill.radius
	query.shape = shape
	query.transform = Transform2D(0, cast_position)
	query.collision_mask = PhysicsLayers.ENEMY
	query.collide_with_bodies = true
	query.collide_with_areas = false

	for result in space_state.intersect_shape(query, 16):
		var body = result.collider
		if not (body is CombatActor):
			continue
		DamageResolver.resolve_hit(self, body, {
			"damage": skill.damage * stat_sheet.get_stat("damage_multiplier"),
			"knockback": 140.0,
			"crit_chance": stat_sheet.get_stat("crit_chance"),
			"crit_multiplier": stat_sheet.get_stat("crit_damage"),
		})
		if skill.slow_duration > 0.0 and body.has_method("apply_slow"):
			body.apply_slow(skill.slow_multiplier, skill.slow_duration)

func _skill_color(skill: SkillData) -> Color:
	if skill.slow_duration > 0.0:
		return Color(0.5, 0.8, 1.0) # Frost Nova
	if skill.dash_distance > 0.0:
		return Color(0.75, 0.4, 1.0) # Blink Strike
	return Color(1.0, 0.6, 0.25) # Whirlwind
