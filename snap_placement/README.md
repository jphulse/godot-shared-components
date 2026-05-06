# Snap Placement

`Snap Placement` is a reusable socket-based placement system for Godot 4.6+.

It lets modular scene pieces connect through authored sockets. This is useful for rooms, corridors, roads, pipes, rails, platformer chunks, puzzle pieces, caves, buildings, or any other scene-based modular content where pieces need to snap together cleanly.

Instead of assuming a tile grid, each piece defines one or more connection points. These connection points are called sockets. A placement utility can then align one piece's socket to another socket, optionally connect them, and record that connection in a graph.

This system supports both 2D and 3D.

## Version Support

This plugin targets **Godot 4.6 and newer**.

Older Godot versions are not officially supported.

## Folder Structure

Location:
```text
res://addons/jeremy_components/snap_placement/
├── shared/
│   ├── snap_connection_data.gd
│   └── snap_placement_graph.gd
├── 2d/
│   ├── snap_socket_2d.gd
│   ├── snap_piece_2d.gd
│   └── snap_placement_utility_2d.gd
└── 3d/
    ├── snap_socket_3d.gd
    ├── snap_piece_3d.gd
    └── snap_placement_utility_3d.gd
```

## Core Concepts

### Snap Piece

A snap piece is a modular scene chunk.

Examples:

```text
Room
Corridor
PipeSegment
RoadSegment
BridgePiece
PlatformerChunk
PuzzlePiece
```

In 3D, a snap piece uses `SnapPiece3D`.

In 2D, a snap piece uses `SnapPiece2D`.

The piece is responsible for collecting its child sockets.

### Snap Socket

A snap socket is a connection point on a piece.

Sockets define:

```text
where another piece can attach
which direction the socket faces
what type/category of socket it is
whether it can auto-connect
whether it is already connected
```

In 3D, sockets use `SnapSocket3D`.

In 2D, sockets use `SnapSocket2D`.



### Snap Placement Utility

The placement utility performs the transform math.

It can:

```text
snap one piece's socket to another socket
connect two sockets
check if two sockets are aligned
auto-connect nearby aligned sockets
```

Use `SnapPlacementUtility3D` for 3D and `SnapPlacementUtility2D` for 2D.

### Snap Placement Graph

`SnapPlacementGraph` records connections between sockets.

This is useful when you want to track the logical structure of a level, dungeon, room graph, pipe network, road system, or modular layout.

## 3D Scene Setup

A typical 3D modular room scene should look like this:

```text
Room_A.tscn
├── Room_ARoot                  SnapPiece3D
│   ├── Geometry                Node3D / MeshInstance3D / imported meshes
│   ├── Collision               StaticBody3D / CollisionShape3D
│   ├── NavigationRegion3D      Optional
│   └── Sockets                 Node3D
│       ├── NorthDoor           SnapSocket3D
│       ├── SouthDoor           SnapSocket3D
│       └── EastDoor            SnapSocket3D
```

The root node should have the `SnapPiece3D` script attached.

The `Sockets` node should contain any `SnapSocket3D` children.

By default, `SnapPiece3D` looks for sockets under a child named:

```text
Sockets
```

You can change this with:

```gdscript
@export var sockets_root_path: NodePath = ^"Sockets"
```

## 3D Socket Direction Convention

For `SnapSocket3D`, the socket's outward-facing direction is local **-Z**.

This matches Godot's common 3D forward direction convention.

For a door socket, point the socket's local -Z direction out through the doorway.

Example:

```text
Room interior
    |
    | socket local -Z points outward through the door
    v
Doorway exit
```

When two sockets connect, they should face opposite directions.

## 3D Socket Inspector Setup

For a standard room door socket:

```text
socket_id: north_door
socket_type: standard_door
accepted_socket_types: []
allow_auto_connect: true
is_connected: false
connection_group: rooms
```

If `accepted_socket_types` is empty, the socket only accepts sockets with the same `socket_type`.

So this socket:

```text
socket_type: standard_door
accepted_socket_types: []
```

can connect to another socket with:

```text
socket_type: standard_door
```

If you want a socket to accept a different type, use `accepted_socket_types`.

