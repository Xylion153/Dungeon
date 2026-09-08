class_name ConsumableData
extends Resource
## A Shop-purchasable one-run buff: bought once, auto-applied (and consumed)
## the next time a run starts. Same StatModifierData the rest of the stat
## pipeline already understands - see GameState.apply_run_buffs()/
## active_run_buffs.

@export var id := ""
@export var display_name := ""
@export var description := ""
@export var price := 0
@export var effect: StatModifierData
