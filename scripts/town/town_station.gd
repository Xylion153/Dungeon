extends Area2D
## A walk-in door in Town: overlap navigates to target_scene_path, matching
## the overlap-trigger pattern scripts/combat/loot_pickup.gd already uses.
## No visual of its own - Town's background art already shows each building
## and its signage, so this is purely an invisible trigger zone.

@export var target_scene_path: String
@export var station_label: String # editor-only identifier, not rendered

var _triggered := false

func _ready() -> void:
	collision_layer = 0
	collision_mask = PhysicsLayers.PLAYER
	monitoring = true
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if _triggered or not body.is_in_group("player"):
		return
	_triggered = true
	get_tree().change_scene_to_file(target_scene_path)
