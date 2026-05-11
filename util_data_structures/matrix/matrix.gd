## General-purpose matrix utility for gameplay/tool algorithms and advanced math
class_name Matrix
extends RefCounted

## Really small number used for determining if something is zero or close to it
const EPSILON : float = .0000001

var _rows : int = 1
var _cols : int = 1
var _matrix : Array[Array] = []
#region engine methods
func _init(rows : int, cols : int, initial_value : float = 0) -> void:
	assert(rows > 0 and cols > 0, "Tried to make a matrix with invalid rows and cols")
	_cols = cols
	_rows = rows
	for i in range(rows): 
		_matrix.append([])
		for j in range(cols):
			_matrix[i].append(initial_value)

func _to_string() -> String:
	return str(_matrix)
#endregion
#region public API
## Gets a copy of the internal array
func get_matrix_copy() -> Array[Array]:
	return _matrix.duplicate_deep()

## Sets the value at [row,col] in the matrix
func set_value(row : int, col : int, value : float) -> void:
	assert(row >= 0 and row < _rows, "Invalid row")
	assert(col >= 0 and col < _cols, "Invalid col")
	_matrix[row][col] = value

## Gets the value at index [row,col] in the matrix
func get_value(row: int, col: int) -> float:
	assert(row >= 0 and row < _rows, "Invalid row")
	assert(col >= 0 and col < _cols, "Invalid col")
	return _matrix[row][col]

## Gets the number of rows in this matrix
func get_row_count() -> int:
	return _rows

## Gets the number of cols in this matrix
func get_col_count() -> int:
	return _cols

## Returns whether or not the matrix is a square (if rows and cols are equal)
func is_square() -> bool:
	return _rows == _cols

## Adds other to self, if modify_self if true it will modify this instance
## otherwise a new instance will be created to store the result
func add(other : Matrix, modify_self : bool = false) -> Matrix:
	assert(_rows == other._rows and _cols == other._cols)
	var result : Matrix = self if modify_self else Matrix.new(_rows, _cols)
	for i in range(_rows):
		for j in range(_cols):
			result._matrix[i][j] = _matrix[i][j] + other._matrix[i][j]
	return result

## Subtracts other from self, if modify_self is true then it will subtract
## from that instance, otherwise will make a new instance
func subtract(other : Matrix, modify_self : bool = false) -> Matrix:
	assert(_rows == other._rows and _cols == other._cols)
	var result : Matrix = self if modify_self else Matrix.new(_rows, _cols)
	for i in range(_rows):
		for j in range(_cols):
			result._matrix[i][j] = _matrix[i][j] - other._matrix[i][j]
	return result

## Multiplies all values in the matrix by the scalar, if modify_self is true
## self will hold the changes otherwise it will be a new instance
func scalar_multiply(scalar : float, modify_self : bool = false) -> Matrix:
	var result : Matrix = self if modify_self else Matrix.new(_rows, _cols)
	for i in range(_rows):
		for j in range(_cols):
			result._matrix[i][j] = _matrix[i][j] * scalar
	return result

## Does scalar multiplication with -1
func negate(modify_self : bool = false) -> Matrix:
	return scalar_multiply(-1, modify_self)

## Multiplies the two matrix objects returning the results
func multiply(other : Matrix) -> Matrix:
	assert(_cols == other._rows, " Tried to multiply two incompatable Matrix objects")
	var result : Matrix = Matrix.new(_rows, other._cols)
	for i : int in range(_rows):
		for j : int in range(other._cols):
			var sum : float = 0.0
			
			for k : int in range(_cols):
				sum += _matrix[i][k] * other._matrix[k][j]
			result._matrix[i][j] = sum
	return result
	

## Returns the transpose of this matrix.
func transpose(modify_self : bool = false) -> Matrix:
	var result : Matrix = Matrix.new(_cols, _rows)

	for i : int in range(_rows):
		for j : int in range(_cols):
			result._matrix[j][i] = _matrix[i][j]

	if modify_self:
		_rows = result._rows
		_cols = result._cols
		_matrix = result._matrix
		return self

	return result



