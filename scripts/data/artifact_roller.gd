class_name ArtifactRoller
extends RefCounted
## Procedural loot generation for Artifacts - same shape as GearRoller
## (scripts/data/gear_roller.gd), rolled at drop time rather than
## hand-authored.

const RARITY_WEIGHTS := [50, 30, 15, 5] # Common, Rare, Epic, Mythic
const RARITY_MULTIPLIERS := [1.0, 1.5, 2.0, 3.0]
const SUBSTAT_COUNTS := [1, 2, 3, 3]

const MAIN_STAT_BY_SLOT := {
	ArtifactPieceData.Slot.AMULET: "crit_damage",
	ArtifactPieceData.Slot.RING: "attack_speed_multiplier",
}

const PERCENT_STAT_BASE := {
	"max_health": 0.04,
	"damage_multiplier": 0.04,
	"move_speed": 0.04,
	"attack_speed_multiplier": 0.04,
}
const FLAT_STAT_BASE := {
	"crit_chance": 0.03,
	"crit_damage": 0.08,
}

const SUBSTAT_POOL := ["damage_multiplier", "max_health", "move_speed", "crit_chance", "crit_damage", "attack_speed_multiplier"]

## max_rarity: -1 (default) rolls the full weighted table; a Rarity value
## clamps the roll down to it afterward (e.g. the Shop's rarity-capped
## purchases) - a simple clamp, not a re-normalized weight table.
static func roll_piece(max_rarity: int = -1) -> ArtifactPieceData:
	var piece := ArtifactPieceData.new()
	piece.slot = _roll_slot()
	piece.rarity = _roll_rarity()
	if max_rarity >= 0:
		piece.rarity = mini(piece.rarity, max_rarity) as ArtifactPieceData.Rarity

	var sets: Array = DataFolder.list_resources("res://data/artifact_sets")
	var chosen_set: ArtifactSetData = sets[randi() % sets.size()] if not sets.is_empty() else null
	piece.set_id = chosen_set.set_id if chosen_set else ""

	var main_stat_name: String = MAIN_STAT_BY_SLOT[piece.slot]
	piece.main_stat = _roll_stat(main_stat_name, piece.rarity)

	var pool: Array = SUBSTAT_POOL.filter(func(s): return s != main_stat_name)
	pool.shuffle()
	var count: int = SUBSTAT_COUNTS[piece.rarity]
	piece.sub_stats = []
	for i in mini(count, pool.size()):
		piece.sub_stats.append(_roll_stat(pool[i], piece.rarity))

	piece.piece_name = "%s %s" % [
		ArtifactPieceData.Rarity.keys()[piece.rarity].capitalize(),
		ArtifactPieceData.Slot.keys()[piece.slot].capitalize(),
	]
	return piece

static func _roll_slot() -> ArtifactPieceData.Slot:
	var slots := ArtifactPieceData.Slot.values()
	return slots[randi() % slots.size()]

static func _roll_rarity() -> ArtifactPieceData.Rarity:
	var total := 0
	for w in RARITY_WEIGHTS:
		total += w
	var roll := randi() % total
	var cumulative := 0
	for i in RARITY_WEIGHTS.size():
		cumulative += RARITY_WEIGHTS[i]
		if roll < cumulative:
			return i as ArtifactPieceData.Rarity
	return ArtifactPieceData.Rarity.COMMON

static func _roll_stat(stat_name: String, rarity: ArtifactPieceData.Rarity) -> StatModifierData:
	var modifier := StatModifierData.new()
	modifier.stat_name = stat_name
	var multiplier: float = RARITY_MULTIPLIERS[rarity]
	if FLAT_STAT_BASE.has(stat_name):
		modifier.flat_bonus = FLAT_STAT_BASE[stat_name] * multiplier
	else:
		modifier.percent_bonus = PERCENT_STAT_BASE.get(stat_name, 0.04) * multiplier
	return modifier
