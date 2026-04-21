class_name BehaviorTree
extends Node

enum TickMode {
	MANUAL,
	PROCESS,
	PHYSICS_PROCESS
}

## Whether or not this tree is enabled, if not enabled tick will immediately fail
@export var enabled : bool = true
## Whether ticking with physics frame, actual frame, or manually
@export var tickmode : TickMode = TickMode.PHYSICS_PROCESS
## The NodePath to the controlled actor
@export var actor_path : NodePath

## The root of the tree, can be any behavior node
var root : BehaviorNode = null
## The blackboard for this behavior tree stores variant key/value entries
var blackboard : Dictionary[Variant, Variant] = {}
## The last status returned from a tick
var last_status : BehaviorNode.Status = BehaviorNode.Status.FAILURE

## The actor this tree controls
var actor : Node = null

func _ready() -> void:
	if actor_path != NodePath():
		actor = get_node_or_null(actor_path)
	else :
		actor = owner if owner else get_parent()

func _process(delta: float) -> void:
	if tickmode == TickMode.PROCESS:
		tick()

func _physics_process(delta: float) -> void:
	if tickmode == TickMode.PHYSICS_PROCESS:
		tick()

## One tick of the behavior tree, returns the propogated status
func tick() -> BehaviorNode.Status:
	if not enabled:
		last_status = BehaviorNode.Status.FAILURE
		return last_status
	if root == null:
		last_status = BehaviorNode.Status.FAILURE
		return last_status
	if actor == null or not is_instance_valid(actor):
		last_status = BehaviorNode.Status.FAILURE
		return last_status
	last_status = root.tick(actor, blackboard)
	return last_status

## Sets the root of the tree
func set_root(new_root : BehaviorNode) -> void:
	root = new_root

## Clears the tree including root, blackboard, and wipes last status
func clear() -> void:
	root = null
	blackboard.clear()
	last_status = BehaviorNode.Status.FAILURE

## Adds the key, value entry to the blackboard, will overwrite existing entry
func set_blackboard_value(key : Variant, value : Variant) -> void:
	blackboard[key] = value

## Gets the blackboard value associated with key, returns default_value if none exist
func get_blackboard_value(key : Variant, default_value : Variant = null) -> Variant:
	return blackboard.get(key, default_value)

## Returns true if the blackboard has an entry for key false otherwise
func has_blackboard_value(key : Variant) -> bool:
	return blackboard.has(key)

## Erases the blackboard entry at key, returns true if there was one, false otherwise
func erase_blackboard_value(key: Variant) -> bool:
	return blackboard.erase(key)

## Resets the root and last status
func reset() -> void:
	if root != null:
		root.reset()
	last_status = BehaviorNode.Status.FAILURE
	
func add_decorator_to_root(decorator: BTDecorator) -> void:
	if root != null:
		root.add_decorator(decorator)
		if root.parent != null:
			root = root.parent
			
