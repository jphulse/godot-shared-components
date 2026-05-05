# ConditionalLockComponent

`ConditionalLockComponent` is a generic condition-gate component. It tracks a set of named conditions and emits signals when those conditions satisfy the selected requirement mode.

This component can be used for doors, chests, puzzle gates, ability unlocks, shortcut unlocks, menu unlocks, progression blockers, and other systems where something should become available after one or more requirements are met.

## Basic Idea

A `ConditionalLockComponent` stores a list of required condition IDs:

```gdscript
@export var required_conditions: Array[StringName] = [
	&"has_key",
	&"generator_powered",
	&"puzzle_solved",
]
```

Each condition starts as unmet. Other objects can satisfy or unsatisfy conditions by calling:

```gdscript
lock.meet_condition(&"has_key")
lock.unmeet_condition(&"generator_powered")
lock.set_condition_state(&"puzzle_solved", true)
```

When the current conditions satisfy the selected `requirement_mode`, the component emits:

```gdscript
unlocked(lock)
```

If `can_relock` is enabled, the component can also emit:

```gdscript
locked(lock)
```

when the requirements are no longer satisfied.

## Requirement Modes

`ConditionalLockComponent` supports several built-in requirement modes:

```gdscript
enum RequirementMode {
	ALL,
	ANY,
	EXACTLY_ONE,
	AT_LEAST_COUNT,
	EXACTLY_COUNT,
}
```

### `ALL`

Every listed condition must be met.

Example:

```text
has_key AND generator_powered AND puzzle_solved
```

### `ANY`

At least one listed condition must be met.

Example:

```text
has_key OR lockpick_used OR door_code_entered
```

### `EXACTLY_ONE`

Exactly one listed condition must be met.

Example:

```text
Only one of three symbols may be active.
```

### `AT_LEAST_COUNT`

At least `required_count` conditions must be met.

Example:

```text
At least 3 of 5 switches must be active.
```

### `EXACTLY_COUNT`

Exactly `required_count` conditions must be met.

Example:

```text
Exactly 2 pressure plates must be held down.
```

## Important Properties

### `required_conditions`

The list of condition IDs this lock tracks.

```gdscript
@export var required_conditions: Array[StringName] = []
```

These are the atomic requirements that other scripts can mark as met or unmet.

### `can_relock`

Whether the lock can become locked again after it has unlocked.

```gdscript
@export var can_relock: bool = false
```

When `false`, the lock behaves like a permanent/latching unlock. Once it unlocks, it stays unlocked.

When `true`, the lock re-evaluates continuously and can lock again if the requirements stop being satisfied.

### `evaluate_on_ready`

Whether the lock should evaluate itself during `_ready()`.

```gdscript
@export var evaluate_on_ready: bool = true
```

This is useful for locks that should start unlocked if their starting requirements are already satisfied.

### `requirement_mode`

Controls how conditions are evaluated.

```gdscript
@export var requirement_mode: RequirementMode = RequirementMode.ALL
```

### `required_count`

Used by `AT_LEAST_COUNT` and `EXACTLY_COUNT`.

```gdscript
@export var required_count: int = 1
```

## Basic Door Example

A door can use a `ConditionalLockComponent` without needing to know where the conditions came from.

```gdscript
class_name ExampleLockedDoor
extends Node3D

## Lock component controlling this door.
@export var lock: ConditionalLockComponent

## Animation player used to play door animations.
@export var animation_player: AnimationPlayer

## Whether this door is currently open.
var is_open: bool = false


## Connects this door to its lock component.
func _ready() -> void:
	if lock != null:
		lock.unlocked.connect(_on_lock_unlocked)


## Attempts to open the door.
func interact() -> void:
	if lock != null and not lock.is_unlocked:
		_on_locked_interaction()
		return

	open()


## Opens the door.
func open() -> void:
	if is_open:
		return

	is_open = true

	if animation_player != null:
		animation_player.play(&"open")


## Handles the lock becoming unlocked.
func _on_lock_unlocked(_lock: ConditionalLockComponent) -> void:
	if animation_player != null:
		animation_player.play(&"unlock")


## Handles interaction while the door is locked.
func _on_locked_interaction() -> void:
	print("The door is locked.")
```

A lever, key item, puzzle panel, trigger, or game-state event can then satisfy conditions:

```gdscript
lock.meet_condition(&"lever_pulled")
lock.meet_condition(&"key_inserted")
lock.meet_condition(&"clock_puzzle_solved")
```

## Nested and Custom Logic

`ConditionalLockComponent` is intentionally small. For complex boolean logic, treat each lock component as an atomic condition gate and combine multiple child locks in a parent script.

For example, if you need:

```text
A AND (B OR C) AND NOT D
```

you can make four child lock components:

```text
CustomPuzzleGate
├── LockA
├── LockB
├── LockC
└── LockD
```

Each child lock handles its own local requirements. The parent script then evaluates the larger expression.

```gdscript
class_name CustomPuzzleGate
extends Node

## Emitted when the full custom puzzle gate becomes unlocked.
signal unlocked

## Child lock representing condition group A.
@export var lock_a: ConditionalLockComponent

## Child lock representing condition group B.
@export var lock_b: ConditionalLockComponent

## Child lock representing condition group C.
@export var lock_c: ConditionalLockComponent

## Child lock representing condition group D.
@export var lock_d: ConditionalLockComponent

## Whether this gate has already emitted its unlock signal.
var is_unlocked: bool = false


## Connects child lock evaluations to this gate.
func _ready() -> void:
	_connect_lock(lock_a)
	_connect_lock(lock_b)
	_connect_lock(lock_c)
	_connect_lock(lock_d)

	evaluate()


## Connects a child lock if it exists.
func _connect_lock(lock: ConditionalLockComponent) -> void:
	if lock == null:
		return

	lock.evaluated.connect(_on_child_lock_evaluated)


## Evaluates the custom nested condition.
func evaluate() -> bool:
	var a := lock_a != null and lock_a.is_unlocked
	var b := lock_b != null and lock_b.is_unlocked
	var c := lock_c != null and lock_c.is_unlocked
	var d := lock_d != null and lock_d.is_unlocked

	return a and (b or c) and not d


## Responds when any child lock evaluates.
func _on_child_lock_evaluated(_lock: ConditionalLockComponent, _is_unlocked: bool) -> void:
	if is_unlocked:
		return

	if evaluate():
		is_unlocked = true
		unlocked.emit()
```

This keeps `ConditionalLockComponent` simple while still allowing custom nested logic at the parent level.

## Recommended Usage Pattern

Use `ConditionalLockComponent` for generic condition tracking:

```text
Which requirements are met?
Should this gate unlock?
Should it relock?
```

Use the owning object for game-specific behavior:

```text
What animation plays?
What sound plays?
Does the door open?
Does the player gain an ability?
Does a secret room appear?
Is the unlock saved permanently?
```

This keeps the component reusable while allowing each game object to define its own response to being unlocked.

## Notes

- If `required_conditions` is empty and `requirement_mode` is `ALL`, the lock evaluates as unlocked because all zero requirements are technically satisfied.
- Use `can_relock = false` for permanent unlocks.
- Use `can_relock = true` for temporary gates, pressure plates, power systems, timed switches, or other reversible conditions.
- For custom nested logic, compose multiple `ConditionalLockComponent` nodes and evaluate them from a parent script.
- The component should not know about doors, inventory, puzzles, animation, audio, or save systems directly. Those systems should react to the component's signals.
