class_name BTDecorator
extends BehaviorNode

## Cached BehaviorNode child.
## The actual Godot scene-tree child is treated as the source of truth.
var child: BehaviorNode = null


func _init(_child: BehaviorNode = null) -> void:
	if _child != null:
		set_child(_child, false)


func _ready() -> void:
	resync_child()


## Rebuilds the cached child reference from the actual scene-tree children.
## This does not add, remove, or free any nodes.
func resync_child() -> void:
	if child != null and child.parent == self:
		child.parent = null

	child = null

	for node in get_children():
		if node is BehaviorNode:
			child = node as BehaviorNode
			child.parent = self
			return


## Sets this decorator's single BehaviorNode child.
##
## If an old child exists, it is removed from this decorator.
## If free_old_child is true, the old child is queued for deletion.
func set_child(new_child: BehaviorNode, free_old_child: bool = true) -> BehaviorNode:
	assert(new_child != null, "Tried to set a null child on a decorator node")
	assert(new_child != self, "Tried to make a circular decorator by adding itself as a child")

	if child == new_child:
		resync_child()
		return null

	var old_child := child

	if old_child != null:
		if old_child.get_parent() == self:
			remove_child(old_child)

		if old_child.parent == self:
			old_child.parent = null

	if new_child.get_parent() != null:
		new_child.get_parent().remove_child(new_child)

	add_child(new_child)
	child = new_child
	child.parent = self

	resync_child()

	if old_child != null and free_old_child:
		old_child.queue_free()
		return null

	return old_child


## Removes this decorator's current child.
##
## Returns the detached child if it was not freed.
func clear_child(free_child: bool = true) -> BehaviorNode:
	if child == null:
		return null

	var old_child := child

	if old_child.get_parent() == self:
		remove_child(old_child)

	if old_child.parent == self:
		old_child.parent = null

	child = null
	resync_child()

	if free_child:
		old_child.queue_free()
		return null

	return old_child


func reset() -> void:
	if child != null:
		child.reset()


## Replaces old_child with new_child if old_child is this decorator's child.
##
## append_child_to_composite_if_not_found is kept for API compatibility,
## but decorators only allow one child, so it is intentionally ignored.
##
## Returns old_child if it was detached and not freed.
func swap_child(
	old_child: BehaviorNode,
	new_child: BehaviorNode,
	append_child_to_composite_if_not_found: bool = false,
	free_old_child: bool = true
) -> BehaviorNode:
	assert(new_child != null, "Tried to swap in a null child")

	if child != old_child:
		push_warning("Tried to swap children on a decorator from a node that is not the decorator's child.")
		return null

	return set_child(new_child, free_old_child)
