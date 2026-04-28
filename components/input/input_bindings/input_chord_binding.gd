class_name InputChordBinding
extends Resource

## Gameplay-facing ID emitted when this chord is pressed, released, or held.
@export var chord_id: StringName = &""

## Input actions that must be held at the same time for this chord to be active.
## Chords require at least two unique input actions.
@export var input_actions: Array[StringName] = []
