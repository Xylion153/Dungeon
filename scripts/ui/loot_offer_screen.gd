extends CanvasLayer
## Loot-offer popup (brief section 5): shown after a wave clears, roll
## already made by the caller (arena.gd) via GearRoller. Equip or Skip.

const RARITY_COLORS := [
	Color(0.85, 0.85, 0.85), # Common
	Color(0.35, 0.65, 1.0),  # Rare
	Color(0.75, 0.35, 0.95), # Epic
	Color(1.0, 0.75, 0.2),   # Mythic
]

const STAT_LABELS := {
	"max_health": "Max Health",
	"damage_multiplier": "Damage",
	"move_speed": "Move Speed",
	"attack_speed_multiplier": "Attack Speed",
	"crit_chance": "Crit Chance",
	"crit_damage": "Crit Damage",
}

@onready var panel: Panel = $Panel
@onready var name_label: Label = $Panel/VBoxContainer/NameLabel
@onready var slot_label: Label = $Panel/VBoxContainer/SlotLabel
@onready var main_stat_label: Label = $Panel/VBoxContainer/MainStatLabel
@onready var sub_stats_label: Label = $Panel/VBoxContainer/SubStatsLabel
@onready var equip_button: Button = $Panel/VBoxContainer/HBoxContainer/EquipButton
@onready var skip_button: Button = $Panel/VBoxContainer/HBoxContainer/SkipButton

var _piece: GearPieceData

func _ready() -> void:
	visible = false
	equip_button.pressed.connect(_on_equip_pressed)
	skip_button.pressed.connect(_on_skip_pressed)

func show_offer(piece: GearPieceData) -> void:
	_piece = piece
	var rarity_color: Color = RARITY_COLORS[piece.rarity]

	name_label.text = piece.piece_name
	name_label.add_theme_color_override("font_color", rarity_color)
	slot_label.text = "Slot: %s" % GearPieceData.Slot.keys()[piece.slot].capitalize()
	main_stat_label.text = "Main: %s" % _format_stat(piece.main_stat)

	var sub_lines := PackedStringArray()
	for sub in piece.sub_stats:
		sub_lines.append(_format_stat(sub))
	sub_stats_label.text = "Sub-stats:\n" + "\n".join(sub_lines)

	visible = true

func _format_stat(modifier: StatModifierData) -> String:
	var label: String = STAT_LABELS.get(modifier.stat_name, modifier.stat_name)
	if modifier.percent_bonus != 0.0:
		return "%s +%d%%" % [label, roundi(modifier.percent_bonus * 100.0)]
	return "%s +%d%%" % [label, roundi(modifier.flat_bonus * 100.0)]

func _on_equip_pressed() -> void:
	if _piece:
		GearManager.equip(_piece)
	visible = false

func _on_skip_pressed() -> void:
	visible = false
