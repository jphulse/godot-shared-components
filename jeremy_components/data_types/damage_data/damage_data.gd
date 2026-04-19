class_name DamageData
extends RefCounted

## The total amount of damage that should be done based on this source
var amount: float = 0.0
## The source node the damage came from, if null the source is hidden or unset
var source: Node = null
## How much knockback should occur, should be done based on source info/state
var knockback: Vector2 = Vector2.ZERO
## The damage type, "physical", "fire", etc. Uses stringNames, can be ignored if the game doesn't
## need damage types
var damage_type: StringName = &"physical"


func _init(_amount : float = 0.0,
			_source : Node = null,
			_knockback : Vector2 = Vector2.ZERO,
			_damage_type : StringName = &"physical"
) -> void:
	amount = _amount
	source = _source
	knockback = _knockback
	damage_type = _damage_type
