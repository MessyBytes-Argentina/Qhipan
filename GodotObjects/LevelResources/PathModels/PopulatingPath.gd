@tool
extends Path3D
## This node populates the path with a list of meshes. Useful to make fences, detailed paths, ivys, etc.
class_name PathPopulator

## How precisely to follow the path.
const PRECISIONPOINT: float = 0.001
## How long to show collider for.
const COLLIDERTIMER: float = 10

## List of meshes to use for populating the path.
@export var multiMeshResources: Array[PathPopulatorResource] = []
## Updates the path's content.
@export_tool_button("Regenerate", "CSGPolygon3D") var execute: Callable = _update_multimesh
## Separator for collision parameters.
@export_category("Collision Parameters")
## Collision layer for a provided collider
@export_custom(PROPERTY_HINT_LAYERS_3D_PHYSICS, "") var collisionLayer: int = 0
## Collider size that will follow this path
@export var colliderSize: Vector2 = Vector2.ONE
## Collision snapping points in reference to the path.
enum SnapPoints {CENTER, TOP, TOP_RIGHT, RIGHT, BOTTOM_RIGHT, BOTTOM, BOTTOM_LEFT, LEFT, TOP_LEFT}
## Where to snap the collision path in reference to the path.
@export var collisionSnapPointToPath: SnapPoints = SnapPoints.CENTER
## Collider deviation from the path in local coordinates (rotates with the path).
@export_custom(PROPERTY_HINT_RANGE, "-1000.0, 1000.0, 0.01") var collisionOffsetFromPath: Vector2 = Vector2.ZERO
## Show the polygon collider
@export_tool_button("Show Collider", "GuiVisibilityXray") var showCollider: Callable = show_collider

## Called when the node enters the scene tree for the first time.
func _ready():
	if Engine.is_editor_hint(): curve_changed.connect(_update_multimesh)
	_update_multimesh()

## Repopulates the path with the multimeshes.
func _update_multimesh():
	for child in get_children(): 
		if child is CSGPolygon3D or child is MultiMeshInstance3D: child.queue_free()
	var pathLength: float = curve.get_baked_length()
	for multiMeshResource in multiMeshResources:
		var count: int
		var currentDistance: float = 0.0
		var multimesh = MultiMeshInstance3D.new()
		var multimeshInstanceNumber: Dictionary[MultiMeshResource, int] = {}
		multimesh.multimesh = MultiMesh.new()
		multimesh.multimesh.transform_format = MultiMesh.TRANSFORM_3D
		var currentMultimeshResource: MultiMeshResource
		if multiMeshResource is MultiMeshResource:
			currentMultimeshResource = multiMeshResource
			multimesh.multimesh.mesh = multiMeshResource.mesh.duplicate()
			if not multiMeshResource.blocksLight:
				multimesh.layers = 2
			add_child(multimesh)
			if currentMultimeshResource.applyOnlyToNodes:
				count = curve.point_count
				multimesh.multimesh.instance_count = count
				multimeshInstanceNumber[currentMultimeshResource] = 0
				for i in range(0, count):
					if i == count - 1 and not curve.closed:
						currentDistance = pathLength - PRECISIONPOINT
						var lastTransform: Transform3D = _create_transform_distance(currentDistance, currentMultimeshResource.normalAlwaysPointsUp)
						lastTransform.origin = curve.sample_baked(pathLength, true)
						multimesh.multimesh.set_instance_transform(i, currentMultimeshResource._get_mesh_offset(i, lastTransform))
						continue
					elif i > 0:
						currentDistance += curve.get_point_position(i - 1).distance_to(curve.get_point_position(i))
					multimesh.multimesh.set_instance_transform(i, currentMultimeshResource._get_mesh_offset(i, _create_transform_distance(currentDistance, currentMultimeshResource.normalAlwaysPointsUp)))
				continue
			else:
				count = floor(pathLength / currentMultimeshResource.distanceBetweenPieces) + 1.0
				multimesh.multimesh.instance_count = count
				multimeshInstanceNumber[currentMultimeshResource] = 0
		var sequence: Array[MultiMeshResource] = []
		var sequenceMultimesh: Array[MultiMeshInstance3D] = []
		if multiMeshResource is RandomMultimeshResource:
			var weights: Array[MultiMeshResource] = []
			var multimeshReference: Dictionary[MultiMeshResource, MultiMeshInstance3D] = {}
			for key in multiMeshResource.multimeshes:
				var currentMultimeshInstance: MultiMeshInstance3D = multimesh.duplicate()
				currentMultimeshInstance.multimesh = currentMultimeshInstance.multimesh.duplicate()
				currentMultimeshInstance.multimesh.mesh = key.mesh.duplicate()
				multimeshReference[key] = currentMultimeshInstance
				multimeshInstanceNumber[key] = 0
				if not key.blocksLight:
					currentMultimeshInstance.layers = 2
				add_child(currentMultimeshInstance)
				for i in multiMeshResource.multimeshes[key]:
					weights.append(key)
			var i: int = 0
			var currentLength: float = multiMeshResource.offsetStart + (multiMeshResource.offsetEnd if multiMeshResource.useOffsetEnd else 0.0)
			while currentLength < pathLength:
				seed(multiMeshResource.randomSeed + i)
				var currentSelection: MultiMeshResource = weights.pick_random()
				currentLength += currentSelection.distanceBetweenPieces
				sequence.append(currentSelection)
				sequenceMultimesh.append(multimeshReference[currentSelection])
				i += 1
			for key in multimeshReference:
				multimeshReference[key].multimesh.instance_count = sequence.count(key)
			count = i
		for i in range(0, count):
			if len(sequence) > 0:
				currentMultimeshResource = sequence[i]
				multimesh = sequenceMultimesh[i]
			var curveDistance = multiMeshResource.offsetStart + (multiMeshResource.offsetEnd if i == count - 1 and multiMeshResource.useOffsetEnd else 0.0) + currentDistance
			currentDistance += currentMultimeshResource.distanceBetweenPieces
			multimesh.multimesh.set_instance_transform(multimeshInstanceNumber[currentMultimeshResource], currentMultimeshResource._get_mesh_offset(i, _create_transform_distance(curveDistance, currentMultimeshResource.normalAlwaysPointsUp)))
			multimeshInstanceNumber[currentMultimeshResource] += 1
	if collisionLayer > 0:
		_make_polygon()

