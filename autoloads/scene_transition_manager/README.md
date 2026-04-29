# Scene Transition Manager

`SceneTransitionManager` is a reusable Godot autoload for changing scenes with transition effects.

It supports three main workflows:

1. Normal fade transitions.
2. Threaded scene loading with progress updates for loading bars.
3. Custom transition callables that let each game override the visual flow.

The manager is designed to be generic enough for use in a shared addon. It does not force one specific loading screen, one specific animation, or one specific scene-switching style. Instead, it provides a safe global API for scene changes, progress reporting, and optional transition overrides.

---

## Recommended Autoload Name

This README assumes the manager is registered as an autoload named:

```gdscript
SceneTransitions
```

Example usage:

```gdscript
await SceneTransitions.change_scene_to_file("res://levels/level_02.tscn")
```

If your plugin registers the autoload under a different name, replace `SceneTransitions` with your actual autoload name.

---

## Basic Idea

A normal scene transition has three phases:

```text
fade out
change scene
fade in
```

A threaded loading transition has five phases:

```text
fade out
load scene in the background
emit progress updates
change to the loaded scene
fade in
```

A custom transition can replace that behavior with anything:

```text
play animation
show loading UI
glitch screen
fade to white
wait for player input
change scene
clean up
```

The important part is that custom transition callables receive a `TransitionContext`. That context contains the scene-change callable and transition settings.

A custom non-threaded transition should usually call this exactly once:

```gdscript
var error: Error = await context.change_scene()
```

For threaded loading transitions, a custom threaded transition should usually call both of these:

```gdscript
var load_error: Error = await SceneTransitions._load_packed_scene_threaded(context)
var scene_error: Error = await context.change_scene()
```

The threaded load step loads and stores the `PackedScene`. The `context.change_scene()` call then swaps to that loaded scene.

---

## Why Most Calls Use `await`

The scene transition methods are asynchronous because they may wait for fades, scene changes, timers, threaded loading, or custom transition logic.

Use `await` when you need to know when the transition is finished or when you need the returned `Error` value.

```gdscript
var error: Error = await SceneTransitions.change_scene_to_file("res://levels/level_02.tscn")

if error != OK:
	push_error("Scene transition failed: %s" % error)
```

Without `await`, the transition may still start, but your code will continue immediately and you will not have the final `Error` result yet.

Use `await` for tests, gameplay flow, menus, door interactions, level travel, and anything that depends on the new scene being active.

```gdscript
await SceneTransitions.change_scene_to_file("res://levels/dungeon.tscn")
print("The dungeon scene is now active.")
```

Avoid this when the next line depends on the scene already being changed:

```gdscript
SceneTransitions.change_scene_to_file("res://levels/dungeon.tscn")
print("This may run before the transition finishes.")
```

Fire-and-forget usage is okay for simple buttons or triggers where the caller does not care about the result, but important gameplay logic should usually await the transition.

---

## Important Testing Note

If a transition test script is attached to the scene being replaced, the test node may be freed during the scene change.

For transition tests, either:

1. Run the test from an autoload.
2. Run the test from a persistent node that will not be freed.
3. Use a static coroutine pattern and avoid using the old node after the scene change.

Example:

```gdscript
extends Node

## Scene used to test a normal non-threaded fade transition.
const TARGET_SCENE_PATH: String = "res://test/test_level/test_level.tscn"


## Starts the normal fade transition test.
func _ready() -> void:
	do_test(self)


## Runs the normal fade transition test from a static coroutine so it can survive scene replacement.
static func do_test(node: Node) -> void:
	await node.get_tree().process_frame

	var error: Error = await SceneTransitions.change_scene_to_file(
		TARGET_SCENE_PATH,
		1.0,
		1.0,
		Color.RED
	)

	assert(error == OK)

	var main_loop: MainLoop = Engine.get_main_loop()
	var tree: SceneTree = main_loop as SceneTree

	assert(tree != null)
	assert(tree.current_scene != null)
	assert(tree.current_scene.scene_file_path == TARGET_SCENE_PATH)

	print("Normal fade transition test passed.")
```

After the scene changes, avoid using the original `node`, because it may have been freed with the old scene. Use `Engine.get_main_loop()` if you need static-safe access to the `SceneTree`.

---

## Main User-Facing API

### `change_scene_to_file`

