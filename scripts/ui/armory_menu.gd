extends Control
## Weapon selection AND gear/artifact equip/unequip in one screen, split
## into "Weapons", "Armor", and "Artifacts" tabs - one "Armory" building in
## Town handles all three now, rather than separate stations. The Weapons
## tab shows the GLOBAL weapon pool (every class is eligible for every
## weapon once unlocked - see ClassData.allowed_weapons), gated by
## SaveManager.owns_weapon() rather than filtered by class at all; only
## Gacha (or a class's own free starter) grants ownership.

const SLOT_NAMES := ["Helmet", "Chest", "Gloves", "Boots"]
const ARTIFACT_SLOT_NAMES := ["Amulet", "Ring"]

@onready var credits_label: Label = $VBoxContainer/CreditsLabel
@onready var weapon_card_list: VBoxContainer = $VBoxContainer/TabContainer/Weapons/ScrollContainer/WeaponCardList
@onready var equipped_row: HBoxContainer = $VBoxContainer/TabContainer/Armor/ScrollContainer/ArmorContent/EquippedRow
@onready var gear_inventory_list: VBoxContainer = $VBoxContainer/TabContainer/Armor/ScrollContainer/ArmorContent/GearInventoryList
@onready var artifact_equipped_row: HBoxContainer = $VBoxContainer/TabContainer/Artifacts/ScrollContainer/ArtifactContent/EquippedRow
@onready var artifact_inventory_list: VBoxContainer = $VBoxContainer/TabContainer/Artifacts/ScrollContainer/ArtifactContent/ArtifactInventoryList
@onready var back_button: Button = $VBoxContainer/BackButton

func _ready() -> void:
	back_button.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/main/Town.tscn"))
	_populate()

func _populate() -> void:
	credits_label.text = "Credits: %d" % SaveManager.get_credits()
	_populate_weapons()
	_populate_gear()
	_populate_artifacts()

func _populate_weapons() -> void:
	for child in weapon_card_list.get_children():
		child.queue_free()

	for weapon: WeaponData in DataFolder.list_resources("res://data/weapons"):
		var owned: bool = SaveManager.owns_weapon(weapon.id)
		var is_equipped: bool = weapon == GameState.equipped_weapon
		var button := Button.new()
		button.custom_minimum_size = Vector2(0, 130)
		button.add_theme_font_size_override("font_size", 30)
		if owned:
			var rank_text: String = " ★%d" % SaveManager.get_weapon_rank(weapon.id)
			button.text = "%s%s%s\n%s" % [weapon.weapon_name, rank_text, " (equipped)" if is_equipped else "", weapon.description]
			button.disabled = is_equipped
			button.pressed.connect(_on_weapon_selected.bind(weapon))
		else:
			var rarity_text: String = "Rare" if weapon.rarity == WeaponData.Rarity.RARE else "Common"
			button.text = "%s (Locked - %s)\nUnlock via Gacha" % [weapon.weapon_name, rarity_text]
			button.disabled = true
		weapon_card_list.add_child(button)

func _on_weapon_selected(weapon: WeaponData) -> void:
	GameState.equipped_weapon = weapon
	_populate()

func _populate_gear() -> void:
	for child in equipped_row.get_children():
		child.queue_free()
	for slot in range(SLOT_NAMES.size()):
		equipped_row.add_child(_build_equipped_card(slot))

	for child in gear_inventory_list.get_children():
		child.queue_free()
	var inventory := SaveManager.get_inventory()
	for i in inventory.size():
		gear_inventory_list.add_child(_build_inventory_card(inventory[i], i))

func _build_equipped_card(slot: int) -> Button:
	var piece: GearPieceData = GearManager.equipped_pieces[slot]
	var button := Button.new()
	button.custom_minimum_size = Vector2(280, 160)
	button.add_theme_font_size_override("font_size", 20)
	if piece:
		button.text = "%s\n%s\n(tap to unequip)" % [SLOT_NAMES[slot], piece.piece_name]
	else:
		button.text = "%s\n(empty)" % SLOT_NAMES[slot]
		button.disabled = true
	button.pressed.connect(_on_unequip.bind(slot))
	return button

