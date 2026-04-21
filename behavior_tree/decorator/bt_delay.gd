class_name BTDelay
extends BTDecorator

var delay_seconds : float = 1.0
var start_time_msec : int = -1


func _init(_child : BehaviorNode = null, _delay_seconds : float = 1.0) -> void:
	child = _child
	delay_seconds = _delay_seconds

## Forces a delay on running child by returning RUNNING unless it is ready to run
func tick(actor : Node, blackboard : Dictionary) -> Status:
	if child == null:
		return Status.FAILURE

	if start_time_msec < 0:
		start_time_msec = Time.get_ticks_msec()

	var elapsed_seconds : float = float(Time.get_ticks_msec() - start_time_msec) / 1000.0

	if elapsed_seconds < delay_seconds:
		return Status.RUNNING

	var result : Status = child.tick(actor, blackboard)

	if result != Status.RUNNING:
		start_time_msec = -1

	return result


func reset() -> void:
	start_time_msec = -1
	super.reset()