Example:

```text
socket_type: locked_door
accepted_socket_types:
    standard_door
    boss_door
```

This socket can connect to `standard_door` or `boss_door`, but the other socket must also accept `locked_door`.

Compatibility is checked from both sides.

## 3D Example: Manual Placement Script

This script shows how to instance two modular pieces and snap one socket to another.

Scene setup:

```text
SnapPlacementExample3D.tscn
├── SnapPlacementExample3D      Node3D
└── Level                       Node3D
```

Attach this script to the root `Node3D`.

```gdscript
class_name SnapPlacementExample3D
extends Node3D

## Parent node that placed pieces will be added under.
@export var level_root: Node3D = null

## First modular piece scene.
@export var first_piece_scene: PackedScene = null

## Second modular piece scene.
@export var second_piece_scene: PackedScene = null

## Stores logical connections between sockets.
var placement_graph: SnapPlacementGraph = SnapPlacementGraph.new()


## Creates two pieces and snaps the second piece to the first.
func _ready() -> void:
	if level_root == null:
		push_error("SnapPlacementExample3D requires a level_root.")
		return

	if first_piece_scene == null or second_piece_scene == null:
		push_error("SnapPlacementExample3D requires both piece scenes.")
		return

	var first_piece: SnapPiece3D = first_piece_scene.instantiate() as SnapPiece3D
	var second_piece: SnapPiece3D = second_piece_scene.instantiate() as SnapPiece3D

	if first_piece == null or second_piece == null:
		push_error("Both scenes must have SnapPiece3D as their root script.")
		return

	level_root.add_child(first_piece)
	level_root.add_child(second_piece)

	first_piece.global_position = Vector3.ZERO
	second_piece.global_position = Vector3(20.0, 0.0, 20.0)

	first_piece.refresh_sockets()
	second_piece.refresh_sockets()

	var target_socket: SnapSocket3D = first_piece.get_socket_by_id(&"north_door")
	var placed_socket: SnapSocket3D = second_piece.get_socket_by_id(&"south_door")

	if target_socket == null or placed_socket == null:
		push_error("Could not find required sockets.")
		return

	var did_connect: bool = SnapPlacementUtility3D.snap_and_connect_piece_socket_to_target_socket(
		second_piece,
		placed_socket,
		target_socket
	)

	if not did_connect:
		push_error("Failed to snap and connect sockets.")
		return

	var connection_data: SnapConnectionData = placement_graph.add_socket_connection(
		first_piece,
		target_socket,
		second_piece,
		placed_socket,
		target_socket.socket_type,
		target_socket.connection_group
	)

	if connection_data == null:
		push_error("Sockets connected physically, but graph connection was not added.")
		return

	print("3D pieces snapped and connected successfully.")
```

## 3D Example: Auto-Connecting Neighboring Pieces

After placing a piece, you can scan nearby existing pieces and automatically connect sockets that are already aligned.

```gdscript
class_name SnapAutoConnectExample3D
extends Node3D

## Parent node containing placed pieces.
@export var level_root: Node3D = null

## Piece that was just placed.
@export var newly_placed_piece: SnapPiece3D = null

## Stores logical connections between sockets.
var placement_graph: SnapPlacementGraph = SnapPlacementGraph.new()


## Attempts to auto-connect the newly placed piece to its neighbors.
func _ready() -> void:
	if level_root == null or newly_placed_piece == null:
		push_error("Auto-connect example requires level_root and newly_placed_piece.")
		return

	var neighbor_pieces: Array[SnapPiece3D] = _get_neighbor_pieces(newly_placed_piece)

	var created_connections: Array[SnapConnectionData] = SnapPlacementUtility3D.auto_connect_piece_to_neighbors(
		newly_placed_piece,
		neighbor_pieces,
		placement_graph
	)

	print("Created 3D auto-connections: ", created_connections.size())


## Returns all SnapPiece3D children under the level root except the given piece.
func _get_neighbor_pieces(excluded_piece: SnapPiece3D) -> Array[SnapPiece3D]:
	var neighbor_pieces: Array[SnapPiece3D] = []

	for child_node: Node in level_root.get_children():
		var snap_piece: SnapPiece3D = child_node as SnapPiece3D

		if snap_piece == null:
			continue

		if snap_piece == excluded_piece:
			continue

		neighbor_pieces.append(snap_piece)

	return neighbor_pieces
```

