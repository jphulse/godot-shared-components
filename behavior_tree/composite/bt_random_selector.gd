class_name BTRandomSelector
extends BTComposite

## Shuffles children and returns the first non failure, or failure if they all fail
func tick(actor : Node, blackboard : Dictionary) -> Status:
	if behavior_children.is_empty():
		return Status.FAILURE

	var shuffled_children : Array[BehaviorNode] = behavior_children.duplicate()
	shuffled_children.shuffle()

	for child : BehaviorNode in shuffled_children:
		var result : Status = child.tick(actor, blackboard)

		match result:
			Status.SUCCESS:
				return Status.SUCCESS

			Status.RUNNING:
				return Status.RUNNING

			Status.FAILURE:
				continue

	return Status.FAILURE
