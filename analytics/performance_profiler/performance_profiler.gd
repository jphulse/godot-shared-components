class_name PerformanceProfiler
extends RefCounted

## Whether profiling is globally enabled.
static var enabled: bool = true

## Whether every profiled call should be printed immediately.
static var print_each_call: bool = true

## Whether profiling should only run in debug builds/editor.
static var debug_builds_only: bool = true

## Default monitors captured by execute_extended().
static var default_extended_monitors: Dictionary = {
	&"memory_static": Performance.MEMORY_STATIC,
	&"memory_static_max": Performance.MEMORY_STATIC_MAX,
	&"message_buffer_max": Performance.MEMORY_MESSAGE_BUFFER_MAX,
	&"object_count": Performance.OBJECT_COUNT,
	&"resource_count": Performance.OBJECT_RESOURCE_COUNT,
	&"node_count": Performance.OBJECT_NODE_COUNT,
	&"orphan_node_count": Performance.OBJECT_ORPHAN_NODE_COUNT,
}

## Stores total elapsed microseconds per profiling label.
static var total_usec_by_label: Dictionary = {}

## Stores call counts per profiling label.
static var call_count_by_label: Dictionary = {}

## Stores maximum single-call elapsed microseconds per profiling label.
static var max_usec_by_label: Dictionary = {}


## Executes a callable. In non-debug builds, this only calls the callable directly.
static func execute(callable: Callable, label: StringName = &"") -> Variant:
	if not callable.is_valid():
		push_error("SimpleProfiler received an invalid Callable.")
		return null

	if not _should_profile():
		return callable.call()

	var resolved_label: StringName = _resolve_label(callable, label)
	var start_usec: int = Time.get_ticks_usec()
	var result: Variant = callable.call()
	var elapsed_usec: int = Time.get_ticks_usec() - start_usec

	_record_sample(resolved_label, elapsed_usec)

	if print_each_call:
		print("%s took %.3f ms" % [resolved_label, elapsed_usec / 1000.0])

	return result


## Executes a callable and returns timing plus resource monitor data.
## In non-debug builds, this only calls the callable and returns a minimal ProfileSample.
static func execute_extended(
	callable: Callable,
	label: StringName = &"",
	monitors: Dictionary = {}
) -> ProfileSample:
	var sample: ProfileSample = ProfileSample.new()

	if not callable.is_valid():
		push_error("SimpleProfiler received an invalid Callable.")
		return sample

	if not _should_profile():
		sample.label = _resolve_label(callable, label)
		sample.result = callable.call()
		return sample

	var resolved_label: StringName = _resolve_label(callable, label)
	var selected_monitors: Dictionary = monitors

	if selected_monitors.is_empty():
		selected_monitors = default_extended_monitors

	sample.label = resolved_label
	sample.before = _capture_monitors(selected_monitors)

	var start_usec: int = Time.get_ticks_usec()
	sample.result = callable.call()
	sample.elapsed_usec = Time.get_ticks_usec() - start_usec

	sample.after = _capture_monitors(selected_monitors)
	sample.delta = _calculate_delta(sample.before, sample.after)

	_record_sample(resolved_label, sample.elapsed_usec)

	if print_each_call:
		sample.print_report()

	return sample


## Returns true when profiling should actually collect data.
static func _should_profile() -> bool:
	if not enabled:
		return false

	if debug_builds_only and not OS.is_debug_build():
		return false

	return true


## Returns the average execution time for a label in milliseconds.
static func get_average_msec(label: StringName) -> float:
	var call_count: int = call_count_by_label.get(label, 0)

	if call_count == 0:
		return 0.0

	var total_usec: int = total_usec_by_label.get(label, 0)
	return float(total_usec) / float(call_count) / 1000.0


## Returns the maximum single-call execution time for a label in milliseconds.
static func get_max_msec(label: StringName) -> float:
	return float(max_usec_by_label.get(label, 0)) / 1000.0


## Returns the number of recorded calls for a label.
static func get_call_count(label: StringName) -> int:
	return call_count_by_label.get(label, 0)


## Clears all accumulated timing data.
static func clear() -> void:
	total_usec_by_label.clear()
	call_count_by_label.clear()
	max_usec_by_label.clear()


## Records timing information for a completed call.
static func _record_sample(label: StringName, elapsed_usec: int) -> void:
	total_usec_by_label[label] = total_usec_by_label.get(label, 0) + elapsed_usec
	call_count_by_label[label] = call_count_by_label.get(label, 0) + 1
	max_usec_by_label[label] = max(max_usec_by_label.get(label, 0), elapsed_usec)


## Captures a snapshot of the requested performance monitors.
static func _capture_monitors(monitors: Dictionary) -> Dictionary:
	var snapshot: Dictionary = {}

	for monitor_label: StringName in monitors.keys():
		var monitor_id: int = monitors[monitor_label]
		snapshot[monitor_label] = Performance.get_monitor(monitor_id)

	return snapshot


## Calculates after-before deltas for captured monitor values.
static func _calculate_delta(before: Dictionary, after: Dictionary) -> Dictionary:
	var result: Dictionary = {}

	for monitor_label: StringName in after.keys():
		result[monitor_label] = after.get(monitor_label, 0.0) - before.get(monitor_label, 0.0)

	return result


## Resolves the label used to store and print profiling data.
static func _resolve_label(callable: Callable, label: StringName) -> StringName:
	if not label.is_empty():
		return label

	return StringName(str(callable))
