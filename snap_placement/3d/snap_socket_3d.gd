class_name SnapSocket3D
extends Marker3D

## Emitted when this socket connects to another socket.
signal socket_connected(self_socket: SnapSocket3D, other_socket: SnapSocket3D)

## Emitted when this socket disconnects from another socket.
signal socket_disconnected(self_socket: SnapSocket3D, other_socket: SnapSocket3D)

## Unique identifier for this socket within its piece.
@export var socket_id: StringName = &""

## Type/category of this socket.
@export var socket_type: StringName = &"standard"

## Socket types this socket can connect to. If empty, only matching socket_type values are accepted.
@export var accepted_socket_types: Array[StringName] = []

## Whether automatic placement systems may connect this socket.
@export var allow_auto_connect: bool = true

## Whether this socket is currently connected.
@export var is_connected: bool = false

## Optional grouping value for filtering connections, such as "doors", "pipes", or "roads".
@export var connection_group: StringName = &"default"

## The socket currently connected to this socket.
var connected_socket: SnapSocket3D = null


## Returns whether this socket is available for a new connection.
func is_open() -> bool:
	return not is_connected


## Returns whether this socket can manually connect to another socket.
func can_connect_to(other_socket: SnapSocket3D) -> bool:
	if other_socket == null:
		return false

	if other_socket == self:
		return false

	if is_connected or other_socket.is_connected:
		return false

	if connection_group != other_socket.connection_group:
		return false

	if not accepts_socket_type(other_socket.socket_type):
		return false

	if not other_socket.accepts_socket_type(socket_type):
		return false

	return true


## Returns whether this socket can automatically connect to another socket.
func can_auto_connect_to(other_socket: SnapSocket3D) -> bool:
	if not allow_auto_connect:
		return false

	if other_socket == null:
		return false

	if not other_socket.allow_auto_connect:
		return false

	return can_connect_to(other_socket)


## Marks this socket as connected to another socket.
func connect_to_socket(other_socket: SnapSocket3D) -> void:
	connected_socket = other_socket
	is_connected = other_socket != null
	
	if is_connected:
		socket_connected.emit(self, connected_socket)


## Clears this socket's current connection.
func disconnect_socket() -> void:
	var previous_socket : SnapSocket3D = connected_socket
	
	connected_socket = null
	is_connected = false
	
	if previous_socket != null:
		socket_disconnected.emit(self, previous_socket)


## Returns this socket's outward-facing direction in global 3D space.
func get_facing_direction() -> Vector3:
	var facing_direction: Vector3 = -global_transform.basis.z
	return facing_direction.normalized()


## Returns whether this socket is facing another socket within the given angle limit.
func is_facing_socket(other_socket: SnapSocket3D, max_angle_degrees: float = 5.0) -> bool:
	if other_socket == null:
		return false

	var this_direction: Vector3 = get_facing_direction()
	var other_direction: Vector3 = other_socket.get_facing_direction()
	var angle_difference: float = this_direction.angle_to(-other_direction)
	var max_angle_radians: float = deg_to_rad(max_angle_degrees)

	return angle_difference <= max_angle_radians


## Returns whether this socket accepts the given socket type.
func accepts_socket_type(candidate_socket_type: StringName) -> bool:
	if accepted_socket_types.is_empty():
		return candidate_socket_type == socket_type

	return accepted_socket_types.has(candidate_socket_type)
