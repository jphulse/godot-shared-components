# Behavior Tree

This folder contains a reusable code-based behavior tree implementation for Godot.

Behavior trees are useful for AI, enemy logic, NPC behavior, boss patterns, interactables, and other decision-making systems. This implementation is designed to be generic: the shared addon provides the behavior tree structure, while individual game projects provide their own game-specific actions and conditions.

## Folder Structure

```text
behavior_tree
|
|-- behavior_tree.gd
|-- behavior_node.gd
|-- bt_factory.gd
|
|-- composites
|   |-- bt_composite.gd
|   |-- bt_sequence.gd
|   |-- bt_selector.gd
|   |-- bt_random_selector.gd
|   |
|   |-- memory_composites
|   |   |-- bt_memory_composite.gd
|   |   |-- bt_memory_sequence.gd
|   |   |-- bt_memory_selector.gd
|   |   |-- bt_memory_random_selector.gd
|   |
|   |-- parallel
|       |-- bt_parallel.gd
|       |-- bt_parallel_sequence.gd
|       |-- bt_parallel_selector.gd
|
|-- decorators
|   |-- bt_decorator.gd
|   |-- bt_inverter.gd
|   |-- bt_always_success.gd
|   |-- bt_always_failure.gd
|   |-- bt_cooldown.gd
|   |-- bt_timeout.gd
|   |-- bt_repeater.gd
|   |-- bt_repeat_until_failure.gd
|   |-- bt_repeat_until_success.gd
|   |-- bt_limit_runs.gd
|   |-- bt_delay.gd
|   |-- bt_chance.gd
|
|-- leaves
	|-- bt_action_callable.gd
	|-- bt_condition_callable.gd
```

## Core Concepts

A behavior tree is made of behavior nodes. Each node returns one of three statuses when ticked:

```gdscript
BehaviorNode.Status.SUCCESS
BehaviorNode.Status.FAILURE
BehaviorNode.Status.RUNNING
```

* `SUCCESS` means the node completed successfully.
* `FAILURE` means the node failed.
* `RUNNING` means the node is still in progress and should continue on a future tick.

The tree is usually ticked every frame, every physics frame, or manually from game code.

## Core Classes

### `BehaviorTree`

`BehaviorTree` is the runner/controller for a behavior tree. It stores the root node, actor, blackboard, tick mode, and most recent status.

Typical usage:

```gdscript
@onready var behavior_tree: BehaviorTree = $BehaviorTree


func _ready() -> void:
	var root := BTSelector.new()
	behavior_tree.set_root(root)
```

### `BehaviorNode`

`BehaviorNode` is the base class for all behavior tree nodes.

All behavior nodes implement:

```gdscript
func tick(actor: Node, blackboard: Dictionary) -> Status:
	return Status.FAILURE
```

They may also implement:

```gdscript
func reset() -> void:
	pass
```

### Actor

The `actor` is the node that owns or performs the behavior. For example, this might be an enemy, NPC, boss, or interactable.

### Blackboard

The blackboard is a shared `Dictionary` passed through the tree. It can store shared state such as:

```gdscript
blackboard["player"] = player
blackboard["target_position"] = target_position
blackboard["last_seen_player_position"] = last_seen_player_position
```

## Leaf Nodes

Leaf nodes are where game-specific behavior usually happens.

### `BTConditionCallable`

`BTConditionCallable` wraps a callable that returns a `bool`.

```gdscript
func _can_see_player(actor: Node, blackboard: Dictionary) -> bool:
	var player: Node2D = blackboard.get("player", null)

	if player == null or not is_instance_valid(player):
		return false

	return actor.global_position.distance_to(player.global_position) < 300.0
```

Usage:

```gdscript
var condition := BTConditionCallable.new(_can_see_player)
```

Return behavior:

```text
true  -> SUCCESS
false -> FAILURE
```

### `BTActionCallable`

`BTActionCallable` wraps a callable that performs an action.

The callable should return a behavior tree status:

```gdscript
func _chase_player(actor: Node, blackboard: Dictionary) -> BehaviorNode.Status:
	var player: Node2D = blackboard.get("player", null)

	if player == null or not is_instance_valid(player):
		return BehaviorNode.Status.FAILURE

	actor.move_toward(player.global_position)
	return BehaviorNode.Status.RUNNING
```

Usage:

```gdscript
var action := BTActionCallable.new(_chase_player)
```

## Composite Nodes

Composite nodes contain multiple child behavior nodes.

Basic composites are stored directly in `composites/`.

Memory composites are stored in `composites/memory_composites/`. These preserve running state across ticks.

Parallel composites are stored in `composites/parallel/`. These tick multiple children during the same tree tick.

### `BTSequence`

Runs children from left to right.

Returns:

* `FAILURE` when any child fails.
* `RUNNING` when any child is running.
* `SUCCESS` only when all children succeed.

