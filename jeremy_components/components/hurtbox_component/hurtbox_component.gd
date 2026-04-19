class_name HurtboxComponent extends Area2D

## Emitted when the hurtbox takes damage
signal hurtbox_damaged(damage : DamageData)

## The shape used in the collision component
@export var shape : Shape2D = null:
	set(val):
		shape = val
		if val != null and is_node_ready():
			collision_shape.shape = val

## The collision shape linked to this area
@onready var collision_shape : CollisionShape2D = $CollisionShape2D

## Sets the shape to be the exported var if not null
func _ready() -> void:
	if shape != null:
		collision_shape.shape = shape


## Applys damage to the hurtbox, logic for attack cooldowns will be handled elsewhere
func apply_damage(damage : DamageData) -> void:
	hurtbox_damaged.emit(damage)
