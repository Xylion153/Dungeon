extends Node
## Rolls world loot drops on every kill (EventBus.enemy_killed already
## fires - no new combat wiring needed). Independent per-type rolls, so a
## single kill can drop multiple pickups, matching typical ARPG loot feel.

const LootPickupScene := preload("res://scenes/combat/LootPickup.tscn")

const REGULAR_RATES := {
	"credits": {"chance": 0.9, "min": 5, "max": 15},
	"health": {"chance": 0.12, "min": 15, "max": 25},
	"mana": {"chance": 0.12, "min": 10, "max": 20},
	"gear": {"chance": 0.08},
}
const BOSS_RATES := {
	"credits": {"chance": 1.0, "min": 80, "max": 150},
	"health": {"chance": 0.4, "min": 15, "max": 25},
	"mana": {"chance": 0.4, "min": 10, "max": 20},
	"gear": {"chance": 1.0},
}

func _ready() -> void:
	EventBus.enemy_killed.connect(_on_enemy_killed)

func _on_enemy_killed(_attacker: Node, enemy: Node, _killing_blow_damage: float) -> void:
	var enemy_2d := enemy as Node2D
	if enemy_2d == null:
		return
	var position: Vector2 = enemy_2d.global_position
	var rates: Dictionary = BOSS_RATES if enemy.is_in_group("boss") else REGULAR_RATES

	if randf() < rates["credits"]["chance"]:
		var amount := randi_range(rates["credits"]["min"], rates["credits"]["max"])
		_spawn(position, func(p): p.setup_credits(amount))

	if randf() < rates["health"]["chance"]:
		var amount := randf_range(rates["health"]["min"], rates["health"]["max"])
		_spawn(position, func(p): p.setup_health(amount))

	if randf() < rates["mana"]["chance"]:
		var amount := randf_range(rates["mana"]["min"], rates["mana"]["max"])
		_spawn(position, func(p): p.setup_mana(amount))

	if randf() < rates["gear"]["chance"]:
		var piece := GearRoller.roll_piece()
		_spawn(position, func(p): p.setup_gear(piece))

func _spawn(position: Vector2, configure: Callable) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.current_scene == null:
		return
	var pickup := LootPickupScene.instantiate()
	tree.current_scene.add_child(pickup)
	# Scatter slightly so multiple simultaneous drops don't perfectly overlap.
	pickup.global_position = position + Vector2(randf_range(-20.0, 20.0), randf_range(-20.0, 20.0))
	configure.call(pickup)
