extends Node
## The single shared damage-resolution pipeline. Every damage source (melee
## swing, projectile, skill, gear-set proc) calls resolve_hit() so hit
## feedback (numbers, hitstop, shake, knockback, kill handling, crit rolls)
## stays consistent no matter what caused the damage.

const DamageNumberScene := preload("res://scenes/combat/DamageNumber.tscn")

func resolve_hit(attacker: Node, target: Node, params: Dictionary) -> void:
	if target == null or not is_instance_valid(target):
		return
	if target.has_method("is_invulnerable") and target.is_invulnerable():
		return

	var base_damage: float = params.get("damage", 0.0)
	var crit_chance: float = params.get("crit_chance", 0.0)
	var crit_mult: float = params.get("crit_multiplier", 1.5)
	var is_crit := randf() < crit_chance
	var final_damage := base_damage * (crit_mult if is_crit else 1.0)

	if target.has_method("take_damage"):
		target.take_damage(final_damage)

	_spawn_damage_number(target, final_damage, is_crit)

	var hitstop: float = params.get("hitstop", -1.0)
	CombatFeel.apply_hitstop(hitstop if hitstop >= 0.0 else (CombatFeel.hitstop_crit if is_crit else CombatFeel.hitstop_normal))

	var shake: float = params.get("shake", -1.0)
	CombatFeel.apply_shake(shake if shake >= 0.0 else (CombatFeel.shake_crit if is_crit else CombatFeel.shake_normal))

	var knockback: float = params.get("knockback", 0.0)
	if knockback > 0.0 and target is Node2D and attacker is Node2D:
		var direction: Vector2 = target.global_position - attacker.global_position
		CombatFeel.apply_knockback(target, direction, knockback)

	if target.has_method("flash_hit"):
		target.flash_hit()

	EventBus.damage_dealt.emit(attacker, target, final_damage, is_crit)
	if is_crit:
		EventBus.crit_landed.emit(attacker, target, final_damage)

	if target.has_method("get_health") and target.get_health() <= 0.0:
		CombatFeel.apply_shake(CombatFeel.shake_kill)
		EventBus.enemy_killed.emit(attacker, target)

func _spawn_damage_number(target: Node, amount: float, is_crit: bool) -> void:
	if not (target is Node2D) or not is_instance_valid(target):
		return
	var tree := target.get_tree()
	if tree == null or tree.current_scene == null:
		return
	var number := DamageNumberScene.instantiate()
	tree.current_scene.add_child(number)
	number.global_position = target.global_position + Vector2(0, -20)
	number.setup(amount, is_crit)
