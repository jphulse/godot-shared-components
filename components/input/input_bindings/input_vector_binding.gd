class_name InputVectorBinding
extends Resource

## The gameplay-facing ID for this vector.
## Example: &"move", &"look", &"menu_nav".
@export var vector_id: StringName

## The Godot InputMap action for negative X.
@export var negative_x_action: StringName

## The Godot InputMap action for positive X.
@export var positive_x_action: StringName

## The Godot InputMap action for negative Y.
## For movement, this is often forward/up.
@export var negative_y_action: StringName

## The Godot InputMap action for positive Y.
## For movement, this is often backward/down.
@export var positive_y_action: StringName

## The circular deadzone passed to Input.get_vector().
@export_range(0.0, 1.0, 0.01) var deadzone: float = -1.0

## Whether this vector should emit every tick, even if unchanged.
@export var emit_unchanged: bool = true
