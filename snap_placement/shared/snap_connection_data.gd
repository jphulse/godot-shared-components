class_name SnapConnectionData
extends Resource


## Stores the path to the first connected piece.
@export var piece_a_path: NodePath = NodePath()

## Stores the path to the first connected socket.
@export var socket_a_path: NodePath = NodePath()

## Stores the path to the second connected piece.
@export var piece_b_path: NodePath = NodePath()

## Stores the path to the second connected socket.
@export var socket_b_path: NodePath = NodePath()

## Stores the socket type used by this connection.
@export var socket_type: StringName = &""

## Stores the connection group used by this connection.
@export var connection_group: StringName = &"default"

## Whether this connection should be interpreted as usable in both directions.
@export var bidirectional: bool = true

## Whether this connection represents a navigation link instead of a physical seam.
@export var is_navigation_link: bool = false


## Creates a new snap connection data resource.
func _init(
		new_piece_a_path: NodePath = NodePath(),
		new_socket_a_path: NodePath = NodePath(),
		new_piece_b_path: NodePath = NodePath(),
		new_socket_b_path: NodePath = NodePath(),
		new_socket_type: StringName = &"",
		new_connection_group: StringName = &"default",
		new_bidirectional: bool = true,
		new_is_navigation_link: bool = false
) -> void:
	piece_a_path = new_piece_a_path
	socket_a_path = new_socket_a_path
	piece_b_path = new_piece_b_path
	socket_b_path = new_socket_b_path
	socket_type = new_socket_type
	connection_group = new_connection_group
	bidirectional = new_bidirectional
	is_navigation_link = new_is_navigation_link


## Returns whether this connection contains the given socket path.
func has_socket_path(socket_path: NodePath) -> bool:
	return socket_a_path == socket_path or socket_b_path == socket_path


## Returns whether this connection contains the given piece path.
func has_piece_path(piece_path: NodePath) -> bool:
	return piece_a_path == piece_path or piece_b_path == piece_path


## Returns the socket path on the opposite side of the connection.
func get_other_socket_path(socket_path: NodePath) -> NodePath:
	if socket_path == socket_a_path:
		return socket_b_path

	if socket_path == socket_b_path:
		return socket_a_path

	return NodePath()


## Returns the piece path on the opposite side of the connection.
func get_other_piece_path(piece_path: NodePath) -> NodePath:
	if piece_path == piece_a_path:
		return piece_b_path

	if piece_path == piece_b_path:
		return piece_a_path

	return NodePath()
