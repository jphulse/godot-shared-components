class_name BTSequence
extends BTComposite


## The tick function for the sequence node, iterates all children until one fails in order
## Returns Success if all pass, otherwise returns the first non-success result
func tick(actor : Node, blackboard : Dictionary) -> Status:
	for child : BehaviorNode in children:
		var result : Status = child.tick(actor, blackboard)
		
		if result != Status.SUCCESS:
			return result
			
	return Status.SUCCESS