Changes to a scene at a file path.

```gdscript
await SceneTransitions.change_scene_to_file(
	scene_path,
	fade_out_duration,
	fade_in_duration,
	transition_color,
	transition_callable_override,
	transition_data
)
```

Common usage:

```gdscript
await SceneTransitions.change_scene_to_file("res://levels/level_02.tscn")
```

With custom fade timing and color:

```gdscript
await SceneTransitions.change_scene_to_file(
	"res://levels/level_02.tscn",
	0.35,
	0.35,
	Color.BLACK
)
```

Parameters:

```text
scene_path:
	Path to the target scene file.

fade_out_duration:
	How long the fade-out should take. Use -1.0 to use the manager default.

fade_in_duration:
	How long the fade-in should take. Use -1.0 to use the manager default.

transition_color:
	Color used by the default fade transition. Custom transitions can also read this from context.transition_color.

transition_callable_override:
	Optional callable used to override the transition behavior for this one scene change.

transition_data:
	Optional dictionary of extra data passed into the TransitionContext.
```

---

### `change_scene_to_file_threaded`

Changes to a scene file using Godot's threaded resource loading API.

Use this when the target scene may be large enough that you want a loading bar or loading screen.

```gdscript
await SceneTransitions.change_scene_to_file_threaded(
	scene_path,
	fade_out_duration,
	fade_in_duration,
	transition_color,
	transition_callable_override,
	transition_data,
	use_sub_threads,
	cache_mode
)
```

Common usage:

```gdscript
await SceneTransitions.change_scene_to_file_threaded("res://levels/large_level.tscn")
```

With custom fade timing and color:

```gdscript
await SceneTransitions.change_scene_to_file_threaded(
	"res://levels/large_level.tscn",
	0.35,
	0.35,
	Color.BLACK
)
```

With a one-off custom threaded transition:

```gdscript
await SceneTransitions.change_scene_to_file_threaded(
	"res://levels/large_level.tscn",
	0.35,
	0.35,
	Color.BLACK,
	Callable(self, "_run_custom_threaded_transition")
)
```

Parameters:

```text
scene_path:
	Path to the scene file that should be loaded in the background.

fade_out_duration:
	How long the fade-out should take.

fade_in_duration:
	How long the fade-in should take.

transition_color:
	Color used by the default loading fade transition.

transition_callable_override:
	Optional callable used to override the threaded transition behavior for this one call.

transition_data:
	Optional dictionary of extra data passed into the TransitionContext.

use_sub_threads:
	Whether Godot should use sub-threads during threaded loading.

cache_mode:
	ResourceLoader cache mode. The default is ResourceLoader.CACHE_MODE_REUSE.
```

---

### `change_scene_to_packed`

Changes to an already-loaded `PackedScene`.

Use this if you manually loaded or preloaded a scene yourself.

```gdscript
## Already-loaded scene used by this example.
var packed_scene: PackedScene = preload("res://levels/level_02.tscn")

await SceneTransitions.change_scene_to_packed(
	packed_scene,
	"level_02",
	0.25,
	0.25,
	Color.BLACK
)
```

This does not provide loading progress because the `PackedScene` is already available.

---

### `change_scene_to_node`

Changes to an already-instantiated scene node.

Use this when you want full control over instantiation before the scene becomes current.

```gdscript
## Packed scene used to create the next scene node.
var packed_scene: PackedScene = preload("res://levels/level_02.tscn")

## Scene instance that will become the current scene.
var scene_node: Node = packed_scene.instantiate()

await SceneTransitions.change_scene_to_node(
	scene_node,
	"level_02_instance",
	0.25,
	0.25,
	Color.BLACK
)
```

This is useful if you want to configure the new scene before it enters as the current scene.

---

### `reload_current_scene`

Reloads the current scene using the transition system.

```gdscript
await SceneTransitions.reload_current_scene()
```

With custom fade timing:

```gdscript
await SceneTransitions.reload_current_scene(
	0.35,
	0.35,
	Color.BLACK
)
```

This only works when the current scene has a valid `scene_file_path`.

---

### `run_transition`

Runs a fully custom transition around a user-provided scene-change callable.

Most users will not need this directly. It is useful for advanced cases where the scene change is not a normal file, packed scene, or instantiated node.

