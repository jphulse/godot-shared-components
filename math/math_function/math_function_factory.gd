class_name MathFunctionFactory
extends Object

func _init() -> void:
	assert(false, "MathFunctionFactory is a static class, and should not be instantiated")

## Makes a linear function in form mx + b
static func make_linear_function(m : float, b : float, auto_prune_zero : bool = true) -> PolynomialFunction:
	return PolynomialFunction.new({1 : m, 0 : b}, auto_prune_zero)

## Makes a quadratic function in form ax^2 + bx + c
static func make_quadratic_function(a : float, b : float, c : float, auto_prune_zero : bool = true) -> PolynomialFunction:
	return PolynomialFunction.new({2 : a, 1 : b, 0 : c}, auto_prune_zero)

## Makes a polynomial function in form ax^3 + bx^2 + cx + d
static func make_cubic_function(a : float, b : float, c : float, d: float, auto_prune_zero : bool = true) -> PolynomialFunction:
	return PolynomialFunction.new({3 : a, 2 : b, 1 : c, 0 : d}, auto_prune_zero)
