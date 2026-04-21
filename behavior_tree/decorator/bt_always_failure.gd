class_name BTAlwaysFailure
extends BTDecorator

## Always returns failure unless the child is running
func tick(actor : Node, blackboard : Dictionary) -> Status:
	if child == null:
		return Status.FAILURE

	var result : Status = child.tick(actor, blackboard)

	if result == Status.RUNNING:
		return Status.RUNNING

	return Status.FAILURE
