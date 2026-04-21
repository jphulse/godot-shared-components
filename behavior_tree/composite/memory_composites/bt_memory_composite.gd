class_name BTMemoryComposite
extends BTComposite

var running_index: int = -1
var running_child: BehaviorNode = null


func reset() -> void:
	clear_running_state()
	super.reset()


func clear_running_state() -> void:
	running_index = -1
	running_child = null


func has_running_child() -> bool:
	if running_child != null:
		return true

	return running_index >= 0 and running_index < behavior_children.size()


func get_running_child() -> BehaviorNode:
	if running_child != null:
		# Optional safety check in case the child was removed from this composite.
		if running_child.get_parent() == self:
			return running_child

		running_child = null

	if running_index >= 0 and running_index < behavior_children.size():
		return behavior_children[running_index]

	return null


func set_running_child(child: BehaviorNode) -> void:
	if child == null:
		clear_running_state()
		return

	var idx := behavior_children.find(child)

	if idx == -1:
		push_warning("Tried to set a running child that is not a child of this memory composite.")
		clear_running_state()
		return

	running_child = child
	running_index = idx


func set_running_index(index: int) -> void:
	if index < 0 or index >= behavior_children.size():
		clear_running_state()
		return

	running_index = index
	running_child = behavior_children[index]
