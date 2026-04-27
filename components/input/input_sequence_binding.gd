class_name InputSequenceBinding
extends Resource

## Determines whether this sequence advances on pressed events or released events.
enum SequenceEventMode {
	PRESSED,
	RELEASED,
}

## Gameplay-facing ID emitted when this sequence completes.
@export var sequence_id: StringName = &""

## Ordered list of input actions required to complete this sequence.
@export var input_actions: Array[StringName] = []

## Whether this sequence advances on pressed or released input events.
@export var sequence_event_mode: SequenceEventMode = SequenceEventMode.PRESSED

## Maximum allowed time in seconds between sequence steps.
## Set to 0.0 or less to disable the timeout.
@export var max_gap_seconds: float = 0.35

## Whether the sequence should reset when a wrong input is received.
@export var reset_on_wrong_input: bool = true
