extends Node
## Tracks equipped Artifacts and aggregates their stat modifiers for Player -
## the Artifacts-side sibling of GearManager (scripts/autoload/gear_manager.gd),
## kept as a separate parallel system rather than sharing code with it (only
## two systems exist so far, not enough repetition to justify factoring out
## a shared base - matches how LootPickup/TownStation and ArmoryMenu/
## SkillsMenu each separately implement their own similar pattern elsewhere
## in this project).
##
## No proc machinery here, deliberately: with only 2 slots, "both equipped"
## already means "the whole set" - there's no partial-vs-full tier to gate a
## proc on, so the set bonus is just an always-on passive modifier once both
## pieces share a set_id. Procs stay a Gear-only identity.

signal artifacts_changed

const SLOT_COUNT := 2 # ArtifactPieceData.Slot has 2 values

var equipped_pieces: Array = [null, null]

func equip(piece: ArtifactPieceData) -> ArtifactPieceData:
	var previous: ArtifactPieceData = equipped_pieces[piece.slot]
	equipped_pieces[piece.slot] = piece
	_refresh()
	return previous

func unequip(slot: int) -> ArtifactPieceData:
	var previous: ArtifactPieceData = equipped_pieces[slot]
	equipped_pieces[slot] = null
	_refresh()
	return previous

func get_all_modifiers() -> Array[StatModifierData]:
	var modifiers: Array[StatModifierData] = []
	for piece in equipped_pieces:
		if piece == null:
			continue
		if piece.main_stat:
			modifiers.append(piece.main_stat)
		modifiers.append_array(piece.sub_stats)

	var set_id := _matched_set_id()
	if set_id != "":
		var set_data := _find_set(set_id)
		if set_data:
			modifiers.append_array(set_data.set_bonus)
	return modifiers

## Both slots filled with the same non-empty set_id -> that set's bonus is active.
func _matched_set_id() -> String:
	var first: ArtifactPieceData = equipped_pieces[0]
	var second: ArtifactPieceData = equipped_pieces[1]
	if first == null or second == null or first.set_id == "":
		return ""
	if first.set_id == second.set_id:
		return first.set_id
	return ""

func _find_set(set_id: String) -> ArtifactSetData:
	for set_data in DataFolder.list_resources("res://data/artifact_sets"):
		if set_data.set_id == set_id:
			return set_data
	return null

func _refresh() -> void:
	artifacts_changed.emit()
