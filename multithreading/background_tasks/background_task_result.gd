class_name BackgroundTaskResult
extends RefCounted

## Whether the background task should be treated as successful.
var succeeded: bool = true

## The value returned by a successful background task.
var value: Variant = null

## The error message returned by a failed background task.
var error_message: String = ""


## Creates a successful task result.
static func success(result_value: Variant = null) -> BackgroundTaskResult:
	var task_result := BackgroundTaskResult.new()
	task_result.succeeded = true
	task_result.value = result_value
	task_result.error_message = ""
	return task_result


## Creates a failed task result.
static func failure(message: String) -> BackgroundTaskResult:
	var task_result := BackgroundTaskResult.new()
	task_result.succeeded = false
	task_result.value = null
	task_result.error_message = message
	return task_result
