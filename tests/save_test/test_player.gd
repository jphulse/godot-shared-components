extends Node2D


@export var health: int = 100
@export var gold: int = 0


func _get_save_state() -> Dictionary:
	return {
		"position": position,
		"health": health,
		"gold": gold,
	}


func _apply_save_state(state: Dictionary) -> void:
	if state.has("position"):
		position = state["position"]

	if state.has("health"):
		health = state["health"]

	if state.has("gold"):
		gold = state["gold"]
