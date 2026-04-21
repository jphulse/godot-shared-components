class_name BTMemorySequence
extends BTMemoryComposite

## Index based memory sequence that continues from where it left off, otherwise runs like a normal sequence
func tick(actor : Node, blackboard : Dictionary) -> Status:
	while running_index < behavior_children.size():
		var child : BehaviorNode = behavior_children[running_index]
		var result : Status = child.tick(actor, blackboard)

		match result:
			Status.SUCCESS:
				running_index += 1

			Status.RUNNING:
				return Status.RUNNING

			Status.FAILURE:
				running_index = 0
				return Status.FAILURE

	running_index = 0
	return Status.SUCCESS
