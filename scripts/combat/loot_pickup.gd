extends Area2D
## A world loot drop (credits/health/mana/gear) - sits in place, waits for
## the player to walk over it, applies its effect, then frees itself.
## Auto-despawns after MAX_LIFETIME if never collected, so a cleared arena
## doesn't accumulate forever-uncollected clutter.

enum Kind { CREDITS, HEALTH, MANA, GEAR, ARTIFACT, GEMS }

const PickupTextScene := preload("res://scenes/combat/PickupText.tscn")
const MAX_LIFETIME := 20.0
const RARITY_COLORS := [
	Color(0.85, 0.85, 0.85), # Common
	Color(0.35, 0.65, 1.0),  # Rare
	Color(0.75, 0.35, 0.95), # Epic
	Color(1.0, 0.75, 0.2),   # Mythic
]

var kind: Kind = Kind.CREDITS
var amount: float = 0.0
var gear_piece: GearPieceData
var artifact_piece: ArtifactPieceData

@onready var shape_visual: Polygon2D = $Visual
@onready var collision: CollisionShape2D = $CollisionShape2D

func setup_credits(value: int) -> void:
	kind = Kind.CREDITS
	amount = value
	_apply_visual(Color(1.0, 0.85, 0.2), _circle_polygon(10.0))

func setup_health(value: float) -> void:
	kind = Kind.HEALTH
	amount = value
	_apply_visual(Color(0.9, 0.25, 0.3), _cross_polygon(10.0))

func setup_mana(value: float) -> void:
	kind = Kind.MANA
	amount = value
	_apply_visual(Color(0.3, 0.55, 1.0), _circle_polygon(10.0))

func setup_gear(piece: GearPieceData) -> void:
	kind = Kind.GEAR
	gear_piece = piece
	_apply_visual(RARITY_COLORS[piece.rarity], _diamond_polygon(12.0))

func setup_artifact(piece: ArtifactPieceData) -> void:
	kind = Kind.ARTIFACT
	artifact_piece = piece
	_apply_visual(RARITY_COLORS[piece.rarity], _star_polygon(12.0, 5.0))

func setup_gems(value: int) -> void:
	kind = Kind.GEMS
	amount = value
	_apply_visual(Color(0.4, 0.85, 1.0), _star_polygon(10.0, 4.5))

func _apply_visual(color: Color, polygon: PackedVector2Array) -> void:
	shape_visual.color = color
	shape_visual.polygon = polygon

func _circle_polygon(radius: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in 10:
		var angle: float = TAU * i / 10.0
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	return points

func _cross_polygon(size: float) -> PackedVector2Array:
	var t := size * 0.35
	return PackedVector2Array([
		Vector2(-t, -size), Vector2(t, -size), Vector2(t, -t), Vector2(size, -t),
		Vector2(size, t), Vector2(t, t), Vector2(t, size), Vector2(-t, size),
		Vector2(-t, t), Vector2(-size, t), Vector2(-size, -t), Vector2(-t, -t),
	])

func _diamond_polygon(size: float) -> PackedVector2Array:
	return PackedVector2Array([Vector2(0, -size), Vector2(size, 0), Vector2(0, size), Vector2(-size, 0)])

func _star_polygon(outer_radius: float, inner_radius: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in 10:
		var angle: float = TAU * i / 10.0 - PI / 2.0
		var radius: float = outer_radius if i % 2 == 0 else inner_radius
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	return points

func _ready() -> void:
	collision_layer = 0
	collision_mask = PhysicsLayers.PLAYER
	monitoring = true
	body_entered.connect(_on_body_entered)
	get_tree().create_timer(MAX_LIFETIME).timeout.connect(_on_lifetime_expired)

	var tween := create_tween().set_loops()
	tween.tween_property(shape_visual, "position:y", -6.0, 0.6).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(shape_visual, "position:y", 0.0, 0.6).set_ease(Tween.EASE_IN_OUT)

func _on_lifetime_expired() -> void:
	if is_instance_valid(self):
		queue_free()

func _on_body_entered(body: Node) -> void:
	if not (body is Player):
		return
	_collect(body)
	queue_free()

func _collect(player: Node) -> void:
	match kind:
		Kind.CREDITS:
			SaveManager.add_credits(int(amount))
			_spawn_text("+%d Credits" % int(amount), Color(1.0, 0.85, 0.2))
		Kind.HEALTH:
			player.heal(amount)
			_spawn_text("+%d HP" % int(amount), Color(0.9, 0.3, 0.3))
		Kind.MANA:
			player.restore_mana(amount)
			_spawn_text("+%d MP" % int(amount), Color(0.3, 0.55, 1.0))
		Kind.GEAR:
			GameState.run_loot.append(gear_piece)
			_spawn_text(gear_piece.piece_name, RARITY_COLORS[gear_piece.rarity])
		Kind.ARTIFACT:
			GameState.run_artifact_loot.append(artifact_piece)
			_spawn_text(artifact_piece.piece_name, RARITY_COLORS[artifact_piece.rarity])
		Kind.GEMS:
			SaveManager.add_gems(int(amount))
			_spawn_text("+%d Gems" % int(amount), Color(0.4, 0.85, 1.0))

func _spawn_text(text: String, color: Color) -> void:
	var parent: Node = get_tree().current_scene
	if parent == null:
		return
	var popup := PickupTextScene.instantiate()
	parent.add_child(popup)
	popup.global_position = global_position
	popup.setup(text, color)
