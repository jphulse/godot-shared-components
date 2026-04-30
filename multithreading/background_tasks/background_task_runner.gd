class_name BackgroundTaskRunner
extends Node

## Whether this runner should automatically poll for completed tasks in _process.
@export var auto_poll_tasks: bool = true

## Whether tasks submitted by this runner should use Godot's high-priority WorkerThreadPool queue.
@export var high_priority: bool = false

## Whether this runner should request cancellation and wait for active tasks when leaving the scene tree.
@export var wait_for_tasks_on_exit: bool = true

## Prefix used for WorkerThreadPool task descriptions.
@export var task_description_prefix: String = "BackgroundTask"

## All task handles currently owned by this runner.
var _active_tasks: Array[BackgroundTaskHandle] = []

## Counter used to make task descriptions easier to distinguish in debugging tools.
var _issued_task_count: int = 0


## Initializes process polling based on auto_poll_tasks.
func _ready() -> void:
	set_process(false)


## Polls active background tasks if auto polling is enabled.
func _process(_delta: float) -> void:
	if auto_poll_tasks:
		poll_completed_tasks()


## Requests cancellation and optionally waits for tasks before this runner is freed.
func _exit_tree() -> void:
	if wait_for_tasks_on_exit:
		cancel_all_tasks()
		wait_for_all_tasks(false)


## Starts a background task and returns a handle that can be used to observe the result.
func run_task(
	task_callable: Callable,
	completed_callback: Callable = Callable(),
	failed_callback: Callable = Callable(),
	cancelled_callback: Callable = Callable(),
	bind_handle: bool = false
) -> BackgroundTaskHandle:
	var handle := BackgroundTaskHandle.new()
	handle._set_callbacks(completed_callback, failed_callback, cancelled_callback)

	if not task_callable.is_valid():
		handle._mark_failed_from_worker("Invalid background task callable.")
		call_deferred("_dispatch_finished_handle", handle)
		return handle

	_issued_task_count += 1

	var task_description := "%s %d" % [task_description_prefix, _issued_task_count]

	var worker_callable := func() -> void:
		BackgroundTaskRunner._execute_task_on_worker(task_callable, handle, bind_handle)

	var worker_task_id := WorkerThreadPool.add_task(worker_callable, high_priority, task_description)
	handle._set_worker_task_id(worker_task_id)

	_active_tasks.append(handle)

	if auto_poll_tasks:
		set_process(true)

	return handle


## Polls all active tasks and dispatches finished task signals on the main thread.
func poll_completed_tasks() -> void:
	var finished_tasks: Array[BackgroundTaskHandle] = []

	for handle in _active_tasks:
		var worker_task_id := handle.get_worker_task_id()

		if worker_task_id >= 0 and WorkerThreadPool.is_task_completed(worker_task_id):
			WorkerThreadPool.wait_for_task_completion(worker_task_id)
			finished_tasks.append(handle)

	for handle in finished_tasks:
		_active_tasks.erase(handle)
		handle._dispatch_finished_on_main_thread()

	if auto_poll_tasks and _active_tasks.is_empty():
		set_process(false)


## Requests cancellation for every active task owned by this runner.
func cancel_all_tasks() -> void:
	for handle in _active_tasks:
		handle.request_cancel()


## Blocks the main thread until every active task is finished.
func wait_for_all_tasks(dispatch_signals: bool = true) -> void:
	var task_snapshot := _active_tasks.duplicate()

	for handle : BackgroundTaskHandle in task_snapshot:
		var worker_task_id := handle.get_worker_task_id()

		if worker_task_id >= 0:
			WorkerThreadPool.wait_for_task_completion(worker_task_id)

		_active_tasks.erase(handle)

		if dispatch_signals:
			handle._dispatch_finished_on_main_thread()

	if auto_poll_tasks:
		set_process(false)


## Returns the number of tasks currently owned by this runner.
func get_active_task_count() -> int:
	return _active_tasks.size()


## Returns whether this runner currently owns any active tasks.
func has_active_tasks() -> bool:
	return not _active_tasks.is_empty()


## Dispatches a finished handle after run_task has already returned.
func _dispatch_finished_handle(handle: BackgroundTaskHandle) -> void:
	handle._dispatch_finished_on_main_thread()


## Executes a task on a worker thread.
static func _execute_task_on_worker(task_callable: Callable, handle: BackgroundTaskHandle, bind_handle: bool) -> void:
	if handle.is_cancel_requested():
		handle._mark_cancelled_from_worker()
		return

	handle._mark_running_from_worker()

	var raw_result: Variant = null

	if bind_handle:
		raw_result = task_callable.call(handle)
	else:
		raw_result = task_callable.call()

	if handle.is_cancel_requested():
		handle._mark_cancelled_from_worker()
		return

	if raw_result is BackgroundTaskResult:
		var task_result := raw_result as BackgroundTaskResult

		if task_result.succeeded:
			handle._mark_completed_from_worker(task_result.value)
		else:
			handle._mark_failed_from_worker(task_result.error_message)
	else:
		handle._mark_completed_from_worker(raw_result)
