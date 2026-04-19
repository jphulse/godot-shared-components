class_name NodeQueue
extends RefCounted

var _list := NodeLinkedList.new()

## Adds to the back of the queue
func enqueue(node: Node) -> void:
	assert(node != null)
	_list.push_back(node)

## Removes the first element from the queue and returns it
func dequeue() -> Node:
	return _list.pop_front()

## Peeks at the element at the front of the queue
func peek() -> Node:
	return _list.front()

## Checks if the list is empty, returns true if size is 0 false otherwise
func is_empty() -> bool:
	return _list.is_empty()

## Returns the number of nodes in the queue
func size() -> int:
	return _list.size()

func clear() -> void:
	_list.clear()