## 3D Navigation Notes

For ordinary physically adjacent rooms, each room can contain its own `NavigationRegion3D`.

To allow navigation to continue across rooms, the doorway edges of the navigation meshes should line up cleanly.

Recommended room structure:

```text
Room_A.tscn
├── Room_ARoot                  SnapPiece3D
│   ├── Geometry
│   ├── StaticBody3D
│   ├── NavigationRegion3D
│   └── Sockets
│       └── NorthDoor           SnapSocket3D
```

For impossible-space layouts, portal doors, or rooms that appear connected visually but are not physically adjacent, use socket graph data together with `NavigationLink3D` or custom transition logic.

This snap system does not force one navigation strategy. It only provides the socket and placement layer.

## 2D Scene Setup

A typical 2D modular room scene should look like this:

```text
Room_2D.tscn
├── Room2DRoot                  SnapPiece2D
│   ├── TileMapLayer            Optional
│   ├── Sprites                 Optional
│   ├── Collision               StaticBody2D / CollisionShape2D
│   ├── NavigationRegion2D      Optional
│   └── Sockets                 Node2D
│       ├── LeftDoor            SnapSocket2D
│       ├── RightDoor           SnapSocket2D
│       └── LadderUp            SnapSocket2D
```

The root node should have the `SnapPiece2D` script attached.

The `Sockets` node should contain any `SnapSocket2D` children.

## 2D Socket Direction Convention

For `SnapSocket2D`, the socket's outward-facing direction is local **+X**.

That means the socket's local right direction points out of the piece.

Example:

```text
Room interior -> socket +X direction -> doorway exit
```

When two sockets connect, they should face opposite directions.

## 2D and TileMaps

TileMaps and snap sockets solve different problems.

TileMaps are best for grid-based cell placement.

Snap sockets are best for connecting whole scene pieces through authored connection points.

A 2D room can still be built with a `TileMapLayer`, while the room as a whole is positioned using `SnapPiece2D` and `SnapSocket2D`.

## 2D Example: Manual Placement Script

Scene setup:

```text
SnapPlacementExample2D.tscn
├── SnapPlacementExample2D      Node2D
└── Level                       Node2D
```

Attach this script to the root `Node2D`.

```gdscript
class_name SnapPlacementExample2D
extends Node2D

## Parent node that placed pieces will be added under.
@export var level_root: Node2D = null

## First modular piece scene.
@export var first_piece_scene: PackedScene = null

## Second modular piece scene.
@export var second_piece_scene: PackedScene = null

## Stores logical connections between sockets.
var placement_graph: SnapPlacementGraph = SnapPlacementGraph.new()


## Creates two pieces and snaps the second piece to the first.
func _ready() -> void:
	if level_root == null:
		push_error("SnapPlacementExample2D requires a level_root.")
		return

	if first_piece_scene == null or second_piece_scene == null:
		push_error("SnapPlacementExample2D requires both piece scenes.")
		return

	var first_piece: SnapPiece2D = first_piece_scene.instantiate() as SnapPiece2D
	var second_piece: SnapPiece2D = second_piece_scene.instantiate() as SnapPiece2D

	if first_piece == null or second_piece == null:
		push_error("Both scenes must have SnapPiece2D as their root script.")
		return

	level_root.add_child(first_piece)
	level_root.add_child(second_piece)

	first_piece.global_position = Vector2.ZERO
	second_piece.global_position = Vector2(500.0, 300.0)

	first_piece.refresh_sockets()
	second_piece.refresh_sockets()

	var target_socket: SnapSocket2D = first_piece.get_socket_by_id(&"right_door")
	var placed_socket: SnapSocket2D = second_piece.get_socket_by_id(&"left_door")

	if target_socket == null or placed_socket == null:
		push_error("Could not find required sockets.")
		return

	var did_connect: bool = SnapPlacementUtility2D.snap_and_connect_piece_socket_to_target_socket(
		second_piece,
		placed_socket,
		target_socket
	)

	if not did_connect:
		push_error("Failed to snap and connect sockets.")
		return

	var connection_data: SnapConnectionData = placement_graph.add_socket_connection(
		first_piece,
		target_socket,
		second_piece,
		placed_socket,
		target_socket.socket_type,
		target_socket.connection_group
	)

	if connection_data == null:
		push_error("Sockets connected physically, but graph connection was not added.")
		return

	print("2D pieces snapped and connected successfully.")
```