```gdscript
await SceneTransitions.run_transition(
	"custom_room_swap",
	Callable(self, "_change_room_custom")
)
```

Example:

```gdscript
## Performs a custom room swap without using a scene path wrapper.
func _change_room_custom() -> Error:
	var old_scene: Node = get_tree().current_scene
	var new_scene: Node = preload("res://rooms/room_02.tscn").instantiate()

	get_tree().root.add_child(new_scene)
	get_tree().current_scene = new_scene

	if old_scene != null:
		old_scene.queue_free()

	return OK
```

This method is the low-level escape hatch.

---

## TransitionContext

Custom transition callables receive a `TransitionContext`.

Important fields:

```text
context.manager:
	Reference to the SceneTransitionManager.

context.target_scene_id:
	Human-readable ID for the target scene.

context.scene_change_callable:
	Callable that performs the actual scene change.

context.data:
	Dictionary of extra transition data.

context.wait_for_scene_changed:
	Whether context.change_scene() should await SceneTree.scene_changed.

context.fade_out_duration:
	Fade-out duration for this transition.

context.fade_in_duration:
	Fade-in duration for this transition.

context.transition_color:
	Color requested by the transition call.

context.loading_progress:
	Current loading progress, from 0.0 to 1.0.

context.loading_status_text:
	Human-readable loading status text.
```

Important methods:

```gdscript
await context.change_scene()
```

Runs the actual scene-change callable.

```gdscript
context.set_loading_progress(progress, status_text)
```

Updates loading progress and emits loading progress signals.

---

## Signals

### Transition Signals

```gdscript
transition_started(target_scene_id: String)
```

Emitted when a transition begins.

```gdscript
fade_out_finished(target_scene_id: String)
```

Emitted by the default fade transitions when fade-out completes.

```gdscript
scene_changed(target_scene_id: String, new_scene: Node)
```

Emitted after the scene change succeeds.

```gdscript
transition_finished(target_scene_id: String)
```

Emitted after the transition callable finishes successfully.

```gdscript
transition_failed(target_scene_id: String, error_code: Error)
```

Emitted when the transition fails.

```gdscript
transition_event(event_name: StringName, event_data: Dictionary)
```

Generic event signal for custom transition code.

---

### Loading Signals

```gdscript
loading_started(target_scene_id: String)
```

Emitted when threaded loading begins.

```gdscript
loading_progress_changed(target_scene_id: String, progress: float, status_text: String)
```

Emitted when threaded loading progress changes.

```gdscript
loading_finished(target_scene_id: String)
```

Emitted when threaded loading finishes successfully.

```gdscript
loading_failed(target_scene_id: String, error_code: Error)
```

Emitted when threaded loading fails.

---

## Example 1: Normal Fade Transition

This is the simplest scene transition. It fades out, changes scene, then fades in.

```gdscript
extends Node

## Scene used to test a normal non-threaded fade transition.
const TARGET_SCENE_PATH: String = "res://test/test_level/test_level.tscn"


## Starts the normal fade transition test.
func _ready() -> void:
	do_test(self)


## Runs the normal fade transition test from a static coroutine.
static func do_test(node: Node) -> void:
	await node.get_tree().process_frame

	SceneTransitions.clear_transition_callable()

	var error: Error = await SceneTransitions.change_scene_to_file(
		TARGET_SCENE_PATH,
		1.0,
		1.0,
		Color.RED
	)

	assert(error == OK)

	var main_loop: MainLoop = Engine.get_main_loop()
	var tree: SceneTree = main_loop as SceneTree

	assert(tree != null)
	assert(tree.current_scene != null)
	assert(tree.current_scene.scene_file_path == TARGET_SCENE_PATH)

	print("Normal fade transition test passed.")
```

What is happening:

```gdscript
SceneTransitions.clear_transition_callable()
```

This ensures the test uses the default fade behavior.

```gdscript
await SceneTransitions.change_scene_to_file(...)
```

This waits until the full transition has finished. That includes fade-out, scene change, and fade-in.

Why the test uses `Engine.get_main_loop()`:

```gdscript
var main_loop: MainLoop = Engine.get_main_loop()
var tree: SceneTree = main_loop as SceneTree
```

After the scene changes, the original node may have been freed. Accessing the current scene through the engine is safer in static test code.

---

## Example 2: Threaded Loading Transition With Progress

