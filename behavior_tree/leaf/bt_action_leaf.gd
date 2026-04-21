class_name BTAction
extends BTLeafNode

## Optional node that owns the method to call.
## If unset, this will default to the actor passed into tick().
@export var target_path: NodePath

## Name of the method to call.
## The method should accept:
##     func method_name(actor: Node, blackboard: Dictionary) -> BehaviorNode.Status
@export var method_name: StringName = &""

## Useful for debugging tree output.
@export var debug_name: String = "Action"

var target: Node = null


func _ready() -> void:
	if target_path != NodePath():
		target = get_node_or_null(target_path)


func tick(actor: Node, blackboard: Dictionary) -> Status:
	var callable_target := target

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

	if result is Status:
		return result

	push_error("%s method '%s' did not return a BehaviorNode.Status." % [debug_name, method_name])
	return Status.FAILURE