## Returns the determinant of this matrix.
func determinant() -> float:
	assert(is_square(), "Cannot calculate determinant of a non-square matrix")

	var working : Array[Array] = get_matrix_copy()
	var determinant_value : float = 1.0

	for pivot_index : int in range(_rows):
		var pivot_row : int = pivot_index
		var largest_abs_value : float = absf(working[pivot_index][pivot_index])

		for row : int in range(pivot_index + 1, _rows):
			var test_abs_value : float = absf(working[row][pivot_index])

			if test_abs_value > largest_abs_value:
				largest_abs_value = test_abs_value
				pivot_row = row

		if _is_nearly_zero(largest_abs_value):
			return 0.0

		if pivot_row != pivot_index:
			_swap_rows(working, pivot_index, pivot_row)
			determinant_value *= -1.0

		var pivot_value : float = working[pivot_index][pivot_index]
		determinant_value *= pivot_value

		for row : int in range(pivot_index + 1, _rows):
			var factor : float = working[row][pivot_index] / pivot_value

			for col : int in range(pivot_index + 1, _cols):
				working[row][col] -= factor * working[pivot_index][col]

			working[row][pivot_index] = 0.0

	return determinant_value


## Returns the inverse of this matrix.
func inverse(modify_self : bool = false) -> Matrix:
	assert(is_square(), "Cannot invert a non-square matrix")

	var left : Array[Array] = get_matrix_copy()
	var right : Array[Array] = _make_identity_array(_rows)

	for pivot_index : int in range(_rows):
		var pivot_row : int = pivot_index
		var largest_abs_value : float = absf(left[pivot_index][pivot_index])

		for row : int in range(pivot_index + 1, _rows):
			var test_abs_value : float = absf(left[row][pivot_index])

			if test_abs_value > largest_abs_value:
				largest_abs_value = test_abs_value
				pivot_row = row

		assert(not _is_nearly_zero(largest_abs_value), "Cannot invert a singular matrix")

		if pivot_row != pivot_index:
			_swap_rows(left, pivot_index, pivot_row)
			_swap_rows(right, pivot_index, pivot_row)

		var pivot_value : float = left[pivot_index][pivot_index]

		for col : int in range(_cols):
			left[pivot_index][col] /= pivot_value
			right[pivot_index][col] /= pivot_value

		for row : int in range(_rows):
			if row == pivot_index:
				continue

			var factor : float = left[row][pivot_index]

			if _is_nearly_zero(factor):
				continue

			for col : int in range(_cols):
				left[row][col] -= factor * left[pivot_index][col]
				right[row][col] -= factor * right[pivot_index][col]

	var result : Matrix = Matrix.new(_rows, _cols)

	for i : int in range(_rows):
		for j : int in range(_cols):
			result._matrix[i][j] = right[i][j]

	if modify_self:
		_matrix = result._matrix
		return self

	return result

## Swaps two rows in this matrix.
func swap_rows(row_a : int, row_b : int) -> void:
	assert(row_a >= 0 and row_a < _rows, "Invalid first row")
	assert(row_b >= 0 and row_b < _rows, "Invalid second row")

	if row_a == row_b:
		return

	var temp : Array = _matrix[row_a]
	_matrix[row_a] = _matrix[row_b]
	_matrix[row_b] = temp


## Swaps two columns in this matrix.
func swap_cols(col_a : int, col_b : int) -> void:
	assert(col_a >= 0 and col_a < _cols, "Invalid first column")
	assert(col_b >= 0 and col_b < _cols, "Invalid second column")

	if col_a == col_b:
		return

	for row : int in range(_rows):
		var temp : float = _matrix[row][col_a]
		_matrix[row][col_a] = _matrix[row][col_b]
		_matrix[row][col_b] = temp

## Returns a copy of this matrix with two rows swapped.
func with_swapped_rows(row_a : int, row_b : int) -> Matrix:
	var result : Matrix = duplicate_matrix()
	result.swap_rows(row_a, row_b)
	return result


## Returns a copy of this matrix with two columns swapped.
func with_swapped_cols(col_a : int, col_b : int) -> Matrix:
	var result : Matrix = duplicate_matrix()
	result.swap_cols(col_a, col_b)
	return result

## Returns a deep Matrix copy of this matrix.
func duplicate_matrix() -> Matrix:
	var result : Matrix = Matrix.new(_rows, _cols)

	for i : int in range(_rows):
		for j : int in range(_cols):
			result._matrix[i][j] = _matrix[i][j]

	return result

