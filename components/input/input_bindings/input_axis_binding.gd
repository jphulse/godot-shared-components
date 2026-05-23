class_name InputAxisBinding
extends Resource

## The gameplay-facing ID for this vector.
## Example: &"move", &"look", &"menu_nav".
@export var axis_id: StringName

## The Godot InputMap action for the negative direction.
@export var negative_action: StringName

## The Godot InputMap action for the positive direction.
@export var positive_action: StringName


## Whether this vector should emit every tick, even if unchanged.
@export var emit_unchanged: bool = true
