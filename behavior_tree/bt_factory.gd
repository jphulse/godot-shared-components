class_name BTFactory
extends RefCounted


#region Basic composites

static func sequence(children: Array[BehaviorNode] = []) -> BTSequence:
	var node := BTSequence.new()
	for child: BehaviorNode in children:
		node.add_child_node(child)
	return node


static func selector(children: Array[BehaviorNode] = []) -> BTSelector:
	var node := BTSelector.new()
	for child: BehaviorNode in children:
		node.add_child_node(child)
	return node


static func random_selector(children: Array[BehaviorNode] = []) -> BTRandomSelector:
	var node := BTRandomSelector.new()
	for child: BehaviorNode in children:
		node.add_child_node(child)
	return node

#endregion


#region Memory composites

static func memory_sequence(children: Array[BehaviorNode] = []) -> BTMemorySequence:
	var node := BTMemorySequence.new()
	for child: BehaviorNode in children:
		node.add_child_node(child)
	return node


static func memory_selector(children: Array[BehaviorNode] = []) -> BTMemorySelector:
	var node := BTMemorySelector.new()
	for child: BehaviorNode in children:
		node.add_child_node(child)
	return node


static func memory_random_selector(children: Array[BehaviorNode] = []) -> BTMemoryRandomSelector:
	var node := BTMemoryRandomSelector.new()
	for child: BehaviorNode in children:
		node.add_child_node(child)
	return node

#endregion


#region Parallel composites

static func parallel(
	children: Array[BehaviorNode] = [],
	success_threshold: int = 1,
	failure_threshold: int = 1
) -> BTParallel:
	var node := BTParallel.new(success_threshold, failure_threshold)
	for child: BehaviorNode in children:
		node.add_child_node(child)
	return node


static func parallel_sequence(children: Array[BehaviorNode] = []) -> BTParallelSequence:
	var node := BTParallelSequence.new()
	for child: BehaviorNode in children:
		node.add_child_node(child)
	return node


static func parallel_selector(children: Array[BehaviorNode] = []) -> BTParallelSelector:
	var node := BTParallelSelector.new()
	for child: BehaviorNode in children:
		node.add_child_node(child)
	return node

#endregion


#region Leaves

static func condition(callable: Callable, debug_name: String = "Condition") -> BTConditionCallable:
	return BTConditionCallable.new(callable, debug_name)


static func action(callable: Callable, debug_name: String = "Action") -> BTActionCallable:
	return BTActionCallable.new(callable, debug_name)

#endregion


#region Basic decorators

static func inverter(child: BehaviorNode) -> BTInverter:
	return BTInverter.new(child)


static func always_success(child: BehaviorNode = null) -> BTAlwaysSuccess:
	return BTAlwaysSuccess.new(child)


static func always_failure(child: BehaviorNode = null) -> BTAlwaysFailure:
	return BTAlwaysFailure.new(child)


static func cooldown(child: BehaviorNode, seconds: float) -> BTCooldown:
	return BTCooldown.new(child, seconds)


static func timeout(child: BehaviorNode, seconds: float) -> BTTimeout:
	return BTTimeout.new(child, seconds)


static func chance(
	child: BehaviorNode,
	success_chance: float,
	roll_once_while_running: bool = true
) -> BTChance:
	return BTChance.new(child, success_chance, roll_once_while_running)

#endregion


#region Repeat/control decorators

static func repeater(child: BehaviorNode, repeat_count: int = -1) -> BTRepeater:
	return BTRepeater.new(child, repeat_count)


static func repeat_until_failure(child: BehaviorNode) -> BTRepeatUntilFailure:
	return BTRepeatUntilFailure.new(child)


static func repeat_until_success(child: BehaviorNode) -> BTRepeatUntilSuccess:
	return BTRepeatUntilSuccess.new(child)


static func limit_runs(
	child: BehaviorNode,
	max_runs: int = 1,
	count_only_success: bool = true
) -> BTLimitRuns:
	return BTLimitRuns.new(child, max_runs, count_only_success)


static func delay(child: BehaviorNode, seconds: float) -> BTDelay:
	return BTDelay.new(child, seconds)

#endregion
