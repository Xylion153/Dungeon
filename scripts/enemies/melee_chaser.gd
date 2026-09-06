extends EnemyBase
## Reference "melee chaser" archetype (brief section 6.1): walks straight at
## the player, telegraphs briefly before its contact attack lands.

@export var contact_damage := 8.0
@export var attack_range := 40.0
@export var attack_cooldown := 1.0

var _attack_timer := 0.0

func scale_difficulty(multiplier: float) -> void:
	contact_damage *= multiplier

func _update_behavior(delta: float) -> void:
	if _attack_timer > 0.0:
		_attack_timer -= delta

	var to_player: Vector2 = _player.global_position - global_position
	var distance := to_player.length()

	if distance <= attack_range and _attack_timer <= 0.0:
		_attack_timer = attack_cooldown
		start_telegraph()
		return

	if distance > attack_range * 0.8:
		velocity = to_player.normalized() * effective_move_speed()
	else:
		velocity = Vector2.ZERO

func _on_telegraph_finished() -> void:
	if _player == null or not is_instance_valid(_player):
		return
	var distance := global_position.distance_to(_player.global_position)
	if distance > attack_range * 1.3:
		return # player escaped the telegraph
	DamageResolver.resolve_hit(self, _player, {
		"damage": contact_damage,
		"knockback": 220.0,
	})
