# Background Task Runner

A scene-local utility for running plain-data jobs on background threads with minimal direct `Thread` or `WorkerThreadPool` boilerplate.

This utility is intended for cases where you want to do expensive work off the main thread, then receive the result back on the main thread through a signal or callback.

It is **not** an Autoload. Add a `BackgroundTaskRunner` node only in scenes or systems that need background work.

---

## Files

```text
addons/jeremy_components/threading/
  background_task_result.gd
  background_task_handle.gd
  background_task_runner.gd
```

The utility contains three main classes:

```text
BackgroundTaskRunner
BackgroundTaskHandle
BackgroundTaskResult
```

---

## Why Use This?

Godot threading usually requires manually submitting tasks, polling for completion, waiting safely, and making sure main-thread-only work is not performed from a worker thread.

This utility gives you a simpler workflow:

```gdscript
var task := task_runner.run_task(
	Callable(self, "_generate_chunk_data").bind(chunk_position)
)

task.completed.connect(_on_chunk_data_ready)
task.failed.connect(_on_chunk_generation_failed)
task.cancelled.connect(_on_chunk_generation_cancelled)
```

The background callable runs on a worker thread.

The `completed`, `failed`, and `cancelled` signals are emitted from the main thread.

---

## Important Thread-Safety Rule

Background tasks should work on **plain data**.

Good background-task work includes:

```text
Procedural data generation
Noise map generation
Pathfinding calculations
Save/load serialization data
Large Array/Dictionary processing
AI planning data
Mesh data preparation
Chunk/tile data generation
Expensive math
```

Avoid doing this directly inside a background task:

```text
add_child()
queue_free()
Changing Node transforms
Spawning enemies/projectiles
Playing animations
Changing UI
Changing physics bodies
Changing scene tree state
Calling random gameplay methods on live Nodes
```

The safe pattern is:

```text
Worker thread:
  Generate plain data.

Main thread:
  Receive completed(result).
  Apply the result to Nodes, scenes, visuals, physics, or UI.
```

This utility makes background work more convenient. It does **not** make unsafe Godot APIs thread-safe.

---

## Basic Setup

Add a `BackgroundTaskRunner` node to any scene that needs background tasks.

Example scene:

```text
World
  Player
  ChunkManager
  BackgroundTaskRunner
```

In your script:

```gdscript
extends Node

## Scene-local background task runner.
@onready var task_runner: BackgroundTaskRunner = $BackgroundTaskRunner
```

---

## Quick Start

```gdscript
extends Node

## Scene-local background task runner.
@onready var task_runner: BackgroundTaskRunner = $BackgroundTaskRunner


## Starts a background task.
func generate_data() -> void:
	var task := task_runner.run_task(
		Callable(self, "_generate_data_on_worker")
	)

	task.completed.connect(_on_data_generated)
	task.failed.connect(_on_data_generation_failed)
	task.cancelled.connect(_on_data_generation_cancelled)


## Runs on a worker thread.
func _generate_data_on_worker() -> Dictionary:
	var result := {
		"tiles": [],
		"width": 128,
		"height": 128
	}

	for i in 128 * 128:
		result["tiles"].append(i % 4)

	return result


## Runs on the main thread.
func _on_data_generated(result: Dictionary) -> void:
	print("Generated tile count: ", result["tiles"].size())


## Runs on the main thread if the task reports failure.
func _on_data_generation_failed(error_message: String) -> void:
	push_warning(error_message)


## Runs on the main thread if the task is cancelled.
func _on_data_generation_cancelled() -> void:
	print("Generation cancelled.")
```

---

## Main Concept

A task has two parts:

```text
Background callable:
  Runs on a worker thread.

Completion handling:
  Runs on the main thread through signals/callbacks.
```

When you call:

```gdscript
var task := task_runner.run_task(Callable(self, "_expensive_function"))
```

you receive a `BackgroundTaskHandle`.

The handle lets you:

```text
Connect to completion signals
Check status
Request cancellation
Read result/error state
```

---

# BackgroundTaskRunner

`BackgroundTaskRunner` is a scene-local `Node` that submits and manages background tasks.

Add it to a scene only when that scene needs background work.

---

## Exported Properties

### `auto_poll_tasks: bool = true`

When `true`, the runner automatically checks for completed tasks during `_process`.

Most users should leave this enabled.

```gdscript
task_runner.auto_poll_tasks = true
```

