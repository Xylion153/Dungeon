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
@export var allowed_weapons: Array[WeaponData] = []
@export var starter_skills: Array[SkillData] = []
@export var base_class_id := "" ## unused for now - reserved so subclasses can reference a base later without a schema change
