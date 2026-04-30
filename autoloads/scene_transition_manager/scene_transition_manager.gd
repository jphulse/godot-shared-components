class_name SceneTransitionManager
extends CanvasLayer

## Data object passed into transition callables.
class TransitionContext:
	extends RefCounted

	## Manager running this transition.
	var manager: SceneTransitionManager

	## Human-readable identifier for the transition target.
	var target_scene_id: String = ""

	## Callable that performs the actual scene change.
	var scene_change_callable: Callable = Callable()

	## Optional callable-specific data supplied by client code.
	var data: Dictionary = {}

	## Whether this transition should await SceneTree.scene_changed after the scene change callable runs.
	var wait_for_scene_changed: bool = true

	## Fade-out duration supplied to the transition.
	var fade_out_duration: float = 0.25

	## Fade-in duration supplied to the transition.
	var fade_in_duration: float = 0.25

	## Overlay color supplied to the transition.
	var transition_color: Color = Color.BLACK

	## Whether the scene change callable has already been called.
	var scene_change_was_requested: bool = false

	## Whether the scene was successfully changed.
	var scene_was_changed: bool = false

	## Error returned by the scene change callable.
	var scene_change_error: Error = OK
	
	## Loading progress for this transition, from 0.0 to 1.0.
	var loading_progress: float = 0.0

	## Human-readable loading status for this transition.
	var loading_status_text: String = ""


	## Creates a transition context.
	func _init(
		p_manager: SceneTransitionManager,
		p_target_scene_id: String,
		p_scene_change_callable: Callable,
		p_data: Dictionary,
		p_wait_for_scene_changed: bool,
		p_fade_out_duration: float,
		p_fade_in_duration: float,
		p_transition_color: Color
	) -> void:
		manager = p_manager
		target_scene_id = p_target_scene_id
		scene_change_callable = p_scene_change_callable
		data = p_data
		wait_for_scene_changed = p_wait_for_scene_changed
		fade_out_duration = p_fade_out_duration
		fade_in_duration = p_fade_in_duration
		transition_color = p_transition_color


	## Runs the scene change callable once and optionally waits for SceneTree.scene_changed.
	func change_scene() -> Error:
		if scene_change_was_requested:
			scene_change_error = ERR_ALREADY_IN_USE
			return scene_change_error

		if not scene_change_callable.is_valid():
			scene_change_error = ERR_INVALID_PARAMETER
			return scene_change_error

		scene_change_was_requested = true

		var result: Variant = await scene_change_callable.call()

		if result is int:
			scene_change_error = result as Error
		else:
			scene_change_error = OK

		if scene_change_error != OK:
			return scene_change_error

		if wait_for_scene_changed:
			await manager.get_tree().scene_changed

		scene_was_changed = true
		return OK
		
	## Updates this transition's loading progress and notifies the manager.
	func set_loading_progress(progress: float, status_text: String = "") -> void:
		loading_progress = clampf(progress, 0.0, 1.0)

		if not status_text.is_empty():
			loading_status_text = status_text

		manager._set_loading_progress(target_scene_id, loading_progress, loading_status_text)

#region signals
## Emitted when a transition begins.
signal transition_started(target_scene_id: String)

## Emitted by the default fade transition after fade-out finishes.
signal fade_out_finished(target_scene_id: String)

## Emitted after the scene change succeeds.
signal scene_changed(target_scene_id: String, new_scene: Node)

## Emitted after the transition callable finishes successfully.
signal transition_finished(target_scene_id: String)

## Emitted when the scene change or transition callable fails.
signal transition_failed(target_scene_id: String, error_code: Error)

## Emitted by custom transition code when it wants to broadcast an arbitrary event.
signal transition_event(event_name: StringName, event_data: Dictionary)

## Emitted when threaded loading begins.
signal loading_started(target_scene_id: String)

## Emitted when threaded loading progress changes.
signal loading_progress_changed(target_scene_id: String, progress: float, status_text: String)

## Emitted when threaded loading finishes successfully.
signal loading_finished(target_scene_id: String)

## Emitted when threaded loading fails.
signal loading_failed(target_scene_id: String, error_code: Error)
#endregion

#region Class constants
## Default autoload name for this manager.
const DEFAULT_AUTOLOAD_NAME: StringName = &"SceneTransitions"

