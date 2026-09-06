class_name PlayerCombat
extends Node
## Combo/cooldown state machine. The cooldown timer starts ONLY when the
## final combo step's recovery finishes, never per-hit, and any attack
## input received during WINDUP/ACTIVE/COOLDOWN is simply dropped rather
## than restarting anything — this is the explicit mash-proofing the brief
## calls out as a real bug worth guarding against.

signal step_started(step_index: int, step: WeaponComboStepData)

enum State { IDLE, WINDUP, ACTIVE, RECOVERY, COOLDOWN }

var weapon: WeaponData
var state: State = State.IDLE
var current_step := 0
var state_timer := 0.0
var chain_buffered := false
var chain_window_timer := 0.0

var _actor: Node2D

func setup(actor: Node2D, weapon_data: WeaponData) -> void:
	_actor = actor
	weapon = weapon_data

func request_attack() -> void:
	match state:
		State.IDLE:
			_start_step(0)
		State.RECOVERY:
			if chain_window_timer > 0.0:
				chain_buffered = true
		_:
			pass # WINDUP / ACTIVE / COOLDOWN: mashing here must never retrigger anything

func can_dash_cancel() -> bool:
	if state != State.RECOVERY or weapon == null:
		return false
	var step := weapon.steps[current_step]
	return state_timer <= step.recovery * weapon.cancel_window

func cancel_into_dash() -> void:
	if state == State.RECOVERY:
		_finish_recovery()

func _start_step(index: int) -> void:
	current_step = index
	var step := weapon.steps[index]
	state = State.WINDUP
	state_timer = step.windup
	chain_buffered = false
	step_started.emit(index, step)

func _process(delta: float) -> void:
	if weapon == null or weapon.steps.is_empty():
		return

	if chain_window_timer > 0.0:
		chain_window_timer -= delta

	match state:
		State.WINDUP:
			state_timer -= delta
			if state_timer <= 0.0:
				_enter_active()
		State.ACTIVE:
			state_timer -= delta
			if state_timer <= 0.0:
				_enter_recovery()
		State.RECOVERY:
			state_timer -= delta
			if state_timer <= 0.0:
				_finish_recovery()
		State.COOLDOWN:
			state_timer -= delta
			if state_timer <= 0.0:
				state = State.IDLE
				current_step = 0

func _enter_active() -> void:
	var step := weapon.steps[current_step]
	state = State.ACTIVE
	state_timer = step.active
	if _actor.has_method("perform_step_hit"):
		_actor.perform_step_hit(step)

func _enter_recovery() -> void:
	var step := weapon.steps[current_step]
	state = State.RECOVERY
	state_timer = step.recovery
	chain_window_timer = weapon.combo_chain_window

func _finish_recovery() -> void:
	var is_last_step := current_step >= weapon.steps.size() - 1
	if chain_buffered and not is_last_step:
		_start_step(current_step + 1)
		return
	if is_last_step:
		state = State.COOLDOWN
		state_timer = weapon.cooldown
	else:
		state = State.IDLE
		current_step = 0