## 2D Example: Auto-Connecting Neighboring Pieces

```gdscript
class_name SnapAutoConnectExample2D
extends Node2D

## Parent node containing placed pieces.
@export var level_root: Node2D = null

## Piece that was just placed.
@export var newly_placed_piece: SnapPiece2D = null

## Stores logical connections between sockets.
var placement_graph: SnapPlacementGraph = SnapPlacementGraph.new()


## Attempts to auto-connect the newly placed piece to its neighbors.
func _ready() -> void:
	if level_root == null or newly_placed_piece == null:
		push_error("Auto-connect example requires level_root and newly_placed_piece.")
		return

	var neighbor_pieces: Array[SnapPiece2D] = _get_neighbor_pieces(newly_placed_piece)

	var created_connections: Array[SnapConnectionData] = SnapPlacementUtility2D.auto_connect_piece_to_neighbors(
		newly_placed_piece,
		neighbor_pieces,
		placement_graph
	)

	print("Created 2D auto-connections: ", created_connections.size())


## Returns all SnapPiece2D children under the level root except the given piece.
func _get_neighbor_pieces(excluded_piece: SnapPiece2D) -> Array[SnapPiece2D]:
	var neighbor_pieces: Array[SnapPiece2D] = []

	for child_node: Node in level_root.get_children():
		var snap_piece: SnapPiece2D = child_node as SnapPiece2D

		if snap_piece == null:
			continue

		if snap_piece == excluded_piece:
			continue

		neighbor_pieces.append(snap_piece)

	return neighbor_pieces
```

## Socket Signals

`SnapSocket2D` and `SnapSocket3D` emit signals when they connect or disconnect.

```gdscript
signal socket_connected(self_socket: SnapSocket3D, other_socket: SnapSocket3D)
signal socket_disconnected(self_socket: SnapSocket3D, other_socket: SnapSocket3D)
```

For 2D sockets, the signal uses `SnapSocket2D` instead.

Each socket emits its own signal. When two sockets connect, both sockets emit `socket_connected`.

Example:

```gdscript
func _ready() -> void:
	socket_connected.connect(_on_socket_connected)
	socket_disconnected.connect(_on_socket_disconnected)


func _on_socket_connected(self_socket: SnapSocket3D, other_socket: SnapSocket3D) -> void:
	print(self_socket.name, " connected to ", other_socket.name)


func _on_socket_disconnected(self_socket: SnapSocket3D, other_socket: SnapSocket3D) -> void:
	print(self_socket.name, " disconnected from ", other_socket.name)
```

These signals are useful for optional side effects such as:

```text
debug visuals
navigation link configuration
door state changes
sound effects
custom connection metadata
editor/runtime placement UI
game-specific connection behavior
```

## Socket Compatibility Rules

Two sockets can connect when all of these are true:

```text
neither socket is null
the sockets are not the same socket
neither socket is already connected
both sockets have the same connection_group
socket A accepts socket B's socket_type
socket B accepts socket A's socket_type
```

Automatic connection also requires:

```text
socket A allow_auto_connect is true
socket B allow_auto_connect is true
the sockets are close enough
the sockets face opposite directions within the angle tolerance
```

## Socket Type Examples

### Same Type Only

```text
Socket A:
    socket_type: standard_door
    accepted_socket_types: []

Socket B:
    socket_type: standard_door
    accepted_socket_types: []
```

These can connect.

### Different Types Rejected By Default

```text
Socket A:
    socket_type: standard_door
    accepted_socket_types: []

Socket B:
    socket_type: locked_door
    accepted_socket_types: []
```

