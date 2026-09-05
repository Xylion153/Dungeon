class_name WeaponComboStepData
extends Resource
## One windup -> active -> recovery step of a weapon's combo.

@export var windup := 0.1
@export var active := 0.1
@export var recovery := 0.2
@export var damage := 10.0
@export var knockback := 80.0
@export var hitstop := -1.0 ## -1 = use CombatFeel's default for the hit
@export var shake := -1.0 ## -1 = use CombatFeel's default for the hit

@export_group("Melee")
@export var arc_degrees := 90.0
@export var range := 60.0

@export_group("Ranged")
@export var projectile_speed := 500.0
@export var projectile_radius := 6.0
@export var pierce := false
@export var splash_radius := 0.0
@export var projectile_count := 1
@export var spread_degrees := 0.0