## Returns true if every value in this matrix is nearly zero.
func is_zero() -> bool:
	for i : int in range(_rows):
		for j : int in range(_cols):
			if not _is_nearly_zero(_matrix[i][j]):
				return false

	return true


## Returns the sum of the main diagonal.
func trace() -> float:
	assert(is_square(), "Cannot calculate trace of a non-square matrix")

	var result : float = 0.0

	for i : int in range(_rows):
		result += _matrix[i][i]

	return result


## Returns this matrix in row echelon form.
func row_echelon(modify_self : bool = false) -> Matrix:
	var result : Matrix = self if modify_self else duplicate_matrix()

	var pivot_row : int = 0

	for pivot_col : int in range(result._cols):
		if pivot_row >= result._rows:
			break

		var best_row : int = pivot_row
		var best_abs_value : float = absf(result._matrix[pivot_row][pivot_col])

		for row : int in range(pivot_row + 1, result._rows):
			var test_abs_value : float = absf(result._matrix[row][pivot_col])

			if test_abs_value > best_abs_value:
				best_abs_value = test_abs_value
				best_row = row

		if result._is_nearly_zero(best_abs_value):
			continue

		result.swap_rows(pivot_row, best_row)

		var pivot_value : float = result._matrix[pivot_row][pivot_col]

		for row : int in range(pivot_row + 1, result._rows):
			var factor : float = result._matrix[row][pivot_col] / pivot_value

			if result._is_nearly_zero(factor):
				continue

			for col : int in range(pivot_col, result._cols):
				result._matrix[row][col] -= factor * result._matrix[pivot_row][col]

			result._matrix[row][pivot_col] = 0.0

		pivot_row += 1

	result._clean_nearly_zero_values()
	return result


## Returns this matrix in reduced row echelon form.
func reduced_row_echelon(modify_self : bool = false) -> Matrix:
	var result : Matrix = self if modify_self else duplicate_matrix()

	var pivot_row : int = 0

	for pivot_col : int in range(result._cols):
		if pivot_row >= result._rows:
			break

		var best_row : int = pivot_row
		var best_abs_value : float = absf(result._matrix[pivot_row][pivot_col])

		for row : int in range(pivot_row + 1, result._rows):
			var test_abs_value : float = absf(result._matrix[row][pivot_col])

			if test_abs_value > best_abs_value:
				best_abs_value = test_abs_value
				best_row = row

		if result._is_nearly_zero(best_abs_value):
			continue

		result.swap_rows(pivot_row, best_row)

		var pivot_value : float = result._matrix[pivot_row][pivot_col]

		for col : int in range(pivot_col, result._cols):
			result._matrix[pivot_row][col] /= pivot_value

		for row : int in range(result._rows):
			if row == pivot_row:
				continue

			var factor : float = result._matrix[row][pivot_col]

			if result._is_nearly_zero(factor):
				continue

			for col : int in range(pivot_col, result._cols):
				result._matrix[row][col] -= factor * result._matrix[pivot_row][col]

			result._matrix[row][pivot_col] = 0.0

		pivot_row += 1

	result._clean_nearly_zero_values()
	return result


## Returns the rank of this matrix.
func rank() -> int:
	var echelon_form : Matrix = row_echelon(false)
	var result : int = 0

	for row : int in range(echelon_form._rows):
		var has_non_zero_value : bool = false

		for col : int in range(echelon_form._cols):
			if not echelon_form._is_nearly_zero(echelon_form._matrix[row][col]):
				has_non_zero_value = true
				break

		if has_non_zero_value:
			result += 1

	return result


