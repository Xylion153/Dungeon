class_name JobGenerator
extends RefCounted
## Rolls a single Job Board bounty ("hunting mission") - kill-count only,
## since the game has no per-enemy-type id today (EventBus.enemy_killed
## passes the node, not a type tag) to support "hunt N Rangers" style
## targeting. Not a Resource/.tres like QuestData - jobs are rolled fresh
## each rotation, never hand-authored content.

const MIN_TARGET := 10
const MAX_TARGET := 25
const CREDITS_PER_KILL := 3
const GEMS_PER_KILL := 2

static func roll() -> Dictionary:
	var target := randi_range(MIN_TARGET, MAX_TARGET)
	return {
		"target_count": target,
		"progress": 0,
		"reward_credits": target * CREDITS_PER_KILL,
		"reward_gems": target * GEMS_PER_KILL,
		"accepted": false,
		"claimed": false,
	}

static func roll_batch(count: int) -> Array:
	var jobs: Array = []
	for i in count:
		jobs.append(roll())
	return jobs
