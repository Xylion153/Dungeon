extends EnemyBase
## First boss test (brief's combat-basics finish line): a single large, tanky
## enemy cycling through 3 telegraphed attacks in a fixed order - melee slam,
## a radial projectile burst, and a telegraph-then-charge dash that deals
## contact damage at the end. A simple health-threshold enrage shortens
## cooldowns past 50% HP. Deliberately simple: this proves the "boss" slot
## in the combat loop rather than being a final boss design.

@export var contact_damage := 18.0
@export var melee_range := 100.0
@export var burst_projectile_count := 10
@export var burst_damage := 10.0
@export var burst_speed := 340.0
@export var charge_speed := 520.0
@export var charge_damage := 22.0
@export var attack_cooldown := 1.6
@export var enrage_health_fraction := 0.5
@export var enrage_cooldown_multiplier := 0.7

const ProjectileScene := preload("res://scenes/combat/Projectile.tscn")

enum Attack { MELEE, BURST, CHARGE }

var _attack_order: Array = [Attack.MELEE, Attack.BURST, Attack.CHARGE]
var _attack_index := 0
var _pending_attack: Attack = Attack.MELEE
var _attack_timer := 0.0
var _enraged := false
var _charging := false
var _charge_direction := Vector2.ZERO
var _charge_timer := 0.0

func _ready() -> void:
	super._ready()
	add_to_group("boss")
	_attack_timer = attack_cooldown

func scale_difficulty(multiplier: float) -> void:
	contact_damage *= multiplier
	burst_damage *= multiplier
	charge_damage *= multiplier

func _update_behavior(delta: float) -> void:
	if not _enraged and health <= max_health * enrage_health_fraction:
		_enraged = true

	if _charging:
		velocity = _charge_direction * charge_speed
		_charge_timer -= delta
		if _charge_timer <= 0.0:
			_end_charge()
		return

	_attack_timer -= delta
	var to_player: Vector2 = _player.global_position - global_position
	var distance := to_player.length()

	if distance > melee_range * 1.5:
		velocity = to_player.normalized() * effective_move_speed()
	else:
		velocity = Vector2.ZERO

	if _attack_timer <= 0.0:
		_attack_timer = attack_cooldown * (enrage_cooldown_multiplier if _enraged else 1.0)
		_begin_attack(_attack_order[_attack_index])
		_attack_index = (_attack_index + 1) % _attack_order.size()

func _begin_attack(kind: Attack) -> void:
	_pending_attack = kind
	match kind:
		Attack.MELEE:
			start_telegraph(0.4)
		Attack.BURST:
			start_telegraph(0.5)
		Attack.CHARGE:
			_charge_direction = (_player.global_position - global_position).normalized()
			start_telegraph(0.45)

func _on_telegraph_finished() -> void:
	match _pending_attack:
		Attack.MELEE:
			_do_melee()
		Attack.BURST:
			_do_burst()
		Attack.CHARGE:
			_begin_charge()

func _do_melee() -> void:
	if _player and is_instance_valid(_player) and global_position.distance_to(_player.global_position) <= melee_range * 1.3:
		DamageResolver.resolve_hit(self, _player, {"damage": contact_damage, "knockback": 260.0})

func _do_burst() -> void:
	var parent := get_tree().current_scene
	if parent == null:
		return
	for i in burst_projectile_count:
		var angle: float = TAU * float(i) / float(burst_projectile_count)
		var direction := Vector2(cos(angle), sin(angle))
		var projectile := ProjectileScene.instantiate()
		parent.add_child(projectile)
		projectile.global_position = global_position
		projectile.setup({
			"direction": direction,
			"speed": burst_speed,
			"radius": 8.0,
			"damage": burst_damage,
			"knockback": 80.0,
			"target_mask": PhysicsLayers.PLAYER,
			"color": Color(0.9, 0.2, 0.3),
		}, self)

func _begin_charge() -> void:
	_charging = true
	_charge_timer = 0.35

func _end_charge() -> void:
	_charging = false
	if _player and is_instance_valid(_player) and global_position.distance_to(_player.global_position) <= melee_range * 1.5:
		DamageResolver.resolve_hit(self, _player, {"damage": charge_damage, "knockback": 320.0})
