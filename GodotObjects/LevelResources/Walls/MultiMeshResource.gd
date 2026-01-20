@tool
extends PathPopulatorResource
class_name MultiMeshResource

## Mesh to instantiate along path.
@export var mesh: Mesh
## Does this model block physical light? For effect light use colliders.
@export var blocksLight: bool = false
## Appleis mesh only to vertices in the path.
@export var applyOnlyToNodes: bool = false
## Distance between instances of this mesh.
@export_range(0.01, 200.0, 0.01) var distanceBetweenPieces = 1.0
## Toggle to make sure the model attaches to and follows the ground floor.
@export var normalAlwaysPointsUp: bool = false
## Snapping points in reference to the path.
enum SnapPoints {CENTER, TOP, TOP_RIGHT, RIGHT, BOTTOM_RIGHT, BOTTOM, BOTTOM_LEFT, LEFT, TOP_LEFT}
## Where to snap in reference to the path.
@export var snapPointToPath: SnapPoints = SnapPoints.CENTER:
	set(value):
		snapPointToPath = value
		if Engine.is_editor_hint(): baseOffset = Vector2(-69, 420)
## Deviation from the path in local coordinates (rotates with the path).
@export_custom(PROPERTY_HINT_RANGE, "-1000.0, 1000.0, 0.01") var offsetFromPath: Vector2 = Vector2.ZERO
## Random deviation from the path per piece in local coordinates (rotates with the path).
@export_custom(PROPERTY_HINT_RANGE, "0.0, 1000.0, 0.01, or_lower") var randomOffset: Vector3 = Vector3.ZERO
## Rotation deviation from the path in local coordinates (rotates with the path).
@export_custom(PROPERTY_HINT_RANGE, "-360.0, 360.0, 1.0, radians_as_degrees") var baseRotation: Vector3 = Vector3.ZERO
## Random rotation deviation from the path per piece in local coordinates (rotates with the path).
@export_custom(PROPERTY_HINT_RANGE, "0.0, 360.0, 1.0, radians_as_degrees, or_lower", ) var randomRotation: Vector3 = Vector3.ZERO
## Storage of calculated offset from path.
@export_storage var baseOffset: Vector2 = Vector2(-69, 420)

## Calculates offsets for current instance in path.
func _get_mesh_offset(instance: int, transform: Transform3D) -> Transform3D:
	var currentSeed = instance * randomSeed
	if baseOffset == Vector2(-69, 420):
		var meshSize = mesh.get_aabb().size
		match snapPointToPath:
			SnapPoints.CENTER:
				baseOffset = Vector2.ZERO
			SnapPoints.TOP:
				baseOffset = Vector2(0.0, meshSize.y / 2.0)
			SnapPoints.TOP_RIGHT:
				baseOffset = Vector2(meshSize.x / 2.0, meshSize.y / 2.0)
			SnapPoints.RIGHT:
				baseOffset = Vector2(meshSize.x / 2.0, 0.0)
			SnapPoints.BOTTOM_RIGHT:
				baseOffset = Vector2(meshSize.x / 2.0, -meshSize.y / 2.0)
			SnapPoints.BOTTOM:
				baseOffset = Vector2(0.0, -meshSize.y / 2.0)
			SnapPoints.BOTTOM_LEFT:
				baseOffset = Vector2(-meshSize.x / 2.0, -meshSize.y / 2.0)
			SnapPoints.LEFT:
				baseOffset = Vector2(-meshSize.x / 2.0, 0.0)
			SnapPoints.TOP_LEFT:
				baseOffset = Vector2(-meshSize.x / 2.0, meshSize.y / 2.0)
	var currentOffset: Vector3 = Vector3(baseOffset.x + offsetFromPath.x, baseOffset.y + offsetFromPath.y, 0.0)
	if randomOffset != Vector3.ZERO:
		for i in range(3):
			if randomOffset[["x", "y", "z"][i]] == 0: continue
			seed(currentSeed + i)
			if randomOffset[["x", "y", "z"][i]] > 0:
				currentOffset[["x", "y", "z"][i]] += randf_range(-randomOffset[["x", "y", "z"][i]], randomOffset[["x", "y", "z"][i]])
			elif randomOffset[["x", "y", "z"][i]] < 0:
				currentOffset[["x", "y", "z"][i]] += randf_range(0, -randomOffset[["x", "y", "z"][i]])
	var currentRotation: Vector3 = baseRotation
	if randomRotation != Vector3.ZERO:
		for i in range(3):
			if randomRotation[["x", "y", "z"][i]] == 0: continue
			seed(currentSeed + i * 2)
			if randomRotation[["x", "y", "z"][i]] > 0:
				currentRotation[["x", "y", "z"][i]] += randf_range(-randomRotation[["x", "y", "z"][i]], randomRotation[["x", "y", "z"][i]])
			elif randomRotation[["x", "y", "z"][i]] < 0:
				currentRotation[["x", "y", "z"][i]] += randf_range(0, -randomRotation[["x", "y", "z"][i]])
	return transform.translated_local(currentOffset).rotated_local(Vector3.RIGHT, currentRotation.x).rotated_local(Vector3.UP, currentRotation.y).rotated_local(Vector3.BACK, currentRotation.z)
