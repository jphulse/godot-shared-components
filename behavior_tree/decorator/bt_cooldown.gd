class_name BTCooldown
extends BTDecorator

var cooldown_seconds : float = 1.0
var last_success_time_msec : int = -1


func _init(_child : BehaviorNode = null, _cooldown_seconds : float = 1.0) -> void:
	child = _child
	cooldown_seconds = _cooldown_seconds

## Enforces a cooldown on running the child node
func tick(actor : Node, blackboard : Dictionary) -> Status:
	if child == null:
		return Status.FAILURE

	var now : int = Time.get_ticks_msec()

	if last_success_time_msec >= 0:
		var elapsed_seconds : float = float(now - last_success_time_msec) / 1000.0

		if elapsed_seconds < cooldown_seconds:
			return Status.FAILURE

	var result : Status = child.tick(actor, blackboard)

	if result == Status.SUCCESS:
		last_success_time_msec = now

	return result


func reset() -> void:
	last_success_time_msec = -1
	super.reset()
