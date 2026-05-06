class_name SnapPlacementUtility3D
extends RefCounted

## Default maximum socket distance for considering two 3D sockets aligned.
const DEFAULT_DISTANCE_EPSILON: float = 0.05

## Default maximum facing angle difference for considering two 3D sockets aligned.
const DEFAULT_MAX_ANGLE_DEGREES: float = 5.0

## Default local axis used to rotate one socket to face another socket.
const DEFAULT_SOCKET_FLIP_AXIS: Vector3 = Vector3.UP


## Snaps a piece so one of its sockets aligns to a target socket.
static func snap_piece_socket_to_target_socket(
		piece: Node3D,
		piece_socket: SnapSocket3D,
		target_socket: SnapSocket3D,
		socket_flip_axis: Vector3 = DEFAULT_SOCKET_FLIP_AXIS
) -> void:
	if piece == null or piece_socket == null or target_socket == null:
		return

	var normalized_flip_axis: Vector3 = socket_flip_axis.normalized()
	var socket_local_transform: Transform3D = piece.global_transform.affine_inverse() * piece_socket.global_transform
	var target_facing_transform: Transform3D = target_socket.global_transform.rotated_local(normalized_flip_axis, PI)

	piece.global_transform = target_facing_transform * socket_local_transform.affine_inverse()


## Snaps a piece socket to a target socket and connects the sockets if allowed.
static func snap_and_connect_piece_socket_to_target_socket(
		piece: Node3D,
		piece_socket: SnapSocket3D,
		target_socket: SnapSocket3D,
		socket_flip_axis: Vector3 = DEFAULT_SOCKET_FLIP_AXIS
) -> bool:
	if piece == null or piece_socket == null or target_socket == null:
		return false
	
	if piece.has_connected_sockets():
		push_warning("SnapPlacementUtility3D refused to snap a piece that already has connected sockets. Disconnect it first or use a cluster-aware placement utility.")
		return false

	
	if not piece_socket.can_connect_to(target_socket):
		return false

	snap_piece_socket_to_target_socket(piece, piece_socket, target_socket, socket_flip_axis)
	return connect_sockets(piece_socket, target_socket)


## Returns whether two sockets can manually connect and are physically aligned.
static func can_connect_aligned_sockets(
		socket_a: SnapSocket3D,
		socket_b: SnapSocket3D,
		max_distance: float = DEFAULT_DISTANCE_EPSILON,
		max_angle_degrees: float = DEFAULT_MAX_ANGLE_DEGREES
) -> bool:
	if socket_a == null or socket_b == null:
		return false

	if not socket_a.can_connect_to(socket_b):
		return false

	if socket_a.global_position.distance_to(socket_b.global_position) > max_distance:
		return false

	if not socket_a.is_facing_socket(socket_b, max_angle_degrees):
		return false

	return true


## Returns whether two sockets can automatically connect and are physically aligned.
static func can_auto_connect_aligned_sockets(
		socket_a: SnapSocket3D,
		socket_b: SnapSocket3D,
		max_distance: float = DEFAULT_DISTANCE_EPSILON,
		max_angle_degrees: float = DEFAULT_MAX_ANGLE_DEGREES
) -> bool:
	if socket_a == null or socket_b == null:
		return false

	if not socket_a.can_auto_connect_to(socket_b):
		return false

	if socket_a.global_position.distance_to(socket_b.global_position) > max_distance:
		return false

	if not socket_a.is_facing_socket(socket_b, max_angle_degrees):
		return false

	return true


## Connects two sockets if they are allowed to connect.
static func connect_sockets(socket_a: SnapSocket3D, socket_b: SnapSocket3D) -> bool:
	if socket_a == null or socket_b == null:
		return false

	if not socket_a.can_connect_to(socket_b):
		return false

	socket_a.connect_to_socket(socket_b)
	socket_b.connect_to_socket(socket_a)
	return true


## Disconnects two sockets from each other.
static func disconnect_sockets(socket_a: SnapSocket3D, socket_b: SnapSocket3D) -> void:
	if socket_a != null and socket_a.connected_socket == socket_b:
		socket_a.disconnect_socket()

	if socket_b != null and socket_b.connected_socket == socket_a:
		socket_b.disconnect_socket()


## Attempts to auto-connect all aligned sockets between a placed piece and neighboring pieces.
static func auto_connect_piece_to_neighbors(
		placed_piece: SnapPiece3D,
		neighbor_pieces: Array[SnapPiece3D],
		placement_graph: SnapPlacementGraph = null,
		max_distance: float = DEFAULT_DISTANCE_EPSILON,
		max_angle_degrees: float = DEFAULT_MAX_ANGLE_DEGREES
) -> Array[SnapConnectionData]:
	var created_connections: Array[SnapConnectionData] = []

	if placed_piece == null:
		return created_connections

	for placed_socket: SnapSocket3D in placed_piece.get_auto_connect_open_sockets():
		for neighbor_piece: SnapPiece3D in neighbor_pieces:
			if placed_socket.is_connected:
				break

			if neighbor_piece == null or neighbor_piece == placed_piece:
				continue

			for neighbor_socket: SnapSocket3D in neighbor_piece.get_auto_connect_open_sockets():
				if not can_auto_connect_aligned_sockets(placed_socket, neighbor_socket, max_distance, max_angle_degrees):
					continue

				var did_connect: bool = connect_sockets(placed_socket, neighbor_socket)

				if not did_connect:
					continue

				var connection_data: SnapConnectionData = SnapConnectionData.new(
					placed_piece.get_path(),
					placed_socket.get_path(),
					neighbor_piece.get_path(),
					neighbor_socket.get_path(),
					placed_socket.socket_type,
					placed_socket.connection_group,
					true,
					false
				)

				created_connections.append(connection_data)

				if placement_graph != null:
					placement_graph.add_connection(connection_data)

				break

	return created_connections
