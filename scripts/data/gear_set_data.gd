class_name GearSetData
extends Resource
## A themed gear set's 2-piece and 4-piece bonuses. The 2-piece bonus is a
## flat stat modifier; the 4-piece bonus is mechanically distinct (a proc),
## so it isn't data here — it will be implemented as an EventBus subscription
## that's connected when the set becomes active and disconnected when it
## isn't (brief section 9), keyed off set_id. This resource just carries the
## flavor text and the 2-piece numbers.

@export var set_name := ""
@export var set_id := ""
@export var two_piece_bonus: Array[StatModifierData] = []
@export var four_piece_description := ""
