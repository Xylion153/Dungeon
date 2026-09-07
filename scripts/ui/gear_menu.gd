extends Control
## Town stand-in (Town itself is Phase 5) for managing gear collected during
## runs: 4 equipped-slot cards up top (tap to unequip), a scrollable
## inventory list below (tap to equip) - same card-list pattern as
## Armory/Skills, just sourced from SaveManager's persistent inventory
## instead of a class's data.

const SLOT_NAMES := ["Helmet", "Chest", "Gloves", "Boots"]

@onready var credits_label: Label = $VBoxContainer/CreditsLabel
@onready var equipped_row: HBoxContainer = $VBoxContainer/EquippedRow
@onready var inventory_list: VBoxContainer = $VBoxContainer/ScrollContainer/InventoryList
@onready var back_button: Button = $VBoxContainer/BackButton

func _ready() -> void:
	back_button.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/main/Town.tscn"))
	_populate()

func _populate() -> void:
	credits_label.text = "Credits: %d" % SaveManager.get_credits()

	for child in equipped_row.get_children():
		child.queue_free()
	for slot in range(SLOT_NAMES.size()):
		equipped_row.add_child(_build_equipped_card(slot))

	for child in inventory_list.get_children():
		child.queue_free()
	var inventory := SaveManager.get_inventory()
	for i in inventory.size():
		inventory_list.add_child(_build_inventory_card(inventory[i], i))

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
