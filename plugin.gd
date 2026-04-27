@tool
extends EditorPlugin

## The autoload singleton name used by this plugin.
const SAVE_MANAGER_NAME: String = "SaveManager"

## The script path for this plugin's SaveManager autoload.
const SAVE_MANAGER_PATH: String = "res://addons/jeremy_components/autoloads/save_manager/save_manager.gd"

## The ProjectSettings key used by Godot for this autoload.
const SAVE_MANAGER_SETTING_NAME: String = "autoload/%s" % SAVE_MANAGER_NAME


## Adds the SaveManager autoload when the plugin is enabled.
func _enable_plugin() -> void:
	if not ProjectSettings.has_setting(SAVE_MANAGER_SETTING_NAME):
		add_autoload_singleton(SAVE_MANAGER_NAME, SAVE_MANAGER_PATH)
		ProjectSettings.save()
		return

	var existing_value: String = str(ProjectSettings.get_setting(SAVE_MANAGER_SETTING_NAME))
	var existing_path: String = _normalize_autoload_path(existing_value)

	if existing_path == SAVE_MANAGER_PATH:
		return

	push_warning(
		"Could not add SaveManager autoload because an autoload named SaveManager already exists at: %s"
		% existing_value
	)


## Removes the SaveManager autoload when the plugin is disabled.
func _disable_plugin() -> void:
	if not ProjectSettings.has_setting(SAVE_MANAGER_SETTING_NAME):
		return

	var existing_value: String = str(ProjectSettings.get_setting(SAVE_MANAGER_SETTING_NAME))
	var existing_path: String = _normalize_autoload_path(existing_value)

	if existing_path != SAVE_MANAGER_PATH:
		push_warning(
			"Not removing SaveManager autoload because it does not point to this plugin. Existing value: %s"
			% existing_value
		)
		return

	remove_autoload_singleton(SAVE_MANAGER_NAME)
	ProjectSettings.save()


## Converts an autoload ProjectSettings value into a comparable res:// path.
func _normalize_autoload_path(value: String) -> String:
	var cleaned_value: String = value.trim_prefix("*")

	if cleaned_value.begins_with("uid://"):
		var resolved_path: String = ResourceUID.ensure_path(cleaned_value)

		if not resolved_path.is_empty():
			return resolved_path

	return cleaned_value
