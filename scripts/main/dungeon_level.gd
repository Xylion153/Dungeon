extends Node2D
## A persistent scene for a whole procedural dungeon level - unlike Arena/
## RaidArena (one fixed space), this stays in ONE scene and swaps a room's
## CONTENTS (walls, doors, enemies) in and out of a fixed local area each
## time the player moves between grid cells, rather than laying every room
## out in real, disjoint world-space. Far simpler, same player-facing
## "snap to the next room" feel.

const ROOM_COUNT := 7
const MAX_GRID_EXTENT := 3
const ROOM_HALF_WIDTH := 350.0
const ROOM_HALF_HEIGHT := 250.0
const WALL_THICKNESS := 60.0
const DOOR_GAP := 140.0
const ENTRY_INSET := 90.0
const KILL_XP := 5.0
const BOSS_REWARD_GEMS := 75
const REWARD_ROOM_GEMS := 25

const ObstacleScene := preload("res://scenes/world/Obstacle.tscn")
const BossScene := preload("res://scenes/enemies/BossEnemy.tscn")
const LootPickupScene := preload("res://scenes/combat/LootPickup.tscn")
const ENEMY_SCENES := [
	preload("res://scenes/enemies/MeleeChaser.tscn"),
	preload("res://scenes/enemies/RangedEnemy.tscn"),
	preload("res://scenes/enemies/OrbitingEnemy.tscn"),
]

@onready var player: Player = $Player
@onready var result_screen: CanvasLayer = $RaidResultScreen
@onready var room_label: Label = $Hud/WaveLabel
@onready var room_content: Node2D = $RoomContent
@onready var room_camera: Camera2D = $RoomCamera

var _rooms: Dictionary = {} # Vector2i -> RoomData
var _current_pos: Vector2i
var _alive_enemies: Array = []
var _door_triggers: Array[Area2D] = []
var _room_has_enemies := false

func _ready() -> void:
	# Fixed per-room camera, not scrolling with the player (small rooms are
	# meant to read as distinct spaces, same idea as Town's fixed diorama
	# camera) - registered after Player's own _ready() already ran (children
	# ready before their parent), so this correctly wins as the active
	# camera and the one CombatFeel's shake effects apply to.
	room_camera.make_current()
	CombatFeel.register_camera(room_camera)

	var generated := RoomGridGenerator.generate(ROOM_COUNT, MAX_GRID_EXTENT)
	_rooms = generated["rooms"]
	_current_pos = generated["start_pos"]

	EventBus.enemy_killed.connect(_on_enemy_killed)
	player.died.connect(_on_player_died)

	_load_room(_current_pos, Vector2i.ZERO)

func _physics_process(_delta: float) -> void:
	if not _room_has_enemies:
		return
	_alive_enemies = _alive_enemies.filter(func(e): return is_instance_valid(e))
	if _alive_enemies.is_empty():
		_room_has_enemies = false
		_rooms[_current_pos].cleared = true
		for door in _door_triggers:
			door.monitoring = true

func _on_enemy_killed(_attacker: Node, _enemy: Node, _killing_blow_damage: float) -> void:
	if GameState.current_class:
		SaveManager.add_xp(GameState.current_class.id, KILL_XP)

func _bank_run_loot() -> void:
	for piece in GameState.run_loot:
		SaveManager.add_to_inventory(piece)
	GameState.run_loot.clear()
	for piece in GameState.run_artifact_loot:
		SaveManager.add_artifact_to_inventory(piece)
	GameState.run_artifact_loot.clear()

func _on_boss_died() -> void:
	_bank_run_loot()
	SaveManager.add_gems(BOSS_REWARD_GEMS)
	result_screen.show_victory(BOSS_REWARD_GEMS, "res://scenes/main/DungeonLevel.tscn")

func _on_player_died() -> void:
	_bank_run_loot()
	result_screen.show_defeat("res://scenes/main/DungeonLevel.tscn")

## entry_direction: the direction the player just MOVED (e.g. Vector2i.UP if
## they walked through the top door) - Vector2i.ZERO for the initial load,
## which just centers the player in the Start room.
func _load_room(pos: Vector2i, entry_direction: Vector2i) -> void:
	for child in room_content.get_children():
		child.queue_free()
	_door_triggers.clear()
	_alive_enemies.clear()
	_room_has_enemies = false

	var room: RoomData = _rooms[pos]
	_current_pos = pos

	room_label.text = "%s Room" % RoomData.Type.keys()[room.room_type].capitalize()

	if entry_direction == Vector2i.ZERO:
		player.global_position = _local_to_global(Vector2.ZERO)
	else:
		player.global_position = _local_to_global(_entry_position(-entry_direction))

	_build_walls(room)

	match room.room_type:
		RoomData.Type.START, RoomData.Type.REWARD:
			room.cleared = true
			if room.room_type == RoomData.Type.REWARD:
				_spawn_gems_pickup(Vector2.ZERO)
		RoomData.Type.COMBAT:
			if room.cleared:
				pass
			else:
				_spawn_combat_enemies()
		RoomData.Type.BOSS:
			if not room.cleared:
				_spawn_boss()

	for door in _door_triggers:
		door.monitoring = room.cleared

func _local_to_global(local_pos: Vector2) -> Vector2:
	return room_content.global_position + local_pos

