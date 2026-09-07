extends SceneTree
## Uses the known-frame-count slicer: the boss holds its axe away from its
## body, so plain gap-detection splits the blade off as its own "frame".

func _initialize() -> void:
	SpriteSheetBuilder.build_with_counts(
		"res://assets/sprites/boss_sheet.png",
		"res://assets/sprites/boss_frames.tres",
		["idle", "walk_down", "walk_up", "walk_left", "walk_right"],
		[5, 6, 5, 6, 6], # this sheet's idle and walk_up rows were drawn with 5 poses, not 6
		{"idle": 6.0, "walk_down": 10.0, "walk_up": 10.0, "walk_left": 10.0, "walk_right": 10.0},
		# Cell must stay under the pose spacing (~256px across, ~205px per row
		# band) or the crop captures the neighbouring pose. The boss's axe is
		# wider than that spacing allows, so its tip clips slightly - much less
		# objectionable than a second boss bleeding into frame.
		248.0, 198.0, 12.0
	)
	quit()
