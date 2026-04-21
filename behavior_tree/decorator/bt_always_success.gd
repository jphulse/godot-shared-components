class_name BTAlwaysSuccess
extends BTDecorator

## Always returns success unless the child is running
func tick(actor : Node, blackboard : Dictionary) -> Status:
	if child == null:
		return Status.SUCCESS

	var result : Status = child.tick(actor, blackboard)

	if result == Status.RUNNING:
		return Status.RUNNING

	return Status.SUCCESS
