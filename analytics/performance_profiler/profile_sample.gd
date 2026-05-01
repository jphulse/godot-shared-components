class_name ProfileSample
extends RefCounted

## Label used to identify this profiling sample.
var label: StringName = &""

## Value returned by the profiled callable.
var result: Variant = null

## Elapsed execution time in microseconds.
var elapsed_usec: int = 0

## Performance monitor values captured before execution.
var before: Dictionary = {}

## Performance monitor values captured after execution.
var after: Dictionary = {}

## Difference between the after and before monitor values.
var delta: Dictionary = {}


## Returns the elapsed execution time in milliseconds.
func get_elapsed_msec() -> float:
	return float(elapsed_usec) / 1000.0


## Returns the after value for a monitor label.
func get_total(monitor_label: StringName) -> float:
	return after.get(monitor_label, 0.0)


## Returns the delta value for a monitor label.
func get_delta(monitor_label: StringName) -> float:
	return delta.get(monitor_label, 0.0)


## Prints this sample in a readable format.
func print_report() -> void:
	print("--- ProfileSample: %s ---" % label)
	print("time: %.3f ms" % get_elapsed_msec())

	for monitor_label: StringName in after.keys():
		var total_value: float = after.get(monitor_label, 0.0)
		var delta_value: float = delta.get(monitor_label, 0.0)

		print("%s | total: %s | delta: %+s" % [
			monitor_label,
			str(total_value),
			str(delta_value),
		])
