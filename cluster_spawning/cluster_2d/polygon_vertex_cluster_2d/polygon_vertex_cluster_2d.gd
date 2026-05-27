class_name PolygonVertexCluster2D
extends Cluster2D

## The radius from the cluster center to each polygon vertex.
@export var radius: float = 64.0

## The starting angle for the first polygon vertex in radians.
@export var start_angle: float = 0.0

## Whether spawned instances should rotate to face away from the polygon center.
@export var rotate_instances_outward: bool = true

## An additional rotation offset applied to each spawned instance.
@export var instance_rotation_offset: float = 0.0


## Builds a regular polygon cluster by placing instances at polygon vertices.
func _setup_cluster() -> void:
	for index: int in range(instance_count):
		var angle: float = start_angle + (TAU * float(index) / float(instance_count))
		var direction: Vector2 = Vector2.RIGHT.rotated(angle)

		var instance_2d: Node2D = _instantiate_cluster_instance()
		instance_2d.position = direction * radius

		if rotate_instances_outward:
			instance_2d.rotation = angle + instance_rotation_offset

		_add_instance_to_cluster(instance_2d)


## Adds an instance to this cluster and performs post-tree initialization if needed.
func _add_instance_to_cluster(instance_2d: Node2D) -> void:
	add_child(instance_2d)

	if not initialize_before_adding_to_tree:
		_initialize_instance(instance_2d)


## Validates polygon cluster settings before setup.
func _validate_cluster_settings() -> void:
	super._validate_cluster_settings()
	assert(radius >= 0.0, "PolygonCluster2D requires radius to be greater than or equal to 0.")