## Attempts to solve the linear system represented by this coefficient matrix and a constants matrix.
## Returns null if the system has no unique solution.
func try_solve_linear_system(constants : Matrix, warn_on_failure : bool = true) -> Matrix:
	if _rows != constants._rows:
		if warn_on_failure:
			push_warning("Coefficient matrix row count must match constants row count")
		return null

	var augmented : Matrix = Matrix.new(_rows, _cols + constants._cols)

	for row : int in range(_rows):
		for col : int in range(_cols):
			augmented.set_value(row, col, _matrix[row][col])

		for col : int in range(constants._cols):
			augmented.set_value(row, _cols + col, constants._matrix[row][col])

	var reduced : Matrix = augmented.reduced_row_echelon(false)

	for row : int in range(reduced._rows):
		var coefficient_row_is_zero : bool = true

		for col : int in range(_cols):
			if not reduced._is_nearly_zero(reduced._matrix[row][col]):
				coefficient_row_is_zero = false
				break

		if coefficient_row_is_zero:
			for col : int in range(constants._cols):
				if not reduced._is_nearly_zero(reduced._matrix[row][_cols + col]):
					if warn_on_failure:
						push_warning("Linear system has no solution")
					return null

	var pivot_count : int = 0

	for row : int in range(reduced._rows):
		for col : int in range(_cols):
			if _is_pivot_position(reduced, row, col):
				pivot_count += 1
				break

	if pivot_count != _cols:
		if warn_on_failure:
			push_warning("Linear system does not have a unique solution")
		return null

	var result : Matrix = Matrix.new(_cols, constants._cols)

	for variable_index : int in range(_cols):
		var pivot_row : int = -1

		for row : int in range(reduced._rows):
			if _is_pivot_position(reduced, row, variable_index):
				pivot_row = row
				break

		if pivot_row == -1:
			if warn_on_failure:
				push_warning("Could not find pivot row for variable")
			return null

		for col : int in range(constants._cols):
			result.set_value(variable_index, col, reduced._matrix[pivot_row][_cols + col])

	return result

## Solves the linear system and asserts if the system cannot be solved uniquely.
func solve_linear_system(constants : Matrix) -> Matrix:
	var result : Matrix = try_solve_linear_system(constants)

	assert(result != null, "Linear system could not be solved uniquely")

	return result

## Returns a new identity matrix of the given size.
static func identity(size : int) -> Matrix:
	assert(size > 0, "Cannot create an identity matrix with invalid size")

	var result : Matrix = Matrix.new(size, size)

	for i : int in range(size):
		result._matrix[i][i] = 1.0

	return result

## Creates a Matrix from a rectangular nested array of numeric values.
static func from_array(values : Array[Array]) -> Matrix:
	assert(values.size() > 0, "Cannot create a Matrix from an empty array")

	var first_row : Array = values[0]
	assert(first_row.size() > 0, "Cannot create a Matrix with zero columns")

	var row_count : int = values.size()
	var col_count : int = first_row.size()
	var result : Matrix = Matrix.new(row_count, col_count)

	for row : int in range(row_count):
		var row_array : Array = values[row]
		assert(row_array.size() == col_count, "Every Matrix source row must have the same number of columns")

		for col : int in range(col_count):
			var cell_value : Variant = row_array[col]
			var cell_type : int = typeof(cell_value)

			assert(
				cell_type == TYPE_FLOAT or cell_type == TYPE_INT,
				"Every Matrix source value must be numeric"
			)

			result.set_value(row, col, float(cell_value))

	return result

#endregion
## Returns true if the given value is close enough to zero.
func _is_nearly_zero(value : float) -> bool:
	return absf(value) <= EPSILON


## Swaps two rows in a raw matrix array.
func _swap_rows(matrix_array : Array[Array], row_a : int, row_b : int) -> void:
	var temp : Array = matrix_array[row_a]
	matrix_array[row_a] = matrix_array[row_b]
	matrix_array[row_b] = temp


## Creates a raw identity matrix array of the given size.
func _make_identity_array(size : int) -> Array[Array]:
	var result : Array[Array] = []

	for i : int in range(size):
		result.append([])

		for j : int in range(size):
			if i == j:
				result[i].append(1.0)
			else:
				result[i].append(0.0)

	return result
	
## Returns true if the given row and column contain a pivot value in a reduced row echelon matrix.
func _is_pivot_position(matrix : Matrix, row : int, col : int) -> bool:
	if not matrix._is_nearly_zero(matrix._matrix[row][col] - 1.0):
		return false

	for test_row : int in range(matrix._rows):
		if test_row == row:
			continue

		if not matrix._is_nearly_zero(matrix._matrix[test_row][col]):
			return false

	for test_col : int in range(col):
		if not matrix._is_nearly_zero(matrix._matrix[row][test_col]):
			return false

	return true


## Replaces very small floating point values with exact zero.
func _clean_nearly_zero_values() -> void:
	for row : int in range(_rows):
		for col : int in range(_cols):
			if _is_nearly_zero(_matrix[row][col]):
				_matrix[row][col] = 0.0
