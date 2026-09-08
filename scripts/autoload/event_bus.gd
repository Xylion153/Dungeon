extends Node
## Global signal hub. Gear-set 4-piece procs will connect to these when a
## set becomes active and disconnect when it's no longer equipped, so no
## effect can outlive its gear (brief section 9).

signal crit_landed(attacker: Node, target: Node, damage: float)
signal enemy_killed(attacker: Node, enemy: Node, killing_blow_damage: float)
signal dash_started(actor: Node)
signal dash_ended(actor: Node)
signal damage_dealt(attacker: Node, target: Node, damage: float, is_crit: bool)
signal skill_cast(actor: Node, cooldown: float)
signal wave_started(wave_number: int)
signal wave_cleared(wave_number: int)
signal content_cleared(content_id: String) ## emitted when a full run of a content type finishes - "raid", "depths"
