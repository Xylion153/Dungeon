class_name ClassData
extends Resource
## A playable class: picked from the start, leveled independently of every
## other class. Passives are stat modifiers (same StatModifierData/StatSheet
## pattern gear will reuse later), not procs, for this first pass.

@export var id := "" ## stable save key, e.g. "warrior" - never shown to the player
@export var display_name := ""
@export var description := ""
@export var passive_description := "" ## UI flavor text for what the passive does
@export var stat_modifiers: Array[StatModifierData] = []
@export var allowed_weapons: Array[WeaponData] = [] ## weapons this class is eligible to use once unlocked - not "immediately available" (see starter_weapon)
@export var starter_weapon: WeaponData ## the one weapon owned for free from the moment this class is picked
@export var starter_skills: Array[SkillData] = []
@export var base_class_id := "" ## unused for now - reserved so subclasses can reference a base later without a schema change
