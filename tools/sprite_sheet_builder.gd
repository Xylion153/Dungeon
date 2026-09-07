class_name SpriteSheetBuilder
extends RefCounted
## Shared row/frame auto-slicer for chibi-style character sheets (5 rows:
## idle, walk_down, walk_up, walk_left, walk_right - see tools/build_*.gd
## callers). Frames within a row rarely share an identical bounding box
## (limbs/weapons naturally extend a different amount per pose), so naively
## cropping each frame to its own tight box would make the character jitter
## as it animates. Instead every frame is cropped to the SAME fixed-size
## cell, positioned so the character's bottom-center (feet) lands at the
## same relative point in every cell - stable anchoring regardless of
## per-frame silhouette variance.

const ALPHA_THRESHOLD := 40 # higher than a bare "any non-zero alpha" check so a
	# faint anti-aliased sliver between two adjacent frames doesn't register as
	# "content" and bridge them into one falsely-merged frame.
const MIN_BAND_SIZE := 6 # rows/frames thinner than this are stray noise pixels
	# left over from background stripping, not real content.

static func build(
	sheet_path: String,
	output_path: String,
	animation_names: Array,
	animation_fps: Dictionary,
	cell_width: float,
	cell_height: float,
	bottom_margin: float,
	min_gap = 1 # int (applies to every row) or an Array with one int per row
) -> void:
	var texture: Texture2D = load(sheet_path)
	if texture == null:
		printerr("Failed to load ", sheet_path, " - run --import first if this is a fresh copy.")
		return
	var img := texture.get_image()
	if img.get_format() != Image.FORMAT_RGBA8:
		img.convert(Image.FORMAT_RGBA8)

	var bands := find_row_bands(img)
	print("Found ", bands.size(), " row bands (expected ", animation_names.size(), ")")
	if bands.size() != animation_names.size():
		printerr("Row count mismatch - update animation_names to match the sheet before trusting output.")

	var sprite_frames := SpriteFrames.new()
	sprite_frames.remove_animation("default")

	for i in bands.size():
		var anim_name: String = animation_names[i] if i < animation_names.size() else "row_%d" % i
		var row_min_gap: int = min_gap[i] if min_gap is Array else min_gap
		var frames := find_frames_in_band(img, bands[i], row_min_gap)
		print("  ", anim_name, ": ", frames.size(), " frames (min_gap=", row_min_gap, ")")

		sprite_frames.add_animation(anim_name)
		sprite_frames.set_animation_loop(anim_name, true)
		sprite_frames.set_animation_speed(anim_name, animation_fps.get(anim_name, 8.0))

		for f in frames:
			var center_x: float = (f.x_start + f.x_end) / 2.0
			var bottom_y: float = f.y_end
			var region := Rect2(
				center_x - cell_width / 2.0,
				bottom_y - cell_height + bottom_margin,
				cell_width,
				cell_height
			)
			var atlas := AtlasTexture.new()
			atlas.atlas = texture
			atlas.region = region
			sprite_frames.add_frame(anim_name, atlas)

	var save_err := ResourceSaver.save(sprite_frames, output_path)
	if save_err != OK:
		printerr("Failed to save ", output_path, ": ", save_err)
		return
	print("Saved ", output_path)

## Like build(), but for sheets where plain gap-detection mis-segments -
## a weapon held away from the body splitting into its own "frame", or wide
## wingtips touching and merging two poses into one. frame_counts gives the
## KNOWN frame count per row (matching animation_names order), which lets
## find_frames_by_count() cut at the widest gaps instead of guessing from an
## absolute gap threshold.
static func build_with_counts(
	sheet_path: String,
	output_path: String,
	animation_names: Array,
	frame_counts: Array,
	animation_fps: Dictionary,
	cell_width: float,
	cell_height: float,
	bottom_margin: float
) -> void:
	var texture: Texture2D = load(sheet_path)
	if texture == null:
		printerr("Failed to load ", sheet_path)
		return
	var img := texture.get_image()
	if img.get_format() != Image.FORMAT_RGBA8:
		img.convert(Image.FORMAT_RGBA8)

	var bands := find_row_bands(img)
	print("Found ", bands.size(), " row bands (expected ", animation_names.size(), ")")

	var sprite_frames := SpriteFrames.new()
	sprite_frames.remove_animation("default")

	for i in bands.size():
		var anim_name: String = animation_names[i] if i < animation_names.size() else "row_%d" % i
		var frame_count: int = frame_counts[i] if i < frame_counts.size() else 1
		var frames: Array = find_frames_by_count(img, bands[i], frame_count) if frame_count > 0 \
			else find_frames_in_band(img, bands[i])
		print("  ", anim_name, ": ", frames.size(), " frames", " (by count)" if frame_count > 0 else " (gap-detect)")

		sprite_frames.add_animation(anim_name)
		sprite_frames.set_animation_loop(anim_name, true)
		sprite_frames.set_animation_speed(anim_name, animation_fps.get(anim_name, 8.0))

		for f in frames:
			var center_x: float = (f.x_start + f.x_end) / 2.0
			var bottom_y: float = f.y_end
			var region := Rect2(
				center_x - cell_width / 2.0,
				bottom_y - cell_height + bottom_margin,
				cell_width,
				cell_height
			)
			var atlas := AtlasTexture.new()
			atlas.atlas = texture
			atlas.region = region
			sprite_frames.add_frame(anim_name, atlas)

	var save_err := ResourceSaver.save(sprite_frames, output_path)
	if save_err != OK:
		printerr("Failed to save ", output_path, ": ", save_err)
		return
	print("Saved ", output_path)

