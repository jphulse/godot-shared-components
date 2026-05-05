class_name ConditionalLockComponent
extends Node

enum RequirementMode {
	ALL,
	ANY,
	EXACTLY_ONE,
	AT_LEAST_COUNT,
	EXACTLY_COUNT,
}

## Emitted when the lock becomes satisfied.
signal unlocked(lock: ConditionalLockComponent)

## Emitted when the lock becomes unsatisfied after previously being unlocked.
signal locked(lock: ConditionalLockComponent)

## Emitted when a condition changes state.
signal condition_changed(condition_id: StringName, is_met: bool)

## Emitted whenever the lock is evaluated.
signal evaluated(lock: ConditionalLockComponent, is_unlocked: bool)

## Conditions required by this lock.
@export var required_conditions: Array[StringName] = []

## Whether the lock can become locked again after unlocking.
@export var can_relock: bool = false

## Whether the lock should evaluate itself during ready.
@export var evaluate_on_ready: bool = true

## How this lock decides whether its conditions are satisfied.
@export var requirement_mode: RequirementMode = RequirementMode.ALL

## Count used by AT_LEAST_COUNT and EXACTLY_COUNT modes.
@export var required_count: int = 1

## Current runtime state for each condition.
var condition_states: Dictionary[StringName, bool] = {}

## Whether the lock is currently unlocked.
var is_unlocked: bool = false

## Whether the runtime condition dictionary has been initialized.
var _is_initialized: bool = false


## Initializes the lock's runtime condition state.
func _ready() -> void:
	initialize_conditions()

	if evaluate_on_ready:
		evaluate()


## Initializes the runtime condition dictionary from the required condition list.
func initialize_conditions() -> void:
	if _is_initialized:
		return

	for condition_id: StringName in required_conditions:
		if not condition_states.has(condition_id):
			condition_states[condition_id] = false

	_is_initialized = true


## Marks a condition as satisfied.
func meet_condition(condition_id: StringName) -> void:
	set_condition_state(condition_id, true)


## Marks a condition as unsatisfied.
func unmeet_condition(condition_id: StringName) -> void:
	set_condition_state(condition_id, false)


## Sets the runtime state of a condition.
func set_condition_state(condition_id: StringName, is_met: bool) -> void:
	initialize_conditions()

	if not condition_states.has(condition_id):
		push_warning("Unknown lock condition: %s" % condition_id)
		return

	if condition_states[condition_id] == is_met:
		return

	condition_states[condition_id] = is_met
	condition_changed.emit(condition_id, is_met)
	evaluate()


## Returns true if this lock contains the given condition.
func has_condition(condition_id: StringName) -> bool:
	initialize_conditions()
	return condition_states.has(condition_id)


## Returns whether the given condition is currently met.
func is_condition_met(condition_id: StringName) -> bool:
	initialize_conditions()
	return condition_states.get(condition_id, false)


## Returns true if the lock's conditions satisfy the current requirement mode.
func are_conditions_met() -> bool:
	initialize_conditions()

	var met_count : int = get_met_condition_count()
	var total_count : int = required_conditions.size()

	match requirement_mode:
		RequirementMode.ALL:
			return met_count == total_count

		RequirementMode.ANY:
			return met_count > 0

		RequirementMode.EXACTLY_ONE:
			return met_count == 1

		RequirementMode.AT_LEAST_COUNT:
			return met_count >= required_count

		RequirementMode.EXACTLY_COUNT:
			return met_count == required_count

		_:
			return false


## Returns the number of currently satisfied conditions.
func get_met_condition_count() -> int:
	var count : int = 0

	for condition_id: StringName in required_conditions:
		if condition_states.get(condition_id, false):
			count += 1

	return count


## Evaluates the lock and emits state-change signals if needed.
func evaluate() -> void:
	initialize_conditions()

	var should_be_unlocked : bool = are_conditions_met()

	if should_be_unlocked:
		if not is_unlocked:
			is_unlocked = true
			unlocked.emit(self)

		evaluated.emit(self, is_unlocked)
		return

	if is_unlocked and can_relock:
		is_unlocked = false
		locked.emit(self)

	evaluated.emit(self, is_unlocked)


## Resets every condition to unmet and optionally relocks this component.
func reset_conditions(relock: bool = true) -> void:
	initialize_conditions()

	for condition_id: StringName in required_conditions:
		condition_states[condition_id] = false
		condition_changed.emit(condition_id, false)

	if relock:
		is_unlocked = false

	evaluate()


## Forces the lock into the unlocked state.
func force_unlock() -> void:
	if is_unlocked:
		evaluated.emit(self, true)
		return

	is_unlocked = true
	unlocked.emit(self)
	evaluated.emit(self, true)


## Forces the lock into the locked state.
func force_lock() -> void:
	if not is_unlocked:
		evaluated.emit(self, false)
		return

	is_unlocked = false
	locked.emit(self)
	evaluated.emit(self, false)
