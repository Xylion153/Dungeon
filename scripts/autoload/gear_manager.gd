extends Node
## Tracks equipped gear, aggregates stat modifiers for Player, and manages
## the 4-piece procs as EventBus subscriptions - connected the instant a set
## crosses 4 pieces, disconnected the instant it drops below, so no effect
## can outlive its gear (brief section 9 / the original architecture intent
## for this autoload, unexercised until now).

signal gear_changed

const SLOT_COUNT := 4 # GearPieceData.Slot has 4 values
const AEGISWORN_KNOCKBACK := 200.0
const AEGISWORN_RADIUS := 120.0
const EMBERWAKE_BURN_FRACTION := 0.4
const EMBERWAKE_TICKS := 4
const EMBERWAKE_TICK_INTERVAL := 1.0
const STORMREND_RADIUS := 300.0
const STORMREND_DAMAGE_FRACTION := 0.5
const VOIDSTEP_PIERCE_DURATION := 2.0

var equipped_pieces: Array = [null, null, null, null]
var _resolving_stormrend := false

var _active_four_piece_sets: Dictionary = {} # set_id -> true, only while connected

func equip(piece: GearPieceData) -> void:
	equipped_pieces[piece.slot] = piece
	_refresh()

func unequip(slot: int) -> void:
	equipped_pieces[slot] = null
	_refresh()

func get_all_modifiers() -> Array[StatModifierData]:
	var modifiers: Array[StatModifierData] = []
	for piece in equipped_pieces:
		if piece == null:
			continue
		if piece.main_stat:
			modifiers.append(piece.main_stat)
		modifiers.append_array(piece.sub_stats)

	for set_id in _set_counts().keys():
		if _set_counts()[set_id] >= 2:
			var set_data := _find_set(set_id)
			if set_data:
				modifiers.append_array(set_data.two_piece_bonus)
	return modifiers

func _set_counts() -> Dictionary:
	var counts: Dictionary = {}
	for piece in equipped_pieces:
		if piece == null or piece.set_id == "":
			continue
		counts[piece.set_id] = counts.get(piece.set_id, 0) + 1
	return counts

func _find_set(set_id: String) -> GearSetData:
	for set_data in DataFolder.list_resources("res://data/gear_sets"):
		if set_data.set_id == set_id:
			return set_data
	return null

func _refresh() -> void:
	var counts := _set_counts()
	var should_be_active: Dictionary = {}
	for set_id in counts.keys():
		if counts[set_id] >= 4:
			should_be_active[set_id] = true

	for set_id in should_be_active.keys():
		if not _active_four_piece_sets.has(set_id):
			_connect_proc(set_id)
			_active_four_piece_sets[set_id] = true

	for set_id in _active_four_piece_sets.keys().duplicate():
		if not should_be_active.has(set_id):
			_disconnect_proc(set_id)
			_active_four_piece_sets.erase(set_id)

	gear_changed.emit()

func _connect_proc(set_id: String) -> void:
	match set_id:
		"emberwake":
			EventBus.crit_landed.connect(_on_emberwake_crit)
		"stormrend":
			EventBus.enemy_killed.connect(_on_stormrend_kill)
		"aegisworn":
			EventBus.dash_started.connect(_on_aegisworn_dash)
		"voidstep":
			EventBus.dash_started.connect(_on_voidstep_dash)

func _disconnect_proc(set_id: String) -> void:
	match set_id:
		"emberwake":
			EventBus.crit_landed.disconnect(_on_emberwake_crit)
		"stormrend":
			EventBus.enemy_killed.disconnect(_on_stormrend_kill)
		"aegisworn":
			EventBus.dash_started.disconnect(_on_aegisworn_dash)
		"voidstep":
			EventBus.dash_started.disconnect(_on_voidstep_dash)

func _on_emberwake_crit(_attacker: Node, target: Node, damage: float) -> void:
	if target.has_method("apply_burn"):
		var total := damage * EMBERWAKE_BURN_FRACTION
		target.apply_burn(total / EMBERWAKE_TICKS, EMBERWAKE_TICK_INTERVAL, EMBERWAKE_TICKS)

func _on_stormrend_kill(attacker: Node, enemy: Node, killing_blow_damage: float) -> void:
	# Reentrancy guard: the bolt below can itself kill something, which fires
	# enemy_killed again and would otherwise re-enter this exact function -
	# an unbounded chain that both crashes (stack overflow, caught in
	# testing) and would be absurd design (one kill wiping an entire wave).
	# The chain is capped at one bolt per original kill, not one per corpse.
	if _resolving_stormrend or not is_instance_valid(enemy):
		return
	var enemy_2d := enemy as Node2D
	if enemy_2d == null:
		return
	_resolving_stormrend = true
	var space_state: PhysicsDirectSpaceState2D = enemy_2d.get_world_2d().direct_space_state
	var query := PhysicsShapeQueryParameters2D.new()
	var shape := CircleShape2D.new()
	shape.radius = STORMREND_RADIUS
	query.shape = shape
	query.transform = Transform2D(0, enemy_2d.global_position)
	query.collision_mask = PhysicsLayers.ENEMY
	query.collide_with_bodies = true
	query.collide_with_areas = false

	var nearest: Node = null
	var nearest_dist := INF
	for result in space_state.intersect_shape(query, 16):
		var body = result.collider
		if body == enemy or not (body is CombatActor):
			continue
		var dist: float = enemy_2d.global_position.distance_to(body.global_position)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest = body
	if nearest:
		DamageResolver.resolve_hit(attacker, nearest, {
			"damage": killing_blow_damage * STORMREND_DAMAGE_FRACTION,
			"knockback": 60.0,
		})
	_resolving_stormrend = false

func _on_aegisworn_dash(actor: Node) -> void:
	var combat_actor := actor as CombatActor
	if combat_actor == null:
		return
	var space_state: PhysicsDirectSpaceState2D = combat_actor.get_world_2d().direct_space_state
	var query := PhysicsShapeQueryParameters2D.new()
	var shape := CircleShape2D.new()
	shape.radius = AEGISWORN_RADIUS
	query.shape = shape
	query.transform = Transform2D(0, combat_actor.global_position)
	query.collision_mask = PhysicsLayers.ENEMY
	query.collide_with_bodies = true
	query.collide_with_areas = false

	var damage: float = combat_actor.max_health * 0.1
	for result in space_state.intersect_shape(query, 16):
		var body = result.collider
		if body is CombatActor:
			DamageResolver.resolve_hit(combat_actor, body, {"damage": damage, "knockback": AEGISWORN_KNOCKBACK})

func _on_voidstep_dash(actor: Node) -> void:
	if actor.has_method("grant_temporary_pierce"):
		actor.grant_temporary_pierce(VOIDSTEP_PIERCE_DURATION)
