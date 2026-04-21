class_name BTActionCallable
extends BehaviorNode

## The action executed every tick
var action : Callable
var debug_name : String 

func _init(_action : Callable, _debug_name : String = "action") -> void:
	action = _action
	debug_name = _debug_name

## Calls the assigned action callable and gives it actor and blackboard
func tick(actor : Node, blackboard : Dictionary) -> Status:
	if not action.is_valid():
		return Status.FAILURE
	var result : Variant = action.call(actor, blackboard)
	if result is Status:
		return result
	push_error("leaf node action function did not return a BehaviorNode.Status, this is required for expected behavior")
	return Status.FAILURE
