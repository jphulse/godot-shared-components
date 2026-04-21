class_name BTConditionCallable
extends BTLeafNode

var condition : Callable
var debug_name : String

func _init(_condition: Callable = Callable(), _debug_name : String = "condition") -> void:
	condition = _condition
	debug_name = _debug_name


func tick(actor: Node, blackboard: Dictionary) -> Status:
	if not condition.is_valid():
		return Status.FAILURE

	var result: Variant = condition.call(actor, blackboard)

	if result is bool:
		return Status.SUCCESS if result else Status.FAILURE

	push_error("BTConditionCallable expected condition to return bool.")
	return Status.FAILURE
