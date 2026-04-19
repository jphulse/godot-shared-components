class_name Graph extends RefCounted

var adjacency_list : Dictionary[Node, Array] = {}

## Removes the vertex from the graph completely including other node's adjacency lists
func remove_vertex(vertex : Node) -> void:
	if not adjacency_list.has(vertex):
		return
	adjacency_list.erase(vertex)
	for other : Array in adjacency_list.values():
		other.erase(vertex)

## Called when a node exits the tree, removes it from the graph structure as well
func _on_graph_node_exit(node : Node) -> void:
	remove_vertex(node)

## Adds a vertex to the graph, will create a new list and bind the signal for the tree exit process if not done so already
func add_vertex(object : Node) -> void:
	assert(object != null)
	if not adjacency_list.has(object):
		adjacency_list[object] = [] as Array[Node]
	if not object.tree_exiting.is_connected(_on_graph_node_exit.bind(object)):
		object.tree_exiting.connect(_on_graph_node_exit.bind(object))
	
## Adds an edge between two node, adds the nodes if needed, also by default adds bidirectionally,
## if bidirectional is false the edge will be from v1 -> v2 otherwise will add v1 <-> v2
func add_edge(v1 : Node, v2: Node, bidirectional: bool = true) -> void:
	add_vertex(v1)
	add_vertex(v2)
	
	var l1 : Array = adjacency_list[v1]
	var l2 :Array = adjacency_list[v2]
	
	if not l1.has(v2):
		l1.append(v2)
	if bidirectional and not l2.has(v1):
		l2.append(v1)
	#
## Gets the list of neighbors for a node	
func get_neighbors(vertex : Node) -> Array[Node]:
	return adjacency_list.get(vertex, []) as Array[Node]


## Returns the set of all nodes that are within max_depth of start
func bfs_by_depth(start : Node, max_depth : int) -> Dictionary[int, Array]:
	assert(start != null)
	assert(max_depth >= 0)
	
	var result : Dictionary[int, Array] = {}
	
	if not adjacency_list.has(start):
		return result
	
	var queue : Array[Node] = [start]
	var visited : Dictionary[Node, bool] = {start : true}
	var distance_by_node : Dictionary[Node, int] = {start : 0}
	
	var queue_index : int = 0
	while queue_index < queue.size():
		var current : Node = queue[queue_index]
		var current_distance : int = distance_by_node[current]
		queue_index += 1
		
		if not result.has(current_distance):
			result[current_distance] = [] as Array[Node]
		result[current_distance].append(current)
		if current_distance >= max_depth:
			continue
		
		for neighbor : Node in get_neighbors(current):
			if not is_instance_valid(neighbor) or visited.has(neighbor):
				continue
			visited[neighbor] = true
			distance_by_node[neighbor] = current_distance + 1
			queue.append(neighbor)
				
	return result
	
## Gets the label as a string for a given node
func _get_node_label(node : Node) -> String:
	if node == null:
		return "<null>"
	elif not is_instance_valid(node):
		return "<free>"
	return node.name

## Perge a random vertex from the graph
func remove_random_vertex() -> void:
	assert(adjacency_list.size() >= 1)
	remove_vertex(adjacency_list.keys().pick_random())


func _to_string() -> String:
	var result : String = ""
	
	for node : Node in adjacency_list.keys():
		
		result += "%s   -> [" % _get_node_label(node)
		var first : bool = true
		for neighbor : Node in adjacency_list[node]:
			if not first:
				result += ", %s" % _get_node_label(neighbor)
			else:
				result += "%s" % _get_node_label(neighbor)
				first = false
		result += "]\n"
	return result
