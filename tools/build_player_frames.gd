extends SceneTree
## One-time (re-runnable) build tool: slices assets/sprites/player_sheet.png
## into a SpriteFrames resource. Not loaded by the game at runtime - run it
## manually with `godot --headless --path <project> --script res://tools/build_player_frames.gd`
## whenever the source sheet changes (e.g. when Attack/Skill/Dash/Hurt/Death
## rows get added - just extend ANIMATION_NAMES to match the new row order).
##
## Frames within a row rarely share an identical bounding box (limbs/hair
## naturally extend a different amount per pose), so naively cropping each
## frame to its own tight box would make the character jitter as it
## animates. Instead every frame is cropped to the SAME fixed-size cell,
## positioned so the character's bottom-center (feet) lands at the same
## relative point in every cell - stable anchoring regardless of per-frame
## silhouette variance.

const SHEET_PATH := "res://assets/sprites/player_sheet.png"
const OUTPUT_PATH := "res://assets/sprites/player_frames.tres"
const ANIMATION_NAMES := ["idle", "walk_down", "walk_up", "walk_left", "walk_right"]
const ANIMATION_FPS := {"idle": 6.0, "walk_down": 10.0, "walk_up": 10.0, "walk_left": 10.0, "walk_right": 10.0}
const ALPHA_THRESHOLD := 10

const CELL_WIDTH := 170.0
const CELL_HEIGHT := 200.0
const BOTTOM_MARGIN := 10.0 # a little breathing room below the feet

func _initialize() -> void:
	# Loaded twice on purpose: `texture` is the properly-imported/compressed
	# asset (referenced by path, not embedded) for the AtlasTextures to point
	# at; `img` is only used locally here for the pixel-level scan to find
	# frame boundaries, and is never saved anywhere.
	var texture: Texture2D = load(SHEET_PATH)
	if texture == null:
		printerr("Failed to load ", SHEET_PATH, " - run --import first if this is a fresh copy.")
		quit(1)
		return
	var img := texture.get_image()
	if img.get_format() != Image.FORMAT_RGBA8:
		img.convert(Image.FORMAT_RGBA8)

	var bands := _find_row_bands(img)
	print("Found ", bands.size(), " row bands (expected ", ANIMATION_NAMES.size(), ")")
	if bands.size() != ANIMATION_NAMES.size():
		printerr("Row count mismatch - update ANIMATION_NAMES to match the sheet before trusting output.")
	var sprite_frames := SpriteFrames.new()
	sprite_frames.remove_animation("default")

	for i in bands.size():
		var anim_name: String = ANIMATION_NAMES[i] if i < ANIMATION_NAMES.size() else "row_%d" % i
		var frames := _find_frames_in_band(img, bands[i])
		print("  ", anim_name, ": ", frames.size(), " frames")

		sprite_frames.add_animation(anim_name)
		sprite_frames.set_animation_loop(anim_name, true)
		sprite_frames.set_animation_speed(anim_name, ANIMATION_FPS.get(anim_name, 8.0))

		for f in frames:
			var center_x: float = (f.x_start + f.x_end) / 2.0
			var bottom_y: float = f.y_end
			var region := Rect2(
				center_x - CELL_WIDTH / 2.0,
				bottom_y - CELL_HEIGHT + BOTTOM_MARGIN,
				CELL_WIDTH,
				CELL_HEIGHT
			)
			var atlas := AtlasTexture.new()
			atlas.atlas = texture
			atlas.region = region
			sprite_frames.add_frame(anim_name, atlas)

	var save_err := ResourceSaver.save(sprite_frames, OUTPUT_PATH)
	if save_err != OK:
		printerr("Failed to save ", OUTPUT_PATH, ": ", save_err)
		quit(1)
		return

	print("Saved ", OUTPUT_PATH)
	quit()

func _find_row_bands(img: Image) -> Array:
	var w := img.get_width()
	var h := img.get_height()
	var row_has_content := PackedByteArray()
	row_has_content.resize(h)
	for y in h:
		var found := false
		for x in w:
			if img.get_pixel(x, y).a8 > ALPHA_THRESHOLD:
				found = true
				break
		row_has_content[y] = 1 if found else 0

	var bands: Array = []
	var in_band := false
	var band_start := 0
	for y in h:
		if row_has_content[y] == 1 and not in_band:
			in_band = true
			band_start = y
		elif row_has_content[y] == 0 and in_band:
			in_band = false
			bands.append({"y_start": band_start, "y_end": y - 1})
	if in_band:
		bands.append({"y_start": band_start, "y_end": h - 1})
	return bands

func _find_frames_in_band(img: Image, band: Dictionary) -> Array:
	var w := img.get_width()
	var y0: int = band.y_start
	var y1: int = band.y_end

	var col_has_content := PackedByteArray()
	col_has_content.resize(w)
	for x in w:
		var found := false
		for y in range(y0, y1 + 1):
			if img.get_pixel(x, y).a8 > ALPHA_THRESHOLD:
				found = true
				break
		col_has_content[x] = 1 if found else 0

	var frame_x_ranges: Array = []
	var in_frame := false
	var frame_start := 0
	for x in w:
		if col_has_content[x] == 1 and not in_frame:
			in_frame = true
			frame_start = x
		elif col_has_content[x] == 0 and in_frame:
			in_frame = false
			frame_x_ranges.append({"x_start": frame_start, "x_end": x - 1})
	if in_frame:
		frame_x_ranges.append({"x_start": frame_start, "x_end": w - 1})

	var frames: Array = []
	for xr in frame_x_ranges:
		var fx0: int = xr.x_start
		var fx1: int = xr.x_end
		var fy0 := y1
		var fy1 := y0
		for y in range(y0, y1 + 1):
			var row_found := false
			for x in range(fx0, fx1 + 1):
				if img.get_pixel(x, y).a8 > ALPHA_THRESHOLD:
					row_found = true
					break
			if row_found:
				fy0 = mini(fy0, y)
				fy1 = maxi(fy1, y)
		frames.append({"x_start": fx0, "x_end": fx1, "y_start": fy0, "y_end": fy1})
	return frames
