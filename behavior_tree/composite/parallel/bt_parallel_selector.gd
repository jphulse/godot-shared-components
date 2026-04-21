class_name BTParallelSelector
extends BTComposite

## Runs all children in order, returns success on the first success, returns failure if they all fail
## and running if at least one was running and none succeeded
func tick(actor : Node, blackboard : Dictionary) -> Status:
	if behavior_children.is_empty():
		return Status.FAILURE

	var failure_count : int = 0

	for child : BehaviorNode in behavior_children:
		var result : Status = child.tick(actor, blackboard)

		match result:
			Status.SUCCESS:
				return Status.SUCCESS
			Status.FAILURE:
				failure_count += 1
			Status.RUNNING:
				pass

	if failure_count == behavior_children.size():
		return Status.FAILURE

	return Status.RUNNING
