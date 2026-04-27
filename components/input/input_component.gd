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

## Emitted when mouse motion is detected in _unhandled_input if capture_mouse_motion is enabled.
signal mouse_motion_changed(motion_id: StringName, relative: Vector2)

## Emitted when a configured input sequence is completed.
## This is emitted before action_pressed or action_released for the same input event.
signal input_sequence_completed(sequence_id: StringName)

## Emitted when an in-progress input sequence is broken.
signal input_sequence_broken(sequence_id: StringName)

## Emitted when one action in a sequence is completed.
## completed_action_index is zero-based.
signal input_sequence_action_completed(
	sequence_id: StringName,
	completed_action_index: int,
	total_actions: int
)

## Emitted when all actions in a configured chord become held at the same time.
signal chord_pressed(chord_id: StringName)

## Emitted when a previously held chord stops being held.
signal chord_released(chord_id: StringName)

## Emitted every polling tick while a configured chord is held.
signal chord_held(chord_id: StringName)

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

## Input sequence bindings checked by this component.
@export var sequence_bindings: Array[InputSequenceBinding] = []

## Chord bindings checked by this component.
@export var chord_bindings: Array[InputChordBinding] = []

@export_group("Mouse Motion")
## Whether this component should emit mouse motion events from _unhandled_input().
@export var capture_mouse_motion: bool = false

## The gameplay-facing ID for mouse motion from this component.
@export var mouse_motion_id: StringName = &"mouse_look"

## Multiplier applied to raw mouse motion.
@export var mouse_sensitivity: float = 1.0

@export_group("Chord rules") 
## Allows for one chord value press to be used in two overlapping chords at once, otherwise it will only fire off the first in the list
@export var allow_overlapping_chord_press_processing : bool = true


## The most recent value for each configured vector ID.
var vector_values: Dictionary[StringName, Vector2] = {}

## Whether each configured action ID is currently held.
var action_held_values: Dictionary[StringName, bool] = {}

## Current matched step index for each configured input sequence ID.
var sequence_progress_values: Dictionary[StringName, int] = {}

## Last step time for each configured input sequence ID.
var sequence_last_input_time_values: Dictionary[StringName, float] = {}

## Whether each configured chord ID is currently held.
var chord_held_values: Dictionary[StringName, bool] = {}


## Initializes this component's cached input state.
func _ready() -> void:
	_initialize_state()


## Polls continuous input from the idle loop when use_process is enabled.
func _process(delta: float) -> void:
	if use_process:
		_poll_continuous_inputs()


## Polls continuous input from the physics loop when use_process is disabled.
func _physics_process(delta: float) -> void:
	if not use_process:
		_poll_continuous_inputs()


## Handles discrete input events such as pressed, released, sequences, chords, and mouse motion.
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

	_poll_input_sequences(event)
	_poll_chord_events(event)
	_poll_action_events(event)


## Initializes cached state for configured input bindings.
func _initialize_state() -> void:
	vector_values.clear()
	action_held_values.clear()
	sequence_progress_values.clear()
	sequence_last_input_time_values.clear()
	chord_held_values.clear()

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

	for binding: InputSequenceBinding in sequence_bindings:
		if not _is_sequence_binding_valid(binding):
			continue

		sequence_progress_values[binding.sequence_id] = 0
		sequence_last_input_time_values[binding.sequence_id] = 0.0
	
	for binding: InputChordBinding in chord_bindings:
		if not _is_chord_binding_valid(binding):
			continue

		chord_held_values[binding.chord_id] = false


## Polls vector inputs and held action inputs.
func _poll_continuous_inputs() -> void:
	if not enabled:
		return

	_poll_vectors()
	_poll_held_chords()
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


## Polls input sequence bindings for a single input event.
func _poll_input_sequences(event: InputEvent) -> void:
	for binding: InputSequenceBinding in sequence_bindings:
		if not _is_sequence_binding_valid(binding):
			continue

		var matching_action: StringName = _get_sequence_action_from_event(binding, event)

		if matching_action == StringName():
			continue

		_advance_input_sequence(binding, matching_action)


## Polls normal action pressed and released events.
func _poll_action_events(event: InputEvent) -> void:
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


## Returns the sequence input action represented by this event, or an empty StringName if none matched.
func _get_sequence_action_from_event(
	binding: InputSequenceBinding,
	event: InputEvent
) -> StringName:
	for input_action: StringName in binding.input_actions:
		if input_action == StringName():
			continue

		match binding.sequence_event_mode:
			InputSequenceBinding.SequenceEventMode.PRESSED:
				if event.is_action_pressed(input_action):
					return input_action

			InputSequenceBinding.SequenceEventMode.RELEASED:
				if event.is_action_released(input_action):
					return input_action

	return StringName()


## Advances a configured input sequence using the given input action.
func _advance_input_sequence(
	binding: InputSequenceBinding,
	input_action: StringName
) -> void:
	var now_seconds: float = Time.get_ticks_msec() / 1000.0
	var progress: int = sequence_progress_values.get(binding.sequence_id, 0)
	var last_input_time: float = sequence_last_input_time_values.get(binding.sequence_id, 0.0)

	if binding.max_gap_seconds > 0.0 and progress > 0:
		if now_seconds - last_input_time > binding.max_gap_seconds:
			input_sequence_broken.emit(binding.sequence_id)
			progress = 0
			sequence_progress_values[binding.sequence_id] = 0
			sequence_last_input_time_values[binding.sequence_id] = 0.0

	var expected_action: StringName = binding.input_actions[progress]

	if input_action == expected_action:
		_complete_input_sequence_step(binding, progress, now_seconds)
		return

	if not binding.reset_on_wrong_input:
		return

	if progress > 0:
		input_sequence_broken.emit(binding.sequence_id)

	_reset_or_restart_input_sequence(binding, input_action, now_seconds)