This transition loads the target scene in the background and emits progress updates.

```gdscript
extends Node

## Scene used to test threaded scene loading.
const TARGET_SCENE_PATH: String = "res://test/test_level/test_level.tscn"

## Whether the loading_started signal was emitted.
static var saw_loading_started: bool = false

## Whether at least one loading progress signal was emitted.
static var saw_loading_progress: bool = false

## Whether the loading_finished signal was emitted.
static var saw_loading_finished: bool = false

## Highest progress value observed during the test.
static var max_seen_progress: float = 0.0


## Starts the threaded loading transition test.
func _ready() -> void:
	do_test(self)


## Runs the threaded loading transition test from a static coroutine.
static func do_test(node: Node) -> void:
	await node.get_tree().process_frame

	SceneTransitions.loading_started.connect(_on_loading_started)
	SceneTransitions.loading_progress_changed.connect(_on_loading_progress_changed)
	SceneTransitions.loading_finished.connect(_on_loading_finished)

	var error: Error = await SceneTransitions.change_scene_to_file_threaded(
		TARGET_SCENE_PATH,
		1.0,
		1.0,
		Color.BLACK
	)

	assert(error == OK)
	assert(saw_loading_started)
	assert(saw_loading_progress)
	assert(saw_loading_finished)
	assert(max_seen_progress >= 1.0)

	var main_loop: MainLoop = Engine.get_main_loop()
	var tree: SceneTree = main_loop as SceneTree

	assert(tree != null)
	assert(tree.current_scene != null)
	assert(tree.current_scene.scene_file_path == TARGET_SCENE_PATH)

	print("Threaded loading transition test passed.")


## Records that threaded loading started.
static func _on_loading_started(_target_scene_id: String) -> void:
	saw_loading_started = true
	print("Loading started.")


## Records loading progress updates.
static func _on_loading_progress_changed(
	_target_scene_id: String,
	progress: float,
	status_text: String
) -> void:
	saw_loading_progress = true
	max_seen_progress = maxf(max_seen_progress, progress)
	print("Received loading progress: %f %s" % [progress, status_text])


## Records that threaded loading finished.
static func _on_loading_finished(_target_scene_id: String) -> void:
	saw_loading_finished = true
	print("Loading finished.")
```

What is happening:

```gdscript
change_scene_to_file_threaded(...)
```

starts a threaded resource load instead of immediately changing to the file.

During loading, the manager emits:

```text
loading_started
loading_progress_changed
loading_finished
```

The scene change happens after the resource is fully loaded.

Why progress may repeat:

Threaded loading is polled every frame. Godot can report the same progress value for multiple frames. A load bar should treat progress as state, not as a one-time event.

For example, this is normal:

```text
0.000000
0.000000
0.166667
0.166667
1.000000
```

If repeated values are undesirable, the manager can deduplicate progress values before emitting `loading_progress_changed`.

---

## Example 3: Custom Non-Threaded Transition Override

This overrides the transition visuals for one scene change.

```gdscript
extends Node

## Scene used to test a custom non-threaded transition callable.
const TARGET_SCENE_PATH: String = "res://test/test_level/test_level.tscn"

## Whether the custom transition callable was entered.
static var custom_transition_ran: bool = false

## Whether the custom transition changed the scene.
static var custom_transition_changed_scene: bool = false


## Starts the custom non-threaded transition override test.
func _ready() -> void:
	do_test(self)


## Runs the custom non-threaded transition override test.
static func do_test(node: Node) -> void:
	await node.get_tree().process_frame

	var error: Error = await SceneTransitions.change_scene_to_file(
		TARGET_SCENE_PATH,
		0.35,
		0.35,
		Color.PINK,
		_run_custom_non_threaded_transition
	)

	assert(error == OK)
	assert(custom_transition_ran)
	assert(custom_transition_changed_scene)

	var main_loop: MainLoop = Engine.get_main_loop()
	var tree: SceneTree = main_loop as SceneTree

	assert(tree != null)
	assert(tree.current_scene != null)
	assert(tree.current_scene.scene_file_path == TARGET_SCENE_PATH)

	print("Custom non-threaded transition test passed.")


## Custom transition callable used to override the default fade behavior.
static func _run_custom_non_threaded_transition(
	context: SceneTransitionManager.TransitionContext
) -> Error:
	custom_transition_ran = true

	SceneTransitions.emit_transition_event(&"custom_transition_started", {
		"target_scene_id": context.target_scene_id,
	})

	await SceneTransitions.fade_out(0.05, context.transition_color)

	var error: Error = await context.change_scene()
	if error != OK:
		await SceneTransitions.fade_in(0.05)
		return error

	custom_transition_changed_scene = true

	var main_loop: MainLoop = Engine.get_main_loop()
	var tree: SceneTree = main_loop as SceneTree

	await tree.create_timer(0.05).timeout
	await SceneTransitions.fade_in(0.35)

	SceneTransitions.emit_transition_event(&"custom_transition_finished", {
		"target_scene_id": context.target_scene_id,
	})

	print("Transition function completed.")

	return OK
```

