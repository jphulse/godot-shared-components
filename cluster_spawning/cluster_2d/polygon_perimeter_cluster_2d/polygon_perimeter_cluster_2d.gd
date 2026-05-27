class_name PolygonPerimeterCluster2D
extends Cluster2D

## The number of sides in the regular polygon.
@export_range(3, 128, 1) var side_count: int = 5

## The distance from the center of the cluster to each polygon vertex.
@export var radius: float = 128.0

## The starting angle for the first polygon vertex in radians.
@export var start_angle: float = -PI / 2.0

## Whether spawned instances should rotate to face along the polygon edge they are placed on.
@export var rotate_instances_along_edges: bool = true

## An additional rotation offset applied to each spawned instance.
@export var instance_rotation_offset: float = 0.0

## The minimum edge length used when calculating polygon placement.
@export var minimum_edge_length: float = 0.001


## Builds a regular polygon perimeter cluster by placing instances evenly along the polygon's closed outline.
func _setup_cluster() -> void:
	var vertices: PackedVector2Array = _calculate_vertices()
	var perimeter: float = _calculate_closed_polygon_perimeter(vertices)

	for index: int in range(instance_count):
		var distance_on_perimeter: float = perimeter * float(index) / float(instance_count)
		var sample_transform: Transform2D = _sample_closed_polygon(vertices, distance_on_perimeter)

		var instance_2d: Node2D = _instantiate_cluster_instance()
		instance_2d.position = sample_transform.origin

		if rotate_instances_along_edges:
			instance_2d.rotation = sample_transform.get_rotation() + instance_rotation_offset

		_add_instance_to_cluster(instance_2d)


## Calculates the vertices of the regular polygon in local space.
func _calculate_vertices() -> PackedVector2Array:
	var vertices: PackedVector2Array = PackedVector2Array()

	for index: int in range(side_count):
		var angle: float = start_angle + (TAU * float(index) / float(side_count))
		var vertex: Vector2 = Vector2.RIGHT.rotated(angle) * radius
		vertices.append(vertex)

	return vertices


## Calculates the perimeter of a closed polygon.
func _calculate_closed_polygon_perimeter(points: PackedVector2Array) -> float:
	var perimeter: float = 0.0
	var point_count: int = points.size()

	for index: int in range(point_count):
		var start_point: Vector2 = points[index]
		var end_point: Vector2 = points[(index + 1) % point_count]
		var edge_length: float = start_point.distance_to(end_point)

		if edge_length > minimum_edge_length:
			perimeter += edge_length

	return perimeter


## Samples a position and edge-facing rotation from a closed polygon at the requested perimeter distance.
func _sample_closed_polygon(points: PackedVector2Array, distance_on_perimeter: float) -> Transform2D:
	var remaining_distance: float = distance_on_perimeter
	var point_count: int = points.size()

	for index: int in range(point_count):
		var start_point: Vector2 = points[index]
		var end_point: Vector2 = points[(index + 1) % point_count]
		var edge_vector: Vector2 = end_point - start_point
		var edge_length: float = edge_vector.length()

		if edge_length <= minimum_edge_length:
			continue

		if remaining_distance <= edge_length:
			var edge_weight: float = remaining_distance / edge_length
			var sample_position: Vector2 = start_point.lerp(end_point, edge_weight)
			var sample_rotation: float = edge_vector.angle()

			return Transform2D(sample_rotation, sample_position)

		remaining_distance -= edge_length

	return Transform2D(0.0, points[0])


## Adds an instance to this cluster and performs post-tree initialization if needed.
func _add_instance_to_cluster(instance_2d: Node2D) -> void:
	add_child(instance_2d)

	if not initialize_before_adding_to_tree:
		_initialize_instance(instance_2d)


## Validates regular polygon perimeter cluster settings before setup.
func _validate_cluster_settings() -> void:
	super._validate_cluster_settings()

	assert(
		side_count >= 3,
		"RegularPolygonPerimeterCluster2D requires side_count to be at least 3."
	)

	assert(
		radius > 0.0,
		"RegularPolygonPerimeterCluster2D requires radius to be greater than 0."
	)

	assert(
		minimum_edge_length > 0.0,
		"RegularPolygonPerimeterCluster2D requires minimum_edge_length to be greater than 0."
	)
