class_name TemplatePlatformerCharacter2D
extends CharacterBody2D

@export_group("Inheritance Settings")
## Whether or not the template class should call move and slide
@export var do_move_and_slide_in_template: bool = true

## Whether or not gravity should be applied in the template
@export var apply_gravity_in_template: bool = true

@export_group("Basic movement")
## The movement speed of the character controller left and right
@export var move_speed: float = 300.0

## The action_id for the axis move operation setup in the input_component
@export var move_action_id: StringName = &"move"

## The action_id for the jump input action binding
@export var jump_action_id: StringName = &"jump"

## The jump velocity of the character, negative is up positive is down on the Y-axis
@export var jump_velocity: float = -400.0

## The current horizontal movement input received from the input component.
var _move_input : float = 0.0

## Applies platformer movement behavior for this template.
func _physics_process(delta: float) -> void:
	if apply_gravity_in_template and not is_on_floor():
		velocity += get_gravity() * delta
	if do_move_and_slide_in_template:
		move_and_slide()

## Intended to be connected to the input component's axis changed signal.
func _on_input_component_axis_changed(axis_id: StringName, value: float) -> void:
	match axis_id:
		move_action_id:
			_move_input = value
			velocity.x = _move_input * move_speed

## Performs a jump if the character is currently on the floor.
func _perform_jump() -> void:
	if is_on_floor():
		velocity.y = jump_velocity

## Intended to be connected to the input component's action pressed signal.
func _on_input_component_action_pressed(action_id: StringName) -> void:
	match action_id:
		jump_action_id:
			_perform_jump()
			
