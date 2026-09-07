class_name ArtifactPieceData
extends Resource
## One piece of the Artifacts equipment category (HSR Planar Ornament
## equivalent to Gear's Relics) - a slot, a rarity-scaled main stat, 1-3
## random sub-stats, and the set it belongs to. Structurally identical to
## GearPieceData by design, but kept as its own parallel type rather than a
## shared base class - see scripts/autoload/artifact_manager.gd's header.

enum Slot { AMULET, RING }
enum Rarity { COMMON, RARE, EPIC, MYTHIC }

@export var piece_name := ""
@export var slot: Slot = Slot.AMULET
@export var rarity: Rarity = Rarity.COMMON
@export var main_stat: StatModifierData
@export var sub_stats: Array[StatModifierData] = []
@export var set_id := ""

func to_dict() -> Dictionary:
	return {
		"piece_name": piece_name,
		"slot": slot,
		"rarity": rarity,
		"set_id": set_id,
		"main_stat": _modifier_to_dict(main_stat),
		"sub_stats": sub_stats.map(_modifier_to_dict),
	}

static func from_dict(data: Dictionary) -> ArtifactPieceData:
	var piece := ArtifactPieceData.new()
	piece.piece_name = data.get("piece_name", "")
	piece.slot = data.get("slot", Slot.AMULET) as Slot
	piece.rarity = data.get("rarity", Rarity.COMMON) as Rarity
	piece.set_id = data.get("set_id", "")
	piece.main_stat = _modifier_from_dict(data.get("main_stat", {}))
	var subs: Array[StatModifierData] = []
	for sub in data.get("sub_stats", []):
		subs.append(_modifier_from_dict(sub))
	piece.sub_stats = subs
	return piece

static func _modifier_to_dict(modifier: StatModifierData) -> Dictionary:
	if modifier == null:
		return {}
	return {
		"stat_name": modifier.stat_name,
		"flat_bonus": modifier.flat_bonus,
		"percent_bonus": modifier.percent_bonus,
	}

static func _modifier_from_dict(data: Dictionary) -> StatModifierData:
	var modifier := StatModifierData.new()
	modifier.stat_name = data.get("stat_name", "")
	modifier.flat_bonus = data.get("flat_bonus", 0.0)
	modifier.percent_bonus = data.get("percent_bonus", 0.0)
	return modifier
