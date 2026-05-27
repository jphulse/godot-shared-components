class_name ClusterShapeFactory2D
extends Object


## Prevents ClusterShapeFactory2D from being instantiated.
func _init() -> void:
	assert(false, "ClusterShapeFactory2D is a static utility class and should not be instantiated.")


## Creates a SegmentShape2D from the provided local-space endpoints.
static func make_segment_shape_2d(start_point: Vector2, end_point: Vector2) -> SegmentShape2D:
	assert(start_point != end_point, "make_segment_shape_2d requires different start and end points.")

	var segment_shape: SegmentShape2D = SegmentShape2D.new()
	segment_shape.a = start_point
	segment_shape.b = end_point

	return segment_shape


## Creates a ConvexPolygonShape2D from the provided local-space points.
static func make_convex_polygon_shape_2d(points: PackedVector2Array) -> ConvexPolygonShape2D:
	assert(points.size() >= 3, "make_convex_polygon_shape_2d requires at least 3 points.")

	var polygon_shape: ConvexPolygonShape2D = ConvexPolygonShape2D.new()
	polygon_shape.points = points

	return polygon_shape


## Creates a ConvexPolygonShape2D from an arbitrary point cloud by generating its convex hull.
static func make_convex_polygon_shape_2d_from_point_cloud(points: PackedVector2Array) -> ConvexPolygonShape2D:
	assert(points.size() >= 3, "make_convex_polygon_shape_2d_from_point_cloud requires at least 3 points.")

	var polygon_shape: ConvexPolygonShape2D = ConvexPolygonShape2D.new()
	polygon_shape.set_point_cloud(points)

	return polygon_shape