## Completes one step of an input sequence.
func _complete_input_sequence_step(
	binding: InputSequenceBinding,
	completed_action_index: int,
	now_seconds: float
) -> void:
	var total_actions: int = binding.input_actions.size()
	var next_progress: int = completed_action_index + 1

	sequence_last_input_time_values[binding.sequence_id] = now_seconds

	input_sequence_action_completed.emit(
		binding.sequence_id,
		completed_action_index,
		total_actions
	)

	if next_progress >= total_actions:
		sequence_progress_values[binding.sequence_id] = 0
		sequence_last_input_time_values[binding.sequence_id] = 0.0
		input_sequence_completed.emit(binding.sequence_id)
		return

	sequence_progress_values[binding.sequence_id] = next_progress


## Resets a sequence after a wrong input, while allowing overlap with the first sequence action.
func _reset_or_restart_input_sequence(
	binding: InputSequenceBinding,
	input_action: StringName,
	now_seconds: float
) -> void:
	var first_action: StringName = binding.input_actions[0]

	if input_action == first_action:
		sequence_progress_values[binding.sequence_id] = 1
		sequence_last_input_time_values[binding.sequence_id] = now_seconds

		input_sequence_action_completed.emit(
			binding.sequence_id,
			0,
			binding.input_actions.size()
		)
	else:
		sequence_progress_values[binding.sequence_id] = 0
		sequence_last_input_time_values[binding.sequence_id] = 0.0
		
		
## Returns true if the input sequence binding has enough data to be checked.
func _is_sequence_binding_valid(binding: InputSequenceBinding) -> bool:
	if binding == null:
		return false

	if binding.sequence_id == StringName():
		return false

	if binding.input_actions.is_empty():
		return false

	for input_action: StringName in binding.input_actions:
		if input_action == StringName():
			return false

	return true


## Polls configured chord bindings for pressed and released events.
func _poll_chord_events(event: InputEvent) -> void:
	for binding: InputChordBinding in chord_bindings:
		if not _is_chord_binding_valid(binding):
			continue

		if not _event_matches_chord_action(binding, event):
			continue

		var was_held: bool = chord_held_values.get(binding.chord_id, false)
		var is_held: bool = _is_chord_held_after_event(binding, event)

		if is_held and not was_held:
			chord_held_values[binding.chord_id] = true
			chord_pressed.emit(binding.chord_id)
			if not allow_overlapping_chord_press_processing:
				return
			continue

		if not is_held and was_held:
			chord_held_values[binding.chord_id] = false
			chord_released.emit(binding.chord_id)


## Polls configured chord bindings that should emit while held.
func _poll_held_chords() -> void:
	for binding: InputChordBinding in chord_bindings:
		if not _is_chord_binding_valid(binding):
			continue

		var was_held: bool = chord_held_values.get(binding.chord_id, false)
		var is_held: bool = _is_chord_currently_held(binding)

		if is_held and not was_held:
			chord_held_values[binding.chord_id] = true
			chord_pressed.emit(binding.chord_id)

		if not is_held and was_held:
			chord_held_values[binding.chord_id] = false
			chord_released.emit(binding.chord_id)

		if is_held:
			chord_held.emit(binding.chord_id)


## Returns true if this input event is related to one of the chord's input actions.
func _event_matches_chord_action(
	binding: InputChordBinding,
	event: InputEvent
) -> bool:
	for input_action: StringName in binding.input_actions:
		if event.is_action_pressed(input_action):
			return true

		if event.is_action_released(input_action):
			return true

	return false


## Returns true if all actions in the chord are held after accounting for this input event.
func _is_chord_held_after_event(
	binding: InputChordBinding,
	event: InputEvent
) -> bool:
	for input_action: StringName in binding.input_actions:
		if event.is_action_released(input_action):
			return false

		if event.is_action_pressed(input_action):
			continue

		if not Input.is_action_pressed(input_action):
			return false

	return true


## Returns true if all actions in the chord are currently held.
func _is_chord_currently_held(binding: InputChordBinding) -> bool:
	for input_action: StringName in binding.input_actions:
		if not Input.is_action_pressed(input_action):
			return false

	return true


## Returns true if the chord binding has enough data to be checked.
func _is_chord_binding_valid(binding: InputChordBinding) -> bool:
	if binding == null:
		return false

	if binding.chord_id == StringName():
		return false

	if binding.input_actions.size() < 2:
		return false

	var seen_actions: Dictionary[StringName, bool] = {}

	for input_action: StringName in binding.input_actions:
		if input_action == StringName():
			return false

		if seen_actions.has(input_action):
			return false

		seen_actions[input_action] = true

	return true


## Returns true if a chord binding is currently held.
func is_chord_held(chord_id: StringName) -> bool:
	return chord_held_values.get(chord_id, false)


## Returns the latest value for a vector binding.
func get_vector(vector_id: StringName) -> Vector2:
	return vector_values.get(vector_id, Vector2.ZERO)


## Returns true if an action binding is currently held.
func is_action_held(action_id: StringName) -> bool:
	return action_held_values.get(action_id, false)


## Returns the current matched step count for an input sequence.
func get_sequence_progress(sequence_id: StringName) -> int:
	return sequence_progress_values.get(sequence_id, 0)


## Resets the progress of one input sequence.
func reset_sequence(sequence_id: StringName) -> void:
	sequence_progress_values[sequence_id] = 0
	sequence_last_input_time_values[sequence_id] = 0.0


## Resets the progress of all input sequences.
func reset_all_sequences() -> void:
	for sequence_id: StringName in sequence_progress_values.keys():
		reset_sequence(sequence_id)
