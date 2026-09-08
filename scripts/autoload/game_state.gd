extends Node
## Run-state: which class/weapon/skill are loaded in for the current run.
## Expanded later with loot/meta-progression state.

var current_class: ClassData = null
var equipped_weapon: WeaponData = null
var equipped_skill: SkillData = null
var run_loot: Array[GearPieceData] = [] ## gear collected THIS run - banked to SaveManager's inventory on death, not equipped mid-run
var run_artifact_loot: Array[ArtifactPieceData] = [] ## same idea as run_loot, for Artifacts
var active_run_buffs: Array[StatModifierData] = [] ## Shop consumable effects for the current run - rebuilt by whatever combat scene's script starts the run

## Consumes one of each owned Shop consumable and stages its effect for the
## run about to start. Must run BEFORE the combat scene loads (its Player
## reads active_run_buffs during its own _ready(), and children ready before
## their parent - the scene's own _ready() would already be too late) - call
## this from every place that changes to a combat scene, not just one.
func apply_run_buffs() -> void:
	active_run_buffs.clear()
	for consumable in DataFolder.list_resources("res://data/consumables"):
		if SaveManager.get_consumable_count(consumable.id) > 0:
			SaveManager.remove_consumable(consumable.id, 1)
			active_run_buffs.append(consumable.effect)

func select_class(class_data: ClassData) -> void:
	current_class = class_data
	SaveManager.get_class_progress(class_data.id) # ensures a save entry exists
	SaveManager.set_current_class_id(class_data.id)

	# Idempotent free grant - picking a class is always immediately playable
	# even before any Gacha pulls, without double-counting as a paid "dupe".
	if class_data.starter_weapon:
		SaveManager.grant_weapon(class_data.starter_weapon.id)
	if not class_data.starter_skills.is_empty():
		SaveManager.grant_skill(class_data.starter_skills[0].id)

	equipped_weapon = class_data.starter_weapon
	equipped_skill = class_data.starter_skills[0] if not class_data.starter_skills.is_empty() else null
