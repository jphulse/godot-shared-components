class_name LinkedList extends RefCounted

#region Internal fields
var length : int = 0
var head : LinkedNode = null
var tail : LinkedNode = null
var node_dict : Dictionary[Node, Array] = {}
#endregion

#region Private helper methods
func _remove_node(node : LinkedNode, all : bool = true) -> void:
	assert(node != null)
	if node.prev:
		node.prev.next = node.next
	if node.next:
		node.next.prev = node.prev
	if node == head:
		head = head.next
	if node == tail:
		tail = tail.prev 
	length -= 1
	if all:
		node_dict.erase(node.node)
	else:
		node_dict[node.node].erase(node)
		if node_dict[node.node].is_empty():
				node_dict.erase(node.node)
	node.free()
	
func _to_string() -> String:
	var current : LinkedNode = head
	var ret_val : String = "["
	while(current):
		ret_val += current.node.name
		current = current.next
		if current:
			ret_val += " -> "
		if current == head:
			break
	ret_val += "]\n"
	return ret_val

func _add_to_array(node : LinkedNode, arr : Array[Node] = []) -> void:
	arr.append(node.node)
#endregion

#region Public API

## Appends a singular node to the list as a linked list at the back
func append(node: Node) -> void:
	var link : LinkedNode = LinkedNode.new(node)
	if head == null:
		head = link
		tail = link
	else :
		link.next = tail.next # should be null but this supports circular lists
		tail.next = link
		link.prev = tail
		tail = link
	
	if node_dict.has(node) :
		node_dict[node].append(link)
	else:
		node_dict[node] = [link] as Array[LinkedNode]
	#node_dict[node] = link
	length += 1
	

## Appends an array of nodes to the list, duplicates are allowed
func append_array(nodes : Array[Node]) -> void:
	for n: Node in nodes:
		append(n)

## Gets the linked node from either the front or the back
func get_linked_node(from_front : bool = true) -> LinkedNode:
	if from_front:
		return head
	else:
		return tail

## Gets the linked node from a given index Allows for external list manipulation
func get_linked_node_from_index(index : int = 0) ->  LinkedNode:
	if index >= length or index < 0:
		return null
	var current : LinkedNode = head
	var current_index : int = 0
	while(current.next != null and current_index < index):
		current = current.next
		current_index += 1
	return current

## Performs the iterative operation defined by callable on the current linkednode
## note that it is required that loop_body takes a LinkedNode as an argument provided by this loop
## all other args will need to be bound using the bind method or some other machnism on the caller before calling this
## by default moves from the front of the list to the back, can also do back to front
func perform_iterative_operation(loop_body : Callable, from_front : bool = true) -> void:
	var current : LinkedNode = head if from_front else tail
	var idx : int = 0 # Supports circular links
	while(current != null and idx < length):
		loop_body.call(current)
		idx += 1
		current = current.next if from_front else current.prev

## Pops the front of the list
func pop_front() -> Node:
	if length <= 0:
		return null
	if length == 1:
		tail = null
	var link : LinkedNode = head
	if head.next != null:
		head.next.prev = head.prev
	head = head.next
	length -= 1
	var ret_val : Node = link.node
	node_dict[ret_val].erase(link)
	link.free()
	return ret_val

## Pops the back element off of the list
func pop_back() -> Node:
	if length <= 0:
		return null
	if length == 1:
		head = null
	var link : LinkedNode = tail
	if tail.prev != null:
		tail.prev.next = tail.next
	tail = tail.prev
	length -= 1
	var ret_val : Node = link.node
	node_dict[ret_val].erase(link)
	link.free()
	return ret_val

## Peeks at the node at the front of the list
func front() -> Node:
	return head.node if head else null
## Peeks at the node at the back of the list
func back() -> Node:
	return tail.node if tail else null

## removes the node from the provided index, the list is 0 indexed
func remove(idx : int, all : bool = false) -> Node:
	if idx < 0 or idx >= length:
		return null
	if idx == 0:
		return pop_front()
	if idx == length - 1:
		return pop_back()
	var current : LinkedNode = head.next
	var current_idx : int = 1
	
	while(current and current_idx < length):
		if idx == current_idx:
			var ret_val : Node = current.node
			_remove_node(current, all)
			return ret_val
		current = current.next
		current_idx += 1
	return null

## Gets the size of the list
func size() -> int:
	return length

## Removes a given node from the list	
func erase(node : Node, all : bool = true) -> void:
	if node_dict.has(node):
		_remove_node(node_dict[node].front(), all)
		
	

## Makes the list circular linking tail and head
func make_circular() -> void:
	if tail != null and head != null:
		tail.next = head
		head.prev = tail

## Checks if the list is circular
func is_circular() -> bool:
	if tail == null or head == null:
		return false
	return tail.next == head and head.prev == tail

## pushes the node to the back of the list, same as append(node)
func push_back(node : Node) -> void:
	append(node)

## Pushes the node to the front of the list
func push_front(node : Node) -> void:
	if head == null:
		append(node)
		return
	var link : LinkedNode = LinkedNode.new(node)
	link.prev = head.prev
	link.next = head
	head.prev = link
	head = link
	length += 1
	if node_dict.has(node):
		node_dict[node].append(link)
	else:
		node_dict[node] = [link] as Array[LinkedNode]

## Return the list as an array of nodes
func to_array(from_front: bool = true) -> Array[Node]:
	var ret_val : Array[Node] = [] as Array[Node]
	perform_iterative_operation(_add_to_array.bind(ret_val), from_front)
	return ret_val

## Picks a random node
func pick_random() -> Node:
	if is_empty():
		return null
	var idx : int = randi_range(0, length - 1)
	return get_linked_node_from_index(idx).node

## Clears the list
func clear() -> void:
	if is_circular():
		tail.next = null
	while(head):
		_remove_node(head)

## Shuffles the list
func shuffle() -> void:
	var temp : Array[Node] = [] as Array[Node]
	push_error("Not implemented yet")
	clear()
	append_array(temp)
## Returns the count of this node
func count(node : Node) -> int:
	if node_dict.has(node):
		return node_dict[node].size()
	return 0
## Checks if the list is empty
func is_empty() -> bool:
	return length == 0
#endregion
