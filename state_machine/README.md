````md
# State Machine

## What is a state machine?

A state machine is a structure that allows an object to behave differently depending on its current state.

Instead of putting every behavior into one large script, each behavior is split into its own `State` node. The `StateMachine` owns those states, keeps track of the currently active one, and handles switching between them.

For example, an enemy might have states like:

- `Idle`
- `Patrol`
- `Chase`
- `Attack`
- `Stunned`
- `Dead`

Only one state is active at a time. The active state receives update calls from the `StateMachine` and can request a transition when its behavior is finished or when conditions change.

## Why use a state machine?

There are several reasons to use a state machine:

- State machines help prevent large, fragile scripts full of branching logic.
- Each state is responsible for one specific behavior, which helps follow the Single Responsibility Principle.
- States make behavior easier to test, debug, and replace.
- States can often be reused across multiple objects if they share similar behavior.
- State transitions are explicit, making it easier to understand how an object changes behavior over time.
- The root object can act more like a manager, while individual states handle specialized behavior.
- This keeps behavior organized in both code and the Godot scene tree.

## Included classes

This state machine system is made of three main classes:

- `State`
- `StateMachine`
- `NestedStateMachine`

## State

`State` is the abstract base class for all states.

Every custom state should extend `State`.

A state is responsible for one focused behavior. It does not decide how the entire object works; it only manages what should happen while that specific state is active.

Example state scripts might include:

```gdscript
class_name IdleState
extends State
```

```gdscript
class_name ChaseState
extends State
```

```gdscript
class_name AttackState
extends State
```

The extended states can also be unnamed if you do not wish to clog your autocomplete
```gdscript
extends State
```

Each state has a `state_id`, which is used by the state machine to register and transition between states.

```gdscript
@export var state_id : StringName
```

Each state also has access to an `owner_node`.

```gdscript
var owner_node : Node
```

The `owner_node` is the main node being controlled by the state machine. For example, if an enemy has a state machine, the enemy node would usually be the `owner_node`.

## State lifecycle methods

Each state can implement these lifecycle methods:

```gdscript
func enter() -> void:
	pass
```

Called when the state becomes active.

```gdscript
func exit() -> void:
	pass
```

Called right before the state stops being active.

```gdscript
func update(_delta : float) -> void:
	pass
```

Called every frame while this state is active.

```gdscript
func physics_update(_delta : float) -> void:
	pass
```

Called every physics frame while this state is active.

## StateMachine

`StateMachine` is the main state machine class.

It should be added to a scene as a node, or attached directly to an existing node. Its child nodes should extend the abstract `State` class.

When the `StateMachine` enters the scene tree, it automatically checks its children and registers any child that extends `State`.

Each state is stored in a dictionary using its `state_id`.

```gdscript
var states : Dictionary[StringName, State] = {}
```

The currently active state is stored in:

```gdscript
var current_state : State = null
```

## Basic scene structure

A typical setup might look like this:

```text
Enemy
├── StateMachine
│   ├── IdleState
│   ├── ChaseState
│   ├── AttackState
│   └── DeadState
├── Sprite2D
├── CollisionShape2D
└── OtherComponents
```

In this setup, `Enemy` is the object being controlled, and the `StateMachine` manages the behavior states.

## Setup instructions

To use this state machine:

1. Add a `StateMachine` node to the scene, or attach the `StateMachine` script directly to a node.
2. Add child nodes under the `StateMachine`.
3. Attach scripts to those children that extend the abstract `State` class.
4. Give each state a unique `state_id` in the editor.
5. Set the `initial_state` export on the `StateMachine`.
6. Optionally set the `operating_node`. If left empty, the state machine will use its parent node.
7. In each state, request transitions by emitting the `Transition` signal.

## Initial state

The `initial_state` export determines which state should be active when the state machine starts.

```gdscript
@export var initial_state : State = null
```

The selected initial state should be one of the child states of the state machine.

If no initial state is selected, the state machine will warn you.

## Operating node

The `operating_node` is the node that the states are controlling.

```gdscript
@export var operating_node : Node = null
```

If `operating_node` is left empty, the state machine uses its parent node.

This allows states to control the main object without needing to hard-code scene paths.

Example:

```gdscript
func enter() -> void:
	owner_node.velocity = Vector2.ZERO
```

## State IDs

Each state needs a unique `state_id`.

For example:

```gdscript
@export var state_id : StringName = &"idle"
```

The state machine stores states using their lowercase `state_id`.

That means these IDs are treated as equivalent:

```text
Idle
idle
IDLE
```

Because of this, each state should have a unique ID regardless of capitalization.

If multiple states use the same `state_id`, the later registered state will replace the earlier one in the state dictionary.

## Normal transitions

A normal transition should be requested by the current active state using the `Transition` signal.

Example:

```gdscript
Transition.emit(self, &"chase")
```

The state machine will only allow a normal transition if the caller is the current active state.

This prevents inactive states from accidentally stealing control.

## Emergency transitions

An emergency transition can be requested using the `EmergencyTransition` signal.

Example:

```gdscript
EmergencyTransition.emit(self, &"dead")
```

Emergency transitions are allowed even if the caller is not the current active state.

This is useful for interrupting behavior, such as:

