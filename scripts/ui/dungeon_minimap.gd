class_name DungeonMinimap
extends Control
## Fog-of-war minimap for a DungeonLevel run. The full room graph is known
## internally at setup (for layout/bounds), but only rooms the player has
## actually visited (RoomData.visited) are ever drawn - discovery happens by
## walking there, not by looking at the map.

const CELL_SIZE := 18.0
const CELL_GAP := 5.0

var _rooms: Dictionary = {} # Vector2i -> RoomData
var _current_pos: Vector2i
var _min_grid: Vector2i

func setup(rooms: Dictionary) -> void:
	_rooms = rooms
	_min_grid = Vector2i.ZERO
	var max_grid := Vector2i.ZERO
	for pos in rooms:
		_min_grid.x = mini(_min_grid.x, pos.x)
		_min_grid.y = mini(_min_grid.y, pos.y)
		max_grid.x = maxi(max_grid.x, pos.x)
		max_grid.y = maxi(max_grid.y, pos.y)
	var span: Vector2i = max_grid - _min_grid + Vector2i.ONE
	var pixel_size := Vector2(span.x, span.y) * (CELL_SIZE + CELL_GAP) - Vector2(CELL_GAP, CELL_GAP)
	custom_minimum_size = pixel_size
	size = pixel_size

## Call after any room-graph state changes (entering a room, clearing one).
func refresh(current_pos: Vector2i) -> void:
	_current_pos = current_pos
	queue_redraw()

func _cell_rect(grid_pos: Vector2i) -> Rect2:
	var local: Vector2i = grid_pos - _min_grid
	return Rect2(Vector2(local.x, local.y) * (CELL_SIZE + CELL_GAP), Vector2(CELL_SIZE, CELL_SIZE))

func _draw() -> void:
	# Door connectors first so room squares layer on top of them.
	for pos in _rooms:
		var room: RoomData = _rooms[pos]
		if not room.visited:
			continue
		for direction in room.doors:
			var neighbor_pos: Vector2i = pos + direction
			if not _rooms.has(neighbor_pos) or not _rooms[neighbor_pos].visited:
				continue
			draw_line(_cell_rect(pos).get_center(), _cell_rect(neighbor_pos).get_center(), Color(0.6, 0.6, 0.68, 0.9), 3.0)

	for pos in _rooms:
		var room: RoomData = _rooms[pos]
		if not room.visited:
			continue
		var rect := _cell_rect(pos)
		draw_rect(rect, _room_color(room), true)
		if pos == _current_pos:
			draw_rect(rect.grow(2.0), Color.WHITE, false, 2.0)

func _room_color(room: RoomData) -> Color:
	match room.room_type:
		RoomData.Type.START:
			return Color(0.35, 0.55, 0.9)
		RoomData.Type.BOSS:
			return Color(0.8, 0.2, 0.25)
		RoomData.Type.REWARD:
			return Color(0.85, 0.7, 0.2)
		_:
			return Color(0.4, 0.75, 0.4) if room.cleared else Color(0.6, 0.58, 0.62)
