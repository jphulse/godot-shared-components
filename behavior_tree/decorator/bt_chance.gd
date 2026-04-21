class_name BTChance
extends BTDecorator

var success_chance : float = 0.5
var roll_once_while_running : bool = true

var has_active_roll : bool = false
var active_roll_passed : bool = false


func _init(
	_child : BehaviorNode = null,
	_success_chance : float = 0.5,
	_roll_once_while_running : bool = true
) -> void:
	child = _child
	success_chance = clampf(_success_chance, 0.0, 1.0)
	roll_once_while_running = _roll_once_while_running

## Random chance decorator that gives the node a random chance of being run or being skipped
func tick(actor : Node, blackboard : Dictionary) -> Status:
	if child == null:
		return Status.FAILURE

	if not roll_once_while_running:
		if randf() > success_chance:
			return Status.FAILURE

		return child.tick(actor, blackboard)

	if not has_active_roll:
		has_active_roll = true
		active_roll_passed = randf() <= success_chance

	if not active_roll_passed:
		has_active_roll = false
		return Status.FAILURE

	var result : Status = child.tick(actor, blackboard)

	if result != Status.RUNNING:
		has_active_roll = false
		active_roll_passed = false

	return result


func reset() -> void:
	has_active_roll = false
	active_roll_passed = false
	super.reset()
