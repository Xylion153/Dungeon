class_name StatModifierData
extends Resource
## One flat/percent bonus to a named stat, contributed by a gear piece or
## set bonus. Read by StatSheet, never applied by mutating the stat directly.

@export var stat_name := ""
@export var flat_bonus := 0.0
@export var percent_bonus := 0.0
