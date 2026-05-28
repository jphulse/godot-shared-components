class_name VisionTarget2D
extends RefCounted

## The last known position of the target node in global space.
var last_known_position: Vector2

## A reference to the target node.
var target: Node2D


## Initializes the target with the given node and its current global position.
func _init(target_node: Node2D) -> void:
	assert(target_node != null, "Target node may not be null.")

	target = target_node
	last_known_position = target.global_position


## Updates cached target information.
func update_target() -> void:
	if is_instance_valid(target):
		last_known_position = target.global_position


## Returns true if the target wraps the given node.
static func target_equals(active_target: VisionTarget2D, node: Node2D) -> bool:
	if active_target == null:
		return false

	if node == null:
		return false

	if not is_instance_valid(node):
		return false

	if not is_instance_valid(active_target.target):
		return false

	return node == active_target.target