What is happening:

```gdscript
Color.PINK
```

is passed into the transition context as:

```gdscript
context.transition_color
```

The custom transition uses it here:

```gdscript
await SceneTransitions.fade_out(0.05, context.transition_color)
```

If you instead write:

```gdscript
await SceneTransitions.fade_out(0.05, Color.WHITE)
```

then the fade-in will also appear white, because `fade_in()` fades out the current overlay color. It does not change the overlay color.

The most important line is:

```gdscript
var error: Error = await context.change_scene()
```

That is where the actual scene change happens.

The manager expects a custom transition to call `context.change_scene()` once. If the transition callable returns without changing the scene, the manager treats that as an error.

---

## Example 4: Custom Threaded Transition Override

This overrides the threaded loading transition for one scene change.

```gdscript
extends Node

## Scene used to test a custom threaded transition callable.
const TARGET_SCENE_PATH: String = "res://test/test_level/test_level.tscn"

## Whether the custom threaded transition callable was entered.
static var custom_threaded_transition_ran: bool = false

## Whether the custom threaded transition loaded the scene.
static var custom_threaded_loaded_scene: bool = false

## Whether the custom threaded transition changed the scene.
static var custom_threaded_changed_scene: bool = false


## Starts the custom threaded transition override test.
func _ready() -> void:
	do_test(self)


## Runs the custom threaded transition override test.
static func do_test(node: Node) -> void:
	await node.get_tree().process_frame

	var error: Error = await SceneTransitions.change_scene_to_file_threaded(
		TARGET_SCENE_PATH,
		0.35,
		0.35,
		Color.BLACK,
		_run_custom_threaded_transition
	)

	assert(error == OK)
	assert(custom_threaded_transition_ran)
	assert(custom_threaded_loaded_scene)
	assert(custom_threaded_changed_scene)

	var main_loop: MainLoop = Engine.get_main_loop()
	var tree: SceneTree = main_loop as SceneTree

	assert(tree != null)
	assert(tree.current_scene != null)
	assert(tree.current_scene.scene_file_path == TARGET_SCENE_PATH)

	print("Custom threaded transition test passed.")


## Custom threaded transition callable used to override the default threaded fade behavior.
static func _run_custom_threaded_transition(
	context: SceneTransitionManager.TransitionContext
) -> Error:
	custom_threaded_transition_ran = true

	await SceneTransitions.fade_out(context.fade_out_duration, context.transition_color)

	var load_error: Error = await SceneTransitions._load_packed_scene_threaded(context)
	if load_error != OK:
		await SceneTransitions.fade_in(context.fade_in_duration)
		return load_error

	custom_threaded_loaded_scene = true

	var scene_error: Error = await context.change_scene()
	if scene_error != OK:
		await SceneTransitions.fade_in(context.fade_in_duration)
		return scene_error

	custom_threaded_changed_scene = true

	await SceneTransitions.fade_in(context.fade_in_duration)

	return OK
```

What is happening:

```gdscript
await SceneTransitions._load_packed_scene_threaded(context)
```

loads the target scene in the background and emits loading progress signals.

```gdscript
await context.change_scene()
```

then changes to the loaded scene.

For threaded custom transitions, both steps are needed. If the custom threaded transition skips `_load_packed_scene_threaded(context)`, then `context.change_scene()` will not find the loaded `PackedScene` and the scene change may return `ERR_UNAVAILABLE`.

---

## Example 5: Connecting a Loading Bar

A project-specific loading screen can listen to the manager's loading progress signal.

