class_name BTComposite
extends BehaviorNode

## Cached, typed view of this composite's direct BehaviorNode children.
## The Godot scene tree is treated as the source of truth.
var behavior_children: Array[BehaviorNode] = []


func _ready() -> void:
	resync_children()


## Rebuilds behavior_children from the actual Godot scene-tree children.
## This does not add, remove, or free any nodes.
func resync_children() -> void:
	for child: BehaviorNode in behavior_children:
		if child != null and child.parent == self:
			child.parent = null

	behavior_children.clear()

	for node in get_children():
		if node is BehaviorNode:
			var child := node as BehaviorNode
			behavior_children.append(child)
			child.parent = self


func add_child_node(child: BehaviorNode) -> void:
	assert(child != null, "Tried to add a null child to a composite node")

	if child.get_parent() == self:
		push_warning("Tried to add a child to a composite node twice. Each child must be its own instance.")
		resync_children()
		return

	if child.get_parent() != null:
		child.get_parent().remove_child(child)

	add_child(child)
	resync_children()


func remove_child_node(child: BehaviorNode, free_child: bool = true) -> BehaviorNode:
	if child == null:
		return null

	if child.get_parent() != self:
		if child.parent == self:
			child.parent = null

		resync_children()
		return child

	remove_child(child)

	if child.parent == self:
		child.parent = null

	resync_children()

	if free_child:
		child.queue_free()
		return null

	return child


func clear_child_nodes(free_children: bool = true) -> Array[BehaviorNode]:
	var detached_children: Array[BehaviorNode] = []
	var children_to_remove: Array[BehaviorNode] = behavior_children.duplicate()

	for child: BehaviorNode in children_to_remove:
		if child == null:
			continue

		if child.get_parent() == self:
			remove_child(child)

		if child.parent == self:
			child.parent = null

		if free_children:
			child.queue_free()
		else:
			detached_children.append(child)

	resync_children()

	return detached_children


func get_behavior_children_count() -> int:
	return behavior_children.size()


func get_behavior_child(index: int) -> BehaviorNode:
	if index < 0 or index >= behavior_children.size():
		return null

	return behavior_children[index]


func reset() -> void:
	for child: BehaviorNode in behavior_children:
		if child != null:
			child.reset()


## Replaces old_child with new_child at old_child's actual scene-tree position.
##
## This is safe even if this composite has non-BehaviorNode children, because it
## uses the real scene-tree index of old_child, not the filtered behavior_children index.
##
## Returns old_child if it was detached and not freed.
## Returns null if old_child was freed, not found, or no replacement happened.
func swap_child(
	old_child: BehaviorNode,
	new_child: BehaviorNode,
	append_if_not_found: bool = false,
	free_old_child: bool = true
) -> BehaviorNode:
	assert(new_child != null, "Tried to swap in a null child")

	if old_child == null or old_child.get_parent() != self:
		if append_if_not_found:
			add_child_node(new_child)
		return null

	if old_child == new_child:
		return null

	# Store old_child's actual scene-tree index, not its behavior_children index.
	var target_scene_index :int = old_child.get_index()

	# If new_child is already somewhere in the scene tree, detach it first.
	# If it is already a child of self before old_child, removing it shifts old_child's
	# scene-tree index down by 1.
	if new_child.get_parent() == self:
		var new_child_index :int = new_child.get_index()

		remove_child(new_child)

		if new_child_index < target_scene_index:
			target_scene_index -= 1
	elif new_child.get_parent() != null:
		new_child.get_parent().remove_child(new_child)

	remove_child(old_child)

	if old_child.parent == self:
		old_child.parent = null

	add_child(new_child)

	# Clamp because after removals, the valid index range may have changed.
	target_scene_index = clampi(target_scene_index, 0, get_child_count() - 1)
	move_child(new_child, target_scene_index)

	resync_children()

	if free_old_child:
		old_child.queue_free()
		return null

	return old_child
