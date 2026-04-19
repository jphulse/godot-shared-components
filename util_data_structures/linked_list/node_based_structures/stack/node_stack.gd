class_name NodeStack
extends RefCounted

var _list := NodeLinkedList.new()

## Pushes a node to the top of the stack
func push(node: Node) -> void:
	assert(node != null)
	_list.push_back(node)

## Pops the node off the top of the stack
func pop() -> Node:
	return _list.pop_back()

## Returns the node on the top of the stack but does not remove it
func peek() -> Node:
	return _list.back()

## Returns true if the stack is empty, false otherwise
func is_empty() -> bool:
	return _list.is_empty()

## Returns the number of nodes in the NodeStack
func size() -> int:
	return _list.size()

## Resets the stack
func clear() -> void:
	_list.clear()