When `false`, you must call:

```gdscript
task_runner.poll_completed_tasks()
```

manually.

Manual polling can be useful if you want tighter control over when completion signals are emitted.

---

### `high_priority: bool = false`

Whether tasks submitted by this runner should use Godot's high-priority worker queue.

```gdscript
task_runner.high_priority = true
```

Most tasks should not need this. Use it only when the background task result is time-sensitive.

---

### `wait_for_tasks_on_exit: bool = true`

When `true`, the runner requests cancellation and waits for active tasks when the runner exits the scene tree.

This helps avoid leaving worker tasks running after the owning scene is gone.

```gdscript
task_runner.wait_for_tasks_on_exit = true
```

---

### `task_description_prefix: String = "BackgroundTask"`

Used to generate task descriptions for debugging.

```gdscript
task_runner.task_description_prefix = "ChunkGenerationTask"
```

---

## Methods

---

### `run_task(...) -> BackgroundTaskHandle`

Starts a background task.

```gdscript
func run_task(
	task_callable: Callable,
	completed_callback: Callable = Callable(),
	failed_callback: Callable = Callable(),
	cancelled_callback: Callable = Callable(),
	bind_handle: bool = false
) -> BackgroundTaskHandle
```

Basic usage:

```gdscript
var task := task_runner.run_task(
	Callable(self, "_expensive_job")
)
```

With callbacks:

```gdscript
var task := task_runner.run_task(
	Callable(self, "_expensive_job"),
	Callable(self, "_on_job_completed"),
	Callable(self, "_on_job_failed"),
	Callable(self, "_on_job_cancelled")
)
```

With cooperative cancellation support:

```gdscript
var task := task_runner.run_task(
	Callable(self, "_expensive_cancellable_job"),
	Callable(self, "_on_job_completed"),
	Callable(self, "_on_job_failed"),
	Callable(self, "_on_job_cancelled"),
	true
)
```

When `bind_handle` is `true`, the worker callable receives the `BackgroundTaskHandle` as its first argument.

```gdscript
func _expensive_cancellable_job(task: BackgroundTaskHandle) -> Variant:
	if task.is_cancel_requested():
		return BackgroundTaskResult.failure("Cancelled.")

	return "Done"
```

---

### `poll_completed_tasks() -> void`

Checks active worker tasks and dispatches finished task signals on the main thread.

You usually do not need to call this manually if `auto_poll_tasks` is enabled.

Manual polling example:

```gdscript
task_runner.auto_poll_tasks = false

var task := task_runner.run_task(
	Callable(self, "_generate_data")
)

# Later:
task_runner.poll_completed_tasks()
```

---

### `cancel_all_tasks() -> void`

Requests cooperative cancellation for every active task owned by this runner.

```gdscript
task_runner.cancel_all_tasks()
```

This does **not** forcibly kill threads.

Tasks must check:

```gdscript
task.is_cancel_requested()
```

to stop early.

---

### `wait_for_all_tasks(dispatch_signals: bool = true) -> void`

Blocks the main thread until every active task owned by this runner finishes.

```gdscript
task_runner.wait_for_all_tasks()
```

With signal dispatch:

```gdscript
task_runner.wait_for_all_tasks(true)
```

Without signal dispatch:

```gdscript
task_runner.wait_for_all_tasks(false)
```

Use this carefully. Blocking the main thread can freeze the game temporarily.

This is most useful for shutdown, tests, tools, or controlled loading situations.

---

### `get_active_task_count() -> int`

Returns the number of active tasks owned by this runner.

```gdscript
print(task_runner.get_active_task_count())
```

---

### `has_active_tasks() -> bool`

Returns whether this runner currently owns any active tasks.

```gdscript
if task_runner.has_active_tasks():
	print("Still working...")
```

---

# BackgroundTaskHandle

`BackgroundTaskHandle` is returned by `BackgroundTaskRunner.run_task()`.

It represents one background task.

You usually use it to connect to signals, check status, or request cancellation.

---

## Signals

### `completed(result: Variant)`

Emitted on the main thread when the task completes successfully.

```gdscript
task.completed.connect(_on_task_completed)
```

```gdscript
func _on_task_completed(result: Variant) -> void:
	print(result)
```

---

### `failed(error_message: String)`

Emitted on the main thread when the task reports failure.

```gdscript
task.failed.connect(_on_task_failed)
```