## Canvas layer used by default so the overlay draws above normal game and UI layers.
const DEFAULT_CANVAS_LAYER: int = 128

## Default fade duration used for fade-out and fade-in when no override is supplied.
const DEFAULT_FADE_DURATION: float = 0.25

## Duration value meaning "use the manager's default duration."
const USE_DEFAULT_DURATION: float = -1.0

## Color value meaning "use the manager's default transition color."
const USE_DEFAULT_COLOR: Color = Color(0.0, 0.0, 0.0, -1.0)

## Minimum progress difference required before another progress signal is emitted.
const LOADING_PROGRESS_EMIT_EPSILON: float = 0.0001
#endregion

#region Exported vars
## Default fade-out duration in seconds.
@export var default_fade_out_duration: float = DEFAULT_FADE_DURATION

## Default fade-in duration in seconds.
@export var default_fade_in_duration: float = DEFAULT_FADE_DURATION

## Default overlay color used for transitions.
@export var default_transition_color: Color = Color.BLACK

## CanvasLayer layer value used by the transition overlay.
@export var transition_canvas_layer: int = DEFAULT_CANVAS_LAYER

## Whether input should be marked as handled while a transition is active.
@export var block_input_during_transition: bool = true

## Whether the SceneTree should be paused while a transition is active.
@export var pause_tree_during_transition: bool = false

## Whether the overlay should be hidden after it becomes fully transparent.
@export var hide_overlay_when_transparent: bool = true
#endregion

#region Public variables
## Optional global transition callable used instead of the default fade transition.
var transition_callable: Callable = Callable()

## Optional global transition callable used instead of the default threaded loading transition.
var loading_transition_callable: Callable = Callable()

## Whether a transition is currently running.
var is_transitioning: bool = false

## Identifier for the scene currently being transitioned to.
var current_target_scene_id: String = ""

## Current loading progress for the active transition.
var current_loading_progress: float = 0.0

## Current loading status text for the active transition.
var current_loading_status_text: String = ""
#endregion

#region Private variables
## Fullscreen ColorRect used by the default transition.
var _overlay: ColorRect = null

## Active tween used by the default transition.
var _active_tween: Tween = null

## Whether input should currently be blocked by this autoload.
var _input_is_blocked: bool = false

## Previous SceneTree pause state before this transition changed it.
var _previous_tree_paused: bool = false

## Whether the current transition changed the SceneTree pause state.
var _pause_was_changed_by_transition: bool = false

## Packed scenes loaded through threaded scene transitions.
var _threaded_loaded_scene_by_path: Dictionary = {}

## Last loading progress value emitted by the manager.
var _last_emitted_loading_progress: float = -1.0

## Last loading status text emitted by the manager.
var _last_emitted_loading_status_text: String = ""

## Whether the manager has emitted at least one loading progress update this transition.
var _has_emitted_loading_progress: bool = false
#endregion

#region engine processing
## Initializes the transition manager and creates the default overlay.
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = transition_canvas_layer

	_ensure_overlay()
	_set_overlay_alpha(0.0)
	_overlay.visible = false


## Blocks input while transitions are active, if configured to do so.
func _input(_event: InputEvent) -> void:
	if _input_is_blocked:
		get_viewport().set_input_as_handled()

#endregion

#region Public API
## Sets the global transition callable.
func set_transition_callable(new_transition_callable: Callable) -> void:
	transition_callable = new_transition_callable


## Clears the global transition callable and restores the default fade behavior.
func clear_transition_callable() -> void:
	transition_callable = Callable()

## Sets the global threaded loading transition callable.
func set_loading_transition_callable(new_loading_transition_callable: Callable) -> void:
	loading_transition_callable = new_loading_transition_callable


## Clears the global threaded loading transition callable and restores the default loading fade behavior.
func clear_loading_transition_callable() -> void:
	loading_transition_callable = Callable()

## Changes to a scene file using the active transition callable.
func change_scene_to_file(
	scene_path: String,
	fade_out_duration: float = USE_DEFAULT_DURATION,
	fade_in_duration: float = USE_DEFAULT_DURATION,
	transition_color: Color = USE_DEFAULT_COLOR,
	transition_callable_override: Callable = Callable(),
	transition_data: Dictionary = {}
) -> Error:
	if scene_path.is_empty():
		return ERR_INVALID_PARAMETER

	return await run_transition(
		scene_path,
		func() -> Error:
			return get_tree().change_scene_to_file(scene_path),
		transition_callable_override,
		transition_data,
		true,
		fade_out_duration,
		fade_in_duration,
		transition_color
	)


