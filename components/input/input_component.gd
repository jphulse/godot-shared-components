class_name InputComponent
extends Node

## Emitted when a configured action is pressed.
signal action_pressed(action_id: StringName)

## Emitted when a configured action is released.
signal action_released(action_id: StringName)

## Emitted every tick for configured held actions with emit_held enabled.
signal action_held(action_id: StringName)

## Emitted when a configured vector changes, or every tick if emit_unchanged is enabled.
signal vector_changed(vector_id: StringName, value: Vector2)

## Emitted when mouse motion is detected in _unhandled_input if capture_mouse_motion is enabled
signal mouse_motion_changed(motion_id: StringName, relative: Vector2)

@export_group("Processing")
## Whether this component is currently reading input.
@export var enabled: bool = true

## Whether vector and held-action polling should happen in _process instead of _physics_process.
@export var use_process: bool = false

@export_group("Bindings")
## Action bindings checked by this component.
@export var action_bindings: Array[InputActionBinding] = []

## Vector bindings checked by this component.
@export var vector_bindings: Array[InputVectorBinding] = []

@export_group("Mouse Motion")
## Whether this component should emit mouse motion events from _unhandled_input().
@export var capture_mouse_motion: bool = false

## The gameplay-facing ID for mouse motion from this component.
@export var mouse_motion_id: StringName = &"mouse_look"

## Multiplier applied to raw mouse motion.
@export var mouse_sensitivity: float = 1.0

@export_group("")

## The most recent value for each configured vector ID.
var vector_values: Dictionary[StringName, Vector2] = {}

## Whether each configured action ID is currently held.
var action_held_values: Dictionary[StringName, bool] = {}


func _ready() -> void:
	_initialize_state()


func _process(delta: float) -> void:
	if use_process:
		_poll_continuous_inputs()


func _physics_process(delta: float) -> void:
	if not use_process:
		_poll_continuous_inputs()


func _unhandled_input(event: InputEvent) -> void:
	if not enabled:
		return
		
	if capture_mouse_motion and event is InputEventMouseMotion:
		var mouse_event: InputEventMouseMotion = event
		mouse_motion_changed.emit(
			mouse_motion_id,
			mouse_event.relative * mouse_sensitivity
		)
		return

	for binding: InputActionBinding in action_bindings:
		if binding == null:
			continue

		if binding.action_id == StringName() or binding.input_action == StringName():
			continue

		if event.is_action_pressed(binding.input_action):
			action_held_values[binding.action_id] = true
			action_pressed.emit(binding.action_id)

		if event.is_action_released(binding.input_action):
			action_held_values[binding.action_id] = false
			action_released.emit(binding.action_id)


## Initializes cached state for configured input bindings.
func _initialize_state() -> void:
	vector_values.clear()
	action_held_values.clear()

	for binding: InputVectorBinding in vector_bindings:
		if binding == null:
			continue

		if binding.vector_id == StringName():
			continue

		vector_values[binding.vector_id] = Vector2.ZERO

	for binding: InputActionBinding in action_bindings:
		if binding == null:
			continue

		if binding.action_id == StringName():
			continue

		action_held_values[binding.action_id] = false


## Polls vector inputs and held action inputs.
func _poll_continuous_inputs() -> void:
	if not enabled:
		return

	_poll_vectors()
	_poll_held_actions()


## Polls configured vector bindings.
func _poll_vectors() -> void:
	for binding: InputVectorBinding in vector_bindings:
		if binding == null:
			continue

		if binding.vector_id == StringName():
			continue

		var old_value: Vector2 = vector_values.get(binding.vector_id, Vector2.ZERO)

		var new_value: Vector2 = Input.get_vector(
			binding.negative_x_action,
			binding.positive_x_action,
			binding.negative_y_action,
			binding.positive_y_action,
			binding.deadzone
		)

		vector_values[binding.vector_id] = new_value

		if binding.emit_unchanged or not new_value.is_equal_approx(old_value):
			vector_changed.emit(binding.vector_id, new_value)


## Polls configured action bindings that should emit while held.
func _poll_held_actions() -> void:
	for binding: InputActionBinding in action_bindings:
		if binding == null:
			continue

		if not binding.emit_held:
			continue

		if binding.action_id == StringName() or binding.input_action == StringName():
			continue

		if Input.is_action_pressed(binding.input_action):
			action_held_values[binding.action_id] = true
			action_held.emit(binding.action_id)
		else:
			action_held_values[binding.action_id] = false


## Returns the latest value for a vector binding.
func get_vector(vector_id: StringName) -> Vector2:
	return vector_values.get(vector_id, Vector2.ZERO)


## Returns true if an action binding is currently held.
func is_action_held(action_id: StringName) -> bool:
	return action_held_values.get(action_id, false)
