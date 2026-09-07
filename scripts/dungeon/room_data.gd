class_name RoomData
extends RefCounted
## One room in a generated dungeon graph - runtime-only (never saved to
## disk), so a plain RefCounted rather than a Resource.

enum Type { START, COMBAT, BOSS, REWARD }

const DIRECTIONS := [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]

var grid_pos: Vector2i
var room_type: Type = Type.COMBAT
var doors: Dictionary = {} # Vector2i direction -> true, one entry per connected neighbor
var cleared := false

func _init(pos: Vector2i) -> void:
	grid_pos = pos
