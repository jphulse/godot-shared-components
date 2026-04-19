class_name LinkedList extends RefCounted

#region Internal fields
var length : int = 0
var head : LinkedNode = null
var tail : LinkedNode = null
var node_dict : Dictionary[Node, Array] = {}
#endregion


#region Private helper methods
func _remove_node(link : LinkedNode) -> void:
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

	if node_dict.has(link.node):
		node_dict[link.node].erase(link)

		if node_dict[link.node].is_empty():
			node_dict.erase(link.node)

	link.prev = null
	link.next = null


func _to_string() -> String:
	var current : LinkedNode = head
	var ret_val : String = "["

	while current:
		ret_val += current.node.name
		current = current.next

		if current:
			ret_val += " -> "

	ret_val += "]\n"
	return ret_val


func _add_to_array(link : LinkedNode, arr : Array[Node] = []) -> void:
	arr.append(link.node)
#endregion


#region Public API

## Appends a singular node to the back of the linked list.
func append(node: Node) -> void:
	var link : LinkedNode = LinkedNode.new(node)

	if head == null:
		head = link
		tail = link
	else:
		link.prev = tail
		tail.next = link
		tail = link

	if node_dict.has(node):
		node_dict[node].append(link)
	else:
		node_dict[node] = [link] as Array[LinkedNode]

	length += 1


## Appends an array of nodes to the list. Duplicates are allowed.
func append_array(nodes : Array[Node]) -> void:
	for n: Node in nodes:
		append(n)


## Gets the linked node from either the front or the back.
func get_linked_node(from_front : bool = true) -> LinkedNode:
	return head if from_front else tail


## Gets the linked node from a given index. Allows for external list manipulation.
func get_linked_node_from_index(index : int = 0) -> LinkedNode:
	if index >= length or index < 0:
		return null

	var current : LinkedNode = head
	var current_index : int = 0

	while current != null and current_index < index:
		current = current.next
		current_index += 1

	return current


## Performs the iterative operation defined by callable on the current LinkedNode.
## loop_body must take a LinkedNode as an argument.
## Additional arguments should be bound by the caller.
func perform_iterative_operation(loop_body : Callable, from_front : bool = true) -> void:
	var current : LinkedNode = head if from_front else tail

	while current != null:
		var next_link : LinkedNode = current.next if from_front else current.prev
		loop_body.call(current)
		current = next_link


## Pops the front of the list.
func pop_front() -> Node:
	if length <= 0:
		return null

	var link : LinkedNode = head
	var ret_val : Node = link.node

	head = head.next

	if head:
		head.prev = null
	else:
		tail = null

	length -= 1

	node_dict[ret_val].erase(link)
	if node_dict[ret_val].is_empty():
		node_dict.erase(ret_val)

	link.prev = null
	link.next = null

	return ret_val


## Pops the back element off of the list.
func pop_back() -> Node:
	if length <= 0:
		return null

	var link : LinkedNode = tail
	var ret_val : Node = link.node

	tail = tail.prev

	if tail:
		tail.next = null
	else:
		head = null

	length -= 1

	node_dict[ret_val].erase(link)
	if node_dict[ret_val].is_empty():
		node_dict.erase(ret_val)

	link.prev = null
	link.next = null

	return ret_val


## Peeks at the node at the front of the list.
func front() -> Node:
	return head.node if head else null


## Peeks at the node at the back of the list.
func back() -> Node:
	return tail.node if tail else null


## Removes the node from the provided index. The list is 0-indexed.
func remove(idx : int) -> Node:
	if idx < 0 or idx >= length:
		return null

	if idx == 0:
		return pop_front()

	if idx == length - 1:
		return pop_back()

	var current : LinkedNode = head.next
	var current_idx : int = 1

	while current != null:
		if idx == current_idx:
			var ret_val : Node = current.node
			_remove_node(current)
			return ret_val

		current = current.next
		current_idx += 1

	return null


## Gets the size of the list.
func size() -> int:
	return length


## Removes a given node from the list.
func erase(node : Node, all : bool = true) -> void:
	if not node_dict.has(node):
		return

	if all:
		var links : Array = node_dict[node].duplicate()

		for link : LinkedNode in links:
			_remove_node(link)
	else:
		_remove_node(node_dict[node].front())


## Pushes the node to the back of the list. Same as append(node).
func push_back(node : Node) -> void:
	append(node)


## Pushes the node to the front of the list.
func push_front(node : Node) -> void:
	var link : LinkedNode = LinkedNode.new(node)

	if head == null:
		head = link
		tail = link
	else:
		link.next = head
		head.prev = link
		head = link

	if node_dict.has(node):
		node_dict[node].append(link)
	else:
		node_dict[node] = [link] as Array[LinkedNode]

	length += 1


## Returns the list as an array of nodes.
func to_array(from_front: bool = true) -> Array[Node]:
	var ret_val : Array[Node] = [] as Array[Node]
	perform_iterative_operation(_add_to_array.bind(ret_val), from_front)
	return ret_val


## Picks a random node.
func pick_random() -> Node:
	if is_empty():
		return null

	var idx : int = randi_range(0, length - 1)
	return get_linked_node_from_index(idx).node


## Clears the list.
func clear() -> void:
	while head:
		_remove_node(head)


## Shuffles the list.
func shuffle() -> void:
	var temp : Array[Node] = to_array()
	temp.shuffle()
	clear()
	append_array(temp)


## Returns the count of this node.
func count(node : Node) -> int:
	if node_dict.has(node):
		return node_dict[node].size()

	return 0


## Checks if the list is empty.
func is_empty() -> bool:
	return length == 0

#endregion
