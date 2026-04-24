class_name HitboxComponent3D extends Area3D

## Emitted by the hitbox when we hit a hurtbox
signal hurtbox_hit(hurtbox : HurtboxComponent3D)

## The shape used in the collision component
@export var shape : Shape3D = null:
	set(val):
		shape = val
		if val != null and is_node_ready():
			collision_shape.shape = val

## Determines whether or not we will guard against duplicate hits without a manual reset
@export var prevent_duplicate_hits: bool = true

## Determines whether or not this hitbox will be monitoring after _ready executes with no
## extra code needed
@export var start_monitoring : bool = false

## The collision shape linked to this area
@onready var collision_shape : CollisionShape3D = $CollisionShape2D

## These items have already been hit by this hitbox, prevents duplicate hits if unwanted
var _already_hit: Array[HurtboxComponent3D] = []


## Sets the shape to be the exported var if not null
func _ready() -> void:
	if shape != null:
		collision_shape.shape = shape
	monitoring = start_monitoring

## Linked in editor called when areas is entered, if hurtbox emit the hit signal
func _on_area_entered(area: Area3D) -> void:
	if area is HurtboxComponent3D and not ( prevent_duplicate_hits and _already_hit.has(area)) :
		hurtbox_hit.emit(area)
		if prevent_duplicate_hits:	
			_already_hit.append(area)
			
## Reset the hurtboxes being protected from duplicate hits, clearing that internal array
func reset_hits() -> void:
	_already_hit.clear()

## Starts the hitbox, makes it monitor and resets hits, basically starting a new attack
func start_hitbox() -> void:
	reset_hits()
	monitoring = true

## stops the hitbox, disabling monitoring, intended for use after the attack ends
func stop_hitbox() -> void:
	monitoring = false
