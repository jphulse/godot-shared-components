class_name NestedStateMachine extends State


@export_group("State machine parent class info")
@export var initial_state :State = null
@export var reset_state : bool = true

@export_group("Nested State machine info")
@export var allow_inactive_standard_transitions : bool = false
@export var allow_inactive_emergency_transitions : bool = true

var states : Dictionary[StringName, State] = {}
var current_state : State = null
var active : bool = false
var emergency_transition_queued : bool = false

func enter() -> void:
	active = true
	if (reset_state or current_state == null) and not emergency_transition_queued:
		current_state = initial_state
	if current_state != null:
		current_state.enter()
		emergency_transition_queued = false
		
func exit() -> void:
	active = false
	if current_state != null:
		current_state.exit()
	if reset_state:
		current_state = initial_state

func set_owner_node(n : Node) -> void:
	super.set_owner_node(n)
	for child in get_children():
		if child is State:
			child.set_owner_node(owner_node)

# Called when this node is ready for use on the tree, it will iterate over it's children adding them
# into the state map automatically, so any states accessed by this state machine should be in the
# scene as children that extend the abstract State class
func _ready() -> void:
	for child in get_children():
		if child is State:
			assert(child.state_id != null and len(child.state_id) >= 1, str("Child of this state machine [", name,"] with name [", child.name, "] has no registered id, set this to be a unique string name on the state in the editor"))
			if states.has(child.state_id.to_lower()):
				push_warning("Duplicate state name detected [%s] in load process, replacing first state with most recent in the map" % child.state_id)
			states[child.state_id.to_lower()] = child
			child.Transition.connect(on_state_transition)
			child.EmergencyTransition.connect(on_state_emergency_transition)
	if initial_state and states.has(initial_state.state_id.to_lower()):
		current_state = initial_state
	elif initial_state:
		push_warning("Initial state in state machine is not registered as a child, check scene structure")
	else:
		push_warning("No initial state selected for nested state machine [%s]" % name)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func update(delta: float) -> void:
	if current_state and active:
		current_state.update(delta)
	

# Called every fixed physics update frame
func physics_update(delta : float) -> void:
	if current_state and active:
		current_state.physics_update(delta)

# When one of the children emits its transition signal we will attempt to leave the current state
# and enter the new state if applicable, does not allow for other states to take control away from 
# another, instead makes it a smooth handoff from current to next
func on_state_transition(caller : State, new_state_id: StringName) -> void:
	if current_state != null and caller != current_state:
		return

	if not active:
		if not allow_inactive_standard_transitions:
			return
		if reset_state:
			push_warning("Inactive standard transition ignored because reset_state is true. Use an emergency transition if this transition must survive reset.")
			return

	var new_state : State = states.get(new_state_id.to_lower())

	if not new_state:
		push_warning("No state found in transition from state with id [%s] and scene name [%s], looking to switch to scene with id [%s]" % [caller.state_id, caller.name, new_state_id])
		return

	if current_state and active:
		current_state.exit()

	current_state = new_state

	if active:
		new_state.enter()

# When we exit the tree call the exit function on the current_state first for smoother cleanup
func _exit_tree() -> void:
	if current_state and active:
		current_state.exit()


func on_state_emergency_transition(caller : State, new_state_id: StringName) -> void:
	
	var new_state :State = states.get(new_state_id.to_lower())
	if not active and not allow_inactive_emergency_transitions:
		push_warning("Tried an emergency transition while this state machine is not active, and allow_inactive_emergency_transitions was false, transition ignored")
		return
	if not new_state:
		push_warning("No state found in transition from state with id [%s] and scene name [%s], looking to switch to scene with id [%s]" % [caller.state_id, caller.name, new_state_id])
		return
	if current_state and active:
		current_state.exit()
	current_state = new_state
	if active:
		new_state.enter()
	else:
		emergency_transition_queued = true
