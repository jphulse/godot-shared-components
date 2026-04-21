class_name BTMemoryComposite
extends BTComposite

var running_index : int = 0
var running_child : BehaviorNode = null


func reset() -> void:
	running_index = 0
	running_child = null
	super.reset()


func clear_running_state() -> void:
	running_index = 0
	running_child = null


func has_running_child() -> bool:
	return running_child != null or (running_index >= 0 and running_index < children.size())


func get_running_child() -> BehaviorNode:
	if running_child != null:
		return running_child

	if running_index >= 0 and running_index < children.size():
		return children[running_index]

	return null
