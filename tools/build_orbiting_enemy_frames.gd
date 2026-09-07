extends SceneTree
## Uses the known-frame-count slicer: this sheet's wide wingtips touch
## between adjacent poses in some rows, so plain gap-detection merges them.

func _initialize() -> void:
	SpriteSheetBuilder.build_with_counts(
		"res://assets/sprites/orbiting_enemy_sheet.png",
		"res://assets/sprites/orbiting_enemy_frames.tres",
		["idle", "walk_down", "walk_up", "walk_right", "walk_left"], # sheet's row 4 is Right, row 5 is Left
		[4, 6, 6, 6, 6],
		{"idle": 6.0, "walk_down": 10.0, "walk_up": 10.0, "walk_left": 10.0, "walk_right": 10.0},
		200.0, 190.0, 15.0
	)
	quit()