- death
- stun
- knockback
- forced cutscene behavior
- scripted overrides
- high-priority AI reactions

Use emergency transitions carefully, since they bypass the usual current-state ownership check.

## Example state

```gdscript
class_name IdleState
extends State

func enter() -> void:
	print("Entered idle state")

func update(delta : float) -> void:
	if should_chase_player():
		Transition.emit(self, &"chase")

func exit() -> void:
	print("Leaving idle state")

func should_chase_player() -> bool:
	return false
```

## NestedStateMachine

`NestedStateMachine` is a state machine that also extends `State`.

This means it can be used as a state inside another state machine, while also managing its own child states.

This is useful when one high-level state needs its own internal behavior states.

For example, an enemy might have a high-level state machine like this:

```text
Enemy
├── StateMachine
│   ├── IdleState
│   ├── CombatState
│   │   ├── ApproachState
│   │   ├── AttackState
│   │   └── RetreatState
│   └── DeadState
```

In this example, `CombatState` could be a `NestedStateMachine`.

The outer state machine only knows that the enemy is in `CombatState`. The nested state machine then handles the smaller combat-specific states like approaching, attacking, and retreating.

## Why use nested state machines?

Nested state machines are useful when a single state becomes complex enough to need its own internal states.

They help avoid states becoming too large.

For example, instead of making one massive `CombatState` script with many branches, you can split combat into smaller states:

- `ApproachState`
- `CircleTargetState`
- `AttackState`
- `RecoverState`
- `RetreatState`

The outer state machine stays simple, while the nested state machine manages the details.

## How NestedStateMachine works

`NestedStateMachine` extends `State`, so it has the same lifecycle methods as a normal state:

```gdscript
func enter() -> void
func exit() -> void
func update(delta : float) -> void
func physics_update(delta : float) -> void
```

When the nested state machine enters, it becomes active.

```gdscript
active = true
```

When it exits, it becomes inactive.

```gdscript
active = false
```

While active, it forwards update calls to its own current child state.

```gdscript
func update(delta: float) -> void:
	if current_state and active:
		current_state.update(delta)
```

```gdscript
func physics_update(delta : float) -> void:
	if current_state and active:
		current_state.physics_update(delta)
```

## Nested state setup

A nested state machine should have child states just like a regular state machine.

Example:

```text
StateMachine
├── IdleState
├── CombatState
│   ├── ApproachState
│   ├── AttackState
│   └── RetreatState
└── DeadState
```

Here, `CombatState` extends `NestedStateMachine`.

Its children extend `State`.

## Nested initial state

`NestedStateMachine` also has an `initial_state`.

```gdscript
@export var initial_state : State = null
```

This determines which child state the nested state machine starts in.

## Reset behavior

`NestedStateMachine` has a `reset_state` option.

```gdscript
@export var reset_state : bool = true
```

If `reset_state` is `true`, the nested state machine resets to its `initial_state` whenever it exits.

If `reset_state` is `false`, the nested state machine remembers its previous child state and resumes from that state the next time it enters.

This is useful for different behavior styles.

Use `reset_state = true` when the nested behavior should restart every time.

Example:

```text
CombatState always starts from ApproachState.
```

Use `reset_state = false` when the nested behavior should resume where it left off.

Example:

```text
A PatrolState remembers which patrol substate it was in.
```

## Nested normal transitions

A nested state machine handles normal transitions similarly to the main `StateMachine`.

A child state can emit:

```gdscript
Transition.emit(self, &"attack")
```

The nested state machine will only allow the transition if:

- the nested state machine is active
- the caller is the current child state

This prevents inactive nested states from changing behavior while the parent state is not active.

## Nested emergency transitions

Nested state machines also support emergency transitions.

```gdscript
EmergencyTransition.emit(self, &"retreat")
```

If an emergency transition happens while the nested state machine is inactive, it will still update its internal `current_state`, but it will warn that the emergency transition occurred while inactive.

If the nested state machine is active, it exits the current child state and enters the new child state immediately.

## Example nested state machine use

Outer state machine:

```text
Enemy
├── StateMachine
│   ├── IdleState
│   ├── CombatState
│   │   ├── ApproachState
│   │   ├── AttackState
│   │   └── RetreatState
│   └── DeadState
```

`CombatState`:

```gdscript
class_name CombatState
extends NestedStateMachine
```

`ApproachState`:

```gdscript
class_name ApproachState
extends State

func update(delta : float) -> void:
	if in_attack_range():
		Transition.emit(self, &"attack")

func in_attack_range() -> bool:
	return false
```

`AttackState`:

```gdscript
class_name AttackState
extends State

func enter() -> void:
	print("Attack started")

func update(delta : float) -> void:
	if should_retreat():
		Transition.emit(self, &"retreat")

func should_retreat() -> bool:
	return false
```

## Design goal

The goal of this state machine system is to reduce reliance on large scripts that handle many different behaviors at once.

Instead of writing one large enemy script with many conditionals, behavior can be separated into smaller state scripts. This makes the codebase easier to maintain, test, debug, and extend.

The `StateMachine` acts as a coordinator, while each `State` handles one focused behavior.

The `NestedStateMachine` allows complex states to be broken down even further without forcing the outer state machine to know every small behavior detail.

This keeps behavior organized, reusable, and easier to reason about as a project grows.
````
