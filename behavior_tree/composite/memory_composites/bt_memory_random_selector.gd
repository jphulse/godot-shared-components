class_name BTMemoryRandomSelector
extends BTMemoryComposite


## Random selector that shuffles children if there is not currently a running_child in memory
func tick(actor : Node, blackboard : Dictionary) -> Status:
	if behavior_children.is_empty():
		return Status.FAILURE

	if running_child != null:
		var running_result : Status = running_child.tick(actor, blackboard)

		if running_result == Status.RUNNING:
			return Status.RUNNING

		running_child = null
		return running_result

	var shuffled_children : Array[BehaviorNode] = behavior_children.duplicate()
	shuffled_children.shuffle()

	for child : BehaviorNode in shuffled_children:
		var result : Status = child.tick(actor, blackboard)

		if result == Status.RUNNING:
			running_child = child
			return Status.RUNNING

		if result == Status.SUCCESS:
			return Status.SUCCESS

	return Status.FAILURE


func reset() -> void:
	super.reset()