## Splits a row into exactly `count` frames by cutting at the count-1 WIDEST
## gaps between content, rather than at every gap wider than some absolute
## threshold. That's scale-free: a weapon held slightly away from the body
## leaves a smaller gap than the spacing between two poses, so the real
## separators win automatically without any per-sheet threshold tuning.
## If poses physically touch (no gap at all to cut on) the widest remaining
## group is halved until `count` frames exist.
static func find_frames_by_count(img: Image, band: Dictionary, count: int) -> Array:
	var w := img.get_width()
	var y0: int = band.y_start
	var y1: int = band.y_end

	var col_has_content := PackedByteArray()
	col_has_content.resize(w)
	var first_content := -1
	var last_content := -1
	for x in w:
		var found := false
		for y in range(y0, y1 + 1):
			if img.get_pixel(x, y).a8 > ALPHA_THRESHOLD:
				found = true
				break
		col_has_content[x] = 1 if found else 0
		if found:
			if first_content < 0:
				first_content = x
			last_content = x

	if first_content < 0:
		return []

	# Gap runs strictly between the first and last content column.
	var gaps: Array = []
	var run_start := -1
	for x in range(first_content, last_content + 1):
		if col_has_content[x] == 0:
			if run_start < 0:
				run_start = x
		elif run_start >= 0:
			gaps.append({"start": run_start, "end": x - 1, "width": x - run_start})
			run_start = -1

	gaps.sort_custom(func(a, b): return a.width > b.width)
	var cuts: Array = []
	for i in mini(count - 1, gaps.size()):
		var gap: Dictionary = gaps[i]
		cuts.append(int((gap.start + gap.end) / 2.0))
	cuts.sort()

	var groups: Array = []
	var group_start := first_content
	for cut in cuts:
		groups.append({"x_start": group_start, "x_end": cut})
		group_start = cut + 1
	groups.append({"x_start": group_start, "x_end": last_content})

	# Poses that physically touch leave no gap to cut on - halve the widest
	# group until the expected frame count is reached.
	while groups.size() < count:
		var widest := 0
		for i in groups.size():
			if groups[i].x_end - groups[i].x_start > groups[widest].x_end - groups[widest].x_start:
				widest = i
		var g: Dictionary = groups[widest]
		var mid := int((g.x_start + g.x_end) / 2.0)
		groups.remove_at(widest)
		groups.insert(widest, {"x_start": mid + 1, "x_end": g.x_end})
		groups.insert(widest, {"x_start": g.x_start, "x_end": mid})

	var frames: Array = []
	for g in groups:
		var fx0: int = g.x_end
		var fx1: int = g.x_start
		var fy0 := y1
		var fy1 := y0
		for y in range(y0, y1 + 1):
			for x in range(g.x_start, g.x_end + 1):
				if img.get_pixel(x, y).a8 > ALPHA_THRESHOLD:
					fx0 = mini(fx0, x)
					fx1 = maxi(fx1, x)
					fy0 = mini(fy0, y)
					fy1 = maxi(fy1, y)
		if fx1 >= fx0 and fy1 >= fy0:
			frames.append({"x_start": fx0, "x_end": fx1, "y_start": fy0, "y_end": fy1})
	return frames

## Debug helper: prints each row's frame count and the max frame width/height
## seen anywhere in the sheet, so a caller can pick sane cell_width/
## cell_height constants before doing a real build.
static func scan(sheet_path: String) -> void:
	var texture: Texture2D = load(sheet_path)
	if texture == null:
		printerr("Failed to load ", sheet_path)
		return
	var img := texture.get_image()
	if img.get_format() != Image.FORMAT_RGBA8:
		img.convert(Image.FORMAT_RGBA8)

	var bands := find_row_bands(img)
	print(sheet_path, " image size: ", img.get_size(), " row bands: ", bands.size())
	var max_w := 0.0
	var max_h := 0.0
	for i in bands.size():
		var frames := find_frames_in_band(img, bands[i])
		var row_max_w := 0.0
		var row_max_h := 0.0
		for f in frames:
			var w: float = f.x_end - f.x_start
			var h: float = f.y_end - f.y_start
			row_max_w = maxf(row_max_w, w)
			row_max_h = maxf(row_max_h, h)
		max_w = maxf(max_w, row_max_w)
		max_h = maxf(max_h, row_max_h)
		print("  row ", i, ": ", frames.size(), " frames, max frame size ", row_max_w, "x", row_max_h)
	print("  OVERALL max frame size: ", max_w, "x", max_h)

static func find_row_bands(img: Image) -> Array:
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
			if y - 1 - band_start >= MIN_BAND_SIZE:
				bands.append({"y_start": band_start, "y_end": y - 1})
	if in_band and h - 1 - band_start >= MIN_BAND_SIZE:
		bands.append({"y_start": band_start, "y_end": h - 1})
	return bands

## min_gap: how many consecutive empty columns are required before a frame
## is considered closed - a small internal gap (e.g. a weapon held slightly
## away from the body) stays part of the same frame until the gap reaches
## this width, so it isn't mistaken for a separator between two poses.
static func find_frames_in_band(img: Image, band: Dictionary, min_gap: int = 1) -> Array:
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
	var last_content_x := 0
	var empty_run := 0
	for x in w:
		if col_has_content[x] == 1:
			if not in_frame:
				in_frame = true
				frame_start = x
			last_content_x = x
			empty_run = 0
		elif in_frame:
			empty_run += 1
			if empty_run >= min_gap:
				in_frame = false
				if last_content_x - frame_start >= MIN_BAND_SIZE:
					frame_x_ranges.append({"x_start": frame_start, "x_end": last_content_x})
	if in_frame and last_content_x - frame_start >= MIN_BAND_SIZE:
		frame_x_ranges.append({"x_start": frame_start, "x_end": last_content_x})

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
