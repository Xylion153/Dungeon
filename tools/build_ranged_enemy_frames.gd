extends SceneTree

func _initialize() -> void:
	SpriteSheetBuilder.build(
		"res://assets/sprites/ranged_enemy_sheet.png",
		"res://assets/sprites/ranged_enemy_frames.tres",
		["idle", "walk_down", "walk_up", "walk_left", "walk_right"],
		{"idle": 6.0, "walk_down": 10.0, "walk_up": 10.0, "walk_left": 10.0, "walk_right": 10.0},
		180.0, 195.0, 10.0
	)
	quit()
