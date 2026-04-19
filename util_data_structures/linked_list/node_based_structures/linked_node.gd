class_name LinkedNode extends RefCounted

var node : Node = null
var next : LinkedNode = null
var prev : LinkedNode = null

func _init(src_node : Node) -> void:
	node = src_node
