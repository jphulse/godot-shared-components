class_name PolynomialFunction
extends MathFunction

## Internal polynomial representation
var _polynomial : Dictionary[int, float] = {}

## Whether or not we will automatically remove elements when their coefficient is almost zero
var automatically_prune_approx_zero : bool = true

func _init(polynomial : Dictionary[int, float] = {}, auto_prune_zero_terms : bool = true) -> void:
	for key : int in polynomial.keys():
		assert(key >= 0, "The standard polynomialFunction class only supports non-negative exponents")
	_polynomial = polynomial.duplicate()
	automatically_prune_approx_zero = auto_prune_zero_terms
	if auto_prune_zero_terms:
		prune_zero_terms()
	
func evaluate(x : float) -> float:
	var ret_val : float = 0.0
	for key : int in _polynomial.keys():
		ret_val += pow(x, key) * _polynomial.get(key, 0.0)
	return ret_val


## Always true for polynomial functions
func is_defined(x : float) -> bool:
	return true

## Adds a value to the polynomial
func add_value(coefficient : float, exponent : int, modify_self : bool = true) -> PolynomialFunction:
	assert(exponent >= 0)
	var ret_val : PolynomialFunction = PolynomialFunction.new(_polynomial, automatically_prune_approx_zero) if not modify_self else self
	ret_val._polynomial[exponent] = coefficient + ret_val._polynomial.get(exponent, 0.0)
	if ret_val.automatically_prune_approx_zero and is_zero_approx(ret_val._polynomial[exponent]):
		ret_val._polynomial.erase(exponent)
	return ret_val

## Adds another polynomial with self
func add_polynomial(other : PolynomialFunction, modify_self: bool = true) -> PolynomialFunction:
	var ret_val : PolynomialFunction = PolynomialFunction.new(_polynomial, automatically_prune_approx_zero) if not modify_self else self
	for key : int in other._polynomial.keys():
		ret_val._polynomial[key] = other._polynomial[key] + ret_val._polynomial.get(key, 0.0)
		if ret_val.automatically_prune_approx_zero and is_zero_approx(ret_val._polynomial[key]):
			ret_val._polynomial.erase(key)
	return ret_val

## Multiplies this polynomial by a scalar
func scalar_multiply(scalar : float, modify_self :  bool = true) -> PolynomialFunction:
	var ret_val : PolynomialFunction = PolynomialFunction.new(_polynomial, automatically_prune_approx_zero) if not modify_self else self
	for key : int in ret_val._polynomial.keys():
		ret_val._polynomial[key] = ret_val._polynomial[key] * scalar
	if ret_val.automatically_prune_approx_zero:
		ret_val.prune_zero_terms()
	return ret_val

## Returns the exact derivative of self
func get_exact_derivative() -> MathFunction:
	var ret_val : PolynomialFunction = PolynomialFunction.new()
	for key : int in _polynomial.keys():
		if key != 0:
			ret_val._polynomial[key - 1] = _polynomial.get(key, 0.0) * key
	return ret_val

## Gets an integral from left_bound to right_bound
func get_exact_finite_integral(left_bound : float, right_bound : float) -> float:
	
	var integral : PolynomialFunction = PolynomialFunction.new()
	
	for key : int in _polynomial.keys():
		integral._polynomial[key + 1] = _polynomial.get(key, 0.0) / float(key + 1)
	return integral.evaluate(right_bound) - integral.evaluate(left_bound)

## Gets an integral using FTC, since this is easy enough to compute on standard
## polynomials we ignore the approximation technique flag and compute exact
func get_approximate_integral(left_bound : float, right_bound: float, 
_method : IntegralApproximationTechnique = IntegralApproximationTechnique.RIEMANN_MID) -> float:
	return get_exact_finite_integral(left_bound, right_bound)

## Prunes out all terms from internal state who are approximately zero
func prune_zero_terms() -> void:
	for key : int in _polynomial.keys():
		if is_zero_approx(_polynomial[key]):
			_polynomial.erase(key)
