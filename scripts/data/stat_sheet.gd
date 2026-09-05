class_name StatSheet
extends RefCounted
## Resolves base -> sum of flat bonuses -> apply percent bonuses, computed
## fresh whenever gear changes, rather than gear pieces mutating stats
## directly. This is what makes swapping gear safe and instant, with no
## stale leftover bonuses.

var base_stats: Dictionary = {}
var _modifiers: Array[StatModifierData] = []

func set_base(stat_name: String, value: float) -> void:
	base_stats[stat_name] = value

func set_modifiers(modifiers: Array[StatModifierData]) -> void:
	_modifiers = modifiers

func get_stat(stat_name: String) -> float:
	var base_value: float = base_stats.get(stat_name, 0.0)
	var flat_sum := 0.0
	var percent_sum := 0.0
	for modifier in _modifiers:
		if modifier.stat_name != stat_name:
			continue
		flat_sum += modifier.flat_bonus
		percent_sum += modifier.percent_bonus
	return (base_value + flat_sum) * (1.0 + percent_sum)
