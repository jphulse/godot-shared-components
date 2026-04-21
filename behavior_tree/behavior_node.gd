class_name BehaviorNode
extends Node

var parent : BehaviorNode = null
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

func swap_child(old_child : BehaviorNode, new_child : BehaviorNode, append_child_to_composite_if_not_found : bool = false, free_orphaned_nodes : bool = true) -> BehaviorNode:
	push_warning("swap_child() called on a BehaviorNode that does not support children.")
	return null

func add_decorator(decorator : BTDecorator) -> void:
	assert(decorator != null, "Tried to add a null decorator")
	decorator.parent = parent
	decorator.child = self
	if parent:
		parent.swap_child(self, decorator)
	parent = decorator
