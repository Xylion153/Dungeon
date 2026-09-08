class_name QuestData
extends Resource
## A hand-authored, non-refreshing quest (Tutorial/Side/Main). The rotating
## Job Board's bounties are the procedural counterpart - see job_generator.gd
## - and are never saved as .tres, since they reroll rather than being
## fixed content.

enum Category { TUTORIAL, SIDE, MAIN }
enum ObjectiveType { KILL_COUNT, CLEAR_CONTENT }

@export var id: String
@export var display_name: String
@export var description: String
@export var category: Category = Category.TUTORIAL
@export var objective_type: ObjectiveType = ObjectiveType.KILL_COUNT
@export var objective_target: String = "" ## "" for KILL_COUNT, "raid"/"depths" for CLEAR_CONTENT
@export var target_count: int = 1
@export var reward_credits: int = 0
@export var reward_gems: int = 0
@export var requires_quest_id: String = "" ## "" = always unlocked; else must be claimed first
