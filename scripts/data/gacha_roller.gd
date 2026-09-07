class_name GachaRoller
extends RefCounted
## Rolls one weapon or skill from the combined pool - mirrors GearRoller/
## ArtifactRoller's shape, but the pool is hand-authored content (via
## DataFolder auto-discovery) rather than procedurally rolled stats, so
## there's no piece-construction step - just picking which existing
## resource to grant.

const RARE_CHANCE := 0.3
const HARD_PITY_THRESHOLD := 10

## Returns a WeaponData or SkillData. pity_counter >= HARD_PITY_THRESHOLD
## forces a Rare regardless of the roll - the caller is responsible for
## persisting/resetting the actual pity counter based on the result.
static func roll(pity_counter: int) -> Variant:
	var weapons: Array = DataFolder.list_resources("res://data/weapons")
	var skills: Array = DataFolder.list_resources("res://data/skills")

	var common_pool: Array = []
	var rare_pool: Array = []
	for weapon in weapons:
		(rare_pool if weapon.rarity == WeaponData.Rarity.RARE else common_pool).append(weapon)
	for skill in skills:
		(rare_pool if skill.rarity == SkillData.Rarity.RARE else common_pool).append(skill)

	var want_rare: bool = pity_counter >= HARD_PITY_THRESHOLD or randf() < RARE_CHANCE
	var pool: Array = rare_pool if (want_rare and not rare_pool.is_empty()) else common_pool
	if pool.is_empty():
		pool = common_pool if not common_pool.is_empty() else rare_pool
	return pool[randi() % pool.size()]

## True if the given roll result is a Rare item - used by the caller to
## decide whether to reset the persisted pity counter.
static func is_rare(item: Variant) -> bool:
	if item is WeaponData:
		return item.rarity == WeaponData.Rarity.RARE
	if item is SkillData:
		return item.rarity == SkillData.Rarity.RARE
	return false
