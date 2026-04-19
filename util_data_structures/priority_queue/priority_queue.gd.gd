class_name PriorityQueue 
extends RefCounted


## A generic Variant priority queue implemented as a binary heap
##
## By default, this is a min-priority queue:
## lower priority values are popped first
##
##  usage example:
## var queue := PriorityQueue.new()
## queue.push("low priority", 10)
## queue.push("high priority", 1)
## print(queue.pop()) # "high priority"

enum PriorityMode {
	MIN,
	MAX
}


var _heap : Array[Dictionary] = []
var _mode : PriorityMode = PriorityMode.MIN

var _insertion_counter : int = 0

func _init(mode : PriorityMode = PriorityMode.MIN) -> void:
		_mode = mode

#region Public API
## Returns true if the internal heap array is empty, false otherwise
func is_empty() -> bool:
	return _heap.is_empty()

## Returns the number of elements in the heap
func size() -> int:
	return _heap.size()

## Clears the internal heap
func clear() -> void:
	_heap.clear()
	_insertion_counter = 0

## Pushes the new value to the correct position in the queue, creating a new entry and placing it in the appropriate spot for it's priority
func push(value: Variant, priority: float) -> void:
	var entry := _make_entry(value, priority)

	_heap.append(entry)
	_sift_up(_heap.size() - 1)


## Returns the first value in the priority queue with the highest priority without modifying the heap
func peek(default_value: Variant = null) -> Variant:
	if _heap.is_empty():
		return default_value

	return _heap[0]["value"]

## Returns the priority of the highest priority value in the queue without modifying the heap
func peek_priority(default_value: float = INF) -> float:
	if _heap.is_empty():
		return default_value

	return _heap[0]["priority"]

## Dequeues the highest priority element and returns it
func pop(default_value: Variant = null) -> Variant:
	if _heap.is_empty():
		return default_value

	var root_entry: Dictionary = _heap[0]
	var last_entry: Dictionary = _heap.pop_back()

	if not _heap.is_empty():
		_heap[0] = last_entry
		_sift_down(0)

	return root_entry["value"]

## Gives a look at the entry wityh highest priority, allows for both value and priority to be viewed
func peek_entry() -> Dictionary:
	if _heap.is_empty():
		return {}

	return _heap[0]

## Pops the entry with highest priority from the queue
func pop_entry() -> Dictionary:
	if _heap.is_empty():
		return {}

	var root_entry: Dictionary = _heap[0]
	var last_entry: Dictionary = _heap.pop_back()

	if not _heap.is_empty():
		_heap[0] = last_entry
		_sift_down(0)

	return root_entry


## Returns the heap stored as an array
func to_heap_array() -> Array[Variant]:
	var result: Array[Variant] = []

	for entry: Dictionary in _heap:
		result.append(entry["value"])

	return result


#endregion
#region Private helper methods
## Makes a new entry for the object with priority
func _make_entry(value: Variant, priority: float) -> Dictionary:
	var entry := {
		"value": value,
		"priority": priority,
		"order": _insertion_counter,
	}

	_insertion_counter += 1

	return entry

## The index of the parent node from the given index
func _parent_index(index: int) -> int:
	return (index - 1) / 2

## Moves an element up the heap until it is in the correct spot
func _sift_up(index: int) -> void:
	var current_index := index

	while current_index > 0:
		var parent_index := _parent_index(current_index)

		if _has_higher_priority(_heap[current_index], _heap[parent_index]):
			_swap(current_index, parent_index)
			current_index = parent_index
		else:
			break
## Moves an element down the heap
func _sift_down(index: int) -> void:
	var current_index := index

	while true:
		var left_index := _left_child_index(current_index)
		var right_index := _right_child_index(current_index)
		var best_index := current_index

		if left_index < _heap.size() and _has_higher_priority(_heap[left_index], _heap[best_index]):
			best_index = left_index

		if right_index < _heap.size() and _has_higher_priority(_heap[right_index], _heap[best_index]):
			best_index = right_index

		if best_index == current_index:
			break

		_swap(current_index, best_index)
		current_index = best_index

## Returns true if a has higher priority than b, is impacted by which mode the queue is in
func _has_higher_priority(a: Dictionary, b: Dictionary) -> bool:
	var a_priority: float = a["priority"]
	var b_priority: float = b["priority"]

	if a_priority == b_priority:
		return a["order"] < b["order"]

	if _mode == PriorityMode.MIN:
		return a_priority < b_priority
	else:
		return a_priority > b_priority

## Swaps indexes a and b in the _heap array
func _swap(a: int, b: int) -> void:
	var temp: Dictionary = _heap[a]
	_heap[a] = _heap[b]
	_heap[b] = temp

## Gets the index of the left child from index
func _left_child_index(index: int) -> int:
	return index * 2 + 1

## Gets the index of the right child from index
func _right_child_index(index: int) -> int:
	return index * 2 + 2
#endregion
