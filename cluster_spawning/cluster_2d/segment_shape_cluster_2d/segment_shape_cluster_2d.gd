class_name SegmentShapeCluster2D
extends Cluster2D

## The SegmentShape2D resource that defines the local line segment used by this cluster.
@export var segment_shape: SegmentShape2D

## Whether spawned instances should rotate to face along the segment direction.
@export var rotate_instances_along_segment: bool = true

## An additional rotation offset applied to each spawned instance.
@export var instance_rotation_offset: float = 0.0


## Builds a segment cluster by placing instances evenly along the SegmentShape2D.
func _setup_cluster() -> void:
	var start_point: Vector2 = segment_shape.a
	var end_point: Vector2 = segment_shape.b
	var segment_direction: Vector2 = end_point - start_point
	var segment_angle: float = segment_direction.angle()

	for index: int in range(instance_count):
		var weight: float = _get_segment_weight(index)

		var instance_2d: Node2D = _instantiate_cluster_instance()
		instance_2d.position = start_point.lerp(end_point, weight)

		if rotate_instances_along_segment:
			instance_2d.rotation = segment_angle + instance_rotation_offset

		_add_instance_to_cluster(instance_2d)


## Gets the interpolation weight for an instance index along the segment.
func _get_segment_weight(index: int) -> float:
	if instance_count <= 1:
		return 0.5

	return float(index) / float(instance_count - 1)


## Adds an instance to this cluster and performs post-tree initialization if needed.
func _add_instance_to_cluster(instance_2d: Node2D) -> void:
	add_child(instance_2d)

	if not initialize_before_adding_to_tree:
		_initialize_instance(instance_2d)


## Validates segment cluster settings before setup.
func _validate_cluster_settings() -> void:
	super._validate_cluster_settings()

	assert(
		segment_shape != null,
		"SegmentShapeCluster2D requires a SegmentShape2D."
	)

	assert(
		segment_shape.a != segment_shape.b or instance_count == 1,
		"SegmentShapeCluster2D requires different segment endpoints when instance_count is greater than 1."
	)
