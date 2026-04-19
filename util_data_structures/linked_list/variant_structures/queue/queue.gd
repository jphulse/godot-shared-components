class_name Queue
extends RefCounted

var _list := LinkedList.new()

## Adds to the back of the queue
func enqueue(val: Variant) -> void:
	assert(val != null)
	_list.push_back(val)

## Removes the first element from the queue and returns it
func dequeue() -> Variant:
	return _list.pop_front()

## Peeks at the element at the front of the queue
func peek() -> Variant:
	return _list.front()

## Checks if the list is empty, returns true if size is 0 false otherwise
func is_empty() -> bool:
	return _list.is_empty()

## Returns the number of elements in the queue
func size() -> int:
	return _list.size()

func clear() -> void:
	_list.clear()