```gdscript
func _on_task_failed(error_message: String) -> void:
	push_warning(error_message)
```

---

### `cancelled`

Emitted on the main thread when the task is cancelled.

```gdscript
task.cancelled.connect(_on_task_cancelled)
```

```gdscript
func _on_task_cancelled() -> void:
	print("Task cancelled.")
```

---

## Status Enum

```gdscript
BackgroundTaskHandle.Status.QUEUED
BackgroundTaskHandle.Status.RUNNING
BackgroundTaskHandle.Status.COMPLETED
BackgroundTaskHandle.Status.FAILED
BackgroundTaskHandle.Status.CANCELLED
```

Example:

```gdscript
if task.get_status() == BackgroundTaskHandle.Status.RUNNING:
	print("Task is still running.")
```

---

## Methods

---

### `request_cancel() -> void`

Requests cooperative cancellation.

```gdscript
task.request_cancel()
```

This does not instantly stop the worker thread. The worker callable must periodically check:

```gdscript
task.is_cancel_requested()
```

---

### `is_cancel_requested() -> bool`

Returns whether cancellation has been requested.

Usually used from a worker callable when `bind_handle` is enabled.

```gdscript
func _generate_data(task: BackgroundTaskHandle) -> Variant:
	for i in 100000:
		if task.is_cancel_requested():
			return BackgroundTaskResult.failure("Generation cancelled.")

		# Do work here.

	return "Done"
```

---

### `is_finished() -> bool`

Returns whether the task reached a final state:

```text
COMPLETED
FAILED
CANCELLED
```

Example:

```gdscript
if task.is_finished():
	print("Task is no longer active.")
```

---

### `is_active() -> bool`

Returns whether the task is still queued or running.

```gdscript
if task.is_active():
	print("Task is still active.")
```

---

### `get_status() -> int`

Returns the current status.

```gdscript
match task.get_status():
	BackgroundTaskHandle.Status.QUEUED:
		print("Queued.")

	BackgroundTaskHandle.Status.RUNNING:
		print("Running.")

	BackgroundTaskHandle.Status.COMPLETED:
		print("Completed.")

	BackgroundTaskHandle.Status.FAILED:
		print("Failed.")

	BackgroundTaskHandle.Status.CANCELLED:
		print("Cancelled.")
```

---

### `get_result() -> Variant`

Returns the result value if the task completed successfully.

```gdscript
var result := task.get_result()
```

Usually you should prefer the `completed(result)` signal instead.

---

### `get_error_message() -> String`

Returns the failure message if the task failed.

```gdscript
var error := task.get_error_message()
```

Usually you should prefer the `failed(error_message)` signal instead.

---

### `get_worker_task_id() -> int`

Returns the internal `WorkerThreadPool` task id.

Most users do not need this.

It is exposed mainly for debugging, testing, and advanced integration.

---

# BackgroundTaskResult

`BackgroundTaskResult` is an optional wrapper that lets a worker callable explicitly report success or failure.

A background task can return a plain value:

```gdscript
func _job() -> int:
	return 42
```

This is treated as success.

Or it can return:

```gdscript
BackgroundTaskResult.success(value)
```

or:

```gdscript
BackgroundTaskResult.failure("Something went wrong.")
```

---

## `BackgroundTaskResult.success(result_value: Variant = null)`

Reports success and passes a value to `completed(result)`.

```gdscript
func _load_save_data() -> BackgroundTaskResult:
	var data := {
		"gold": 100,
		"level": 5
	}

	return BackgroundTaskResult.success(data)
```

---

## `BackgroundTaskResult.failure(message: String)`

Reports failure and passes a message to `failed(error_message)`.

```gdscript
func _load_save_data() -> BackgroundTaskResult:
	if not FileAccess.file_exists("user://save.tres"):
		return BackgroundTaskResult.failure("Save file does not exist.")

	return BackgroundTaskResult.success("Loaded.")
```

---

## Returning Plain Values vs BackgroundTaskResult

These are equivalent successful results:

```gdscript
func _job() -> int:
	return 42
```

```gdscript
func _job() -> BackgroundTaskResult:
	return BackgroundTaskResult.success(42)
```

Use a plain value when the task cannot fail in an expected way.

Use `BackgroundTaskResult` when the task may intentionally report failure.

---

## Example: Chunk Generation

