class_name BigNumber
extends RefCounted

const EXPONENT_ADD_CUTOFF: int = 16
static var use_exponent_math_cutoff : bool = false

var mantissa: float = 0.0
var exponent: int = 0


func _init(_mantissa: float = 0.0, _exponent: int = 0) -> void:
	mantissa = _mantissa
	exponent = _exponent
	_normalize()


#region Constructors

static func from_float(value: float) -> BigNumber:
	return BigNumber.new(value, 0)


static func from_int(value: int) -> BigNumber:
	return BigNumber.new(float(value), 0)


static func from_parts(_mantissa: float, _exponent: int) -> BigNumber:
	return BigNumber.new(_mantissa, _exponent)


static func zero() -> BigNumber:
	return BigNumber.new(0.0, 0)


static func one() -> BigNumber:
	return BigNumber.new(1.0, 0)


func duplicate_number() -> BigNumber:
	return BigNumber.new(mantissa, exponent)

#endregion


#region Basic properties

func is_zero() -> bool:
	return mantissa == 0.0


func is_positive() -> bool:
	return mantissa > 0.0


func is_negative() -> bool:
	return mantissa < 0.0


func abs_number() -> BigNumber:
	return BigNumber.new(absf(mantissa), exponent)


func negated() -> BigNumber:
	return BigNumber.new(-mantissa, exponent)

#endregion


#region Math

func add_float(value: float) -> BigNumber:
	return add(BigNumber.from_float(value))


func subtract_float(value: float) -> BigNumber:
	return subtract(BigNumber.from_float(value))

func add(other: BigNumber) -> BigNumber:
	if is_zero():
		return other.duplicate_number()

	if other.is_zero():
		return duplicate_number()


	if exponent - other.exponent > EXPONENT_ADD_CUTOFF and use_exponent_math_cutoff:
		return duplicate_number()

	if other.exponent - exponent > EXPONENT_ADD_CUTOFF and use_exponent_math_cutoff:
		return other.duplicate_number()

	var result_exponent := max(exponent, other.exponent)

	var adjusted_self := mantissa * pow(10.0, float(exponent - result_exponent))
	var adjusted_other := other.mantissa * pow(10.0, float(other.exponent - result_exponent))

	return BigNumber.new(adjusted_self + adjusted_other, result_exponent)


func subtract(other: BigNumber) -> BigNumber:
	return add(other.negated())

func multiply_float(other : float) -> BigNumber:
	return BigNumber.from_float(other)
	

func multiply(other: BigNumber) -> BigNumber:
	if is_zero() or other.is_zero():
		return BigNumber.zero()

	return BigNumber.new(
		mantissa * other.mantissa,
		exponent + other.exponent
	)


func divide_float(other : float) -> BigNumber:
	return divide(BigNumber.from_float(other))
func divide(other: BigNumber) -> BigNumber:
	assert(not other.is_zero(), "Cannot divide BigNumber by zero.")

	if is_zero():
		return BigNumber.zero()

	return BigNumber.new(
		mantissa / other.mantissa,
		exponent - other.exponent
	)


func multiply_float(value: float) -> BigNumber:
	return multiply(BigNumber.from_float(value))


func divide_float(value: float) -> BigNumber:
	assert(value != 0.0, "Cannot divide BigNumber by zero.")
	return divide(BigNumber.from_float(value))


func pow_float(power: float) -> BigNumber:
	if is_zero():
		return BigNumber.zero()

	# For negative values, fractional powers are not supported in this simple version.
	assert(mantissa > 0.0 or floor(power) == power, "Fractional powers of negative BigNumbers are not supported.")

	var sign := 1.0

	if mantissa < 0.0:
		var int_power := int(power)
		if int_power % 2 != 0:
			sign = -1.0

	var log10_value := _log10(absf(mantissa)) + float(exponent)
	var powered_log := log10_value * power

	var new_exponent := int(floor(powered_log))
	var new_mantissa := sign * pow(10.0, powered_log - float(new_exponent))

	return BigNumber.new(new_mantissa, new_exponent)


func sqrt_number() -> BigNumber:
	assert(mantissa >= 0.0, "Cannot take square root of negative BigNumber.")
	return pow_float(0.5)

#endregion


#region Comparison

func compare_to(other: BigNumber) -> int:
	if is_zero() and other.is_zero():
		return 0

	if mantissa > 0.0 and other.mantissa < 0.0:
		return 1

	if mantissa < 0.0 and other.mantissa > 0.0:
		return -1

	var both_negative := mantissa < 0.0 and other.mantissa < 0.0

	if exponent > other.exponent:
		return -1 if both_negative else 1

	if exponent < other.exponent:
		return 1 if both_negative else -1

	if mantissa > other.mantissa:
		return 1

	if mantissa < other.mantissa:
		return -1

	return 0


func equals(other: BigNumber) -> bool:
	return compare_to(other) == 0


func greater_than(other: BigNumber) -> bool:
	return compare_to(other) > 0


func greater_than_or_equal(other: BigNumber) -> bool:
	return compare_to(other) >= 0


func less_than(other: BigNumber) -> bool:
	return compare_to(other) < 0


func less_than_or_equal(other: BigNumber) -> bool:
	return compare_to(other) <= 0

#endregion


#region Conversion / Printing

func to_float() -> float:
	# This can overflow to INF for very large exponents.
	return mantissa * pow(10.0, float(exponent))


func to_scientific_string(decimal_places: int = 2) -> String:
	if is_zero():
		return "0"

	var format := "%." + str(decimal_places) + "f"
	return format % mantissa + "e" + str(exponent)


func to_short_string(decimal_places: int = 2) -> String:
	if is_zero():
		return "0"

	if exponent >= 0 and exponent < 3:
		var value := to_float()
		var format_small := "%." + str(decimal_places) + "f"
		return _trim_trailing_zeroes(format_small % value)

	if exponent < 0:
		return to_scientific_string(decimal_places)

	var suffixes := [
		"",
		"K",
		"M",
		"B",
		"T",
		"Qa",
		"Qi",
		"Sx",
		"Sp",
		"Oc",
		"No",
		"Dc"
	]

	var suffix_index := int(exponent / 3)

	if suffix_index > 0 and suffix_index < suffixes.size():
		var display_exponent := exponent % 3
		var display_value := mantissa * pow(10.0, float(display_exponent))

		var format_suffix := "%." + str(decimal_places) + "f"
		return _trim_trailing_zeroes(format_suffix % display_value) + suffixes[suffix_index]

	return to_scientific_string(decimal_places)
func _to_string() -> String:
	return to_short_string()

#endregion


#region Internal helpers
func _log10(val : float) -> float:
	return log(val) / log(10)

func _normalize() -> void:
	if mantissa == 0.0:
		exponent = 0
		return

	var sign := 1.0

	if mantissa < 0.0:
		sign = -1.0
		mantissa = absf(mantissa)
	
	var exponent_shift := int(floor(_log10(mantissa)))

	mantissa = mantissa / pow(10.0, float(exponent_shift))
	exponent += exponent_shift

	# Floating-point safety cleanup.
	if mantissa >= 10.0:
		mantissa /= 10.0
		exponent += 1
	elif mantissa < 1.0:
		mantissa *= 10.0
		exponent -= 1

	mantissa *= sign


func _trim_trailing_zeroes(text: String) -> String:
	if not text.contains("."):
		return text

	while text.ends_with("0"):
		text = text.substr(0, text.length() - 1)

	if text.ends_with("."):
		text = text.substr(0, text.length() - 1)

	return text

#endregion
