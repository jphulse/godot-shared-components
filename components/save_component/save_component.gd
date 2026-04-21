class_name SaveComponent
extends Node

@export var save_id: StringName
@export var target_path: NodePath

var target: Node


func _ready() -> void:
	add_to_group("saveable")

	if target_path != NodePath():
		target = get_node_or_null(target_path)
	else:
		target = get_parent()

	if save_id == &"":
		push_warning("SaveComponent on %s has no save_id." % get_path())


func get_save_data() -> SaveData:
	var data := SaveData.new()
	data.save_id = save_id
	data.node_path = target.get_path() if target else NodePath()
	data.scene_path = target.scene_file_path if target else ""
	data.state = get_state()
	return data


func apply_save_data(data: SaveData) -> void:
	apply_state(data.state)


func get_state() -> Dictionary:
	if target == null:
		return {}

	if target.has_method("_get_save_state"):
		return target._get_save_state()

	var state := {}

	if target is Node2D:
		state["position"] = target.position
		state["rotation"] = target.rotation
		state["scale"] = target.scale

	return state


func apply_state(state: Dictionary) -> void:
	if target == null:
		return

	if target.has_method("_apply_save_state"):
		target._apply_save_state(state)
		return

	if target is Node2D:
		if state.has("position"):
			target.position = state["position"]
		if state.has("rotation"):
			target.rotation = state["rotation"]
		if state.has("scale"):
			target.scale = state["scale"]
