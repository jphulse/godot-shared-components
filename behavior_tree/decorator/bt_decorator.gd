class_name BTDecorator
extends BehaviorNode

var child : BehaviorNode = null

func _init(_child : BehaviorNode = null) -> void:
	child = _child

func set_child(new_child : BehaviorNode) -> void:
	assert(new_child != null, "Tried to set a null child on a decorator node")
	child = new_child

func reset() -> void:
	if child != null:
		child.reset()
