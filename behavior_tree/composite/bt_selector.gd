class_name BTSelector
extends BTComposite



## The tick function for the sequence node, iterates all children until one passes or runs in order
## Returns Failure if all fail, otherwise returns the first non-failing result
func tick(actor : Node, blackboard : Dictionary) -> Status:
	for child : BehaviorNode in children:
		var result : Status = child.tick(actor, blackboard)
		
		if result != Status.FAILURE:
			return result
			
	return Status.FAILURE
