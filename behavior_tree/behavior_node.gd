class_name BehaviorNode
extends RefCounted

enum Status {
	SUCCESS,
	FAILURE,
	RUNNING
}

## tick intended for call by behavior tree, specifically by the parent of this node in the tree
func tick(actor : Node, blackboard : Dictionary) -> Status:
	return Status.FAILURE

func reset() -> void:
	pass
