class_name TemplateTopDownCharacter2D
extends CharacterBody2D

@export_group("Inheritance Settings")
## Whether or not the template class should call move and slide
@export var do_move_and_slide_in_template: bool = true

@export_group("Basic movement")

## The vector action id used for the move input
@export var move_action_id: StringName =  &"move"

## The movement speed of the character controller
@export var move_speed: float = 300.0

var _move_input : Vector2 = Vector2.ZERO

func _physics_process(delta: float) -> void:
	if do_move_and_slide_in_template:
		move_and_slide()

## Intended to be connected  to the input component
func _on_input_component_vector_changed(vector_id: StringName, value: Vector2) -> void:
	match vector_id:
		move_action_id:
			_move_input = value
			velocity = _move_input.normalized() * move_speed
