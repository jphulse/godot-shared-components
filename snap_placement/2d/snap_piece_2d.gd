class_name SnapPiece2D
extends Node2D

## Unique identifier for this snap piece.
@export var piece_id: StringName = &""

## NodePath to the node that contains this piece's sockets.
@export var sockets_root_path: NodePath = ^"Sockets"

## Whether this piece should gather sockets during _ready().
@export var auto_find_sockets_on_ready: bool = true

## Sockets currently registered to this piece.
var sockets: Array[SnapSocket2D] = []


## Finds sockets automatically when the piece enters the scene tree.
func _ready() -> void:
	if auto_find_sockets_on_ready:
		refresh_sockets()


## Refreshes the list of sockets belonging to this piece.
func refresh_sockets() -> void:
	sockets.clear()

	var sockets_root: Node = get_node_or_null(sockets_root_path)

	if sockets_root == null:
		_collect_sockets_recursive(self, sockets)
		return

	_collect_sockets_recursive(sockets_root, sockets)


## Returns whether this piece has any connected sockets.
func has_connected_sockets() -> bool:
	for socket: SnapSocket2D in sockets:
		if socket.is_connected:
			return true

	return false

## Returns all sockets belonging to this piece.
func get_sockets() -> Array[SnapSocket2D]:
	var copied_sockets: Array[SnapSocket2D] = []

	for socket: SnapSocket2D in sockets:
		copied_sockets.append(socket)

	return copied_sockets


## Returns all sockets that are not currently connected.
func get_open_sockets() -> Array[SnapSocket2D]:
	var open_sockets: Array[SnapSocket2D] = []

	for socket: SnapSocket2D in sockets:
		if socket.is_open():
			open_sockets.append(socket)

	return open_sockets


## Returns all open sockets that allow automatic connections.
func get_auto_connect_open_sockets() -> Array[SnapSocket2D]:
	var open_sockets: Array[SnapSocket2D] = []

	for socket: SnapSocket2D in sockets:
		if socket.is_open() and socket.allow_auto_connect:
			open_sockets.append(socket)

	return open_sockets


## Returns the first socket with the requested socket id.
func get_socket_by_id(target_socket_id: StringName) -> SnapSocket2D:
	for socket: SnapSocket2D in sockets:
		if socket.socket_id == target_socket_id:
			return socket

	return null


## Returns sockets on this piece that can manually connect to the given socket.
func get_compatible_open_sockets(target_socket: SnapSocket2D) -> Array[SnapSocket2D]:
	var compatible_sockets: Array[SnapSocket2D] = []

	for socket: SnapSocket2D in get_open_sockets():
		if socket.can_connect_to(target_socket):
			compatible_sockets.append(socket)

	return compatible_sockets


## Returns sockets on this piece that can automatically connect to the given socket.
func get_auto_compatible_open_sockets(target_socket: SnapSocket2D) -> Array[SnapSocket2D]:
	var compatible_sockets: Array[SnapSocket2D] = []

	for socket: SnapSocket2D in get_auto_connect_open_sockets():
		if socket.can_auto_connect_to(target_socket):
			compatible_sockets.append(socket)

	return compatible_sockets


## Disconnects all sockets registered to this piece.
func disconnect_all_sockets() -> void:
	for socket: SnapSocket2D in sockets:
		socket.disconnect_socket()


## Recursively collects SnapSocket2D children from the given root node.
func _collect_sockets_recursive(root_node: Node, output_sockets: Array[SnapSocket2D]) -> void:
	for child_node: Node in root_node.get_children():
		var socket: SnapSocket2D = child_node as SnapSocket2D

		if socket != null:
			output_sockets.append(socket)

		_collect_sockets_recursive(child_node, output_sockets)