Use this for ordered requirements:

```text
Sequence
|-- CanSeePlayer
|-- ChasePlayer
```

Meaning:

```text
If the enemy can see the player, chase the player.
```

### `BTSelector`

Runs children from left to right until one succeeds or runs.

Returns:

* `SUCCESS` when any child succeeds.
* `RUNNING` when any child is running.
* `FAILURE` only when all children fail.

Use this for priority/fallback behavior:

```text
Selector
|-- ChasePlayer
|-- SearchForPlayer
|-- Patrol
```

Meaning:

```text
Try to chase. If that fails, search. If that fails, patrol.
```

### `BTRandomSelector`

Tries children in a random order each tick.

Returns the first `SUCCESS` or `RUNNING`. Returns `FAILURE` only if all children fail.

Useful for idle variety:

```text
RandomSelector
|-- LookAround
|-- Wander
|-- PlayIdleAnimation
```

### `BTMemorySequence`

Like `BTSequence`, but remembers the currently running child.

Use this when a multi-step behavior should continue where it left off instead of restarting from the first child every tick.

```text
MemorySequence
|-- MoveToAttackRange
|-- PlayAttackWindup
|-- DealDamage
```

### `BTMemorySelector`

Like `BTSelector`, but remembers the currently running child.

Use this when a selected behavior should continue until it succeeds or fails.

### `BTMemoryRandomSelector`

Like `BTRandomSelector`, but remembers the currently running child.

Use this when choosing a random behavior that may take multiple ticks to finish.

### `BTParallel`

Ticks all children every tick and uses success/failure thresholds to determine the result.

Use this for advanced simultaneous behavior.

### `BTParallelSequence`

Ticks all children every tick.

Returns:

* `FAILURE` if any child fails.
* `SUCCESS` if all children succeed.
* `RUNNING` otherwise.

Useful for simultaneous requirements:

```text
ParallelSequence
|-- MoveTowardTarget
|-- FaceTarget
|-- PlayChargeAnimation
```

### `BTParallelSelector`

Ticks all children every tick.

Returns:

* `SUCCESS` if any child succeeds.
* `FAILURE` if all children fail.
* `RUNNING` otherwise.

## Decorator Nodes

Decorator nodes wrap one child and modify the child’s result or execution.

### `BTInverter`

Flips success and failure.

```text
SUCCESS -> FAILURE
FAILURE -> SUCCESS
RUNNING -> RUNNING
```

Useful for `not` logic.

```text
Inverter
|-- CanSeePlayer
```

Meaning:

```text
Cannot see player.
```

### `BTAlwaysSuccess`

Runs the child, but returns `SUCCESS` unless the child is still running.

Useful for optional behavior.

### `BTAlwaysFailure`

Runs the child, but returns `FAILURE` unless the child is still running.

Useful for forcing selector fallback.

### `BTCooldown`

Prevents the child from running again until a cooldown period has passed.

Useful for attacks, abilities, barks, or special actions.

```text
Cooldown(2.0)
|-- Attack
```

### `BTTimeout`

Fails the child if it runs for too long.

Useful for “try this for a few seconds, then give up.”

```text
Timeout(3.0)
|-- MoveToTarget
```

### `BTRepeater`

Repeats its child a fixed number of times. A negative repeat count repeats forever.

### `BTRepeatUntilFailure`

Repeats the child until it fails. When the child fails, this decorator returns `SUCCESS`.

### `BTRepeatUntilSuccess`

Repeats the child until it succeeds. When the child succeeds, this decorator returns `SUCCESS`.

### `BTLimitRuns`

Allows the child to run a limited number of times.

Useful for one-time behaviors:

```text
LimitRuns(1)
|-- PlayIntroRoar
```

### `BTDelay`

Waits for a certain amount of time before ticking the child.

Useful for delayed or telegraphed behavior.

### `BTChance`

Runs the child only if a random chance roll passes.

Useful for optional flavor behaviors:

```text
Chance(0.25)
|-- Taunt
```

## `BTFactory`

`BTFactory` is a helper class for building trees more easily.

Without the factory, tree construction can get verbose:

```gdscript
var root := BTSelector.new()

var chase_sequence := BTSequence.new()
chase_sequence.add_child_node(BTConditionCallable.new(_can_see_player))
chase_sequence.add_child_node(BTActionCallable.new(_chase_player))

root.add_child_node(chase_sequence)
```

With `BTFactory`, the same tree can be written more compactly:

```gdscript
var root := BTFactory.selector([
	BTFactory.sequence([
		BTFactory.condition(_can_see_player, "Can See Player"),
		BTFactory.action(_chase_player, "Chase Player"),
	]),
])
```

The factory is optional. It does not replace the behavior tree classes; it only makes tree construction cleaner.

Example factory usage:

