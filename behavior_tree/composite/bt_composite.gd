class_name BTComposite
extends BehaviorNode

var children : Array[BehaviorNode] = []


func add_child_node(child : BehaviorNode) -> void:
	assert(child != null, "Tried to add a null child to a composite node")
	children.append(child)

func remove_child_node(child : BehaviorNode) -> void:
	children.erase(child)


func clear_children() -> void:
	children.clear()


func get_child_count() -> int:
	return children.size()


func reset() -> void:
	for child : BehaviorNode in children:
		child.reset()
