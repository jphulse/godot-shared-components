class_name InputActionBinding
extends Resource

## The gameplay-facing ID for this action.
## Example: &"jump", &"primary_attack", &"interact".
@export var action_id: StringName

## The Godot InputMap action name to check.
## Example: &"ui_accept", &"move_jump", &"attack".
@export var input_action: StringName

## Whether this action should emit while held every process tick.
@export var emit_held: bool = false
