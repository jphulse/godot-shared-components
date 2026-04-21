class_name BTRepeater
extends BTDecorator

## Negative means repeat forever.
var repeat_count : int = -1
var current_count : int = 0


func _init(_child : BehaviorNode = null, _repeat_count : int = -1) -> void:
	child = _child
	repeat_count = _repeat_count

## Repeats the child operation, returns success if the child completes repeat_count times
func tick(actor : Node, blackboard : Dictionary) -> Status:
	if child == null:
		return Status.FAILURE

	while repeat_count < 0 or current_count < repeat_count:
		var result : Status = child.tick(actor, blackboard)

		if result == Status.RUNNING:
			return Status.RUNNING

		current_count += 1
		child.reset()

		# Avoid an infinite loop in a single frame for infinite repeaters.
		if repeat_count < 0:
			return Status.RUNNING

	current_count = 0
	return Status.SUCCESS


func reset() -> void:
	current_count = 0
	super.reset()
