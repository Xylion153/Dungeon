extends Node
## Global signal hub. Gear-set 4-piece procs will connect to these when a
## set becomes active and disconnect when it's no longer equipped, so no
## effect can outlive its gear (brief section 9).

signal crit_landed(attacker: Node, target: Node, damage: float)
signal enemy_killed(attacker: Node, enemy: Node)
signal dash_started(actor: Node)
signal dash_ended(actor: Node)
signal damage_dealt(attacker: Node, target: Node, damage: float, is_crit: bool)