```gdscript
extends Node

## Scene-local task runner.
@onready var task_runner: BackgroundTaskRunner = $BackgroundTaskRunner


## Starts generating chunk data in the background.
func request_chunk(chunk_position: Vector2i) -> void:
	var task := task_runner.run_task(
		Callable(self, "_generate_chunk_data").bind(chunk_position)
	)

	task.completed.connect(_on_chunk_data_generated)
	task.failed.connect(_on_chunk_generation_failed)


## Runs on a worker thread.
func _generate_chunk_data(chunk_position: Vector2i) -> Dictionary:
	var tile_ids: Array[int] = []
	var chunk_size := 64

	for y in chunk_size:
		for x in chunk_size:
			var world_x := chunk_position.x * chunk_size + x
			var world_y := chunk_position.y * chunk_size + y
			var tile_id := abs(world_x + world_y) % 4
			tile_ids.append(tile_id)

	return {
		"chunk_position": chunk_position,
		"chunk_size": chunk_size,
		"tile_ids": tile_ids
	}


## Runs on the main thread.
func _on_chunk_data_generated(result: Dictionary) -> void:
	var chunk_position: Vector2i = result["chunk_position"]
	var tile_ids: Array = result["tile_ids"]

	print("Apply chunk to scene: ", chunk_position)
	print("Tile count: ", tile_ids.size())

	# This is where you would safely update TileMapLayer, MeshInstances, Nodes, etc.


## Runs on the main thread.
func _on_chunk_generation_failed(error_message: String) -> void:
	push_warning("Chunk generation failed: %s" % error_message)
```

---

## Example: Cancellable Chunk Generation

```gdscript
extends Node

## Scene-local task runner.
@onready var task_runner: BackgroundTaskRunner = $BackgroundTaskRunner

## Currently running generation task.
var current_generation_task: BackgroundTaskHandle


## Starts cancellable generation.
func start_generation() -> void:
	current_generation_task = task_runner.run_task(
		Callable(self, "_generate_data_with_cancellation"),
		Callable(self, "_on_generation_completed"),
		Callable(self, "_on_generation_failed"),
		Callable(self, "_on_generation_cancelled"),
		true
	)


## Requests cancellation.
func cancel_generation() -> void:
	if current_generation_task != null:
		current_generation_task.request_cancel()


## Runs on a worker thread.
func _generate_data_with_cancellation(task: BackgroundTaskHandle) -> Variant:
	var values: Array[int] = []

	for i in 500000:
		if task.is_cancel_requested():
			return BackgroundTaskResult.failure("Generation cancelled.")

		values.append(i % 8)

	return values


## Runs on the main thread.
func _on_generation_completed(result: Array[int]) -> void:
	print("Generated values: ", result.size())


## Runs on the main thread.
func _on_generation_failed(error_message: String) -> void:
	push_warning(error_message)


## Runs on the main thread.
func _on_generation_cancelled() -> void:
	print("Generation was cancelled.")
```

Important note: when cancellation is requested, the runner treats cancellation as the final state if the worker observes it before completion dispatch.

---

## Example: Save Serialization Data

This is useful when preparing plain save data in the background, then writing/applying it safely afterward.

```gdscript
extends Node

## Scene-local task runner.
@onready var task_runner: BackgroundTaskRunner = $BackgroundTaskRunner


## Starts preparing save data.
func prepare_save_async(raw_state: Dictionary) -> void:
	var task := task_runner.run_task(
		Callable(self, "_serialize_save_data").bind(raw_state)
	)

	task.completed.connect(_on_save_data_ready)
	task.failed.connect(_on_save_data_failed)


## Runs on a worker thread.
func _serialize_save_data(raw_state: Dictionary) -> BackgroundTaskResult:
	if raw_state.is_empty():
		return BackgroundTaskResult.failure("Cannot save empty state.")

	var save_payload := {
		"version": 1,
		"state": raw_state.duplicate(true),
		"created_at_unix": Time.get_unix_time_from_system()
	}

	return BackgroundTaskResult.success(save_payload)


## Runs on the main thread.
func _on_save_data_ready(save_payload: Dictionary) -> void:
	print("Save payload ready.")
	# Write to disk here if the APIs you use are safe for your project setup,
	# or hand this data to your SaveManager.


## Runs on the main thread.
func _on_save_data_failed(error_message: String) -> void:
	push_warning(error_message)
```

---

## Example: Manual Polling

By default, the runner automatically emits completed/failed/cancelled signals from `_process`.

If you want manual control, disable `auto_poll_tasks`.