## Makes collision polygon
func _make_polygon() -> CSGPolygon3D:
	var collisionOffset: Vector2 = collisionOffsetFromPath
	match collisionSnapPointToPath:
		SnapPoints.CENTER:
			collisionOffset += Vector2.ZERO
		SnapPoints.TOP:
			collisionOffset += Vector2(0.0, colliderSize.y / 2.0)
		SnapPoints.TOP_RIGHT:
			collisionOffset += Vector2(colliderSize.x / 2.0, colliderSize.y / 2.0)
		SnapPoints.RIGHT:
			collisionOffset += Vector2(colliderSize.x / 2.0, 0.0)
		SnapPoints.BOTTOM_RIGHT:
			collisionOffset += Vector2(colliderSize.x / 2.0, -colliderSize.y / 2.0)
		SnapPoints.BOTTOM:
			collisionOffset += Vector2(0.0, -colliderSize.y / 2.0)
		SnapPoints.BOTTOM_LEFT:
			collisionOffset += Vector2(-colliderSize.x / 2.0, -colliderSize.y / 2.0)
		SnapPoints.LEFT:
			collisionOffset += Vector2(-colliderSize.x / 2.0, 0.0)
		SnapPoints.TOP_LEFT:
			collisionOffset += Vector2(-colliderSize.x / 2.0, colliderSize.y / 2.0)
	var profile: PackedVector2Array = [colliderSize * Vector2(-0.5, -0.5) + collisionOffset, colliderSize * Vector2(-0.5, 0.5) + collisionOffset, colliderSize * Vector2(0.5, 0.5) + collisionOffset, colliderSize * Vector2(0.5, -0.5) + collisionOffset]
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
	polygon.path_joined = curve.closed
	return polygon

## auxilliary function to create valid points for the meshes to be populated at.
func _create_transform_distance(curveDistance: float, normalUp: bool) -> Transform3D:
	var meshPosition: Vector3 = curve.sample_baked(curveDistance, true)
	var meshBasis: Basis = Basis()
	var up: Vector3 = curve.sample_baked_up_vector(curveDistance, true) if not normalUp else Vector3.UP
	var forward: Vector3 = meshPosition.direction_to(curve.sample_baked(curveDistance + 0.1, true))
	meshBasis.y = up
	meshBasis.x = forward.cross(up).normalized()
	meshBasis.z = -forward
	return Transform3D(meshBasis, meshPosition)

## Shows object cocllider.
func show_collider() -> void:
	if collisionLayer == 0: return
	for child in get_children():
		if child is CSGPolygon3D:
			child.queue_free()
			break
	var polygon: CSGPolygon3D = _make_polygon()
	polygon.layers = 1
	polygon.material = ORMMaterial3D.new()
	polygon.material.albedo_color = Color(Color.PURPLE, 0.5)
	polygon.material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_DEPTH_PRE_PASS
	polygon.owner = get_tree().edited_scene_root
	await get_tree().create_timer(COLLIDERTIMER).timeout
	if polygon: polygon.queue_free()

## Reverts the path points.
func flip_path() -> void:
	var flippedPathPoints: PackedVector3Array = []
	var flippedPathIn: PackedVector3Array = []
	var flippedPathOut: PackedVector3Array = []
	var flippedPathTilts: PackedFloat32Array = []
	for i in range(curve.point_count - 1, -1, -1):
		flippedPathPoints.append(curve.get_point_position(i))
		flippedPathTilts.append(curve.get_point_tilt(i))
		flippedPathIn.append(curve.get_point_out(i))
		flippedPathOut.append(curve.get_point_in(i))
	for i in range(curve.point_count):
		curve.set_point_position(i, flippedPathPoints[i])
		curve.set_point_tilt(i, flippedPathTilts[i])
		curve.set_point_in(i, flippedPathIn[i])
		curve.set_point_out(i, flippedPathOut[i])
	_update_multimesh()