## Changes to a PackedScene using the active transition callable.
func change_scene_to_packed(
	packed_scene: PackedScene,
	scene_id: String = "",
	fade_out_duration: float = USE_DEFAULT_DURATION,
	fade_in_duration: float = USE_DEFAULT_DURATION,
	transition_color: Color = USE_DEFAULT_COLOR,
	transition_callable_override: Callable = Callable(),
	transition_data: Dictionary = {}
) -> Error:
	if packed_scene == null:
		return ERR_INVALID_PARAMETER

	var target_scene_id: String = scene_id
	if target_scene_id.is_empty():
		target_scene_id = packed_scene.resource_path
	if target_scene_id.is_empty():
		target_scene_id = "<packed_scene>"

	return await run_transition(
		target_scene_id,
		func() -> Error:
			return get_tree().change_scene_to_packed(packed_scene),
		transition_callable_override,
		transition_data,
		true,
		fade_out_duration,
		fade_in_duration,
		transition_color
	)


## Changes to an already-instantiated scene node using the active transition callable.
func change_scene_to_node(
	scene_node: Node,
	scene_id: String = "",
	fade_out_duration: float = USE_DEFAULT_DURATION,
	fade_in_duration: float = USE_DEFAULT_DURATION,
	transition_color: Color = USE_DEFAULT_COLOR,
	transition_callable_override: Callable = Callable(),
	transition_data: Dictionary = {}
) -> Error:
	if scene_node == null:
		return ERR_INVALID_PARAMETER

	var target_scene_id: String = scene_id
	if target_scene_id.is_empty():
		target_scene_id = scene_node.name

	return await run_transition(
		target_scene_id,
		func() -> Error:
			return get_tree().change_scene_to_node(scene_node),
		transition_callable_override,
		transition_data,
		true,
		fade_out_duration,
		fade_in_duration,
		transition_color
	)


## Reloads the current scene using the active transition callable.
func reload_current_scene(
	fade_out_duration: float = USE_DEFAULT_DURATION,
	fade_in_duration: float = USE_DEFAULT_DURATION,
	transition_color: Color = USE_DEFAULT_COLOR,
	transition_callable_override: Callable = Callable(),
	transition_data: Dictionary = {}
) -> Error:
	var current_scene: Node = get_tree().current_scene
	if current_scene == null:
		return ERR_UNAVAILABLE

	var current_scene_path: String = current_scene.scene_file_path
	if current_scene_path.is_empty():
		return ERR_UNAVAILABLE

	return await change_scene_to_file(
		current_scene_path,
		fade_out_duration,
		fade_in_duration,
		transition_color,
		transition_callable_override,
		transition_data
	)


## Runs a fully custom transition around a client-provided scene-change callable.
func run_transition(
	target_scene_id: String,
	scene_change_callable: Callable,
	transition_callable_override: Callable = Callable(),
	transition_data: Dictionary = {},
	wait_for_scene_changed: bool = true,
	fade_out_duration: float = USE_DEFAULT_DURATION,
	fade_in_duration: float = USE_DEFAULT_DURATION,
	transition_color: Color = USE_DEFAULT_COLOR
) -> Error:
	if is_transitioning:
		return ERR_BUSY

	if target_scene_id.is_empty():
		target_scene_id = "<custom_transition>"

	if not scene_change_callable.is_valid():
		return ERR_INVALID_PARAMETER

	is_transitioning = true
	current_target_scene_id = target_scene_id
	_input_is_blocked = block_input_during_transition

	_apply_pause_if_needed()

	var context := TransitionContext.new(
		self,
		target_scene_id,
		scene_change_callable,
		transition_data,
		wait_for_scene_changed,
		_resolve_duration(fade_out_duration, default_fade_out_duration),
		_resolve_duration(fade_in_duration, default_fade_in_duration),
		_resolve_color(transition_color)
	)

	transition_started.emit(target_scene_id)

	var chosen_transition_callable: Callable = _resolve_transition_callable(transition_callable_override)
	var result: Variant = await chosen_transition_callable.call(context)
	var transition_error: Error = _coerce_result_to_error(result)

	if transition_error != OK:
		transition_failed.emit(target_scene_id, transition_error)
		_finish_transition()
		return transition_error

	if not context.scene_change_was_requested:
		transition_failed.emit(target_scene_id, ERR_DOES_NOT_EXIST)
		_finish_transition()
		return ERR_DOES_NOT_EXIST

	if context.scene_change_error != OK:
		transition_failed.emit(target_scene_id, context.scene_change_error)
		_finish_transition()
		return context.scene_change_error

	if context.scene_was_changed:
		scene_changed.emit(target_scene_id, get_tree().current_scene)

	transition_finished.emit(target_scene_id)
	_finish_transition()

	return OK


