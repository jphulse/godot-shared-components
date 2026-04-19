@abstract class_name State extends Node

@export_category("Abstract state info")
@export var state_id : StringName

# Used to hook transitions between states in state machine
@warning_ignore("unused_signal") signal Transition(caller : State, next_state_id : StringName)

@warning_ignore("unused_signal") signal EmergencyTransition(caller : State, next_state_id : StringName)


var owner_node : Node

func set_owner_node(n : Node) -> void:
	owner_node = n

# executes code of the next state after the state switch
func enter() -> void:
	pass

# executes code right before a called state switch
func exit() -> void:
	pass

# '_process's frame iteration is passed to the state's update to run every frame
func update(_delta : float) -> void:
	pass

# '_physics_process' frame iteration is passed to the state's update to run every fixed physics frame
func physics_update(_delta : float) -> void:
	pass
