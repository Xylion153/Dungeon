extends SceneTree
## The 4 uploaded enemy sheets have a checkerboard baked into opaque RGB
## pixels (no real alpha) instead of true transparency. This flood-fills
## from the image border through any near-white/near-gray "background-like"
## pixel (grayscale + bright) and zeroes its alpha - stops naturally at the
## dark outline strokes around each character, so anything fully enclosed
## by the character (white eye highlights etc.) is untouched because the
## flood can only spread through 4-connected matching pixels reachable from
## the border.

const SHEETS := [
	"res://assets/sprites/melee_chaser_sheet.png",
	"res://assets/sprites/ranged_enemy_sheet.png",
	"res://assets/sprites/orbiting_enemy_sheet.png",
	"res://assets/sprites/boss_sheet.png",
]

const GRAY_TOLERANCE := 14 # out of 255
const BRIGHTNESS_MIN := 190 # out of 255

func _initialize() -> void:
	for path in SHEETS:
		_strip(path)
	quit()

func _strip(path: String) -> void:
	var texture: Texture2D = load(path)
	var img := texture.get_image()
	if img.get_format() != Image.FORMAT_RGBA8:
		img.convert(Image.FORMAT_RGBA8)
	var w := img.get_width()
	var h := img.get_height()
	var data := img.get_data()

	var candidate := PackedByteArray()
	candidate.resize(w * h)
	for i in w * h:
		var o := i * 4
		var r: int = data[o]
		var g: int = data[o + 1]
		var b: int = data[o + 2]
		var is_gray: bool = absi(r - g) < GRAY_TOLERANCE and absi(g - b) < GRAY_TOLERANCE and absi(r - b) < GRAY_TOLERANCE
		var is_bright: bool = r > BRIGHTNESS_MIN
		candidate[i] = 1 if (is_gray and is_bright) else 0

	var visited := PackedByteArray()
	visited.resize(w * h)
	var stack: Array[int] = []

	for x in w:
		_seed_xy(x, candidate, visited, stack) # top row
		_seed_xy((h - 1) * w + x, candidate, visited, stack) # bottom row
	for y in h:
		_seed_xy(y * w, candidate, visited, stack) # left column
		_seed_xy(y * w + (w - 1), candidate, visited, stack) # right column

	while stack.size() > 0:
		var i: int = stack.pop_back()
		var x: int = i % w
		var y: int = int(i / w)
		_try_visit(x + 1, y, w, h, candidate, visited, stack)
		_try_visit(x - 1, y, w, h, candidate, visited, stack)
		_try_visit(x, y + 1, w, h, candidate, visited, stack)
		_try_visit(x, y - 1, w, h, candidate, visited, stack)

	var cleared := 0
	for i in w * h:
		if visited[i] == 1:
			data[i * 4 + 3] = 0
			cleared += 1
	print(path, ": cleared ", cleared, " / ", w * h, " pixels to transparent")

	var new_img := Image.create_from_data(w, h, false, Image.FORMAT_RGBA8, data)
	var err := new_img.save_png(path)
	if err != OK:
		printerr("Failed to save ", path, ": ", err)
	else:
		print("  saved ", path)

func _seed_xy(i: int, candidate: PackedByteArray, visited: PackedByteArray, stack: Array[int]) -> void:
	if candidate[i] == 1 and visited[i] == 0:
		visited[i] = 1
		stack.append(i)

func _try_visit(x: int, y: int, w: int, h: int, candidate: PackedByteArray, visited: PackedByteArray, stack: Array[int]) -> void:
	if x < 0 or x >= w or y < 0 or y >= h:
		return
	var i := y * w + x
	if candidate[i] == 1 and visited[i] == 0:
		visited[i] = 1
		stack.append(i)
