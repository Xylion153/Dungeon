extends Node
## Minimal run-state stub: which weapon/skill are loaded in for the current
## run. Expanded later with wave/loot/meta-progression state.

var equipped_weapon: WeaponData = preload("res://data/weapons/sword.tres")
var equipped_skill: SkillData = null
