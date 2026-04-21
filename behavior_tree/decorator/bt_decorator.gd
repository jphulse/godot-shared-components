class_name BTDecorator
extends BehaviorNode

var child : BehaviorNode = null

func _init(_child : BehaviorNode = null) -> void:
	if child != null:
		set_child(_child)

func set_child(new_child : BehaviorNode) -> void:
	assert(new_child != null, "Tried to set a null child on a decorator node")
	assert(new_child != self, "Tried to make a circular decorator by adding itself as a child")
	if child and child.parent == self:
		child.parent = null
	child = new_child
	child.parent = self

func reset() -> void:
	if child != null:
		child.reset()

func swap_child(old_child : BehaviorNode, new_child : BehaviorNode, append_child_to_composite_if_not_found : bool = false) -> void:
	if child == old_child:
		set_child(new_child)
	else :
		push_warning("Tried to swap children on a decorator from a node that is not the decorator's child")
