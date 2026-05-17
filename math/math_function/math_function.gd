@abstract class_name MathFunction
extends RefCounted

## enum defining various integral approximation techniques
enum IntegralApproximationTechnique {
	## Using left endpoint rectangle Riemann sums
	RIEMANN_LEFT,
	## Using right endpoint rectangle Riemann sums
	RIEMANN_RIGHT,
	## Using midpoint rectangle Riemann sums (default technique)
	RIEMANN_MID
}

## Required abstract method, evaluates the function f(x) at x
@abstract func evaluate(x : float) -> float

## Required abstract method, evaluates to true if the function is defined at x, false otherwise
@abstract func is_defined(x : float) -> bool

## Gets the exact derivate of this function, returns a new copy
func get_exact_derivative() -> MathFunction:
	push_warning("get_exact_derivative must be implemented in child classes of Math Function")
	return null

## Gets the approximate derivative at the given point
func get_approximate_derivative(x : float, epsilon : float = .00001) -> float:
	assert( not is_zero_approx(2 * epsilon), "Epsilon cannot be zero for the default ")
	if not(is_defined(x - epsilon) and is_defined(x) and is_defined(x + epsilon)):
		push_warning("Function is not defined at x, x - epsilon, or x + epsilon")
		return NAN
	return (evaluate(x + epsilon) - evaluate(x - epsilon)) / (2 * epsilon)

## Approximates the integral from left_bound to right_bound using the specified method
func get_approximate_integral(left_bound : float, right_bound: float, 
		method : IntegralApproximationTechnique = IntegralApproximationTechnique.RIEMANN_MID) -> float:
	push_warning("get_approximate_integral should be overidden in child classes for use")
	return NAN

## Solves the equation f(x)=y for x, returns an array of solutions
func solve(y : float) -> Array[float]:
	push_warning("solve must be overidden in child clases for use")
	return []