```gdscript
extends Control

## ProgressBar shown during scene loading.
@export var progress_bar: ProgressBar

## Label shown during scene loading.
@export var status_label: Label


## Connects this loading UI to the global transition manager.
func _ready() -> void:
	SceneTransitions.loading_started.connect(_on_loading_started)
	SceneTransitions.loading_progress_changed.connect(_on_loading_progress_changed)
	SceneTransitions.loading_finished.connect(_on_loading_finished)

	visible = false


## Shows and resets the loading UI when loading begins.
func _on_loading_started(_target_scene_id: String) -> void:
	visible = true

	if progress_bar != null:
		progress_bar.value = 0.0

	if status_label != null:
		status_label.text = "Loading..."


## Updates the visible loading bar.
func _on_loading_progress_changed(
	_target_scene_id: String,
	progress: float,
	status_text: String
) -> void:
	if progress_bar != null:
		progress_bar.value = progress * 100.0

	if status_label != null:
		status_label.text = status_text


## Marks the loading UI as ready once loading finishes.
func _on_loading_finished(_target_scene_id: String) -> void:
	if progress_bar != null:
		progress_bar.value = 100.0

	if status_label != null:
		status_label.text = "Ready"
```

The loading UI does not need to know how scenes are changed. It only listens to progress signals.

This keeps the manager generic. One game can show a simple progress bar. Another can show animated tips. Another can show a fake boot screen, PSX loading screen, VHS distortion, or no loading UI at all.

---

## Example 6: Global Normal Transition Override

Use this when a project wants all normal scene transitions to use the same custom transition.

```gdscript
extends Node


## Registers this node's custom transition globally.
func _ready() -> void:
	SceneTransitions.set_transition_callable(_run_global_transition)


## Clears this node's custom transition when it exits.
func _exit_tree() -> void:
	SceneTransitions.clear_transition_callable()


## Global custom transition callable used for normal scene changes.
func _run_global_transition(
	context: SceneTransitionManager.TransitionContext
) -> Error:
	await SceneTransitions.fade_out(context.fade_out_duration, context.transition_color)

	var error: Error = await context.change_scene()
	if error != OK:
		await SceneTransitions.fade_in(context.fade_in_duration)
		return error

	await SceneTransitions.fade_in(context.fade_in_duration)

	return OK
```

After this is set, normal calls like this will use the global custom transition:

```gdscript
await SceneTransitions.change_scene_to_file("res://levels/level_02.tscn")
```

A per-call override still takes priority over the global override.

---

## Example 7: Optional Global Threaded Transition Override

If your version of the manager includes a separate loading transition callable, you can support a global threaded override.

Recommended API:

```gdscript
SceneTransitions.set_loading_transition_callable(Callable(self, "_run_global_loading_transition"))
SceneTransitions.clear_loading_transition_callable()
```

Example:

```gdscript
extends Node


## Registers this node's custom threaded transition globally.
func _ready() -> void:
	SceneTransitions.set_loading_transition_callable(_run_global_loading_transition)


## Clears this node's custom threaded transition when it exits.
func _exit_tree() -> void:
	SceneTransitions.clear_loading_transition_callable()


## Global custom transition callable used for threaded scene changes.
func _run_global_loading_transition(
	context: SceneTransitionManager.TransitionContext
) -> Error:
	await SceneTransitions.fade_out(context.fade_out_duration, context.transition_color)

	var load_error: Error = await SceneTransitions._load_packed_scene_threaded(context)
	if load_error != OK:
		await SceneTransitions.fade_in(context.fade_in_duration)
		return load_error

	var scene_error: Error = await context.change_scene()
	if scene_error != OK:
		await SceneTransitions.fade_in(context.fade_in_duration)
		return scene_error

	await SceneTransitions.fade_in(context.fade_in_duration)

	return OK
```

This lets projects customize all threaded loading transitions without affecting simple non-threaded transitions.

If the manager does not include `set_loading_transition_callable()` yet, threaded transitions can still be overridden per call:

```gdscript
await SceneTransitions.change_scene_to_file_threaded(
	"res://levels/large_level.tscn",
	0.35,
	0.35,
	Color.BLACK,
	_run_global_loading_transition
)
```

---

## Fire-and-Forget Usage

Sometimes a button or trigger does not care about the returned error.

This is acceptable:

```gdscript
## Starts a scene transition without waiting for completion.
func _on_start_button_pressed() -> void:
	SceneTransitions.change_scene_to_file("res://levels/level_01.tscn")
```

However, this is not ideal for tests or important gameplay logic because the caller does not know if the transition succeeded.

Prefer this when correctness matters:

```gdscript
## Starts a scene transition and reports failure.
func _on_start_button_pressed() -> void:
	var error: Error = await SceneTransitions.change_scene_to_file("res://levels/level_01.tscn")

	if error != OK:
		push_error("Failed to start level: %s" % error)
```

---

## Error Handling

All scene transition functions return an `Error`.

Common checks:

```gdscript
var error: Error = await SceneTransitions.change_scene_to_file("res://levels/level_02.tscn")

match error:
	OK:
		print("Scene changed successfully.")

	ERR_BUSY:
		push_warning("A transition is already running.")

	ERR_INVALID_PARAMETER:
		push_error("Invalid transition argument.")

	ERR_UNAVAILABLE:
		push_error("Requested scene was unavailable.")

	_:
		push_error("Scene transition failed: %s" % error)
```

`ERR_BUSY` usually means another transition is already active.

---

## Input Blocking

The manager can block input while a transition is active.

```gdscript
SceneTransitions.block_input_during_transition = true
```

When enabled, the manager marks input as handled during transitions.

This is useful when you do not want the player to move, attack, pause, or interact during a scene change.

---

## Pausing During Transitions

The manager can pause the scene tree while a transition is active.

```gdscript
SceneTransitions.pause_tree_during_transition = true
```

The manager itself uses `PROCESS_MODE_ALWAYS`, so it can continue animating its fade overlay even if the tree is paused.

Use this carefully. It is useful for menus or hard scene cuts, but some custom transition logic may expect gameplay timers or nodes to continue processing.

---

## Fade Helpers

The manager exposes helper methods that custom transitions can use.

### `fade_out`

Fades the overlay to fully opaque.

```gdscript
await SceneTransitions.fade_out(0.35, Color.BLACK)
```

This changes the overlay color and fades alpha to `1.0`.

### `fade_in`

Fades the overlay to fully transparent.

```gdscript
await SceneTransitions.fade_in(0.35)
```

This does not change the overlay color. It fades whatever color the overlay currently has.

Example:

```gdscript
await SceneTransitions.fade_out(0.35, Color.WHITE)
await SceneTransitions.fade_in(0.35)
```

This fades out to white, then fades back in from white.

If you want the custom transition to respect the color passed into the scene-change call, use:

```gdscript
await SceneTransitions.fade_out(context.fade_out_duration, context.transition_color)
```

### `cover_screen`

Immediately makes the overlay opaque.

```gdscript
SceneTransitions.cover_screen(Color.BLACK)
```

### `clear_overlay`

Immediately hides the overlay.

```gdscript
SceneTransitions.clear_overlay()
```

---

## Recommended Patterns

### Use `change_scene_to_file` for small scenes

```gdscript
await SceneTransitions.change_scene_to_file("res://levels/small_room.tscn")
```

This is simple and usually enough for small games, menus, and quick room changes.

### Use `change_scene_to_file_threaded` for large scenes

```gdscript
await SceneTransitions.change_scene_to_file_threaded("res://levels/large_world.tscn")
```

This is better when a scene may cause a visible frame hitch if loaded normally.

### Use a per-call override for special transitions

```gdscript
await SceneTransitions.change_scene_to_file(
	"res://levels/boss_room.tscn",
	0.5,
	0.5,
	Color.RED,
	_run_boss_room_transition
)
```

This is good for boss rooms, dream sequences, teleporters, death transitions, or horror effects.

### Use a global override for project-wide style

```gdscript
SceneTransitions.set_transition_callable(_run_project_transition)
```

This is good when one project wants all normal transitions to share the same style.

### Keep loading UI outside the manager

The manager should emit progress.

The project should decide how to display it.

This keeps the addon reusable.

---

## Common Mistakes

### Mistake: using a node after it was freed by a scene change

Bad:

```gdscript
var error: Error = await SceneTransitions.change_scene_to_file(TARGET_SCENE_PATH)
print(node.name)
```

The old node may have been freed.

Better:

```gdscript
var error: Error = await SceneTransitions.change_scene_to_file(TARGET_SCENE_PATH)

var tree: SceneTree = Engine.get_main_loop() as SceneTree
print(tree.current_scene.name)
```

---

### Mistake: expecting `fade_in()` to change color

Bad assumption:

```gdscript
await SceneTransitions.fade_out(0.2, Color.WHITE)
await SceneTransitions.fade_in(0.2)
```

This fades in from white.

If you want pink, fade out with pink:

```gdscript
await SceneTransitions.fade_out(0.2, Color.PINK)
await SceneTransitions.fade_in(0.2)
```

Or use the context color:

```gdscript
await SceneTransitions.fade_out(0.2, context.transition_color)
await SceneTransitions.fade_in(0.2)
```

---

### Mistake: custom transition never changes the scene

Bad:

```gdscript
## Incorrect custom transition that never changes the scene.
func _my_transition(context: SceneTransitionManager.TransitionContext) -> Error:
	await SceneTransitions.fade_out(0.2)
	await SceneTransitions.fade_in(0.2)
	return OK
```

This never calls:

```gdscript
await context.change_scene()
```

Better:

```gdscript
## Correct custom transition that performs the scene change.
func _my_transition(context: SceneTransitionManager.TransitionContext) -> Error:
	await SceneTransitions.fade_out(0.2)

	var error: Error = await context.change_scene()
	if error != OK:
		await SceneTransitions.fade_in(0.2)
		return error

	await SceneTransitions.fade_in(0.2)

	return OK
```

---

### Mistake: custom threaded transition changes scene before loading

Bad:

```gdscript
var scene_error: Error = await context.change_scene()
```

For threaded transitions, the loaded scene must exist first.

Better:

```gdscript
var load_error: Error = await SceneTransitions._load_packed_scene_threaded(context)
if load_error != OK:
	return load_error

var scene_error: Error = await context.change_scene()
if scene_error != OK:
	return scene_error
```

---

## Minimal Door Example

```gdscript
extends Area3D

## Scene path this door transitions to.
@export var target_scene_path: String = ""


## Connects the door trigger signal.
func _ready() -> void:
	body_entered.connect(_on_body_entered)


## Handles bodies entering the door trigger.
func _on_body_entered(body: Node3D) -> void:
	if target_scene_path.is_empty():
		return

	if not body.is_in_group("player"):
		return

	var error: Error = await SceneTransitions.change_scene_to_file(
		target_scene_path,
		0.25,
		0.25,
		Color.BLACK
	)

	if error != OK:
		push_error("Door transition failed: %s" % error)
```

---

## Minimal Main Menu Button Example

```gdscript
extends Button

## Scene path for the first playable level.
@export var first_level_path: String = "res://levels/level_01.tscn"


## Connects the button press signal.
func _ready() -> void:
	pressed.connect(_on_pressed)


## Starts the first level when the button is pressed.
func _on_pressed() -> void:
	disabled = true

	var error: Error = await SceneTransitions.change_scene_to_file(
		first_level_path,
		0.4,
		0.4,
		Color.BLACK
	)

	if error != OK:
		disabled = false
		push_error("Failed to start game: %s" % error)
```

---

## Minimal Death Reload Example

```gdscript
extends Node


## Reloads the current scene after the player dies.
func _on_player_died() -> void:
	var error: Error = await SceneTransitions.reload_current_scene(
		0.75,
		0.25,
		Color.BLACK
	)

	if error != OK:
		push_error("Failed to reload scene after death: %s" % error)
```

---

## Summary

Use this for normal fade transitions:

```gdscript
await SceneTransitions.change_scene_to_file(path)
```

Use this for large scenes and loading bars:

```gdscript
await SceneTransitions.change_scene_to_file_threaded(path)
```

Use this for one-off custom visual transitions:

```gdscript
await SceneTransitions.change_scene_to_file(path, -1.0, -1.0, Color.BLACK, custom_callable)
```

Use this inside custom non-threaded transitions:

```gdscript
await context.change_scene()
```

Use this inside custom threaded transitions:

```gdscript
await SceneTransitions._load_packed_scene_threaded(context)
await context.change_scene()
```

Use `await` whenever you need to wait for the scene change to finish or inspect the returned `Error`.

Keep the manager generic. Let individual projects decide what the loading UI looks like.
