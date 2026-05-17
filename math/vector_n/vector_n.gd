class_name VectorN
extends RefCounted

var _vector : Array[float] = []

## The dimensions of this vector, gets the size of the array
var dimensions : int:
	get:
		return _vector.size()

## Initializes a vector to be an n size array of floats with the set default value
func _init(n : int, default_value : float = 0.0) -> void:
	assert(n > 0)
	for i : int in range(n):
		_vector.append(default_value)

## Gets the value of the vector at the index
func get_value(idx : int) -> float:
	assert(idx >= 0 and idx < dimensions, "Invalid idx in VectorN")
	return _vector[idx]

## Sets the vallue of the vector at the index to value
func set_value(idx : int, value : float) -> void:
	assert(idx >= 0 and idx < dimensions, "Invalid idx in VectorN")
	_vector[idx] = value

## Duplicates and returns the array representation of the vector
func as_array() -> Array[float]:
	return _vector.duplicate()

## Adds another vector to this
func add(other : VectorN, modify_self : bool = false) -> VectorN:
	assert(_can_perform_math_operations(other))
	var result : VectorN = self if modify_self else VectorN.new(dimensions)
	for i : int in range(dimensions):
		result.set_value(i, _vector[i] + other._vector[i])
	return result

## Subtracts another vector from this
func subtract(other : VectorN, modify_self : bool = false) -> VectorN:
	assert(_can_perform_math_operations(other))
	var result : VectorN = self if modify_self else VectorN.new(dimensions)
	for i : int in range(dimensions):
		result.set_value(i, _vector[i] - other._vector[i])
	return result

## Multiplies this vector by a scalar
func scalar_multiply(scalar : float, modify_self : bool = false) -> VectorN:
	var result : VectorN = self if modify_self else VectorN.new(dimensions)
	for i : int in range(dimensions):
		result.set_value(i, _vector[i] * scalar)
	return result
	
## Negates this vector, same as multiplying by -1
func negate(modify_self : bool = false) -> VectorN:
	return scalar_multiply(-1.0, modify_self)

## Gets the unit vector in the same direction as this vector
func unit_vector(modify_self : bool = false) -> VectorN:
	if is_approx_zero_vector():
		push_warning("Tried to get unit vector for a zero vector")
		return null
	return scalar_multiply(1.0 / magnitude(), modify_self)

## Turns this into a unit vector in the same direction
func to_unit_vector() -> VectorN:
	return unit_vector(true)

## Normalizes this vector
func normalize() -> VectorN:
	return to_unit_vector()

## Returns a unit vector in the same direction as this one
func normalized() -> VectorN:
	return unit_vector(false)

## Returns the dot product of this and another VectorN of the same size
func dot_product(other : VectorN) -> float:
	assert(_can_perform_math_operations(other))
	var result : float = 0.0
	for i : int in range(dimensions):
		result += _vector[i] * other._vector[i]
	return result

## Returns the magnitude ||V||
func magnitude() -> float:
	var base : float = 0.0
	for i : int in range(dimensions):
		base += _vector[i] * _vector[i]
	return sqrt(base)

## Returns the magnitude of this VectorN 
func length() -> float:
	return magnitude()

## Private method determines if these two vectors are suitable for math
func _can_perform_math_operations(other : VectorN) -> bool:
	return other != null and dimensions == other.dimensions

## Returns true if the vector is approx zero, false otherwise
func is_approx_zero_vector() -> bool:
	for i : float in _vector:
		if not is_zero_approx(i):
			return false
	return is_zero_approx(magnitude())

## Returns true if the vector is normalized false if it is not
func is_normalized() -> bool:
	return is_unit_vector()

## Returns true if the magnitude is about equal to 1 or the vector is a unit vector
func is_unit_vector() -> bool:
	return is_equal_approx(magnitude(), 1.0)

## Calculates the cosine similarity between this and another vector
## dot(self, other) / (||self||||other||)
func cosine_similarity(other : VectorN) -> float:
	assert(_can_perform_math_operations(other), "Vectors incompatable for cosine similarity")
	var mag_product : float = magnitude() * other.magnitude()
	if is_zero_approx(mag_product):
		push_warning("Cannot find angle between zero vector")
		return NAN
	return dot_product(other) / mag_product

## Returns the angle between self and other
func angle_to(other : VectorN) -> float:
	var cos_val : float = cosine_similarity(other)
	if is_nan(cos_val):
		return cos_val
	return acos(clampf(cos_val, -1.0, 1.0))

## Returns the size of this vector
func size() -> int:
	return _vector.size()

## Adds the other vector to self in place
func add_in_place(other : VectorN) -> VectorN:
	return add(other, true)

## Subtracts the other vector from self in place
func subtract_in_place(other : VectorN) -> VectorN:
	return subtract(other, true)

## Multiplies this vector by a scalar in place
func scalar_multiply_in_place(scalar : float) -> VectorN:
	return scalar_multiply(scalar, true)

## Creates a VectorN from a made array
static func from_array(vector : Array[float]) -> VectorN:
	assert(not vector.is_empty(), "Cannot create vector from empty array")
	var result : VectorN = VectorN.new(len(vector))
	for i : int in range(result.dimensions):
		result._vector[i] = vector[i]
	return result
