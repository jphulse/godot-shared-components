class_name BTMemorySelector
extends BTMemoryComposite

## Selector that iterates through children with a tracked remembered index
func tick(actor : Node, blackboard : Dictionary) -> Status:
	while running_index < children.size():
		var child : BehaviorNode = children[running_index]
		var result : Status = child.tick(actor, blackboard)

		match result:
			Status.FAILURE:
				running_index += 1

			Status.RUNNING:
				return Status.RUNNING

			Status.SUCCESS:
				running_index = 0
				return Status.SUCCESS

	running_index = 0
	return Status.FAILURE
