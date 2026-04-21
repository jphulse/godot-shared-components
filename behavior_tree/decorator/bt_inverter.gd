class_name BTInverter
extends BTDecorator



## Returns the child's tick value inverted
## Success -> Failure
## Failure -> Success
## Running -> Running
## Always fails if the status is unrecognized or child is null
func tick(actor : Node, blackboard : Dictionary) -> Status:
	if child == null:
		return Status.FAILURE
	
	var result : Status = child.tick(actor, blackboard)
	
	match result:
		Status.SUCCESS:
			return Status.FAILURE
		Status.FAILURE:
			return Status.SUCCESS
		Status.RUNNING:
			return Status.RUNNING
	
	return Status.FAILURE
