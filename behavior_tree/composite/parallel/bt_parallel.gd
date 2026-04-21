class_name BTParallel
extends BTComposite

@export var success_threshold : int = 1
@export var failure_threshold : int = 1


func _init(_success_threshold : int = 1, _failure_threshold : int = 1) -> void:
	success_threshold = _success_threshold
	failure_threshold = _failure_threshold


## Runs all children in order, and returns success or failure based on whether thresholds were exceeded
## will prioritize returning success, if neither threshold was met returns running
func tick(actor : Node, blackboard : Dictionary) -> Status:
	if behavior_children.is_empty():
		return Status.SUCCESS

	var success_count : int = 0
	var failure_count : int = 0

	for child : BehaviorNode in behavior_children:
		var result : Status = child.tick(actor, blackboard)

		match result:
			Status.SUCCESS:
				success_count += 1
			Status.FAILURE:
				failure_count += 1
			Status.RUNNING:
				pass

	if success_count >= success_threshold:
		return Status.SUCCESS

	if failure_count >= failure_threshold:
		return Status.FAILURE

	return Status.RUNNING