func _entry_position(direction: Vector2i) -> Vector2:
	if direction == Vector2i.UP:
		return Vector2(0.0, -ROOM_HALF_HEIGHT + ENTRY_INSET)
	if direction == Vector2i.DOWN:
		return Vector2(0.0, ROOM_HALF_HEIGHT - ENTRY_INSET)
	if direction == Vector2i.LEFT:
		return Vector2(-ROOM_HALF_WIDTH + ENTRY_INSET, 0.0)
	if direction == Vector2i.RIGHT:
		return Vector2(ROOM_HALF_WIDTH - ENTRY_INSET, 0.0)
	return Vector2.ZERO

func _build_walls(room: RoomData) -> void:
	_build_wall(Vector2i.UP, room.doors.has(Vector2i.UP), room)
	_build_wall(Vector2i.DOWN, room.doors.has(Vector2i.DOWN), room)
	_build_wall(Vector2i.LEFT, room.doors.has(Vector2i.LEFT), room)
	_build_wall(Vector2i.RIGHT, room.doors.has(Vector2i.RIGHT), room)

func _build_wall(direction: Vector2i, has_door: bool, room: RoomData) -> void:
	var horizontal := direction == Vector2i.UP or direction == Vector2i.DOWN
	var axis_extent: float = ROOM_HALF_WIDTH if horizontal else ROOM_HALF_HEIGHT
	var cross_offset: float = -ROOM_HALF_HEIGHT if direction == Vector2i.UP \
		else (ROOM_HALF_HEIGHT if direction == Vector2i.DOWN \
		else (-ROOM_HALF_WIDTH if direction == Vector2i.LEFT else ROOM_HALF_WIDTH))

	if not has_door:
		var full_size := Vector2(axis_extent * 2.0 + WALL_THICKNESS, WALL_THICKNESS) if horizontal \
			else Vector2(WALL_THICKNESS, axis_extent * 2.0 + WALL_THICKNESS)
		var full_center := Vector2(0.0, cross_offset) if horizontal else Vector2(cross_offset, 0.0)
		_build_wall_segment(full_center, full_size)
		return

	var segment_extent: float = axis_extent + WALL_THICKNESS * 0.5 - DOOR_GAP * 0.5
	var segment_center_axis: float = DOOR_GAP * 0.5 + segment_extent * 0.5
	if horizontal:
		var size := Vector2(segment_extent, WALL_THICKNESS)
		_build_wall_segment(Vector2(-segment_center_axis, cross_offset), size)
		_build_wall_segment(Vector2(segment_center_axis, cross_offset), size)
	else:
		var size := Vector2(WALL_THICKNESS, segment_extent)
		_build_wall_segment(Vector2(cross_offset, -segment_center_axis), size)
		_build_wall_segment(Vector2(cross_offset, segment_center_axis), size)

	_build_door_trigger(direction, cross_offset, horizontal, room)

func _build_wall_segment(local_center: Vector2, size: Vector2) -> void:
	var obstacle := ObstacleScene.instantiate()
	room_content.add_child(obstacle)
	obstacle.position = local_center
	obstacle.scale = size / 100.0

func _build_door_trigger(direction: Vector2i, cross_offset: float, horizontal: bool, room: RoomData) -> void:
	var door := Area2D.new()
	door.collision_layer = 0
	door.collision_mask = PhysicsLayers.PLAYER
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(DOOR_GAP, WALL_THICKNESS + 40.0) if horizontal else Vector2(WALL_THICKNESS + 40.0, DOOR_GAP)
	shape.shape = rect
	door.add_child(shape)
	door.position = Vector2(0.0, cross_offset) if horizontal else Vector2(cross_offset, 0.0)
	room_content.add_child(door)
	door.body_entered.connect(_on_door_entered.bind(direction))
	_door_triggers.append(door)

func _on_door_entered(body: Node, direction: Vector2i) -> void:
	if not body.is_in_group("player"):
		return
	var target_pos: Vector2i = _current_pos + direction
	if not _rooms.has(target_pos):
		return
	_load_room(target_pos, direction)

func _spawn_combat_enemies() -> void:
	var count := randi_range(2, 4)
	for i in count:
		var scene: PackedScene = ENEMY_SCENES[randi() % ENEMY_SCENES.size()]
		var enemy = scene.instantiate()
		room_content.add_child(enemy)
		var offset := Vector2(randf_range(-ROOM_HALF_WIDTH + 80.0, ROOM_HALF_WIDTH - 80.0), randf_range(-ROOM_HALF_HEIGHT + 80.0, ROOM_HALF_HEIGHT - 80.0))
		enemy.global_position = _local_to_global(offset)
		_alive_enemies.append(enemy)
	_room_has_enemies = true

func _spawn_boss() -> void:
	var boss := BossScene.instantiate()
	room_content.add_child(boss)
	boss.global_position = _local_to_global(Vector2.ZERO)
	boss.died.connect(_on_boss_died)
	_alive_enemies.append(boss)
	_room_has_enemies = true

func _spawn_gems_pickup(local_pos: Vector2) -> void:
	var pickup := LootPickupScene.instantiate()
	room_content.add_child(pickup)
	pickup.global_position = _local_to_global(local_pos)
	pickup.setup_gems(REWARD_ROOM_GEMS)
