extends SceneTree
## One-time (re-runnable) build tool: slices assets/sprites/player_sheet.png
## into a SpriteFrames resource. Not loaded by the game at runtime - run it
## manually with `godot --headless --path <project> --script res://tools/build_player_frames.gd`
## whenever the source sheet changes.

func _initialize() -> void:
	SpriteSheetBuilder.build(
		"res://assets/sprites/player_sheet.png",
		"res://assets/sprites/player_frames.tres",
		# Unlike the enemy sheets (generated later, in a session that explicitly
		# prompted row 4 = Right / row 5 = Left), this sheet is older and was
		# generated with row 4 = Left / row 5 = Right - this order stood
		# correctly for many commits before an earlier fix wrongly applied the
		# enemy sheets' convention here too, actually breaking the player.
		["idle", "walk_down", "walk_up", "walk_left", "walk_right"],
		{"idle": 6.0, "walk_down": 10.0, "walk_up": 10.0, "walk_left": 10.0, "walk_right": 10.0},
		170.0, 200.0, 10.0
	)
	quit()