## Fades the transition overlay to fully opaque without changing scenes.
func fade_out(
	duration: float = USE_DEFAULT_DURATION,
	transition_color: Color = USE_DEFAULT_COLOR
) -> void:
	_ensure_overlay()
	_prepare_overlay_for_transition(_resolve_color(transition_color))
	await _fade_overlay_to_alpha(1.0, _resolve_duration(duration, default_fade_out_duration))


## Fades the transition overlay to fully transparent without changing scenes.
func fade_in(duration: float = USE_DEFAULT_DURATION) -> void:
	_ensure_overlay()
	await _fade_overlay_to_alpha(0.0, _resolve_duration(duration, default_fade_in_duration))

	if hide_overlay_when_transparent:
		_overlay.visible = false


## Immediately sets the overlay to fully transparent and hidden.
func clear_overlay() -> void:
	_kill_active_tween()
	_ensure_overlay()
	_set_overlay_alpha(0.0)
	_overlay.visible = false
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_input_is_blocked = false


## Immediately sets the overlay to fully opaque.
func cover_screen(transition_color: Color = USE_DEFAULT_COLOR) -> void:
	_kill_active_tween()
	_ensure_overlay()
	_prepare_overlay_for_transition(_resolve_color(transition_color))
	_set_overlay_alpha(1.0)
	_overlay.visible = true


## Emits a custom transition event for client transition callables.
func emit_transition_event(event_name: StringName, event_data: Dictionary = {}) -> void:
	transition_event.emit(event_name, event_data)

## Changes to a scene file using threaded loading so progress can be displayed.
func change_scene_to_file_threaded(
	scene_path: String,
	fade_out_duration: float = USE_DEFAULT_DURATION,
	fade_in_duration: float = USE_DEFAULT_DURATION,
	transition_color: Color = USE_DEFAULT_COLOR,
	transition_callable_override: Callable = Callable(),
	transition_data: Dictionary = {},
	use_sub_threads: bool = false,
	cache_mode: int = ResourceLoader.CACHE_MODE_REUSE
) -> Error:
	if scene_path.is_empty():
		return ERR_INVALID_PARAMETER

	var threaded_transition_data: Dictionary = transition_data.duplicate()
	threaded_transition_data["scene_path"] = scene_path
	threaded_transition_data["use_sub_threads"] = use_sub_threads
	threaded_transition_data["cache_mode"] = cache_mode

	var chosen_transition_callable: Callable = _resolve_loading_transition_callable(transition_callable_override)

	return await run_transition(
		scene_path,
		func() -> Error:
			var loaded_scene: PackedScene = _threaded_loaded_scene_by_path.get(scene_path) as PackedScene

			if loaded_scene == null:
				return ERR_UNAVAILABLE

			_threaded_loaded_scene_by_path.erase(scene_path)
			return get_tree().change_scene_to_packed(loaded_scene),
		chosen_transition_callable,
		threaded_transition_data,
		true,
		fade_out_duration,
		fade_in_duration,
		transition_color
	)
#endregion

#region Private helpers
## Default transition implementation: fade out, change scene, fade in.
func _run_default_fade_transition(context: TransitionContext) -> Error:
	_prepare_overlay_for_transition(context.transition_color)

	await _fade_overlay_to_alpha(1.0, context.fade_out_duration)

	fade_out_finished.emit(context.target_scene_id)

	var scene_error: Error = await context.change_scene()
	if scene_error != OK:
		await _fade_overlay_to_alpha(0.0, context.fade_in_duration)
		return scene_error

	await _fade_overlay_to_alpha(0.0, context.fade_in_duration)

	if hide_overlay_when_transparent:
		_overlay.visible = false

	return OK