These cannot connect.

### Different Types Accepted Explicitly

```text
Socket A:
    socket_type: standard_door
    accepted_socket_types:
        locked_door

Socket B:
    socket_type: locked_door
    accepted_socket_types:
        standard_door
```

These can connect because both sockets accept the other socket's type.

## Connection Groups

`connection_group` prevents unrelated socket systems from connecting.

Examples:

```text
rooms
pipes
roads
rails
wires
ladders
```

A room door socket should not accidentally connect to a pipe socket, even if the socket types are similar.

Example:

```text
Socket A:
	socket_type: standard
	connection_group: rooms

Socket B:
	socket_type: standard
	connection_group: pipes
```

These cannot connect because their groups differ.

## Manual Connection vs Auto Connection

Manual connection uses:

```gdscript
socket_a.can_connect_to(socket_b)
```

Auto connection uses:

```gdscript
socket_a.can_auto_connect_to(socket_b)
```

The difference is that auto connection respects `allow_auto_connect`.

This allows some sockets to be connectable by explicit code but ignored by automatic placement scans.

Example use cases:

```text
secret doors
boss exits
one-time scripted transitions
locked connections
designer-only sockets
debug sockets
```

## Common Workflow

A good workflow for modular level construction is:

```text
1. Create a reusable scene piece.
2. Attach SnapPiece2D or SnapPiece3D to the root.
3. Add a child node named Sockets.
4. Add SnapSocket2D or SnapSocket3D children under Sockets.
5. Set each socket_id.
6. Set socket_type and connection_group.
7. Point each socket outward.
8. Use a placement utility to snap one piece to another.
9. Store the connection in a SnapPlacementGraph if you need logical tracking.
```

## Runtime Placement Flow

A runtime placer or editor helper can be built on top of this system.

Typical flow:

```text
1. User selects a piece scene.
2. Tool instances the piece.
3. Tool shows a ghost preview.
4. User chooses a socket on the new piece.
5. User chooses a target socket in the existing layout.
6. Tool calls snap_piece_socket_to_target_socket().
7. Tool validates overlap, rules, or navigation.
8. Tool calls connect_sockets().
9. Tool records the connection in SnapPlacementGraph.
10. Tool optionally calls auto_connect_piece_to_neighbors().
```

## Procedural Placement Flow

A procedural generator can use the same system.

Typical flow:

```text
1. Keep a list of open sockets.
2. Pick an open target socket.
3. Pick a compatible piece scene.
4. Pick a compatible socket on the new piece.
5. Instance the new piece.
6. Snap the new piece socket to the target socket.
7. Check for overlap or rule violations.
8. Connect the sockets if placement is valid.
9. Add the connection to SnapPlacementGraph.
10. Add the new piece's remaining open sockets to the open socket list.
```



## Recommended Naming

For room-based games:

```text
north_door
south_door
east_door
west_door
stairs_up
stairs_down
secret_wall
```

For pipe-based games:

```text
pipe_left
pipe_right
pipe_input
pipe_output
junction_a
junction_b
```

For roads:

```text
road_north
road_south
road_east
road_west
intersection_entry
intersection_exit
```

Use names that describe the socket's role within the piece.

## Best Practices

Keep socket directions consistent.

For 3D:

```text
local -Z points outward
```

For 2D:

```text
local +X points outward
```

Use `connection_group` to separate unrelated systems.

Use `socket_type` for compatibility categories.

Use `accepted_socket_types` only when a socket should accept types other than its own.

Keep socket IDs unique within a piece.

Use `SnapPlacementGraph` when you need to reason about the layout after placement.

Do not rely on socket placement alone for collision validation. A placer or generator should still check for piece overlap when needed.

## What This System Does Not Do

This system does not automatically provide:

```text
collision overlap rejection
full editor UI
room selection UI
procedural generation scoring
navigation baking
pathfinding behavior
portal teleport behavior
save/load of complete generated levels
```

Those systems can be built on top of this one.

The purpose of Snap Placement is to provide the reusable foundation:

```text
sockets
pieces
snapping
connection checks
auto-connection
connection graph data
```
