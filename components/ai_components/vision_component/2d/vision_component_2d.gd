class_name VisionComponent2D
extends Area2D

## Emitted when a target is spotted and aded into the active targets list
signal target_spotted(target: VisionTarget2D)

## Emitted when vision of a target has been broke, either by line of sight or by leaving
## the area, this will only be emitted if the node was an active target before The target will be
## removed from the active targets list when this signal is emitted
signal target_lost(target: VisionTarget2D)

## The mode used to decide whether this component tracks bodies, areas, or both.
enum Mode {
	BODIES,
	AREAS,
	BOTH
}

## The mode this vision component is operating in.
@export var mode: Mode = Mode.BODIES:
	set(value):
		mode = value

		if is_inside_tree():
			_sync_detection_signals()

## The half angle of the vision cone in radians.
@export_range(0.0, 180.0, 0.01, "radians_as_degrees") var half_angle: float = PI / 2.0

## The local-space forward direction for the component.
## This is rotated by the component's global rotation when evaluating vision.
@export var forward_direction: Vector2 = Vector2.RIGHT

## Whether this component should evaluate targets every physics frame.
## If false, call evaluate_overlapping_nodes() externally.
@export var automatically_evaluate_targets: bool = true

## Optional group filter. If empty, any overlapping Node2D can be a target.
@export var target_group: StringName = &""

## Whether targets must have a clear raycast line of sight to be visible.
@export var require_line_of_sight: bool = false

## The physics layers that can block line of sight.
## Usually this should include walls, terrain, doors, and other vision blockers.
@export_flags_2d_physics var line_of_sight_collision_mask: int = 1

## Whether the line-of-sight ray should collide with PhysicsBody2D objects.
@export var line_of_sight_collide_with_bodies: bool = true

## Whether the line-of-sight ray should collide with Area2D objects.
@export var line_of_sight_collide_with_areas: bool = false

## Whether a line-of-sight raycast hit on the target itself should count as visible.
##
## In most standard use cases, this should remain true. If the target's collision
## layer is included in line_of_sight_collision_mask, the raycast may hit the
## target before reaching the target's origin. In that case, hitting the target
## should usually mean the target is visible.
##
## Set this to false only when line_of_sight_collision_mask is being used as a
## pure obstruction mask and any raycast hit should be treated as blocking vision.
@export var target_hit_counts_as_visible: bool = true

## A local-space offset for the raycast origin.
## Useful if the vision origin should come from an eye/head point instead of this node's origin.
@export var line_of_sight_origin_offset: Vector2 = Vector2.ZERO

## Extra collision objects to exclude from the line-of-sight raycast.
## Add the owning character body here if the ray starts inside the owner.
@export var extra_line_of_sight_exclusions: Array[CollisionObject2D] = []

## The nodes currently overlapping with the broad detection Area2D.
var _overlapping_nodes: Array[Node2D] = []

## The currently visible targets.
var _active_targets: Array[VisionTarget2D] = []


func _ready() -> void:
	_sync_detection_signals()


func _physics_process(_delta: float) -> void:
	if automatically_evaluate_targets:
		evaluate_overlapping_nodes()


## Gets a duplicated array of the internal overlapping nodes array.
func get_overlapping_nodes() -> Array[Node2D]:
	return _overlapping_nodes.duplicate() as Array[Node2D]


## Gets a duplicated array of the currently active targets.
func get_active_targets() -> Array[VisionTarget2D]:
	return _active_targets.duplicate() as Array[VisionTarget2D]


## Gets the visible target nodes without exposing the VisionTarget2D wrapper objects.
func get_active_target_nodes() -> Array[Node2D]:
	var ret_val: Array[Node2D] = []

	for active_target: VisionTarget2D in _active_targets:
		if active_target != null and is_instance_valid(active_target.target):
			ret_val.append(active_target.target)

	return ret_val