## Resolves the transition callable to use for the current transition.
func _resolve_transition_callable(transition_callable_override: Callable) -> Callable:
	if transition_callable_override.is_valid():
		return transition_callable_override

	if transition_callable.is_valid():
		return transition_callable

	return Callable(self, "_run_default_fade_transition")


## Resolves the threaded loading transition callable to use for the current transition.
func _resolve_loading_transition_callable(transition_callable_override: Callable) -> Callable:
	if transition_callable_override.is_valid():
		return transition_callable_override

	if loading_transition_callable.is_valid():
		return loading_transition_callable

	return Callable(self, "_run_default_loading_fade_transition")

## Ensures the fullscreen overlay exists.
func _ensure_overlay() -> void:
	if is_instance_valid(_overlay):
		return

	_overlay = ColorRect.new()
	_overlay.name = "TransitionOverlay"
	_overlay.color = Color(default_transition_color.r, default_transition_color.g, default_transition_color.b, 0.0)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.anchor_left = 0.0
	_overlay.anchor_top = 0.0
	_overlay.anchor_right = 1.0
	_overlay.anchor_bottom = 1.0
	_overlay.offset_left = 0.0
	_overlay.offset_top = 0.0
	_overlay.offset_right = 0.0
	_overlay.offset_bottom = 0.0

	add_child(_overlay)


## Prepares the overlay color and visibility for a transition.
func _prepare_overlay_for_transition(transition_color: Color) -> void:
	_ensure_overlay()

	var current_alpha: float = _overlay.color.a
	_overlay.color = Color(transition_color.r, transition_color.g, transition_color.b, current_alpha)
	_overlay.visible = true
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP if block_input_during_transition else Control.MOUSE_FILTER_IGNORE


## Animates the overlay alpha to the requested value.
func _fade_overlay_to_alpha(target_alpha: float, duration: float) -> void:
	_ensure_overlay()
	_kill_active_tween()

	var clamped_alpha: float = clampf(target_alpha, 0.0, 1.0)
	var target_color: Color = _overlay.color
	target_color.a = clamped_alpha

	if duration <= 0.0:
		_overlay.color = target_color
		await get_tree().process_frame
		return

	_active_tween = create_tween()
	_active_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_active_tween.tween_property(_overlay, "color", target_color, duration)

	await _active_tween.finished

	_active_tween = null


## Sets the overlay alpha without tweening.
func _set_overlay_alpha(alpha: float) -> void:
	_ensure_overlay()

	var next_color: Color = _overlay.color
	next_color.a = clampf(alpha, 0.0, 1.0)
	_overlay.color = next_color


## Kills the active overlay tween if one exists.
func _kill_active_tween() -> void:
	if is_instance_valid(_active_tween):
		_active_tween.kill()

	_active_tween = null


## Resolves a duration override into a concrete duration.
func _resolve_duration(duration: float, default_duration: float) -> float:
	if duration < 0.0:
		return maxf(default_duration, 0.0)

	return maxf(duration, 0.0)


## Resolves a color override into a concrete transition color.
func _resolve_color(transition_color: Color) -> Color:
	if transition_color.a < 0.0:
		return default_transition_color

	return transition_color


## Converts a transition callable result into an Error value.
func _coerce_result_to_error(result: Variant) -> Error:
	if result is int:
		return result as Error

	return OK


## Pauses the SceneTree if transition pausing is enabled.
func _apply_pause_if_needed() -> void:
	_pause_was_changed_by_transition = false

	if not pause_tree_during_transition:
		return

	_previous_tree_paused = get_tree().paused
	get_tree().paused = true
	_pause_was_changed_by_transition = true


## Restores transition state after success or failure.
func _finish_transition() -> void:
	if is_instance_valid(_overlay):
		if hide_overlay_when_transparent and is_equal_approx(_overlay.color.a, 0.0):
			_overlay.visible = false

		_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if _pause_was_changed_by_transition:
		get_tree().paused = _previous_tree_paused

	_pause_was_changed_by_transition = false
	_input_is_blocked = false
	is_transitioning = false
	current_target_scene_id = ""

