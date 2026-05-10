## Abstract lifecycle base for wave-based encounter managers.
##
## This class owns the common wave lifecycle:
## start sequence -> delay -> start wave -> spawn/update wave -> complete wave
## -> repeat or complete sequence.
##
## Subclasses define what a wave is, how spawning works, and when a wave
## should be considered complete.
@abstract class_name WaveManagerBase
extends Node

## Emitted when the wave sequence begins
signal wave_sequence_started(manager: WaveManagerBase)

## Emitted when an individual wave in a sequence begins
signal wave_started(manager: WaveManagerBase, wave_index: int)

## Emitted when an individual wave in a sequence has completed.
signal wave_completed(manager: WaveManagerBase, wave_index: int)

## Emitted at the end of the entire wave sequence
signal wave_sequence_completed(manager: WaveManagerBase)

## Emitted on failure during the wave process
signal wave_manager_failed(manager: WaveManagerBase, error_message: String)

## Emitted when the manager resets itself
signal wave_manager_reset(manager: WaveManagerBase)

## Emitted any time the amount of active enemies changes
signal active_enemy_count_changed(manager: WaveManagerBase, active_enemy_count: int)

## Emitted any time the manager is paused or unpaused
signal pause_changed(manager: WaveManagerBase, is_paused: bool)

## The state of the wave manager
enum WaveManagerState {
	IDLE,
	STARTING,
	BETWEEN_WAVES,
	SPAWNING,
	ACTIVE,
	COMPLETED,
	FAILED,
	STOPPED,
}

## Whether or not to start the wave initialization process automatically
@export var auto_start_on_ready: bool = false

## Whether or not to reset everytime a wave sequence is started
@export var reset_on_start: bool = true

## The index of the starting wave
@export_range(1, 9999, 1) var start_wave_index: int = 1

## The initial delay in waves in seconds
@export_range(0.0, 600.0, 0.1) var initial_delay_seconds: float = 0.0

## Whether or not we use the wave timer in our transitions, if not the wave logic will
## need to be called manually elsewhere in the subclass or code calling the subclass
@export var use_timer_based_wave_delay: bool = true

## Delay in time between waves
@export_range(0.0, 600.0, 0.1) var time_between_waves_seconds: float = 3.0



## The current state of the manager
var state: WaveManagerState = WaveManagerState.IDLE

var current_wave_index: int = 0
var active_enemy_count: int = 0
var is_paused: bool = false
var last_error: String = ""

var _wave_delay_timer: Timer = Timer.new()
var _next_wave_pending_after_pause: bool = false
var _manual_wave_advance_pending: bool = false
var _stop_requested: bool = false

#region engine processing
func _ready() -> void:
	_ensure_wave_delay_timer()

	if auto_start_on_ready:
		start_waves.call_deferred()


func _process(delta: float) -> void:
	if is_paused:
		return

	if state == WaveManagerState.SPAWNING or state == WaveManagerState.ACTIVE:
		_update_wave(delta)
#endregion

## Starts up the wave sequence
func start_waves() -> bool:
	if is_running():
		report_wave_manager_error("Cannot start waves because the wave manager is already running.")
		return false

	if reset_on_start:
		reset_waves()

	_ensure_wave_delay_timer()

	_stop_requested = false
	_next_wave_pending_after_pause = false
	_manual_wave_advance_pending = false
	last_error = ""
	current_wave_index = start_wave_index - 1
	state = WaveManagerState.STARTING

	wave_sequence_started.emit(self)
	_on_wave_sequence_started()

	if initial_delay_seconds > 0.0:
		_schedule_next_wave(initial_delay_seconds)
	else:
		_begin_next_wave()

	return true

## Stops the wave sequence
func stop_waves() -> void:
	if not is_running():
		return

	_stop_requested = true
	_next_wave_pending_after_pause = false
	_manual_wave_advance_pending = false

	if is_instance_valid(_wave_delay_timer):
		_wave_delay_timer.stop()

	state = WaveManagerState.STOPPED
	_on_waves_stopped()

## Resets the wave sequence
func reset_waves() -> void:
	_stop_requested = false
	_next_wave_pending_after_pause = false
	_manual_wave_advance_pending = false
	last_error = ""
	current_wave_index = start_wave_index - 1
	active_enemy_count = 0
	state = WaveManagerState.IDLE

	if is_instance_valid(_wave_delay_timer):
		_wave_delay_timer.stop()

	_reset_waves()
	wave_manager_reset.emit(self)
	active_enemy_count_changed.emit(self, active_enemy_count)

## Sets the paused state.
func set_waves_paused(value: bool) -> void:
	if is_paused == value:
		return

	is_paused = value
	pause_changed.emit(self, is_paused)
	_on_pause_changed(is_paused)

	if not is_paused and _next_wave_pending_after_pause:
		_next_wave_pending_after_pause = false
		_begin_next_wave()
		
## Completes the current wave and either moves on to the next or finishes the sequence
func complete_current_wave() -> bool:
	if state != WaveManagerState.ACTIVE and state != WaveManagerState.SPAWNING:
		return false

	var completed_wave_index: int = current_wave_index

	state = WaveManagerState.BETWEEN_WAVES
	wave_completed.emit(self, completed_wave_index)
	_on_wave_completed(completed_wave_index)

	var next_wave_index: int = current_wave_index + 1

	if _has_next_wave(next_wave_index):
		_schedule_next_wave(time_between_waves_seconds)
	else:
		_complete_wave_sequence()

	return true

## Forces an immediate complete of the current wave
func force_complete_current_wave() -> bool:
	return complete_current_wave()