func _build_inventory_card(piece: GearPieceData, index: int) -> Button:
	var button := Button.new()
	button.custom_minimum_size = Vector2(0, 110)
	button.add_theme_font_size_override("font_size", 26)
	button.text = "%s (%s)\n%s +%s" % [
		piece.piece_name,
		SLOT_NAMES[piece.slot],
		piece.main_stat.stat_name,
		("%d%%" % roundi(piece.main_stat.percent_bonus * 100.0)) if piece.main_stat.percent_bonus != 0.0
			else ("%d%%" % roundi(piece.main_stat.flat_bonus * 100.0)),
	]
	button.pressed.connect(_on_equip.bind(piece, index))
	return button

func _on_equip(piece: GearPieceData, inventory_index: int) -> void:
	SaveManager.remove_from_inventory(inventory_index)
	var bumped: GearPieceData = GearManager.equip(piece)
	if bumped:
		SaveManager.add_to_inventory(bumped)
	_populate()

func _on_unequip(slot: int) -> void:
	var piece: GearPieceData = GearManager.unequip(slot)
	if piece:
		SaveManager.add_to_inventory(piece)
	_populate()

func _populate_artifacts() -> void:
	for child in artifact_equipped_row.get_children():
		child.queue_free()
	for slot in range(ARTIFACT_SLOT_NAMES.size()):
		artifact_equipped_row.add_child(_build_artifact_equipped_card(slot))

	for child in artifact_inventory_list.get_children():
		child.queue_free()
	var inventory := SaveManager.get_artifact_inventory()
	for i in inventory.size():
		artifact_inventory_list.add_child(_build_artifact_inventory_card(inventory[i], i))

func _build_artifact_equipped_card(slot: int) -> Button:
	var piece: ArtifactPieceData = ArtifactManager.equipped_pieces[slot]
	var button := Button.new()
	button.custom_minimum_size = Vector2(280, 160)
	button.add_theme_font_size_override("font_size", 20)
	if piece:
		button.text = "%s\n%s\n(tap to unequip)" % [ARTIFACT_SLOT_NAMES[slot], piece.piece_name]
	else:
		button.text = "%s\n(empty)" % ARTIFACT_SLOT_NAMES[slot]
		button.disabled = true
	button.pressed.connect(_on_artifact_unequip.bind(slot))
	return button

func _build_artifact_inventory_card(piece: ArtifactPieceData, index: int) -> Button:
	var button := Button.new()
	button.custom_minimum_size = Vector2(0, 110)
	button.add_theme_font_size_override("font_size", 26)
	button.text = "%s (%s)\n%s +%s" % [
		piece.piece_name,
		ARTIFACT_SLOT_NAMES[piece.slot],
		piece.main_stat.stat_name,
		("%d%%" % roundi(piece.main_stat.percent_bonus * 100.0)) if piece.main_stat.percent_bonus != 0.0
			else ("%d%%" % roundi(piece.main_stat.flat_bonus * 100.0)),
	]
	button.pressed.connect(_on_artifact_equip.bind(piece, index))
	return button

func _on_artifact_equip(piece: ArtifactPieceData, inventory_index: int) -> void:
	SaveManager.remove_artifact_from_inventory(inventory_index)
	var bumped: ArtifactPieceData = ArtifactManager.equip(piece)
	if bumped:
		SaveManager.add_artifact_to_inventory(bumped)
	_populate()

func _on_artifact_unequip(slot: int) -> void:
	var piece: ArtifactPieceData = ArtifactManager.unequip(slot)
	if piece:
		SaveManager.add_artifact_to_inventory(piece)
	_populate()
