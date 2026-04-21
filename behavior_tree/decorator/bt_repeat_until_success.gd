class_name BTRepeatUntilSuccess
extends BTDecorator

## Repeats until success form the child and returns running in other cases.  
## By returning run that allows us to keep running
func tick(actor : Node, blackboard : Dictionary) -> Status:
	if child == null:
		return Status.FAILURE

	var result : Status = child.tick(actor, blackboard)

	match result:
		Status.RUNNING:
			return Status.RUNNING

		Status.SUCCESS:
			child.reset()
			return Status.SUCCESS

		Status.FAILURE:
			child.reset()
			return Status.RUNNING

	return Status.FAILURE


func reset() -> void:
	super.reset()