```gdscript
var root := BTFactory.selector([
	BTFactory.sequence([
		BTFactory.condition(_can_see_player, "Can See Player"),
		BTFactory.cooldown(
			BTFactory.action(_attack, "Attack"),
			1.5
		),
	]),

	BTFactory.memory_sequence([
		BTFactory.condition(_has_last_seen_position, "Has Last Seen Position"),
		BTFactory.action(_move_to_last_seen_position, "Move To Last Seen Position"),
	]),

	BTFactory.random_selector([
		BTFactory.action(_patrol, "Patrol"),
		BTFactory.action(_look_around, "Look Around"),
		BTFactory.action(_idle, "Idle"),
	]),
])
```

This creates the following behavior:

```text
Selector
|-- Sequence
|   |-- CanSeePlayer
|   |-- Cooldown(1.5)
|       |-- Attack
|
|-- MemorySequence
|   |-- HasLastSeenPosition
|   |-- MoveToLastSeenPosition
|
|-- RandomSelector
	|-- Patrol
	|-- LookAround
	|-- Idle
```

Meaning:

```text
If the enemy can see the player, attack with a cooldown.
Otherwise, if it has a last known player position, move there.
Otherwise, choose a random idle behavior.
```

## Full Example

```gdscript
@onready var behavior_tree: BehaviorTree = $BehaviorTree


func _ready() -> void:
	behavior_tree.blackboard["player"] = get_tree().get_first_node_in_group("player")

	var root := BTFactory.selector([
		BTFactory.sequence([
			BTFactory.condition(_can_see_player, "Can See Player"),
			BTFactory.action(_chase_player, "Chase Player"),
		]),

		BTFactory.memory_sequence([
			BTFactory.condition(_has_last_seen_position, "Has Last Seen Position"),
			BTFactory.action(_move_to_last_seen_position, "Move To Last Seen Position"),
		]),

		BTFactory.random_selector([
			BTFactory.action(_patrol, "Patrol"),
			BTFactory.action(_look_around, "Look Around"),
			BTFactory.action(_idle, "Idle"),
		]),
	])

	behavior_tree.set_root(root)


func _can_see_player(actor: Node, blackboard: Dictionary) -> bool:
	var player: Node2D = blackboard.get("player", null)

	if player == null or not is_instance_valid(player):
		return false

	return actor.global_position.distance_to(player.global_position) < 300.0


func _chase_player(actor: Node, blackboard: Dictionary) -> BehaviorNode.Status:
	var player: Node2D = blackboard.get("player", null)

	if player == null or not is_instance_valid(player):
		return BehaviorNode.Status.FAILURE

	actor.move_toward(player.global_position)
	return BehaviorNode.Status.RUNNING


func _has_last_seen_position(actor: Node, blackboard: Dictionary) -> bool:
	return blackboard.has("last_seen_player_position")


func _move_to_last_seen_position(actor: Node, blackboard: Dictionary) -> BehaviorNode.Status:
	var target_position: Vector2 = blackboard.get("last_seen_player_position")

	if actor.global_position.distance_to(target_position) < 8.0:
		return BehaviorNode.Status.SUCCESS

	actor.move_toward(target_position)
	return BehaviorNode.Status.RUNNING


func _patrol(actor: Node, blackboard: Dictionary) -> BehaviorNode.Status:
	actor.patrol()
	return BehaviorNode.Status.RUNNING


func _look_around(actor: Node, blackboard: Dictionary) -> BehaviorNode.Status:
	actor.look_around()
	return BehaviorNode.Status.SUCCESS


func _idle(actor: Node, blackboard: Dictionary) -> BehaviorNode.Status:
	return BehaviorNode.Status.SUCCESS
```

## Normal vs Memory Composites

Normal composites reevaluate from the first child every tick.

This is useful for high-priority checks:

```text
Selector
|-- ChasePlayer
|-- Patrol
```

A normal selector lets `ChasePlayer` interrupt `Patrol` as soon as it becomes valid.

Memory composites remember their currently running child.

This is useful for behaviors that should not restart every frame:

```text
MemorySequence
|-- MoveToPoint
|-- PlayAnimation
|-- PerformAction
```

Use normal composites near the top of the tree for priority decisions. Use memory composites lower in the tree for multi-step behaviors.

## Parallel Nodes

Parallel nodes tick multiple children during the same tick.

Use them carefully. They are useful when children control different parts of the actor.

Good:

```text
ParallelSequence
|-- MoveTowardTarget
|-- FaceTarget
|-- PlayChargeAnimation
```

Potentially bad:

```text
ParallelSequence
|-- MoveLeft
|-- MoveRight
```

Parallel nodes can cause conflicts if multiple children try to control the same property.

## Notes

This behavior tree system is code-based. It does not require a visual editor.

The shared addon should provide generic behavior tree structure. Game-specific behavior should usually be implemented in the individual game project through callable conditions and actions.
