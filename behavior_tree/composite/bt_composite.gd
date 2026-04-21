class_name BTComposite
extends BehaviorNode

var children : Array[BehaviorNode] = []


func add_child_node(child : BehaviorNode) -> void:
	assert(child != null, "Tried to add a null child to a composite node")
	children.append(child)
	child.parent = self

func remove_child_node(child : BehaviorNode) -> void:
	children.erase(child)
	if child.parent == self:
		child.parent = null


func clear_children() -> void:
	for child : BehaviorNode in children:
		if child.parent == self:
			child.parent = null
	children.clear()


func get_child_count() -> int:
	return children.size()


func reset() -> void:
	for child : BehaviorNode in children:
		child.reset()

## Swaps the old_child with new child at the same spot, if the child is not found and append_child_to_children is true then it will
## add the new_child as a new child to parent otherwise it will do nothing in that case
func swap_child(old_child : BehaviorNode, new_child : BehaviorNode, append_child_to_children_if_not_found : bool = false) -> void:
		var idx : int = children.find(old_child)
		if idx == -1 and append_child_to_children_if_not_found:
			add_child_node(new_child)
		elif idx >= 0:
			children[idx] = new_child
			new_child.parent = self
