## Abstract lifecycle base for procedural generation systems.
##
## This class owns the common generation lifecycle:
## reset -> generate -> verify -> complete/fail
##
## Subclasses are responsible for implementing the actual generation, validation,
## and reset behavior through the abstract hook methods.
@abstract class_name ProceduralGenerationBase
extends Node


## States of generation process
enum GenerationState {
	IDLE, ## pre generation idle
	GENERATING, ## In process of actively generating
	VERIFYING, ## Verifying a generation's validity
	COMPLETED, ## Completed the entire generation process
	FAILED, ## Failed the generation process
	CANCELLED, ## Canceled or aborted the generation process prematurely
}

#region signals
## Signal emitted when the generator has started it's generation process
signal generation_started(generator : ProceduralGenerationBase)

## Signal emitted when the generator starts an attempt, mainly intended for implementations that may
## use multiple generation attempts in their approaches
signal generation_attempt_started(generator : ProceduralGenerationBase, attempt_number : int)

## Emitted if a procedural generator has an attempt failure for any reason, provides the number
## and a reference to the generator
signal generation_attempt_failed(generator : ProceduralGenerationBase, attempt_numer : int)

## Emitted when a generation is verified, and provides the validation result
signal generation_verified(generator: ProceduralGenerationBase, is_valid: bool)

## Emitted when the generation is completed
signal generation_completed(generator: ProceduralGenerationBase)

## Emitted when the generation has failed with an error message
signal generation_failed(generator: ProceduralGenerationBase, error_message: String)

## Emitted if the generation is canceled prematurely
signal generation_cancelled(generator: ProceduralGenerationBase)

## Emitted if the generation process has been reset
signal generation_reset(generator: ProceduralGenerationBase)
#endregion

#region exported fields
## Whether or not to start generation as soon as this node is ready
@export var auto_generate_on_ready : bool = false

## Whether or not to call reset functionality before attempting a generation
@export var reset_before_generation: bool = true

## Whether or not the verification process is called automatically after a generation
@export var verify_after_generation : bool = true

## The max number of allowed fails or generation attempts to be made in one generation process
@export_range(1, 256, 1) var max_generation_attempts : int = 1

## Whether or not to use a random seed
@export var use_random_seed : bool = true

## Manual seed to be used in generation
@export var seed : int = 0
#endregion

#region public variables
## The current state of the generator
var state : GenerationState = GenerationState.IDLE

## The attempt the generator has gotten to and is currently processing
var current_attempt : int = 0

## The previous seed used
var last_seed : int = 0

## The last error provided during a generation
var last_error : String = ""

## Core rng system used for consistent seeding
var rng : RandomNumberGenerator = RandomNumberGenerator.new()

## The most recent generation result produced by this generator.
##
## Concrete subclasses may store a Resource, Dictionary, Array, Node, or any
## other generated value here. Typed subclasses should expose a typed getter
## for safer access.
var last_result: Variant = null

#endregion

#region private vars
var _cancel_requested : bool = false
#endregion


func _ready() -> void:
	if auto_generate_on_ready:
		generate.call_deferred()

#region Provided lifecycle methods
## Core generation process will do up to max generation attempts at the subclasses core implementation
func generate() -> bool:
	if is_busy():
		report_generation_error("Cannot start generation while another generation is already running.")
		return false

	_cancel_requested = false
	last_error = ""
	current_attempt = 0

	if reset_before_generation:
		reset_generation()

	state = GenerationState.GENERATING
	generation_started.emit(self)

	var was_successful: bool = false
	var attempt_number: int = 1

	while attempt_number <= max_generation_attempts:
		current_attempt = attempt_number
		_prepare_random_number_generator()

		generation_attempt_started.emit(self, current_attempt)
		_before_generation_attempt(current_attempt)

		state = GenerationState.GENERATING
		var generated_successfully: bool = _generate()

		if _cancel_requested:
			state = GenerationState.CANCELLED
			_on_generation_cancelled()
			generation_cancelled.emit(self)
			return false

		var verified_successfully: bool = true

		if generated_successfully and verify_after_generation:
			state = GenerationState.VERIFYING
			verified_successfully = _verify_generation()
			generation_verified.emit(self, verified_successfully)

		if generated_successfully and verified_successfully:
			was_successful = true
			break

		generation_attempt_failed.emit(self, current_attempt)
		_after_generation_attempt_failed(current_attempt, generated_successfully, verified_successfully)

		if attempt_number < max_generation_attempts:
			_reset_generation()

		attempt_number += 1

	if was_successful:
		state = GenerationState.COMPLETED
		_after_generation_completed()
		generation_completed.emit(self)
		return true

	state = GenerationState.FAILED

	if last_error.is_empty():
		last_error = "Generation failed after %d attempt(s)." % max_generation_attempts

	_after_generation_failed(last_error)
	generation_failed.emit(self, last_error)
	return false

## Reset the current generation
func reset_generation() -> void:
	_cancel_requested = false
	current_attempt = 0
	last_error = ""
	state = GenerationState.IDLE

	_reset_generation()
	generation_reset.emit(self)

## Send a request to cancel the current generation
func cancel_generation() -> void:
	if not is_busy():
		return

	_cancel_requested = true

## Returns true if the generator is generating or verifying
func is_busy() -> bool:
	return state == GenerationState.GENERATING or state == GenerationState.VERIFYING

## Returns true if the generator is in the COMPLETED state
func is_completed() -> bool:
	return state == GenerationState.COMPLETED

## Returns true if the generator is in the FAILED state
func is_failed() -> bool:
	return state == GenerationState.FAILED

## Returns true if a cancel has been requested and the private field is true
func is_cancel_requested() -> bool:
	return _cancel_requested

## Places the most recent error into the last_error field so it is stored
func report_generation_error(error_message: String) -> void:
	last_error = error_message
#endregion

## Private method sets rng as needed for the next generation
func _prepare_random_number_generator() -> void:
	if use_random_seed:
		rng.randomize()
	else:
		rng.seed = seed

	last_seed = rng.seed

#region Optional unimplemented hook methods

func _before_generation_attempt(attempt_number: int) -> void:
	pass


func _after_generation_attempt_failed(
	attempt_number: int,
	generated_successfully: bool,
	verified_successfully: bool
) -> void:
	pass


func _after_generation_completed() -> void:
	pass


func _after_generation_failed(error_message: String) -> void:
	pass


func _on_generation_cancelled() -> void:
	pass
#endregion

#region required hook methods
@abstract
func _generate() -> bool


@abstract
func _verify_generation() -> bool


@abstract
func _reset_generation() -> void
#endregion
