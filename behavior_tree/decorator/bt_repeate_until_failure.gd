class_name BTRepeatUntilFailure
extends BTDecorator

## Returns running on Running and success from the child, resets the child when it finishes but keeps 
## rerunning until failure and then returns success on failure
func tick(actor : Node, blackboard : Dictionary) -> Status:
	if child == null:
		return Status.FAILURE

	var result : Status = child.tick(actor, blackboard)

	match result:
		Status.RUNNING:
			return Status.RUNNING

		Status.FAILURE:
			child.reset()
			return Status.SUCCESS

		Status.SUCCESS:
			child.reset()
			return Status.RUNNING

	return Status.FAILURE


func reset() -> void:
	super.reset()
