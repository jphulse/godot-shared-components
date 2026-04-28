class_name InputBufferComponent
extends Node

## The type of buffered input.
enum BufferKind {
	ACTION,
	CHORD,
	SEQUENCE,
}

## Emitted when an input is stored in the buffer.
signal input_buffered(buffer_kind: BufferKind, input_id: StringName)

## Emitted when an input is successfully consumed from the buffer.
signal input_consumed(buffer_kind: BufferKind, input_id: StringName)

## Emitted when an input expires and is removed from the buffer.
signal input_expired(buffer_kind: BufferKind, input_id: StringName)

@export_group("Input Source")
## Input component this buffer listens to.
## Leave empty if another object will manually route inputs to this buffer
@export var input_component: InputComponent

## Whether this component should connect to the input component during _ready().
@export var connect_on_ready: bool = true

## Whether this buffer should automatically listen for action_pressed signals.
@export var auto_connect_actions: bool = true

## Whether this buffer should automatically listen for chord_pressed signals.
@export var auto_connect_chords: bool = true

## Whether this buffer should automatically listen for input_sequence_completed signals.
@export var auto_connect_sequences: bool = true

@export_group("Buffer Rules")
## Whether this component is currently storing and consuming buffered inputs.
@export var enabled: bool = true

## Default amount of time, in seconds, that an input remains buffered.
@export var default_buffer_seconds: float = 0.15

## Per-input buffer window overrides.
## Keys should be gameplay-facing IDs such as &"jump" or &"dash".
## Values should be buffer durations in seconds.
@export var custom_buffer_seconds: Dictionary[StringName, float] = {}

## Whether action_pressed events should be buffered.
@export var buffer_actions: bool = true

## Whether chord_pressed events should be buffered.
@export var buffer_chords: bool = true

## Whether input_sequence_completed events should be buffered.
@export var buffer_sequences: bool = true

## Whether expired inputs should be cleared automatically every process tick.
@export var auto_clear_expired_inputs: bool = true

## Whether all buffered inputs should be cleared when this component is disabled through set_enabled().
@export var clear_when_disabled: bool = true

## Last buffered time for each action ID.
var action_buffer_times: Dictionary[StringName, float] = {}

## Last buffered time for each chord ID.
var chord_buffer_times: Dictionary[StringName, float] = {}

## Last buffered time for each sequence ID.
var sequence_buffer_times: Dictionary[StringName, float] = {}


## Connects to the configured input component if connect_on_ready is enabled.
func _ready() -> void:
	if connect_on_ready:
		connect_input_component()


## Disconnects from the configured input component before leaving the scene tree.
func _exit_tree() -> void:
	disconnect_input_component()


## Clears expired inputs automatically if enabled.
func _process(delta: float) -> void:
	if not enabled:
		return

	if auto_clear_expired_inputs:
		clear_expired_inputs()


## Enables or disables this buffer component.
func set_enabled(value: bool) -> void:
	enabled = value

	if not enabled and clear_when_disabled:
		clear_all()


## Assigns a new input component and reconnects this buffer to it.
func set_input_component(new_input_component: InputComponent) -> void:
	disconnect_input_component()
	input_component = new_input_component
	connect_input_component()


## Connects this buffer to the configured input component's event signals.
func connect_input_component() -> void:
	if input_component == null:
		return

	if auto_connect_actions and not input_component.action_pressed.is_connected(_on_action_pressed):
		input_component.action_pressed.connect(_on_action_pressed)

	if auto_connect_chords and not input_component.chord_pressed.is_connected(_on_chord_pressed):
		input_component.chord_pressed.connect(_on_chord_pressed)

	if auto_connect_sequences and not input_component.input_sequence_completed.is_connected(_on_input_sequence_completed):
		input_component.input_sequence_completed.connect(_on_input_sequence_completed)


## Disconnects this buffer from the configured input component's event signals.
func disconnect_input_component() -> void:
	if input_component == null:
		return

	if input_component.action_pressed.is_connected(_on_action_pressed):
		input_component.action_pressed.disconnect(_on_action_pressed)

	if input_component.chord_pressed.is_connected(_on_chord_pressed):
		input_component.chord_pressed.disconnect(_on_chord_pressed)

	if input_component.input_sequence_completed.is_connected(_on_input_sequence_completed):
		input_component.input_sequence_completed.disconnect(_on_input_sequence_completed)

## Reconnects this buffer to the input component using the current auto-connect settings.
func reconnect_input_component() -> void:
	disconnect_input_component()
	connect_input_component()

## Stores an action press in the input buffer.
func _on_action_pressed(action_id: StringName) -> void:
	buffer_action(action_id)


## Stores a chord press in the input buffer.
func _on_chord_pressed(chord_id: StringName) -> void:
	buffer_chord(chord_id)


## Stores a completed input sequence in the input buffer.
func _on_input_sequence_completed(sequence_id: StringName) -> void:
	buffer_sequence(sequence_id)

## Manually stores an action press in the buffer.
func buffer_action(action_id: StringName) -> void:
	if not enabled:
		return

	if not buffer_actions:
		return

	_store_buffered_input(action_buffer_times, BufferKind.ACTION, action_id)


## Manually stores a chord press in the buffer.
func buffer_chord(chord_id: StringName) -> void:
	if not enabled:
		return

	if not buffer_chords:
		return

	_store_buffered_input(chord_buffer_times, BufferKind.CHORD, chord_id)


## Manually stores a completed input sequence in the buffer.
func buffer_sequence(sequence_id: StringName) -> void:
	if not enabled:
		return

	if not buffer_sequences:
		return

	_store_buffered_input(sequence_buffer_times, BufferKind.SEQUENCE, sequence_id)

