class_name BTCondition
extends BTLeafNode

## Optional node that owns the condition method.
## If unset, this condition calls the actor passed into tick().
@export var target_path: NodePath

## Method to call.
## Expected signature:
##     func method_name(actor: Node, blackboard: Dictionary) -> bool
##
## Returning BehaviorNode.Status is also allowed for convenience.
@export var method_name: StringName = &""

@export var debug_name: String = "Condition"

var target: Node = null


func _ready() -> void:
	if target_path != NodePath():
		target = get_node_or_null(target_path)


func tick(actor: Node, blackboard: Dictionary) -> Status:
	var callable_target: Node = target

	if callable_target == null:
		callable_target = actor

	if callable_target == null:
		push_error("%s has no target and no actor was provided." % debug_name)
		return Status.FAILURE

	if method_name == &"":
		push_error("%s has no method_name assigned." % debug_name)
		return Status.FAILURE

	if not callable_target.has_method(method_name):
		push_error("%s target does not have method '%s'." % [debug_name, method_name])
		return Status.FAILURE

	var result: Variant = callable_target.call(method_name, actor, blackboard)

	if result is bool:
		return Status.SUCCESS if result else Status.FAILURE

	if result is Status:
		return result

	push_error("%s method '%s' must return bool or BehaviorNode.Status." % [debug_name, method_name])
	return Status.FAILURE
