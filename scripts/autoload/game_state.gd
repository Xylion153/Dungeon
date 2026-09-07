extends Node
## Run-state: which class/weapon/skill are loaded in for the current run.
## Expanded later with loot/meta-progression state.

var current_class: ClassData = null
var equipped_weapon: WeaponData = null
var equipped_skill: SkillData = null
var run_loot: Array[GearPieceData] = [] ## gear collected THIS run - banked to SaveManager's inventory on death, not equipped mid-run

func select_class(class_data: ClassData) -> void:
	current_class = class_data
	SaveManager.get_class_progress(class_data.id) # ensures a save entry exists
	SaveManager.set_current_class_id(class_data.id)

	equipped_weapon = class_data.allowed_weapons[0] if not class_data.allowed_weapons.is_empty() else null
	equipped_skill = class_data.starter_skills[0] if not class_data.starter_skills.is_empty() else null
