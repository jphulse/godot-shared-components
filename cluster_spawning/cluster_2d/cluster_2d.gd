@abstract class_name Cluster2D
extends Node2D

## Emitted when a cluster expires, useful if the clusters are managed by an external system
signal cluster_expired(cluster: Cluster2D)

@export_group("Scene initialization")
## The scene that will be instantiated by this cluster one or more times.
@export var instance_scene: PackedScene

## The number of instances of the instance_scene that will be used to make the cluster.
@export_range(1, 1024, 1) var instance_count: int = 1

## A resource object given to each clustered scene during setup.
@export var initialization_resource: Resource = null

## The name of the initialization method that will be called with the initialization resource.
@export var initialization_method_name: StringName = &"config"

## Whether initialization should occur before the instance is added to the tree.
## If false, subclasses are responsible for calling _initialize_instance()
## after adding the instance to the scene tree.
@export var initialize_before_adding_to_tree: bool = true

@export_group("Cluster movement")
## The linear velocity that the cluster moves in pixels per second.
@export var cluster_velocity: Vector2 = Vector2.ZERO

## The velocity that this object rotates with in radians per second.
@export var rotation_velocity: float = 0.0

## Whether cluster rotation should rotate the linear velocity direction.
@export var rotation_impacts_linear_velocity: bool = false

## The speed in pixels per second that the spawned instances will spread out if positive or in if negative
@export var cluster_expansion_speed: float = 0.0

@export_group("Cluster lifecycle")
## Whether the cluster structure should be set up in _ready().
@export var spawn_cluster_on_ready: bool = true

## The time before this cluster expires. Values less than or equal to 0 disable expiration.
@export var expiration_time: float = 3.0

## The expiration timer. If unassigned, a child named ExpirationTimer will be used if present.
@export var expiration_timer: Timer

## Whether this cluster uses _physics_process instead of _process.
@export var use_physics_process: bool = false

## Whether the cluster requires setup_structure() to be called before updating.
@export var wait_for_setup_to_update: bool = true

## Whether or not the cluster should be freed on expiring automatically
@export var auto_free_on_expiration: bool = true

## Whether the cluster structure has been set up.
var _setup: bool = false

var spawned_instances: Array[Node2D] = []

func _ready() -> void:
	_ensure_expiration_timer()

	if spawn_cluster_on_ready:
		setup_structure()


func _process(delta: float) -> void:
	if not use_physics_process and _should_update():
		_handle_basic_movement(delta)


func _physics_process(delta: float) -> void:
	if use_physics_process and _should_update():
		_handle_basic_movement(delta)


## Performs the setup for the cluster.
func setup_structure() -> void:
	assert(not _setup, "Cluster2D setup_structure() should not be called more than once.")
	_validate_cluster_settings()
	_setup_cluster()
	_setup = true
	_start_expiration_timer()


## Builds the specific cluster structure.
@abstract func _setup_cluster() -> void


## Updates the cluster's internal structure after basic movement.
func update_cluster(delta: float) -> void:
	if not is_zero_approx(cluster_expansion_speed):
		for instance: Node2D in spawned_instances:
			var direction: Vector2 = (instance.global_position - global_position).normalized()
			instance.global_position += direction * cluster_expansion_speed * delta


## Handles basic linear and rotational movement of the cluster.
func _handle_basic_movement(delta: float) -> void:
	if rotation_impacts_linear_velocity:
		global_position += cluster_velocity.rotated(global_rotation) * delta
	else:
		global_position += cluster_velocity * delta

	global_rotation += rotation_velocity * delta
	update_cluster(delta)


## Instantiates the configured cluster instance scene.
func _instantiate_cluster_instance() -> Node2D:
	assert(instance_scene != null, "ClusterSpawner2D requires an instance_scene.")

	var instance_node: Node = instance_scene.instantiate()
	var instance_2d: Node2D = instance_node as Node2D

	assert(instance_2d != null, "ClusterSpawner2D instance_scene root must extend Node2D.")
	if initialize_before_adding_to_tree:
		_initialize_instance(instance_2d)
	spawned_instances.append(instance_2d)

	return instance_2d


## Initializes a spawned cluster instance if an initialization resource is assigned.
func _initialize_instance(instance: Node) -> void:
	if initialization_resource == null:
		return

	assert(
		instance.has_method(initialization_method_name),
		"Cluster instance does not have initialization method: %s" % initialization_method_name
	)

	instance.call(initialization_method_name, initialization_resource)


## Validates the cluster settings before structure setup.
func _validate_cluster_settings() -> void:
	assert(instance_scene != null, "ClusterSpawner2D requires an instance_scene.")
	assert(instance_count > 0, "ClusterSpawner2D requires instance_count to be greater than 0.")


## Starts the expiration timer if expiration is enabled.
func _start_expiration_timer() -> void:
	if expiration_time <= 0.0:
		return

	if expiration_timer == null:
		return

	expiration_timer.start(expiration_time)


## Frees the cluster on expiration timeout.
func _on_expiration_timer_timeout() -> void:
	cluster_expired.emit(self)
	if auto_free_on_expiration:
		queue_free()


## Whether the update process should run for this cluster.
func _should_update() -> bool:
	return _setup or not wait_for_setup_to_update
	
## Ensures an expiration timer exists if expiration is enabled.
func _ensure_expiration_timer() -> void:
	if expiration_time <= 0.0:
		return

	if expiration_timer == null:
		expiration_timer = get_node_or_null("ExpirationTimer") as Timer

	if expiration_timer == null:
		expiration_timer = Timer.new()
		expiration_timer.name = "ExpirationTimer"
		add_child(expiration_timer)

	expiration_timer.one_shot = true

	if not expiration_timer.timeout.is_connected(_on_expiration_timer_timeout):
		expiration_timer.timeout.connect(_on_expiration_timer_timeout)
