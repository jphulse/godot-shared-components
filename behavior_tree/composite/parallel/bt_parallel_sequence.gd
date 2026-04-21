class_name BTParallelSequence
extends BTComposite

## Does a sequence operation where all children are run in sequence, if any fail it leaves early and 
## returns failure, otherwise checks total success and if they all succeeded it returns success else
## at least one was running so it returns running
func tick(actor : Node, blackboard : Dictionary) -> Status:
	if behavior_children.is_empty():
		return Status.SUCCESS

	var success_count : int = 0

	for child : BehaviorNode in behavior_children:
		var result : Status = child.tick(actor, blackboard)

		match result:
			Status.SUCCESS:
				success_count += 1
			Status.FAILURE:
				return Status.FAILURE
			Status.RUNNING:
				pass

	if success_count == behavior_children.size():
		return Status.SUCCESS

	return Status.RUNNING
