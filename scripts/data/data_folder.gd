class_name DataFolder
extends RefCounted
## Scans a res:// folder for .tres resources so menus (Armory, Skills) can
## list whatever data exists without hardcoding filenames — dropping a new
## weapon/skill .tres into the folder is enough for it to show up.

static func list_resources(dir_path: String) -> Array:
	var file_names: Array = []
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return []

	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		# Exported builds remap resource files (sword.tres -> sword.tres.remap
		# on disk inside the .pck) - load() resolves that transparently, but a
		# raw directory listing sees the .remap name, not the .tres one.
		if not dir.current_is_dir():
			var clean_name := file_name
			if clean_name.ends_with(".remap"):
				clean_name = clean_name.substr(0, clean_name.length() - ".remap".length())
			if clean_name.ends_with(".tres"):
				file_names.append(clean_name)
		file_name = dir.get_next()
	dir.list_dir_end()

	file_names.sort()

	var resources: Array = []
	for name in file_names:
		resources.append(load(dir_path.path_join(name)))
	return resources
