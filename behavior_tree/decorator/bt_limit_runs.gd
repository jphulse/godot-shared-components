class_name BTLimitRuns
extends BTDecorator

var max_runs : int = 1
var run_count : int = 0
var count_only_success : bool = true


func _init(
	_child : BehaviorNode = null,
	_max_runs : int = 1,
	_count_only_success : bool = true
) -> void:
	child = _child
	max_runs = _max_runs
	count_only_success = _count_only_success

## Only allows a total number of runs for the child tick, if this is exceeded will return failure
## until reset
func tick(actor : Node, blackboard : Dictionary) -> Status:
	if child == null:
		return Status.FAILURE

	if run_count >= max_runs:
		return Status.FAILURE

	var result : Status = child.tick(actor, blackboard)

	if result == Status.RUNNING:
		return Status.RUNNING

	if count_only_success:
		if result == Status.SUCCESS:
			run_count += 1
	else:
		run_count += 1

	return result


func reset() -> void:
	run_count = 0
	super.reset()
