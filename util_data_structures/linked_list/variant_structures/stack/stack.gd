class_name Stack
extends RefCounted

var _list := LinkedList.new()

## Pushes an element to the top of the stack
func push(val: Variant) -> void:
	assert(val != null)
	_list.push_back(val)

## Pops the element off the top of the stack
func pop() -> Variant:
	return _list.pop_back()

## Returns the element on the top of the stack but does not remove it
func peek() -> Variant:
	return _list.back()

## Returns true if the stack is empty, false otherwise
func is_empty() -> bool:
	return _list.is_empty()

## Returns the number of elements in the stack
func size() -> int:
	return _list.size()

## Resets the stack
func clear() -> void:
	_list.clear()