## Emits a signal that the enemy count has changed
func notify_enemy_spawned(count: int = 1) -> void:
	if count <= 0:
		return

	active_enemy_count += count
	active_enemy_count_changed.emit(self, active_enemy_count)

## Called when an enemy is defeated
func notify_enemy_defeated(count: int = 1) -> void:
	if count <= 0:
		return

	active_enemy_count = maxi(active_enemy_count - count, 0)
	active_enemy_count_changed.emit(self, active_enemy_count)

	if state == WaveManagerState.ACTIVE and _is_wave_complete(current_wave_index):
		complete_current_wave()


func is_running() -> bool:
	return (
		state == WaveManagerState.STARTING
		or state == WaveManagerState.BETWEEN_WAVES
		or state == WaveManagerState.SPAWNING
		or state == WaveManagerState.ACTIVE
	)


func is_completed() -> bool:
	return state == WaveManagerState.COMPLETED


func is_failed() -> bool:
	return state == WaveManagerState.FAILED

## Updates the last_error value with the error message
func report_wave_manager_error(error_message: String) -> void:
	last_error = error_message

## Handles the failing scenario
func fail_wave_manager(error_message: String) -> void:
	last_error = error_message
	state = WaveManagerState.FAILED

	if is_instance_valid(_wave_delay_timer):
		_wave_delay_timer.stop()

	_on_wave_manager_failed(error_message)
	wave_manager_failed.emit(self, error_message)

## Advances to the next wave if the manager is currently waiting between waves.
##
## This is mainly useful when use_timer_based_wave_delay is false.
func advance_to_next_wave() -> bool:
	if state != WaveManagerState.STARTING and state != WaveManagerState.BETWEEN_WAVES:
		return false

	if not use_timer_based_wave_delay and not _manual_wave_advance_pending:
		return false

	_manual_wave_advance_pending = false
	_next_wave_pending_after_pause = false
	_begin_next_wave()
	return true

## Makes sure the delay timer is in a valid state.
func _ensure_wave_delay_timer() -> void:
	if not is_instance_valid(_wave_delay_timer):
		_wave_delay_timer = Timer.new()

	_wave_delay_timer.one_shot = true

	if _wave_delay_timer.get_parent() == null:
		add_child(_wave_delay_timer)

	if use_timer_based_wave_delay:
		if not _wave_delay_timer.timeout.is_connected(_on_wave_delay_timer_timeout):
			_wave_delay_timer.timeout.connect(_on_wave_delay_timer_timeout)
	else:
		if _wave_delay_timer.timeout.is_connected(_on_wave_delay_timer_timeout):
			_wave_delay_timer.timeout.disconnect(_on_wave_delay_timer_timeout)

## Starts up the next wave using either the internal timer or manual delay handling.
func _schedule_next_wave(delay_seconds: float) -> void:
	if _stop_requested:
		return

	if delay_seconds <= 0.0:
		_begin_next_wave()
		return

	state = WaveManagerState.BETWEEN_WAVES

	if not use_timer_based_wave_delay:
		_manual_wave_advance_pending = true
		_on_manual_wave_delay_started(delay_seconds)
		return

	_ensure_wave_delay_timer()
	_wave_delay_timer.start(delay_seconds)

## Begins the next wave based on the index
func _begin_next_wave() -> void:
	if _stop_requested:
		return

	if is_paused:
		_next_wave_pending_after_pause = false
		return

	var next_wave_index: int = current_wave_index + 1

	if not _has_next_wave(next_wave_index):
		_complete_wave_sequence()
		return

	current_wave_index = next_wave_index
	active_enemy_count = 0
	active_enemy_count_changed.emit(self, active_enemy_count)

	state = WaveManagerState.SPAWNING
	wave_started.emit(self, current_wave_index)
	_on_wave_started(current_wave_index)

	var spawned_successfully: bool = _spawn_wave(current_wave_index)

	if not spawned_successfully:
		fail_wave_manager("Wave %d failed to spawn." % current_wave_index)
		return

	state = WaveManagerState.ACTIVE

	if _is_wave_complete(current_wave_index):
		complete_current_wave()

## Finishes off the wave process
func _complete_wave_sequence() -> void:
	state = WaveManagerState.COMPLETED

	if is_instance_valid(_wave_delay_timer):
		_wave_delay_timer.stop()

	_on_wave_sequence_completed()
	wave_sequence_completed.emit(self)

## Calls the next wave to begin if applicable on timeout 
func _on_wave_delay_timer_timeout() -> void:
	if state != WaveManagerState.STARTING and state != WaveManagerState.BETWEEN_WAVES:
		return

	if is_paused:
		_next_wave_pending_after_pause = false
		return

	_begin_next_wave()

#region optional hook methods
func _on_wave_sequence_started() -> void:
	pass


func _on_wave_started(wave_index: int) -> void:
	pass


func _on_wave_completed(wave_index: int) -> void:
	pass


func _on_wave_sequence_completed() -> void:
	pass


func _on_waves_stopped() -> void:
	pass


func _on_wave_manager_failed(error_message: String) -> void:
	pass


func _on_pause_changed(paused: bool) -> void:
	pass


func _update_wave(delta: float) -> void:
	pass
	
## Called when timer-based wave delay is disabled and the base class reaches a delay point.
##
## Subclasses can override this to start animations, wait for arena conditions,
## wait for dialogue, or manually call advance_to_next_wave().
func _on_manual_wave_delay_started(delay_seconds: float) -> void:
	pass
#endregion

#region required hook methods
@abstract
func _spawn_wave(wave_index: int) -> bool


@abstract
func _has_next_wave(next_wave_index: int) -> bool


@abstract
func _is_wave_complete(wave_index: int) -> bool


@abstract
func _reset_waves() -> void
#endregion
