class_name BackgroundTaskHandle
extends RefCounted

## Emitted on the main thread when the task completes successfully.
signal completed(result: Variant)

## Emitted on the main thread when the task reports failure.
signal failed(error_message: String)

## Emitted on the main thread when the task is cancelled.
signal cancelled

## Possible lifecycle states for a background task.
enum Status {
	QUEUED,
	RUNNING,
	COMPLETED,
	FAILED,
	CANCELLED
}

## Protects task state shared between the main thread and worker threads.
var _mutex: Mutex = Mutex.new()

## The current lifecycle status of this task.
var _status: int = Status.QUEUED

## The WorkerThreadPool task id assigned by Godot.
var _worker_task_id: int = -1

## The value produced by the task if it completed successfully.
var _result: Variant = null

## The failure message produced by the task if it failed.
var _error_message: String = ""

## Whether cancellation has been requested by the main thread.
var _cancel_requested: bool = false

## Optional callback invoked on the main thread when the task succeeds.
var _completed_callback: Callable = Callable()

## Optional callback invoked on the main thread when the task fails.
var _failed_callback: Callable = Callable()

## Optional callback invoked on the main thread when the task is cancelled.
var _cancelled_callback: Callable = Callable()


## Requests cooperative cancellation of this task.
func request_cancel() -> void:
	_mutex.lock()
	if _status == Status.QUEUED or _status == Status.RUNNING:
		_cancel_requested = true
	_mutex.unlock()


## Returns whether cancellation has been requested.
func is_cancel_requested() -> bool:
	_mutex.lock()
	var requested := _cancel_requested
	_mutex.unlock()
	return requested


## Returns whether the task has reached a final state.
func is_finished() -> bool:
	var current_status := get_status()
	return current_status == Status.COMPLETED or current_status == Status.FAILED or current_status == Status.CANCELLED


## Returns whether the task is still queued or running.
func is_active() -> bool:
	return not is_finished()


## Returns the current task status.
func get_status() -> int:
	_mutex.lock()
	var current_status := _status
	_mutex.unlock()
	return current_status


## Returns the WorkerThreadPool task id.
func get_worker_task_id() -> int:
	_mutex.lock()
	var task_id := _worker_task_id
	_mutex.unlock()
	return task_id


## Returns the successful result value, or null if no result exists.
func get_result() -> Variant:
	_mutex.lock()
	var current_result := _result
	_mutex.unlock()
	return current_result


## Returns the failure message, or an empty string if no failure exists.
func get_error_message() -> String:
	_mutex.lock()
	var current_error_message := _error_message
	_mutex.unlock()
	return current_error_message


## Stores the WorkerThreadPool task id assigned by Godot.
func _set_worker_task_id(task_id: int) -> void:
	_mutex.lock()
	_worker_task_id = task_id
	_mutex.unlock()


## Stores optional callbacks that should run on the main thread after completion.
func _set_callbacks(completed_callback: Callable, failed_callback: Callable, cancelled_callback: Callable) -> void:
	_completed_callback = completed_callback
	_failed_callback = failed_callback
	_cancelled_callback = cancelled_callback


## Marks this task as running.
func _mark_running_from_worker() -> void:
	_mutex.lock()
	if _status == Status.QUEUED:
		_status = Status.RUNNING
	_mutex.unlock()


## Marks this task as completed from a worker thread.
func _mark_completed_from_worker(task_result: Variant) -> void:
	_mutex.lock()
	if _cancel_requested:
		_status = Status.CANCELLED
	else:
		_result = task_result
		_error_message = ""
		_status = Status.COMPLETED
	_mutex.unlock()


## Marks this task as failed from a worker thread.
func _mark_failed_from_worker(message: String) -> void:
	_mutex.lock()
	if _cancel_requested:
		_status = Status.CANCELLED
	else:
		_result = null
		_error_message = message
		_status = Status.FAILED
	_mutex.unlock()


## Marks this task as cancelled from a worker thread.
func _mark_cancelled_from_worker() -> void:
	_mutex.lock()
	_cancel_requested = true
	_status = Status.CANCELLED
	_mutex.unlock()


## Emits the correct final signal from the main thread.
func _dispatch_finished_on_main_thread() -> void:
	var current_status := get_status()

	match current_status:
		Status.COMPLETED:
			var current_result := get_result()
			completed.emit(current_result)

			if _completed_callback.is_valid():
				_completed_callback.call(current_result)

		Status.FAILED:
			var current_error_message := get_error_message()
			failed.emit(current_error_message)

			if _failed_callback.is_valid():
				_failed_callback.call(current_error_message)

		Status.CANCELLED:
			cancelled.emit()

			if _cancelled_callback.is_valid():
				_cancelled_callback.call()
