# State Machine

This folder contains a reusable state machine system for Godot.

The system is built around three main classes:

- `State`
- `StateMachine`
- `NestedStateMachine`

The goal is to let behavior be split into small, focused state scripts instead of one large script with many conditionals.

## State

`State` is the abstract base class for all states.

A state script should extend `State`.

You can give a state script a `class_name` if you want it to appear in autocomplete:

```gdscript
class_name AttackState
extends State
```

The extended states can also be unnamed if you do not wish to clog your autocomplete:

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

Each state is stored in a dictionary using its lowercase `state_id`.

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

When inactive, the nested state machine does not update or physics update its current child state.

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

The selected initial state should be one of the direct child states of the nested state machine.

If no initial state is selected, the nested state machine will warn you.

## Reset behavior

`NestedStateMachine` has a `reset_state` option.

```gdscript
@export var reset_state : bool = true
```

If `reset_state` is `true`, the nested state machine resets to its `initial_state` whenever it exits.

If `reset_state` is `false`, the nested state machine remembers its previous child state and resumes from that state the next time it enters.

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

## Nested active state behavior

A nested state machine has an internal `active` flag.

```gdscript
var active : bool = false
```

The nested state machine is active only while the parent state machine is currently inside that nested state.

When the nested state machine is active:

- it can update its current child state
- it can physics update its current child state
- normal child transitions are allowed
- emergency child transitions are allowed

When the nested state machine is inactive:

- it does not update its current child state
- it does not physics update its current child state
- normal transitions are ignored by default
- emergency transitions may still be allowed, depending on settings

This prevents inactive nested states from accidentally controlling behavior when their parent state is not active.

## Nested normal transitions

A nested state machine handles normal transitions similarly to the main `StateMachine`.

A child state can emit:

```gdscript
Transition.emit(self, &"attack")
```

By default, the nested state machine will only allow a normal transition if:

- the caller is the current child state
- the nested state machine is active

This prevents inactive nested states from changing behavior while the parent state is not active.

## Inactive standard transitions

`NestedStateMachine` has an option for allowing standard transitions while inactive.

```gdscript
@export var allow_inactive_standard_transitions : bool = false
```

By default, this is `false`.

If this is `false`, normal transitions are ignored while the nested state machine is inactive.

If this is `true`, normal transitions may be allowed while inactive.

Inactive standard transitions are mainly useful when `reset_state` is also `false`, because the nested state machine can remember the new child state and resume from it later.

If `reset_state` is `true`, inactive standard transitions should generally be ignored, because the nested state machine resets to `initial_state` the next time it enters.

Emergency transitions should be used instead for important inactive transitions that must survive reset behavior.

A recommended rule is:

```text
Inactive standard transitions should only be allowed when reset_state is false.
```

This keeps standard transitions from accidentally behaving like emergency transitions.

## Nested emergency transitions

Nested state machines also support emergency transitions.

```gdscript
EmergencyTransition.emit(self, &"retreat")
```

Emergency transitions are intended for important events that should be able to interrupt or override normal behavior.

Examples include:

- death
- stun
- knockback
- forced cutscene behavior
- scripted overrides
- high-priority AI reactions

Emergency transitions are allowed even if the caller is not the current child state.

This makes them useful for situations where an inactive or non-current child state needs to force the nested state machine into a specific state.

## Inactive emergency transitions

`NestedStateMachine` has an option for allowing emergency transitions while inactive.

```gdscript
@export var allow_inactive_emergency_transitions : bool = true
```

By default, this is `true`.

If an emergency transition happens while the nested state machine is active, it exits the current child state and enters the new child state immediately.

If an emergency transition happens while the nested state machine is inactive, it updates the internal `current_state`, but does not call `enter()` on the new state yet.

Instead, the transition is queued using:

```gdscript
var emergency_transition_queued : bool = false
```

When the nested state machine enters again, the queued emergency state is entered instead of resetting to `initial_state`.

This allows important emergency transitions to survive `reset_state`.

For example, if `CombatState` is inactive but receives an emergency transition to `RetreatState`, then the next time `CombatState` becomes active, it can enter `RetreatState` immediately instead of restarting from `ApproachState`.

If `allow_inactive_emergency_transitions` is `false`, emergency transitions are ignored while the nested state machine is inactive.

## Emergency transitions and reset_state

Emergency transitions have special behavior with `reset_state`.

Normally, if `reset_state` is `true`, the nested state machine resets to its `initial_state` when entered.

However, an inactive emergency transition can override this once.

Example:

```text
reset_state = true
initial_state = ApproachState

CombatState is inactive.
An emergency transition requests RetreatState.
CombatState becomes active again.
CombatState enters RetreatState instead of ApproachState.
```

After the queued emergency state is entered, the emergency queue is cleared.

This behavior is intentionally limited to emergency transitions. Standard transitions should not usually override reset behavior.

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

An external system can also force an emergency transition.

For example, a `HealthComponent` could emit an emergency transition when health reaches zero:

```gdscript
func on_health_depleted() -> void:
	EmergencyTransition.emit(self, &"dead")
```

## Design goal

The goal of this state machine system is to reduce reliance on large scripts that handle many different behaviors at once.

Instead of writing one large enemy script with many conditionals, behavior can be separated into smaller state scripts. This makes the codebase easier to maintain, test, debug, and extend.

The `StateMachine` acts as a coordinator, while each `State` handles one focused behavior.

The `NestedStateMachine` allows complex states to be broken down even further without forcing the outer state machine to know every small behavior detail.

The nested machine also supports inactive emergency transitions, allowing important state changes to be queued safely without accidentally running inactive child state logic.

This keeps behavior organized, reusable, and easier to reason about as a project grows.
