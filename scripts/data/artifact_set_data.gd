class_name ArtifactSetData
extends Resource
## An Artifact set's bonus. Unlike GearSetData there's only one tier - with
## just 2 slots (Amulet, Ring), "both pieces equipped" already means the
## whole set, so there's no partial/full split to model. The bonus is a
## plain passive stat modifier, not a proc - see
## scripts/autoload/artifact_manager.gd's header for why Artifacts don't
## get Gear's proc mechanic.

@export var set_name := ""
@export var set_id := ""
@export var set_bonus: Array[StatModifierData] = []
