class_name SkillData
extends Resource
## An equippable secondary ability: instant-cast, no combo, own cooldown.

enum Rarity { COMMON, RARE }

@export var id := "" ## stable save key, e.g. "whirlwind" - never shown to the player
@export var skill_name := ""
@export var description := ""
@export var rarity: Rarity = Rarity.COMMON
@export var damage := 0.0
@export var radius := 0.0
@export var cooldown := 5.0
@export var mana_cost := 0.0
@export var self_invulnerable_duration := 0.0
@export var slow_duration := 0.0
@export var slow_multiplier := 1.0
@export var dash_distance := 0.0
