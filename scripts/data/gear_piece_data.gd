class_name GearPieceData
extends Resource
## One piece of equipment: a slot, a rarity-scaled main stat, 1-3 random
## sub-stats, and the set it belongs to.

enum Slot { HELMET, CHEST, GLOVES, BOOTS }
enum Rarity { COMMON, RARE, EPIC, MYTHIC }

@export var piece_name := ""
@export var slot: Slot = Slot.CHEST
@export var rarity: Rarity = Rarity.COMMON
@export var main_stat: StatModifierData
@export var sub_stats: Array[StatModifierData] = []
@export var set_id := ""
