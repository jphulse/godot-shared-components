extends Node

const SAVE_ROOT: String = "user://saves"
const DEFAULT_SLOT: String = "slot_1"

var current_slot: String = DEFAULT_SLOT


## Saves all SaveComponent nodes currently in the "saveable" group.
func save_game(slot: String = current_slot) -> void:
	current_slot = slot

	var slot_dir: String = get_slot_dir(slot)
	_ensure_dir(slot_dir)

	var save_components: Array[Node] = get_tree().get_nodes_in_group("saveable")

	for node: Node in save_components:
		if not node is SaveComponent:
			continue

		var save_component: SaveComponent = node as SaveComponent

		if save_component.save_id == &"":
			push_warning("Skipping SaveComponent with empty save_id at: %s" % save_component.get_path())
			continue

		var save_data: SaveData = save_component.get_save_data()
		var save_path: String = "%s/%s.tres" % [slot_dir, String(save_data.save_id)]

		var error: Error = ResourceSaver.save(save_data, save_path)

		if error != OK:
			push_error("Failed to save %s to %s. Error: %s" % [save_data.save_id, save_path, error])


## Loads all .tres SaveData files from the given slot and applies them to matching SaveComponents.
func load_game(slot: String = current_slot) -> void:
	current_slot = slot

	var slot_dir: String = get_slot_dir(slot)

	if not DirAccess.dir_exists_absolute(slot_dir):
		push_warning("Save slot does not exist: %s" % slot_dir)
		return

	var save_components_by_id: Dictionary = _get_save_components_by_id()

	var dir: DirAccess = DirAccess.open(slot_dir)
	if dir == null:
		push_error("Could not open save directory: %s" % slot_dir)
		return

	dir.list_dir_begin()

	var file_name: String = dir.get_next()

	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			var save_path: String = "%s/%s" % [slot_dir, file_name]
			var resource: Resource = ResourceLoader.load(save_path)

			if resource is SaveData:
				var save_data: SaveData = resource as SaveData

				if save_components_by_id.has(save_data.save_id):
					var save_component: SaveComponent = save_components_by_id[save_data.save_id]
					save_component.apply_save_data(save_data)
				else:
					push_warning("No SaveComponent found for save_id: %s" % save_data.save_id)
			else:
				push_warning("Skipping non-SaveData resource: %s" % save_path)

		file_name = dir.get_next()

	dir.list_dir_end()


## Deletes all saved files for a slot.
func delete_save(slot: String = current_slot) -> void:
	var slot_dir: String = get_slot_dir(slot)

	if not DirAccess.dir_exists_absolute(slot_dir):
		return

	var dir: DirAccess = DirAccess.open(slot_dir)
	if dir == null:
		push_error("Could not open save directory for deletion: %s" % slot_dir)
		return

	dir.list_dir_begin()

	var file_name: String = dir.get_next()

	while file_name != "":
		if not dir.current_is_dir():
			var file_path: String = "%s/%s" % [slot_dir, file_name]
			var error: Error = DirAccess.remove_absolute(file_path)

			if error != OK:
				push_error("Failed to delete save file %s. Error: %s" % [file_path, error])

		file_name = dir.get_next()

	dir.list_dir_end()

	var remove_error: Error = DirAccess.remove_absolute(slot_dir)
	if remove_error != OK:
		push_error("Failed to remove save slot directory %s. Error: %s" % [slot_dir, remove_error])


## Returns true if a save directory exists for the given slot.
func save_exists(slot: String = current_slot) -> bool:
	return DirAccess.dir_exists_absolute(get_slot_dir(slot))


## Returns the directory path for a save slot.
func get_slot_dir(slot: String) -> String:
	return "%s/%s" % [SAVE_ROOT, slot]


## Returns the full .tres path for a specific save_id in a slot.
func get_save_file_path(save_id: StringName, slot: String = current_slot) -> String:
	return "%s/%s.tres" % [get_slot_dir(slot), String(save_id)]


func _get_save_components_by_id() -> Dictionary:
	var result: Dictionary = {}

	var save_components: Array[Node] = get_tree().get_nodes_in_group("saveable")

	for node: Node in save_components:
		if not node is SaveComponent:
			continue

		var save_component: SaveComponent = node as SaveComponent

		if save_component.save_id == &"":
			push_warning("SaveComponent with empty save_id found at: %s" % save_component.get_path())
			continue

		if result.has(save_component.save_id):
			push_warning("Duplicate save_id found: %s at %s" % [
				save_component.save_id,
				save_component.get_path()
			])

		result[save_component.save_id] = save_component

	return result


func _ensure_dir(path: String) -> void:
	if DirAccess.dir_exists_absolute(path):
		return

	var error: Error = DirAccess.make_dir_recursive_absolute(path)

	if error != OK:
		push_error("Could not create save directory %s. Error: %s" % [path, error])
