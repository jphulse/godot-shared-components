@tool
extends EditorPlugin

const SAVE_MANAGER_NAME : String = "SaveManager"
const SAVE_MANAGER_PATH : String = "res://addons/jeremy_components/autoloads/save_manager/save_manager.gd"


func _enter_tree() -> void:
	var setting_name := "autoload/%s" % SAVE_MANAGER_NAME

	if not ProjectSettings.has_setting(setting_name):
		add_autoload_singleton(SAVE_MANAGER_NAME, SAVE_MANAGER_PATH)
		return

	var existing_path: String = str(ProjectSettings.get_setting(setting_name))

	if existing_path != "*%s" % SAVE_MANAGER_PATH and existing_path != SAVE_MANAGER_PATH:
		push_warning(
			"Could not add SaveManager autoload because an autoload named SaveManager already exists at: %s"
			% existing_path
		)


func _exit_tree() -> void:
	var setting_name := "autoload/%s" % SAVE_MANAGER_NAME

	if not ProjectSettings.has_setting(setting_name):
		return

	var existing_path: String = str(ProjectSettings.get_setting(setting_name))

	if existing_path == "*%s" % SAVE_MANAGER_PATH or existing_path == SAVE_MANAGER_PATH:
		remove_autoload_singleton(SAVE_MANAGER_NAME)