## Stores an input ID in the given buffer dictionary.
func _store_buffered_input(
	buffer_times: Dictionary[StringName, float],
	buffer_kind: BufferKind,
	input_id: StringName
) -> void:
	if input_id == StringName():
		return

	buffer_times[input_id] = _get_now_seconds()
	input_buffered.emit(buffer_kind, input_id)


## Returns true if the given action is currently buffered.
func has_buffered_action(action_id: StringName) -> bool:
	return _has_buffered_input(action_buffer_times, BufferKind.ACTION, action_id)


## Returns true if the given chord is currently buffered.
func has_buffered_chord(chord_id: StringName) -> bool:
	return _has_buffered_input(chord_buffer_times, BufferKind.CHORD, chord_id)


## Returns true if the given sequence is currently buffered.
func has_buffered_sequence(sequence_id: StringName) -> bool:
	return _has_buffered_input(sequence_buffer_times, BufferKind.SEQUENCE, sequence_id)


## Consumes a buffered action if it is still valid.
func consume_action(action_id: StringName) -> bool:
	return _consume_buffered_input(
		action_buffer_times,
		BufferKind.ACTION,
		action_id
	)


## Consumes a buffered chord if it is still valid.
func consume_chord(chord_id: StringName) -> bool:
	return _consume_buffered_input(
		chord_buffer_times,
		BufferKind.CHORD,
		chord_id
	)


## Consumes a buffered sequence if it is still valid.
func consume_sequence(sequence_id: StringName) -> bool:
	return _consume_buffered_input(
		sequence_buffer_times,
		BufferKind.SEQUENCE,
		sequence_id
	)


## Returns true if the given input ID exists and has not expired.
func _has_buffered_input(
	buffer_times: Dictionary[StringName, float],
	buffer_kind : BufferKind,
	input_id: StringName
) -> bool:
	if not enabled:
		return false

	if not buffer_times.has(input_id):
		return false

	if _is_buffered_input_expired(buffer_times, input_id):
		buffer_times.erase(input_id)
		input_expired.emit(buffer_kind, input_id)
		return false

	return true


## Consumes a buffered input if it exists and has not expired.
func _consume_buffered_input(
	buffer_times: Dictionary[StringName, float],
	buffer_kind: BufferKind,
	input_id: StringName
) -> bool:
	if not _has_buffered_input(buffer_times, buffer_kind, input_id):
		return false

	buffer_times.erase(input_id)
	input_consumed.emit(buffer_kind, input_id)
	return true


## Returns true if the buffered input has exceeded its allowed buffer window.
func _is_buffered_input_expired(
	buffer_times: Dictionary[StringName, float],
	input_id: StringName
) -> bool:
	var buffered_time: float = buffer_times.get(input_id, -999.0)
	var age_seconds: float = _get_now_seconds() - buffered_time
	var buffer_seconds: float = get_buffer_seconds(input_id)

	return age_seconds > buffer_seconds


## Returns the configured buffer duration for the given input ID.
func get_buffer_seconds(input_id: StringName) -> float:
	if custom_buffer_seconds.has(input_id):
		return float(custom_buffer_seconds[input_id])

	return default_buffer_seconds


## Returns the age of a buffered action in seconds, or -1.0 if it is not buffered.
func get_action_age_seconds(action_id: StringName) -> float:
	return _get_buffer_age_seconds(action_buffer_times, action_id)


## Returns the age of a buffered chord in seconds, or -1.0 if it is not buffered.
func get_chord_age_seconds(chord_id: StringName) -> float:
	return _get_buffer_age_seconds(chord_buffer_times, chord_id)


## Returns the age of a buffered sequence in seconds, or -1.0 if it is not buffered.
func get_sequence_age_seconds(sequence_id: StringName) -> float:
	return _get_buffer_age_seconds(sequence_buffer_times, sequence_id)


## Returns the age of a buffered input in seconds, or -1.0 if it is not buffered.
func _get_buffer_age_seconds(
	buffer_times: Dictionary[StringName, float],
	input_id: StringName
) -> float:
	if not buffer_times.has(input_id):
		return -1.0

	return _get_now_seconds() - buffer_times[input_id]


## Clears all expired inputs from all buffers.
func clear_expired_inputs() -> void:
	_clear_expired_inputs_from_buffer(action_buffer_times, BufferKind.ACTION)
	_clear_expired_inputs_from_buffer(chord_buffer_times, BufferKind.CHORD)
	_clear_expired_inputs_from_buffer(sequence_buffer_times, BufferKind.SEQUENCE)


## Clears expired inputs from a specific buffer dictionary.
func _clear_expired_inputs_from_buffer(
	buffer_times: Dictionary[StringName, float],
	buffer_kind: BufferKind
) -> void:
	for input_id: StringName in buffer_times.keys():
		if not _is_buffered_input_expired(buffer_times, input_id):
			continue

		buffer_times.erase(input_id)
		input_expired.emit(buffer_kind, input_id)


## Clears a buffered action manually.
func clear_action(action_id: StringName) -> void:
	action_buffer_times.erase(action_id)


## Clears a buffered chord manually.
func clear_chord(chord_id: StringName) -> void:
	chord_buffer_times.erase(chord_id)


## Clears a buffered sequence manually.
func clear_sequence(sequence_id: StringName) -> void:
	sequence_buffer_times.erase(sequence_id)


## Clears all buffered actions, chords, and sequences.
func clear_all() -> void:
	action_buffer_times.clear()
	chord_buffer_times.clear()
	sequence_buffer_times.clear()


## Returns the current time in seconds.
func _get_now_seconds() -> float:
	return Time.get_ticks_msec() / 1000.0