```gdscript
extends Node

## Scene-local task runner.
@onready var task_runner: BackgroundTaskRunner = $BackgroundTaskRunner


## Configures manual polling.
func _ready() -> void:
	task_runner.auto_poll_tasks = false


## Starts a task.
func start_task() -> void:
	var task := task_runner.run_task(
		Callable(self, "_expensive_job")
	)

	task.completed.connect(_on_task_completed)


## Manually chooses when finished task signals may dispatch.
func _process(_delta: float) -> void:
	if _can_accept_background_results_now():
		task_runner.poll_completed_tasks()


## Runs on a worker thread.
func _expensive_job() -> String:
	return "Done"


## Runs on the main thread.
func _on_task_completed(result: String) -> void:
	print(result)


## Returns whether this frame is a safe time to apply results.
func _can_accept_background_results_now() -> bool:
	return true
```

Manual polling can be useful if you want to avoid applying generated results during certain gameplay states.

---

## Example: Using Callbacks Instead of Signals

You can provide callbacks directly to `run_task`.

```gdscript
var task := task_runner.run_task(
	Callable(self, "_load_data"),
	Callable(self, "_on_load_completed"),
	Callable(self, "_on_load_failed"),
	Callable(self, "_on_load_cancelled")
)
```

The callbacks run on the main thread.

```gdscript
func _load_data() -> Dictionary:
	return {
		"loaded": true
	}


func _on_load_completed(result: Dictionary) -> void:
	print("Loaded: ", result)


func _on_load_failed(error_message: String) -> void:
	push_warning(error_message)


func _on_load_cancelled() -> void:
	print("Cancelled.")
```

You can use signals, callbacks, or both.

---

## Example: Waiting for All Tasks

`wait_for_all_tasks()` blocks until active tasks finish.

```gdscript
task_runner.wait_for_all_tasks(true)
```

This can be useful for tests or controlled shutdown.

Avoid calling it during normal gameplay unless you are okay with freezing the main thread until the tasks are done.

```gdscript
func _exit_tree() -> void:
	task_runner.cancel_all_tasks()
	task_runner.wait_for_all_tasks(false)
```

---

## When To Use This Utility

Use this utility when you have work that is:

```text
Expensive enough to hurt frame rate
Mostly independent from the scene tree
Able to produce plain data as a result
Safe to finish later
```

Good examples:

```text
Generate chunk data
Generate loot tables
Calculate pathfinding routes
Prepare save data
Parse large JSON-like data
Build procedural room layouts
Generate noise maps
Run AI planning
Precompute graph/search results
```

---

## When Not To Use This Utility

Do not use this utility just to avoid writing normal code.

Do not use it for very small operations where thread overhead is larger than the work.

Avoid it for tasks that need to directly manipulate live Nodes every frame.

Bad examples:

```text
Move the player
Update enemy transforms
Spawn bullets directly
Change UI labels directly
Call add_child() from the worker
Call queue_free() from the worker
Drive AnimationPlayer from the worker
Modify physics bodies from the worker
```

Instead, return data and apply the data on the main thread.

---

## Common Pattern: Generate Data, Then Apply Data

Recommended:

```gdscript
func _generate_enemy_spawn_data() -> Array[Dictionary]:
	var spawns: Array[Dictionary] = []

	for i in 100:
		spawns.append({
			"position": Vector2(i * 32, 0),
			"enemy_type": &"basic"
		})

	return spawns
```

Then on the main thread:

```gdscript
func _on_enemy_spawn_data_ready(spawns: Array[Dictionary]) -> void:
	for spawn_data in spawns:
		var enemy := enemy_scene.instantiate()
		enemy.global_position = spawn_data["position"]
		add_child(enemy)
```

Avoid:

```gdscript
func _generate_enemy_spawn_data() -> void:
	var enemy := enemy_scene.instantiate()
	add_child(enemy) # Do not do this from a worker thread.
```

---

## Error Handling

This utility does not catch arbitrary script errors inside the worker callable.

If a task can fail in an expected way, return:

```gdscript
return BackgroundTaskResult.failure("Useful error message.")
```

Example:

```gdscript
func _build_layout(width: int, height: int) -> BackgroundTaskResult:
	if width <= 0 or height <= 0:
		return BackgroundTaskResult.failure("Width and height must be positive.")

	var layout := []
	return BackgroundTaskResult.success(layout)
```

