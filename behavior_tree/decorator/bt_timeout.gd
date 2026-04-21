class_name BTTimeout
extends BTDecorator

var timeout_seconds : float = 1.0
var start_time_msec : int = -1


func _init(_child : BehaviorNode = null, _timeout_seconds : float = 1.0) -> void:
	child = _child
	timeout_seconds = maxf(_timeout_seconds, 0.0)

## Ticks the child node with a time limit.
##
## Returns the child's result if it finishes before timeout_seconds. If the child
## is still running after the timeout is reached, resets the child and returns
## FAILURE.
func tick(actor : Node, blackboard : Dictionary) -> Status:
	if child == null:
		return Status.FAILURE

	if start_time_msec < 0:
		start_time_msec = Time.get_ticks_msec()

	var elapsed_seconds : float = float(Time.get_ticks_msec() - start_time_msec) / 1000.0

	if elapsed_seconds >= timeout_seconds:
		start_time_msec = -1
		child.reset()
		return Status.FAILURE

	var result : Status = child.tick(actor, blackboard)

	if result != Status.RUNNING:
		start_time_msec = -1

	return result


func reset() -> void:
	start_time_msec = -1
	super.reset()
