class_name NavigationComponent3D
extends NavigationAgent3D

## Emitted when the parent should move toward the next path position.
signal nav_component_request_move(next_path_position: Vector3, delta: float)

## How often the target position should be refreshed.
## Lower values track moving targets more smoothly.
@export var position_query_timer: float = 0.25

## The node this navigation component should follow.
@export var target: Node3D

## Whether this component should request movement.
@export var enabled: bool = true

## The timer used to periodically refresh the target position.
@onready var target_timer: Timer = $NavTimer

## The last queried target position.
var _target_position: Vector3 = Vector3.ZERO


func _ready() -> void:
	# NavigationServer3D syncs after physics frames, so avoid querying immediately.
	await get_tree().physics_frame

	if target == null and get_parent().has_method("get_target"):
		target = get_parent().get_target()

	if target != null:
		_refresh_target_position()

	if position_query_timer > 0.0:
		target_timer.wait_time = position_query_timer
		target_timer.start()


func _physics_process(delta: float) -> void:
	if not enabled:
		return

	if target == null:
		return

	if is_navigation_finished():
		return

	var next_path_position: Vector3 = get_next_path_position()
	nav_component_request_move.emit(next_path_position, delta)


## Updates the navigation target position from the current target node.
func _refresh_target_position() -> void:
	if target == null:
		return

	_target_position = target.global_position
	target_position = _target_position


## Called when the target query timer times out.
func _on_nav_timer_timeout() -> void:
	_refresh_target_position()
