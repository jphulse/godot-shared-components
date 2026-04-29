@tool
extends EditorPlugin

## The autoload singleton name used by this plugin for save management.
const SAVE_MANAGER_NAME: String = "SaveManager"

## The script path for this plugin's SaveManager autoload.
const SAVE_MANAGER_PATH: String = "res://addons/jeremy_components/autoloads/save_manager/save_manager.gd"

## The autoload singleton name used by this plugin for scene transitions.
const SCENE_TRANSITIONS_NAME: String = "SceneTransitions"

## The script path for this plugin's SceneTransitionManager autoload.
const SCENE_TRANSITIONS_PATH: String = "res://addons/jeremy_components/autoloads/scene_transition_manager/scene_transition_manager.gd"

## The ProjectSettings prefix used by Godot for autoload settings.
const AUTOLOAD_SETTING_PREFIX: String = "autoload/"


## Adds this plugin's autoloads when the plugin is enabled.
func _enable_plugin() -> void:
	var save_manager_changed: bool = _try_add_plugin_autoload(SAVE_MANAGER_NAME, SAVE_MANAGER_PATH)
	var scene_transitions_changed: bool = _try_add_plugin_autoload(SCENE_TRANSITIONS_NAME, SCENE_TRANSITIONS_PATH)

	if save_manager_changed or scene_transitions_changed:
		ProjectSettings.save()


## Removes this plugin's autoloads when the plugin is disabled.
func _disable_plugin() -> void:
	var save_manager_changed: bool = _try_remove_plugin_autoload(SAVE_MANAGER_NAME, SAVE_MANAGER_PATH)
	var scene_transitions_changed: bool = _try_remove_plugin_autoload(SCENE_TRANSITIONS_NAME, SCENE_TRANSITIONS_PATH)

	if save_manager_changed or scene_transitions_changed:
		ProjectSettings.save()


## Adds an autoload if the name is unused, or warns if the name is already taken by another path.
func _try_add_plugin_autoload(autoload_name: String, autoload_path: String) -> bool:
	var setting_name: String = _get_autoload_setting_name(autoload_name)

	if not ProjectSettings.has_setting(setting_name):
		add_autoload_singleton(autoload_name, autoload_path)
		return true

	var existing_value: String = str(ProjectSettings.get_setting(setting_name))
	var existing_path: String = _normalize_autoload_path(existing_value)

	if existing_path == autoload_path:
		return false

	push_warning(
		"Could not add %s autoload because an autoload named %s already exists at: %s"
		% [autoload_name, autoload_name, existing_value]
	)

	return false


## Removes an autoload if it points to this plugin's expected path.
func _try_remove_plugin_autoload(autoload_name: String, autoload_path: String) -> bool:
	var setting_name: String = _get_autoload_setting_name(autoload_name)

	if not ProjectSettings.has_setting(setting_name):
		return false

	var existing_value: String = str(ProjectSettings.get_setting(setting_name))
	var existing_path: String = _normalize_autoload_path(existing_value)

	if existing_path != autoload_path:
		push_warning(
			"Not removing %s autoload because it does not point to this plugin. Existing value: %s"
			% [autoload_name, existing_value]
		)
		return false

	remove_autoload_singleton(autoload_name)
	return true


## Returns the ProjectSettings key used for an autoload name.
func _get_autoload_setting_name(autoload_name: String) -> String:
	return AUTOLOAD_SETTING_PREFIX + autoload_name


## Converts an autoload ProjectSettings value into a comparable res:// path.
func _normalize_autoload_path(value: String) -> String:
	var cleaned_value: String = value.trim_prefix("*")

	if cleaned_value.begins_with("uid://"):
		var resolved_path: String = ResourceUID.ensure_path(cleaned_value)

		if not resolved_path.is_empty():
			return resolved_path

	return cleaned_value
