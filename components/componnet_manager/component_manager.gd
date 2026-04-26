class_name ComponentManager
extends Node

@export var component_actor : Node = null

## Assigns the actor to all children who have the field
func _ready() -> void:
	if component_actor == null:
		component_actor = get_parent()
	for child : Node in get_children():
		child.set("component_actor", component_actor)
