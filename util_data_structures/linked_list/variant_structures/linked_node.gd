class_name ListLink extends RefCounted

var data : Variant = null
var next : ListLink = null
var prev : ListLink = null

func _init(src_data : Variant) -> void:
	data = src_data
