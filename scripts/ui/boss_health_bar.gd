extends CanvasLayer
## Minimal top-of-screen boss health bar. Polls the boss's health each frame
## rather than needing a new health-changed signal threaded through
## DamageResolver — simplest option for a first pass, only shown while a
## boss is alive in the scene.

@onready var bar: ProgressBar = $Panel/ProgressBar
@onready var label: Label = $Panel/Label

var _boss: Node = null

func _ready() -> void:
	visible = false

func _process(_delta: float) -> void:
	if _boss == null or not is_instance_valid(_boss):
		_boss = get_tree().get_first_node_in_group("boss")
		visible = _boss != null
		if _boss == null:
			return

	bar.max_value = _boss.max_health
	bar.value = _boss.get_health()
	label.text = "Boss  %d / %d" % [int(_boss.get_health()), int(_boss.max_health)]
