# StateMachine
#
# Notes on usage:
# - Add a node with a script extending this class to a scene, or placing this script directly
# - Add child nodes to that that extend the abstract State class
# - Set the initial_state variable in the editor window after setting up the scripts to start in 
#	that state
# - Program the states to request state transitions using the Transition signal defined in the 
#	abstract State class
#  
#   This should promote good separation of code and logic as well as make the codebase easier to 
#	maintain and build upon during the semester
#   the primary goal being to reduce complexity and overall reliance on singular large scripts to 
#	handle multiple states and behavior
#   while also maximizing reuse for shared states and behavior
class_name StateMachine extends Node

@export_group("State machine parent class info")
@export var initial_state :State = null

# For the 'Boss' object, 'Boss' appears to be the operating node. - John
@export var operating_node : Node = null

# This is a dictionary holding state names as keys to state objects. 
# - A known issue, is that if two states in a state machine share the same state_id, the only the 
#   lowest state with the shared name in the hierarchy will be present in the dictionary
var states : Dictionary[StringName, State] = {}
var current_state : State = null

# Called when this node is ready for use on the tree, it will iterate over it's children adding them
# into the state map automatically, so any states accessed by this state machine should be in the
# scene as children that extend the abstract State class
func _ready() -> void:
	
	if operating_node == null:
		operating_node = get_parent()
	for child in get_children():
		if child is State:
			# Assertion checks if the child state and its ID is valid, if it is not, throw an error
			# mentioning the anomolous state.
			assert
			(
				child.state_id != null and len(child.state_id) >= 1, 
				str(
					"Child of this state machine [", name,"] with name [", child.name, "] has no 
					 registered id, set this to be a unique string name on the state in the editor"
				)
			)
			if states.has(child.state_id.to_lower()):
				push_warning(
					"Duplicate state name detected [%s] in load process, replacing first 
					 state with most recent in the map" % child.state_id
				)
			# overrides prior states with the same state_id if duplicate state_ids are present
			states[child.state_id.to_lower()] = child
			child.Transition.connect(on_state_transition)
			child.EmergencyTransition.connect(on_state_emergency_transition)
			child.set_owner_node(operating_node)
	# checks for the initiatial state and if it is present in the state machine hierachy.
	if initial_state and states.has(initial_state.state_id.to_lower()):
		current_state = initial_state
		initial_state.enter()
	elif initial_state:
		push_warning(
			"Initial state in state machine is not registered as a child, check scene structure"
		)
	else:
		push_warning(
			"No initial state selected in state machine [%s] operating on node [%s]", 
			name, 
			operating_node.name
		)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if current_state:
		current_state.update(delta)
	

# Called every fixed physics update frame
func _physics_process(delta: float) -> void:
	if current_state:
		current_state.physics_update(delta)

# When one of the children emits its transition signal we will attempt to leave the current state
# and enter the new state if applicable, does not allow for other states to take control away from 
# another, instead makes it a smooth handoff from current to next
func on_state_transition(caller : State, new_state_id: StringName):
	if caller != current_state and current_state:
		return
	var new_state :State = states.get(new_state_id.to_lower())
	if not new_state:
		push_warning(
			"No state found in transition from state with id [%s] and scene name [%s], 
			looking to switch to scene with id [%s]" % [caller.state_id, caller.name, new_state_id]
		)
		return
	if current_state:
		current_state.exit()
	current_state = new_state
	new_state.enter()

### 
# Allows for the use of interrupting code from other states besides the current one running
###
func on_state_emergency_transition(caller : State, new_state_id: StringName):
	var new_state :State = states.get(new_state_id.to_lower())
	if not new_state:
		push_warning("No state found in transition from state with id [%s] and scene name [%s], looking to switch to scene with id [%s]" % [caller.state_id, caller.name, new_state_id])
		return
	if current_state:
		current_state.exit()
	current_state = new_state
	new_state.enter()

# When we exit the tree call the exit function on the current_state first for smoother cleanup
func _exit_tree() -> void:
	if current_state:
		current_state.exit()
