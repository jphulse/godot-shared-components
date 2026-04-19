class_name HealthComponent
extends Node

@export var max_health: float = 100
var current_health: float

signal died
signal damaged(amount: float)

func _ready() -> void:
	current_health = max_health

## Called when this object takes damage
func damage(amount: float) -> void:
	current_health -= amount
	damaged.emit(amount)

	if current_health <= 0:
		died.emit()
