extends Control
## Spends Credits: Consumables (one-run buffs, see GameState.apply_run_buffs())
## and repeatable rarity-capped Gear/Artifact purchases straight into the
## same persistent inventories a loot pickup would land in. No persistent
## shop stock to track - Gear/Artifact offers just re-roll on each purchase.

const EQUIPMENT_MAX_RARITY := 1 # GearPieceData.Rarity.RARE / ArtifactPieceData.Rarity.RARE
const EQUIPMENT_PRICE := 150

@onready var credits_label: Label = $VBoxContainer/CreditsLabel
@onready var consumable_list: VBoxContainer = $VBoxContainer/ScrollContainer/ContentList/ConsumableList
@onready var equipment_list: VBoxContainer = $VBoxContainer/ScrollContainer/ContentList/EquipmentList
@onready var back_button: Button = $VBoxContainer/BackButton

func _ready() -> void:
	back_button.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/main/Town.tscn"))
	_populate()

func _populate() -> void:
	credits_label.text = "Credits: %d" % SaveManager.get_credits()
	_populate_consumables()
	_populate_equipment()

func _populate_consumables() -> void:
	for child in consumable_list.get_children():
		child.queue_free()

	for consumable: ConsumableData in DataFolder.list_resources("res://data/consumables"):
		var owned := SaveManager.get_consumable_count(consumable.id)
		var affordable := SaveManager.get_credits() >= consumable.price
		var button := Button.new()
		button.custom_minimum_size = Vector2(0, 130)
		button.add_theme_font_size_override("font_size", 28)
		button.text = "%s — %d Credits (Owned: %d)\n%s" % [consumable.display_name, consumable.price, owned, consumable.description]
		button.disabled = not affordable
		button.pressed.connect(_on_buy_consumable.bind(consumable))
		consumable_list.add_child(button)

func _on_buy_consumable(consumable: ConsumableData) -> void:
	if SaveManager.get_credits() < consumable.price:
		return
	SaveManager.add_credits(-consumable.price)
	SaveManager.add_consumable(consumable.id)
	_populate()

func _populate_equipment() -> void:
	for child in equipment_list.get_children():
		child.queue_free()

	var gear_button := Button.new()
	gear_button.custom_minimum_size = Vector2(0, 110)
	gear_button.add_theme_font_size_override("font_size", 28)
	gear_button.text = "Buy Gear (Rare max) — %d Credits" % EQUIPMENT_PRICE
	gear_button.disabled = SaveManager.get_credits() < EQUIPMENT_PRICE
	gear_button.pressed.connect(_on_buy_gear)
	equipment_list.add_child(gear_button)

	var artifact_button := Button.new()
	artifact_button.custom_minimum_size = Vector2(0, 110)
	artifact_button.add_theme_font_size_override("font_size", 28)
	artifact_button.text = "Buy Artifact (Rare max) — %d Credits" % EQUIPMENT_PRICE
	artifact_button.disabled = SaveManager.get_credits() < EQUIPMENT_PRICE
	artifact_button.pressed.connect(_on_buy_artifact)
	equipment_list.add_child(artifact_button)

func _on_buy_gear() -> void:
	if SaveManager.get_credits() < EQUIPMENT_PRICE:
		return
	SaveManager.add_credits(-EQUIPMENT_PRICE)
	SaveManager.add_to_inventory(GearRoller.roll_piece(EQUIPMENT_MAX_RARITY))
	_populate()

func _on_buy_artifact() -> void:
	if SaveManager.get_credits() < EQUIPMENT_PRICE:
		return
	SaveManager.add_credits(-EQUIPMENT_PRICE)
	SaveManager.add_artifact_to_inventory(ArtifactRoller.roll_piece(EQUIPMENT_MAX_RARITY))
	_populate()
