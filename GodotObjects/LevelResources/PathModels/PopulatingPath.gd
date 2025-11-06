@tool
extends Path3D
class_name PathPopulator

const PRECISIONPOINT: float = 0.001

@export var multiMeshResources: Array[MultiMeshResource] = []
@export_tool_button("Regenerate", "CSGPolygon3D") var execute: Callable = _update_multimesh
@export_custom(PROPERTY_HINT_LAYERS_3D_PHYSICS, "") var collisionLayer: int = 0
@export var colliderSize: Vector2 = Vector2.ONE

# Called when the node enters the scene tree for the first time.
func _ready():
	if Engine.is_editor_hint(): curve_changed.connect(_update_multimesh)
	else: _update_multimesh()

func _update_multimesh():
	for child in get_children(): child.queue_free()
	var pathLength: float = curve.get_baked_length()
	if collisionLayer > 0:
		var halfSize: Vector2 = colliderSize / 2.0
		var profile: PackedVector2Array = [-halfSize, halfSize * Vector2(-1.0, 1.0), halfSize, halfSize * Vector2(1.0, -1.0)]
		var polygon: CSGPolygon3D = CSGPolygon3D.new()
		add_child(polygon)
		polygon.polygon = profile
		polygon.mode = CSGPolygon3D.MODE_PATH
		polygon.path_local = true
		polygon.path_simplify_angle = 1.0
		polygon.use_collision = true
		polygon.collision_layer = collisionLayer
		polygon.collision_mask = 0
		polygon.path_node = "../"
		polygon.layers = 0
	for multiMeshResource in multiMeshResources:
		var multimesh = MultiMeshInstance3D.new()
		multimesh.multimesh = multiMeshResource.multiMesh.duplicate()
		add_child(multimesh)
		if multiMeshResource.applyOnlyToNodes:
			var count = curve.point_count
			multimesh.multimesh.instance_count = count
			var currentDistance: float = 0.0
			for i in range(0, count):
				if i == count - 1:
					currentDistance = pathLength - PRECISIONPOINT
					var lastTransform: Transform3D = _create_transform_distance(currentDistance, multiMeshResource.normalAlwaysPointsUp)
					lastTransform.origin = curve.sample_baked(pathLength, true)
					multimesh.multimesh.set_instance_transform(i, lastTransform)
					continue
				elif i > 0:
					currentDistance += curve.get_point_position(i - 1).distance_to(curve.get_point_position(i))
				multimesh.multimesh.set_instance_transform(i, _create_transform_distance(currentDistance, multiMeshResource.normalAlwaysPointsUp))
		else:
			var count = floor(pathLength / multiMeshResource.distanceBetweenPieces) + 1.0
			multimesh.multimesh.instance_count = count
			for i in range(0, count):
				var curveDistance = multiMeshResource.offsetStart + (multiMeshResource.offsetEnd if i == count - 1 and multiMeshResource.useOffsetEnd else 0.0) + multiMeshResource.distanceBetweenPieces * i
				multimesh.multimesh.set_instance_transform(i, _create_transform_distance(curveDistance, multiMeshResource.normalAlwaysPointsUp))

func _create_transform_distance(curveDistance: float, normalUp: bool) -> Transform3D:
	var meshPosition: Vector3 = curve.sample_baked(curveDistance, true)
	var meshBasis: Basis = Basis()
	var up: Vector3 = curve.sample_baked_up_vector(curveDistance, true) if not normalUp else Vector3.UP
	var forward: Vector3 = meshPosition.direction_to(curve.sample_baked(curveDistance + 0.1, true))
	meshBasis.y = up
	meshBasis.x = forward.cross(up).normalized()
	meshBasis.z = -forward
	return Transform3D(meshBasis, meshPosition)