## Returns true if the given node is currently an active visible target.
func has_active_target(node: Node2D) -> bool:
	return _active_targets.find_custom(VisionTarget2D.target_equals.bind(node)) >= 0


## Evaluates the overlapping nodes and updates the active target list.
func evaluate_overlapping_nodes() -> void:
	_prune_invalid_overlapping_nodes()
	_prune_invalid_active_targets()

	for node: Node2D in _overlapping_nodes:
		if _node_should_be_target(node):
			_add_or_update_target(node)
		else:
			_remove_target(node)


## Removes all active targets and emits target_lost for each removed target.
func clear_targets() -> void:
	for i: int in range(_active_targets.size() - 1, -1, -1):
		var active_target: VisionTarget2D = _active_targets[i]
		target_lost.emit(active_target)
		_active_targets.remove_at(i)

	_overlapping_nodes.clear()


## Returns the current forward direction in global space.
func get_global_forward_direction() -> Vector2:
	if forward_direction.is_zero_approx():
		return Vector2.RIGHT.rotated(global_rotation)

	return forward_direction.normalized().rotated(global_rotation)


## Returns the global raycast origin used for line-of-sight checks.
func get_line_of_sight_origin() -> Vector2:
	return global_transform * line_of_sight_origin_offset


## Adds or updates a node in the active target list.
func _add_or_update_target(node: Node2D) -> void:
	var idx: int = _active_targets.find_custom(VisionTarget2D.target_equals.bind(node))

	if idx >= 0:
		_active_targets[idx].update_target()
		return

	var new_target: VisionTarget2D = VisionTarget2D.new(node)
	_active_targets.append(new_target)
	target_spotted.emit(new_target)


## Removes a node from the active target list.
func _remove_target(node: Node2D) -> VisionTarget2D:
	var ret_val: VisionTarget2D = null

	for i: int in range(_active_targets.size() - 1, -1, -1):
		var active_target: VisionTarget2D = _active_targets[i]

		if active_target == null:
			_active_targets.remove_at(i)
			continue

		if not is_instance_valid(active_target.target):
			target_lost.emit(active_target)
			_active_targets.remove_at(i)
			continue

		if active_target.target == node:
			target_lost.emit(active_target)
			ret_val = active_target
			_active_targets.remove_at(i)
			break

	return ret_val


## Checks whether a node should currently be treated as a visible target.
func _node_should_be_target(node: Node2D) -> bool:
	if not _node_is_valid_candidate(node):
		return false

	if not _node_is_inside_vision_cone(node):
		return false

	if require_line_of_sight and not _node_has_line_of_sight(node):
		return false

	return true


## Returns true if the node is a valid candidate before angle/raycast tests.
func _node_is_valid_candidate(node: Node2D) -> bool:
	if node == null:
		return false

	if not is_instance_valid(node):
		return false

	if node == self:
		return false

	if target_group != &"" and not node.is_in_group(target_group):
		return false

	return true


## Returns true if the node is inside the component's vision cone.
func _node_is_inside_vision_cone(node: Node2D) -> bool:
	var direction_to_node: Vector2 = node.global_position - global_position

	if direction_to_node.is_zero_approx():
		return true

	var global_forward_direction: Vector2 = get_global_forward_direction()
	var normalized_direction_to_node: Vector2 = direction_to_node.normalized()
	var minimum_dot: float = cos(half_angle)
	var dot_to_target: float = global_forward_direction.dot(normalized_direction_to_node)

	return dot_to_target >= minimum_dot


