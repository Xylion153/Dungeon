class_name RoomGridGenerator
extends RefCounted
## Generates a small, connected room graph via random-walk placement - the
## same technique The Binding of Isaac itself uses, simplified: every new
## room is placed adjacent to an already-placed one, so the graph is
## connected by construction with no separate connectivity pass needed.

const MAX_ATTEMPTS_MULTIPLIER := 20 # give up placing more rooms after this many failed tries per room

## Returns {"rooms": Dictionary[Vector2i, RoomData], "start_pos": Vector2i, "boss_pos": Vector2i}.
static func generate(room_count: int, max_grid_extent: int = 3) -> Dictionary:
	var start_pos := Vector2i.ZERO
	var rooms: Dictionary = {start_pos: RoomData.new(start_pos)}
	var placement_order: Array[Vector2i] = [start_pos]

	var attempts := 0
	var max_attempts := room_count * MAX_ATTEMPTS_MULTIPLIER
	while rooms.size() < room_count and attempts < max_attempts:
		attempts += 1
		var from_pos: Vector2i = placement_order[randi() % placement_order.size()]
		var direction: Vector2i = RoomData.DIRECTIONS[randi() % RoomData.DIRECTIONS.size()]
		var target_pos: Vector2i = from_pos + direction

		if rooms.has(target_pos):
			continue
		if absi(target_pos.x) > max_grid_extent or absi(target_pos.y) > max_grid_extent:
			continue

		var new_room := RoomData.new(target_pos)
		rooms[target_pos] = new_room
		placement_order.append(target_pos)

		var from_room: RoomData = rooms[from_pos]
		from_room.doors[direction] = true
		new_room.doors[-direction] = true

	var boss_pos := _find_boss_room(rooms, start_pos, placement_order)
	rooms[start_pos].room_type = RoomData.Type.START
	rooms[boss_pos].room_type = RoomData.Type.BOSS

	var reward_pos: Variant = _find_reward_room(rooms, start_pos, boss_pos)
	if reward_pos != null:
		rooms[reward_pos].room_type = RoomData.Type.REWARD

	for pos in rooms:
		var room: RoomData = rooms[pos]
		if room.room_type != RoomData.Type.START and room.room_type != RoomData.Type.BOSS and room.room_type != RoomData.Type.REWARD:
			room.room_type = RoomData.Type.COMBAT

	return {"rooms": rooms, "start_pos": start_pos, "boss_pos": boss_pos}

## BFS distance from start; boss = furthest room, ties broken by placement
## order (later-placed wins) so the result is deterministic given the same
## random walk rather than depending on Dictionary iteration order.
static func _find_boss_room(rooms: Dictionary, start_pos: Vector2i, placement_order: Array[Vector2i]) -> Vector2i:
	var distances := _bfs_distances(rooms, start_pos)
	var best_pos := start_pos
	var best_distance := -1
	for pos in placement_order:
		var dist: int = distances.get(pos, 0)
		if dist >= best_distance:
			best_distance = dist
			best_pos = pos
	return best_pos

static func _bfs_distances(rooms: Dictionary, start_pos: Vector2i) -> Dictionary:
	var distances := {start_pos: 0}
	var queue: Array[Vector2i] = [start_pos]
	var head := 0
	while head < queue.size():
		var current: Vector2i = queue[head]
		head += 1
		var current_room: RoomData = rooms[current]
		for direction in current_room.doors:
			var neighbor: Vector2i = current + direction
			if not distances.has(neighbor):
				distances[neighbor] = distances[current] + 1
				queue.append(neighbor)
	return distances

## A random leaf room (exactly one door) that isn't Start or Boss - a small
## optional side room, per the branching-grid request. Returns null (not a
## Vector2i) if no room qualifies, since Vector2i has no natural "none".
static func _find_reward_room(rooms: Dictionary, start_pos: Vector2i, boss_pos: Vector2i) -> Variant:
	var candidates: Array[Vector2i] = []
	for pos in rooms:
		if pos == start_pos or pos == boss_pos:
			continue
		var room: RoomData = rooms[pos]
		if room.doors.size() == 1:
			candidates.append(pos)
	if candidates.is_empty():
		return null
	return candidates[randi() % candidates.size()]
