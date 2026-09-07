class_name WeaponData
extends Resource
## An equippable weapon: kind, combo steps, and the one cooldown applied
## after the final step finishes (never after every individual hit).

enum Kind { MELEE, RANGED }
enum Rarity { COMMON, RARE }

@export var id := "" ## stable save key, e.g. "sword" - never shown to the player
@export var weapon_name := ""
@export var description := ""
@export var rarity: Rarity = Rarity.COMMON
@export var kind: Kind = Kind.MELEE
@export var steps: Array[WeaponComboStepData] = []
@export var combo_chain_window := 0.4
@export var cancel_window := 0.5 ## fraction of a step's recovery, from the end, that dash can skip
@export var cooldown := 0.35