## Returns true if a raycast from this component to the node is not blocked.
func _node_has_line_of_sight(node: Node2D) -> bool:
	var ray_origin: Vector2 = get_line_of_sight_origin()
	var ray_target: Vector2 = node.global_position
	var excluded_rids: Array[RID] = _get_line_of_sight_excluded_rids()

	var query: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(
		ray_origin,
		ray_target,
		line_of_sight_collision_mask,
		excluded_rids
	)

	query.collide_with_bodies = line_of_sight_collide_with_bodies
	query.collide_with_areas = line_of_sight_collide_with_areas

	var result: Dictionary = get_world_2d().direct_space_state.intersect_ray(query)

	if result.is_empty():
		return true

	if not target_hit_counts_as_visible:
		return false

	var collider_variant: Variant = result.get("collider")
	var collider_node: Node = collider_variant as Node

	if collider_node == null:
		return false

	if collider_node == node:
		return true

	if node.is_ancestor_of(collider_node):
		return true

	return false


## Gets the RIDs that should be excluded from line-of-sight raycasts.
func _get_line_of_sight_excluded_rids() -> Array[RID]:
	var ret_val: Array[RID] = []

	ret_val.append(get_rid())

	for collision_object: CollisionObject2D in extra_line_of_sight_exclusions:
		if collision_object != null and is_instance_valid(collision_object):
			ret_val.append(collision_object.get_rid())

	return ret_val


## Removes invalid nodes from the overlapping node cache.
func _prune_invalid_overlapping_nodes() -> void:
	for i: int in range(_overlapping_nodes.size() - 1, -1, -1):
		var node: Node2D = _overlapping_nodes[i]

		if not is_instance_valid(node):
			_overlapping_nodes.remove_at(i)


## Removes invalid targets from the active target list.
func _prune_invalid_active_targets() -> void:
	for i: int in range(_active_targets.size() - 1, -1, -1):
		var active_target: VisionTarget2D = _active_targets[i]

		if active_target == null:
			_active_targets.remove_at(i)
			continue

		if not is_instance_valid(active_target.target):
			target_lost.emit(active_target)
			_active_targets.remove_at(i)


## Adds a candidate node to the overlapping node cache.
func _add_overlapping_node(node: Node2D) -> void:
	if not _node_is_valid_candidate(node):
		return

	if not _overlapping_nodes.has(node):
		_overlapping_nodes.append(node)


## Connected to the body_entered signal.
func _on_body_entered(body: Node2D) -> void:
	_add_overlapping_node(body)


## Connected to the body_exited signal.
func _on_body_exited(body: Node2D) -> void:
	_overlapping_nodes.erase(body)
	_remove_target(body)


## Connected to the area_entered signal.
func _on_area_entered(area: Area2D) -> void:
	_add_overlapping_node(area)


## Connected to the area_exited signal.
func _on_area_exited(area: Area2D) -> void:
	_overlapping_nodes.erase(area)
	_remove_target(area)


## Connects and disconnects detection signals to match the current mode.
func _sync_detection_signals() -> void:
	_disconnect_body_signals()
	_disconnect_area_signals()

	match mode:
		Mode.BODIES:
			_connect_body_signals()
		Mode.AREAS:
			_connect_area_signals()
		Mode.BOTH:
			_connect_body_signals()
			_connect_area_signals()


## Safely connects body detection signals.
func _connect_body_signals() -> void:
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

	if not body_exited.is_connected(_on_body_exited):
		body_exited.connect(_on_body_exited)


## Safely connects area detection signals.
func _connect_area_signals() -> void:
	if not area_entered.is_connected(_on_area_entered):
		area_entered.connect(_on_area_entered)

	if not area_exited.is_connected(_on_area_exited):
		area_exited.connect(_on_area_exited)


## Safely disconnects body detection signals.
func _disconnect_body_signals() -> void:
	if body_entered.is_connected(_on_body_entered):
		body_entered.disconnect(_on_body_entered)

	if body_exited.is_connected(_on_body_exited):
		body_exited.disconnect(_on_body_exited)


## Safely disconnects area detection signals.
func _disconnect_area_signals() -> void:
	if area_entered.is_connected(_on_area_entered):
		area_entered.disconnect(_on_area_entered)

	if area_exited.is_connected(_on_area_exited):
		area_exited.disconnect(_on_area_exited)
