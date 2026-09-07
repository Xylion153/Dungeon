extends SceneTree
## One-time (re-runnable) build tool: slices assets/sprites/player_sheet.png
## into a SpriteFrames resource. Not loaded by the game at runtime - run it
## manually with `godot --headless --path <project> --script res://tools/build_player_frames.gd`
## whenever the source sheet changes.

func _initialize() -> void:
	SpriteSheetBuilder.build(
		"res://assets/sprites/player_sheet.png",
		"res://assets/sprites/player_frames.tres",
		["idle", "walk_down", "walk_up", "walk_right", "walk_left"], # sheet's row 4 is Right, row 5 is Left
		{"idle": 6.0, "walk_down": 10.0, "walk_up": 10.0, "walk_left": 10.0, "walk_right": 10.0},
		170.0, 200.0, 10.0
	)
	quit()
