class_name SnapPlacementGraph
extends Resource


## Stores every known connection in the placement graph.
@export var connections: Array[SnapConnectionData] = []

## Maps socket path strings to their active connection data.
var socket_connection_map: Dictionary[String, SnapConnectionData] = {}

## Whether the socket connection map needs to be rebuilt from the exported connection array.
var index_is_dirty: bool = true


## Adds a connection to the graph and returns whether it was accepted.
func add_connection(connection_data: SnapConnectionData) -> bool:
	if connection_data == null:
		return false

	if not _is_connection_data_valid(connection_data):
		return false

	_ensure_index_current()

	if is_socket_path_connected(connection_data.socket_a_path):
		return false

	if is_socket_path_connected(connection_data.socket_b_path):
		return false

	connections.append(connection_data)
	_insert_connection_into_index(connection_data)
	return true


## Creates and adds a connection from live piece and socket nodes.
func add_socket_connection(
		piece_a: Node,
		socket_a: Node,
		piece_b: Node,
		socket_b: Node,
		socket_type: StringName = &"",
		connection_group: StringName = &"default",
		bidirectional: bool = true,
		is_navigation_link: bool = false
) -> SnapConnectionData:
	if piece_a == null or socket_a == null or piece_b == null or socket_b == null:
		return null

	var connection_data: SnapConnectionData = SnapConnectionData.new(
		piece_a.get_path(),
		socket_a.get_path(),
		piece_b.get_path(),
		socket_b.get_path(),
		socket_type,
		connection_group,
		bidirectional,
		is_navigation_link
	)

	var was_added: bool = add_connection(connection_data)

	if not was_added:
		return null

	return connection_data


## Removes the connection that contains the given socket path.
func remove_connection_for_socket_path(socket_path: NodePath) -> bool:
	_ensure_index_current()

	var socket_key: String = _get_socket_key(socket_path)

	if not socket_connection_map.has(socket_key):
		return false

	var connection_data: SnapConnectionData = socket_connection_map[socket_key]

	if connection_data == null:
		socket_connection_map.erase(socket_key)
		return false

	connections.erase(connection_data)
	socket_connection_map.erase(_get_socket_key(connection_data.socket_a_path))
	socket_connection_map.erase(_get_socket_key(connection_data.socket_b_path))
	return true


## Removes the exact connection resource from the graph.
func remove_connection(connection_data: SnapConnectionData) -> bool:
	if connection_data == null:
		return false

	var has: bool = connections.has(connection_data)

	if has:
		connections.erase(connection_data)
		socket_connection_map.erase(_get_socket_key(connection_data.socket_a_path))
		socket_connection_map.erase(_get_socket_key(connection_data.socket_b_path))

	return has


## Returns whether the given socket path already has a graph connection.
func is_socket_path_connected(socket_path: NodePath) -> bool:
	_ensure_index_current()
	return socket_connection_map.has(_get_socket_key(socket_path))


## Returns whether two socket paths are connected to each other.
func are_socket_paths_connected(socket_a_path: NodePath, socket_b_path: NodePath) -> bool:
	var connection_data: SnapConnectionData = get_connection_for_socket_path(socket_a_path)

	if connection_data == null:
		return false

	var socket_a_matches: bool = connection_data.socket_a_path == socket_a_path and connection_data.socket_b_path == socket_b_path
	var socket_b_matches: bool = connection_data.socket_a_path == socket_b_path and connection_data.socket_b_path == socket_a_path

	return socket_a_matches or socket_b_matches


## Returns the connection containing the given socket path.
func get_connection_for_socket_path(socket_path: NodePath) -> SnapConnectionData:
	_ensure_index_current()

	var socket_key: String = _get_socket_key(socket_path)

	if not socket_connection_map.has(socket_key):
		return null

	return socket_connection_map[socket_key]


## Returns copied connection references in a new typed array.
func get_connections() -> Array[SnapConnectionData]:
	var copied_connections: Array[SnapConnectionData] = []

	for connection_data: SnapConnectionData in connections:
		copied_connections.append(connection_data)

	return copied_connections


## Marks the graph index as dirty so it will be rebuilt before the next lookup.
func mark_index_dirty() -> void:
	index_is_dirty = true


## Rebuilds the internal lookup map from the exported connection array.
func rebuild_index() -> void:
	socket_connection_map.clear()

	for connection_data: SnapConnectionData in connections:
		if not _is_connection_data_valid(connection_data):
			continue

		if socket_connection_map.has(_get_socket_key(connection_data.socket_a_path)):
			continue

		if socket_connection_map.has(_get_socket_key(connection_data.socket_b_path)):
			continue

		_insert_connection_into_index(connection_data)

	index_is_dirty = false


## Removes every graph connection.
func clear() -> void:
	connections.clear()
	socket_connection_map.clear()
	index_is_dirty = false


## Rebuilds the index if needed.
func _ensure_index_current() -> void:
	if index_is_dirty:
		rebuild_index()


## Adds one connection to the internal lookup map.
func _insert_connection_into_index(connection_data: SnapConnectionData) -> void:
	socket_connection_map[_get_socket_key(connection_data.socket_a_path)] = connection_data
	socket_connection_map[_get_socket_key(connection_data.socket_b_path)] = connection_data


## Returns whether the connection has usable socket endpoints.
func _is_connection_data_valid(connection_data: SnapConnectionData) -> bool:
	if connection_data == null:
		return false

	if connection_data.socket_a_path == NodePath():
		return false

	if connection_data.socket_b_path == NodePath():
		return false

	if connection_data.socket_a_path == connection_data.socket_b_path:
		return false

	return true


## Converts a socket path into a stable dictionary key.
func _get_socket_key(socket_path: NodePath) -> String:
	return String(socket_path)
