class_name ConvexPolygonShapeCluster2D
extends Cluster2D

## The ConvexPolygonShape2D resource whose points define the custom closed polygon.
@export var polygon_shape: ConvexPolygonShape2D

## Whether spawned instances should rotate to face along the polygon edge they are placed on.
@export var rotate_instances_along_edges: bool = true

## An additional rotation offset applied to each spawned instance.
@export var instance_rotation_offset: float = 0.0

## The minimum edge length used when calculating polygon placement.
@export var minimum_edge_length: float = 0.001


## Builds a custom closed polygon cluster by placing instances evenly along the polygon shape perimeter.
func _setup_cluster() -> void:
	var points: PackedVector2Array = polygon_shape.points
	var perimeter: float = _calculate_closed_polygon_perimeter(points)

	for index: int in range(instance_count):
		var distance_on_perimeter: float = perimeter * float(index) / float(instance_count)
		var sample_transform: Transform2D = _sample_closed_polygon(points, distance_on_perimeter)

		var instance_2d: Node2D = _instantiate_cluster_instance()
		instance_2d.position = sample_transform.origin

		if rotate_instances_along_edges:
			instance_2d.rotation = sample_transform.get_rotation() + instance_rotation_offset

		_add_instance_to_cluster(instance_2d)


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


## Validates custom polygon shape cluster settings before setup.
func _validate_cluster_settings() -> void:
	super._validate_cluster_settings()

	assert(
		polygon_shape != null,
		"ConvexPolygonShapeCluster2D requires a ConvexPolygonShape2D."
	)

	assert(
		polygon_shape.points.size() >= 3,
		"ConvexPolygonShapeCluster2D requires the ConvexPolygonShape2D to have at least 3 points."
	)

	assert(
		minimum_edge_length > 0.0,
		"ConvexPolygonShapeCluster2D requires minimum_edge_length to be greater than 0."
	)

	assert(
		_calculate_closed_polygon_perimeter(polygon_shape.points) > minimum_edge_length,
		"ConvexPolygonShapeCluster2D requires at least one valid polygon edge."
	)