## Updates global loading progress state and emits progress signals when the value meaningfully changes.
func _set_loading_progress(target_scene_id: String, progress: float, status_text: String = "") -> void:
	current_loading_progress = clampf(progress, 0.0, 1.0)

	if not status_text.is_empty():
		current_loading_status_text = status_text

	var progress_changed: bool = absf(current_loading_progress - _last_emitted_loading_progress) > LOADING_PROGRESS_EMIT_EPSILON
	var status_changed: bool = current_loading_status_text != _last_emitted_loading_status_text

	if _has_emitted_loading_progress and not progress_changed and not status_changed:
		return

	_has_emitted_loading_progress = true
	_last_emitted_loading_progress = current_loading_progress
	_last_emitted_loading_status_text = current_loading_status_text

	loading_progress_changed.emit(target_scene_id, current_loading_progress, current_loading_status_text)

	transition_event.emit(&"loading_progress_changed", {
		"target_scene_id": target_scene_id,
		"progress": current_loading_progress,
		"status_text": current_loading_status_text,
	})



## Default loading transition: fade out, threaded load with progress, change scene, fade in.
func _run_default_loading_fade_transition(context: TransitionContext) -> Error:
	_prepare_overlay_for_transition(context.transition_color)

	await _fade_overlay_to_alpha(1.0, context.fade_out_duration)

	fade_out_finished.emit(context.target_scene_id)

	var load_error: Error = await _load_packed_scene_threaded(context)
	if load_error != OK:
		await _fade_overlay_to_alpha(0.0, context.fade_in_duration)
		return load_error

	var scene_error: Error = await context.change_scene()
	if scene_error != OK:
		await _fade_overlay_to_alpha(0.0, context.fade_in_duration)
		return scene_error

	await _fade_overlay_to_alpha(0.0, context.fade_in_duration)

	if hide_overlay_when_transparent:
		_overlay.visible = false

	return OK


## Resets loading progress emission tracking for a new threaded load.
func _reset_loading_progress_tracking() -> void:
	current_loading_progress = 0.0
	current_loading_status_text = ""
	_last_emitted_loading_progress = -1.0
	_last_emitted_loading_status_text = ""
	_has_emitted_loading_progress = false

## Loads a PackedScene in the background and stores it for the scene-change callable.
func _load_packed_scene_threaded(context: TransitionContext) -> Error:
	var scene_path: String = str(context.data.get("scene_path", context.target_scene_id))
	var use_sub_threads: bool = bool(context.data.get("use_sub_threads", false))
	var cache_mode: int = int(context.data.get("cache_mode", ResourceLoader.CACHE_MODE_REUSE))

	if scene_path.is_empty():
		return ERR_INVALID_PARAMETER

	_reset_loading_progress_tracking()

	loading_started.emit(context.target_scene_id)
	context.set_loading_progress(0.0, "Loading...")

	var request_error: Error = ResourceLoader.load_threaded_request(
		scene_path,
		"PackedScene",
		use_sub_threads,
		cache_mode
	)

	if request_error != OK:
		loading_failed.emit(context.target_scene_id, request_error)
		return request_error

	var progress_array: Array = []

	while true:
		progress_array.clear()

		var status: ResourceLoader.ThreadLoadStatus = ResourceLoader.load_threaded_get_status(
			scene_path,
			progress_array
		)

		if progress_array.size() > 0:
			context.set_loading_progress(float(progress_array[0]), "Loading...")

		match status:
			ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
				loading_failed.emit(context.target_scene_id, ERR_INVALID_DATA)
				return ERR_INVALID_DATA

			ResourceLoader.THREAD_LOAD_IN_PROGRESS:
				await get_tree().process_frame

			ResourceLoader.THREAD_LOAD_FAILED:
				loading_failed.emit(context.target_scene_id, ERR_FILE_CANT_OPEN)
				return ERR_FILE_CANT_OPEN

			ResourceLoader.THREAD_LOAD_LOADED:
				context.set_loading_progress(1.0, "Ready")
				break

	var loaded_resource: Resource = ResourceLoader.load_threaded_get(scene_path)
	var loaded_scene: PackedScene = loaded_resource as PackedScene

	if loaded_scene == null:
		loading_failed.emit(context.target_scene_id, ERR_INVALID_DATA)
		return ERR_INVALID_DATA

	_threaded_loaded_scene_by_path[scene_path] = loaded_scene

	loading_finished.emit(context.target_scene_id)
	return OK
#endregion