Expected failures should be represented with `BackgroundTaskResult.failure(...)`.

Unexpected script errors should still be fixed as bugs.

---

## Cancellation Model

Cancellation is cooperative.

Calling:

```gdscript
task.request_cancel()
```

does not forcibly kill the task.

The worker function needs to check:

```gdscript
task.is_cancel_requested()
```

Example:

```gdscript
func _long_job(task: BackgroundTaskHandle) -> Variant:
	for i in 100000:
		if task.is_cancel_requested():
			return BackgroundTaskResult.failure("Cancelled.")

		# Continue work.

	return "Done"
```

To receive the handle inside the worker callable, pass `bind_handle = true`:

```gdscript
var task := task_runner.run_task(
	Callable(self, "_long_job"),
	Callable(self, "_on_done"),
	Callable(self, "_on_failed"),
	Callable(self, "_on_cancelled"),
	true
)
```

---

## Scene-Local Design

This utility is intentionally not an Autoload.

Reasons:

```text
Not every project needs background task management.
Not every scene needs threading.
Scene-local ownership makes cleanup easier.
Different systems may want different polling/cancellation behavior.
```

Recommended usage:

```text
World
  BackgroundTaskRunner
  ChunkManager

MainMenu
  BackgroundTaskRunner

GenerationTool
  BackgroundTaskRunner
```

Only add it where it is useful.

---


## Full Minimal Example

Scene:

```text
TestScene
  BackgroundTaskRunner
```

Script:

```gdscript
extends Node

## Scene-local background task runner.
@onready var task_runner: BackgroundTaskRunner = $BackgroundTaskRunner


## Starts a test task.
func _ready() -> void:
	var task := task_runner.run_task(
		Callable(self, "_expensive_sum").bind(10, 32)
	)

	task.completed.connect(_on_sum_completed)
	task.failed.connect(_on_sum_failed)


## Runs on a worker thread.
func _expensive_sum(a: int, b: int) -> int:
	OS.delay_msec(100)
	return a + b


## Runs on the main thread.
func _on_sum_completed(result: int) -> void:
	print("Result: ", result)


## Runs on the main thread.
func _on_sum_failed(error_message: String) -> void:
	push_warning(error_message)
```

Expected output:

```text
Result: 42
```

---

## Best Practices

Prefer returning plain `Dictionary`, `Array`, `int`, `float`, `String`, `Vector2`, `Vector3`, and other data-like values.

Avoid returning live `Node` references from worker threads.

Keep worker functions focused and isolated.

Use `BackgroundTaskResult.failure(...)` for expected failures.

Use cancellation checks in long loops.

Apply results to the scene only from `completed(...)` callbacks/signals.

Use scene-local runners rather than a global task manager unless your project truly needs a global system.

---

## Troubleshooting

### My task completed, but nothing happened.

Make sure either:

```gdscript
task_runner.auto_poll_tasks = true
```

or you manually call:

```gdscript
task_runner.poll_completed_tasks()
```

Also make sure you connect the signal immediately after starting the task, especially if the task is extremely fast.

---

### My cancellation request did nothing.

Cancellation is cooperative.

The task must check:

```gdscript
task.is_cancel_requested()
```

inside the worker callable.

Also make sure `bind_handle` is set to `true` if the task needs access to the handle.

---

### My game crashed or produced weird errors.

Check whether the worker callable is touching Nodes, the scene tree, physics, UI, animations, or other main-thread-only systems.

Move that work into the `completed(result)` handler.

---

### My failed signal is not emitted after a script error.

Expected failures should be returned manually:

```gdscript
return BackgroundTaskResult.failure("Something went wrong.")
```

Unexpected script errors are still bugs in the worker callable.

---

### My task freezes the game.

You may be calling:

```gdscript
wait_for_all_tasks()
```

during gameplay.

That method blocks the main thread until tasks finish. Prefer signals/callbacks for normal gameplay.

---

## Summary

Use `BackgroundTaskRunner` when you want a scene-local way to run expensive plain-data work in the background.

Use `BackgroundTaskHandle` to observe task status, connect to completion signals, and request cancellation.

Use `BackgroundTaskResult` when a task needs to explicitly report success or failure.

The core workflow is:

```text
1. Start task with BackgroundTaskRunner.run_task().
2. Do plain-data work on a worker thread.
3. Receive completed/failed/cancelled on the main thread.
4. Apply results to the scene safely.
```
