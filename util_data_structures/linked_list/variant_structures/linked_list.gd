class_name LinkedList extends RefCounted

#region Internal fields
var length : int = 0
var head : ListLink = null
var tail : ListLink = null
var link_dict : Dictionary[Variant, Array] = {}
#endregion


#region Private helper methods
func _remove_link(link : ListLink) -> void:
	assert(link != null)

	if link.prev:
		link.prev.next = link.next

	if link.next:
		link.next.prev = link.prev

	if link == head:
		head = link.next

	if link == tail:
		tail = link.prev

	length -= 1

	if link_dict.has(link.data):
		link_dict[link.data].erase(link)

		if link_dict[link.data].is_empty():
			link_dict.erase(link.data)

	link.prev = null
	link.next = null


func _to_string() -> String:
	var current : ListLink = head
	var ret_val : String = "["

	while current:
		ret_val += str(current.data)
		current = current.next

		if current:
			ret_val += " -> "

	ret_val += "]\n"
	return ret_val


func _add_to_array(link : ListLink, arr : Array[Variant] = []) -> void:
	arr.append(link.data)
#endregion


#region Public API

## Appends a singular element to the back of the linked list.
func append(value: Variant) -> void:
	var link : ListLink = ListLink.new(value)

	if head == null:
		head = link
		tail = link
	else:
		link.prev = tail
		tail.next = link
		tail = link

	if link_dict.has(value):
		link_dict[value].append(link)
	else:
		link_dict[value] = [link] as Array[ListLink]

	length += 1


## Appends an array of elements to the list. Duplicates are allowed.
func append_array(values : Array[Variant]) -> void:
	for n: Variant in values:
		append(n)


## Gets the linked node from either the front or the back.
func get_link(from_front : bool = true) -> ListLink:
	return head if from_front else tail


## Gets the linked node from a given index. Allows for external list manipulation.
func get_link_from_index(index : int = 0) -> ListLink:
	if index >= length or index < 0:
		return null

	var current : ListLink = head
	var current_index : int = 0

	while current != null and current_index < index:
		current = current.next
		current_index += 1

	return current


## Performs the iterative operation defined by callable on the current ListLink.
## loop_body must take a ListLink as an argument.
## Additional arguments should be bound by the caller.
func perform_iterative_operation(loop_body : Callable, from_front : bool = true) -> void:
	var current : ListLink = head if from_front else tail

	while current != null:
		var next_link : ListLink = current.next if from_front else current.prev
		loop_body.call(current)
		current = next_link


## Pops the front of the list.
func pop_front() -> Variant:
	if length <= 0:
		return null

	var link : ListLink = head
	var ret_val : Variant = link.data

	head = head.next

	if head:
		head.prev = null
	else:
		tail = null

	length -= 1

	link_dict[ret_val].erase(link)
	if link_dict[ret_val].is_empty():
		link_dict.erase(ret_val)

	link.prev = null
	link.next = null

	return ret_val


## Pops the back element off of the list.
func pop_back() -> Variant:
	if length <= 0:
		return null

	var link : ListLink = tail
	var ret_val : Variant = link.data

	tail = tail.prev

	if tail:
		tail.next = null
	else:
		head = null

	length -= 1

	link_dict[ret_val].erase(link)
	if link_dict[ret_val].is_empty():
		link_dict.erase(ret_val)

	link.prev = null
	link.next = null

	return ret_val


## Peeks at the value at the front of the list.
func front() -> Variant:
	return head.data if head else null


## Peeks at the value at the back of the list.
func back() -> Variant:
	return tail.data if tail else null


## Removes the element from the provided index. The list is 0-indexed.
func remove(idx : int) -> Variant:
	if idx < 0 or idx >= length:
		return null

	if idx == 0:
		return pop_front()

	if idx == length - 1:
		return pop_back()

	var current : ListLink = head.next
	var current_idx : int = 1

	while current != null:
		if idx == current_idx:
			var ret_val : Variant = current.data
			_remove_link(current)
			return ret_val

		current = current.next
		current_idx += 1

	return null


## Gets the size of the list.
func size() -> int:
	return length


## Removes a given element from the list.
func erase(value : Variant, all : bool = true) -> void:
	if not link_dict.has(value):
		return

	if all:
		var links : Array = link_dict[value].duplicate()

		for link : ListLink in links:
			_remove_link(link)
	else:
		_remove_link(link_dict[value].front())


## Pushes the value to the back of the list. Same as append(value).
func push_back(value : Variant) -> void:
	append(value)


## Pushes the value to the front of the list.
func push_front(value : Variant) -> void:
	var link : ListLink = ListLink.new(value)

	if head == null:
		head = link
		tail = link
	else:
		link.next = head
		head.prev = link
		head = link

	if link_dict.has(value):
		link_dict[value].append(link)
	else:
		link_dict[value] = [link] as Array[ListLink]

	length += 1


## Returns the list as an array.
func to_array(from_front: bool = true) -> Array[Variant]:
	var ret_val : Array[Variant] = [] as Array[Variant]
	perform_iterative_operation(_add_to_array.bind(ret_val), from_front)
	return ret_val


## Picks a random element.
func pick_random() -> Variant:
	if is_empty():
		return null

	var idx : int = randi_range(0, length - 1)
	return get_link_from_index(idx).data


## Clears the list.
func clear() -> void:
	while head:
		_remove_link(head)


## Shuffles the list.
func shuffle() -> void:
	var temp : Array[Variant] = to_array()
	temp.shuffle()
	clear()
	append_array(temp)


## Returns the count of this element.
func count(value : Variant) -> int:
	if link_dict.has(value):
		return link_dict[value].size()

	return 0


## Checks if the list is empty.
func is_empty() -> bool:
	return length == 0

## Removes the link from the list safely
func remove_link(link: ListLink) -> Variant:
	if link == null:
		return null

	var ret_val: Variant = link.data
	_remove_link(link)
	return ret_val

## Returns true if the list has the value, false otherwise
func contains(value: Variant) -> bool:
	return link_dict.has(value)

#endregion
