@tool
extends Camera3D

## Camera that handles tracking player movement.
class_name RailCamera

## Camera modes, for different interactions.
enum CameraModes {FREE, ROTATION_LOCKED, FOLLOW_PLAYER, FIXED, FIXED_FOLLOW_PLAYER}
## Current camera mode.
@export var mode: CameraModes = CameraModes.FREE:
	set(value):
		mode = value
		if Engine.is_editor_hint() and is_node_ready():
			setup_rail()
## Path camera offset.
@export_custom(PROPERTY_HINT_RANGE, "-30.0,30.0,0.01") var pathOffset: Vector3 = Vector3.ZERO:
	set(value):
		pathOffset = value
		if Engine.is_editor_hint() and is_node_ready():
			update_camera_position()
## Rotation to apply on top of free rotations.
@export_custom(PROPERTY_HINT_RANGE, "-180,180,1,radians_as_degrees") var freeBaseRotation: Vector3 = Vector3.ZERO:
	set(value):
		freeBaseRotation = value
		if Engine.is_editor_hint() and is_node_ready() and mode == CameraModes.FREE:
			update_camera_position()
## Base rotation for follow rotations.
@export_custom(PROPERTY_HINT_RANGE, "-180,180,1,radians_as_degrees") var followBaseRotation: Vector3 = Vector3.ZERO:
	set(value):
		followBaseRotation = value
		if Engine.is_editor_hint() and is_node_ready() and mode in [CameraModes.FOLLOW_PLAYER, CameraModes.FIXED_FOLLOW_PLAYER]:
			update_camera_position()
## Rotation limit for follow player rotations.
@export_custom(PROPERTY_HINT_RANGE, "0,180,1,radians_as_degrees") var followRotationLimit: Vector3 = Vector3.ZERO:
	set(value):
		followRotationLimit = value
		if Engine.is_editor_hint() and is_node_ready() and mode in [CameraModes.FOLLOW_PLAYER, CameraModes.FIXED_FOLLOW_PLAYER]:
			update_camera_position()
## Rotation offset for follow player rotations.
@export_custom(PROPERTY_HINT_RANGE, "-180,180,1,radians_as_degrees") var followRotationOffset: Vector3 = Vector3.ZERO:
	set(value):
		followRotationOffset = value
		if Engine.is_editor_hint() and is_node_ready() and mode in [CameraModes.FOLLOW_PLAYER, CameraModes.FIXED_FOLLOW_PLAYER]:
			update_camera_position()
## Leash length. Ffor offsetting the camara in regard to the player position.
@export_range(0.0, 20.0, 0.01) var leashLength: float:
	set(value):
		leashLength = value
		if Engine.is_editor_hint() and is_node_ready():
			update_camera_position()
## Leash axis lock. The influence on each given axis.
@export_custom(PROPERTY_HINT_RANGE, "-1.0,1.0,0.01") var leashAxis: Vector3 = Vector3.ZERO:
	set(value):
		leashAxis = value
		if Engine.is_editor_hint() and is_node_ready():
			update_camera_position()
## Offset to lag behind the player.
@export_range(0.0, 5.0, 0.01) var offsetToStartFollowing: float = 0.2
## How fast to lerp the camera.
@export_range(0.0, 20.0, 0.01) var followSpeed: float = 1
## Current progress, used to lerp along the rail. Exposed for testing the camera.
@export_range(0.0, 1.0, 0.01) var progress: float = 0:
	set(value):
		progress = value
		if Engine.is_editor_hint() and is_node_ready():
			update_camera_position()
@export_tool_button("Reset Leash", "Loop") var resetLeash: Callable = func(): if Engine.is_editor_hint(): currentLeashPosition = global_position

## Reference to the path to follow.
var path: Path3D
## Reference to the path follower.
var pathFollower: PathFollow3D
## Reference to the player.
var player: Player
## The path's curve.
var curve: Curve3D
## The curve's points.
var points: PackedVector3Array
## The length of the segments between points.
var pointLength: float
## The length of the curve.
var curveLength: float = 0
## The current offset of the curve that the camera is settled into.
var currentOffset: float = 0
## The offset position, used for leash operations.
var currentLeashPosition: Vector3
## Leash flag.
var leashSet: bool = false

## Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_to_group("Camera")
	set_cull_mask_value(18, false)
	set_cull_mask_value(19, false)
	setup_rail()
	get_player()
	progress = 0
	update_camera_position()
	freeBaseRotation = Vector3(fmod(freeBaseRotation.x, 4 * PI), fmod(freeBaseRotation.y, 4 * PI), fmod(freeBaseRotation.z, 4 * PI))

## Creates and mans the rail.
func setup_rail() -> void:
	if not path:
		for child in get_children():
			if child is Path3D and child.has_meta("CameraPath"):
				path = child
				break
	if mode in [CameraModes.FIXED, CameraModes.FIXED_FOLLOW_PLAYER]: 
		if path: path.queue_free()
		path = null
		pathFollower = null
		return
	if not path:
		path = Path3D.new()
		path.name = "CameraPath"
		path.top_level = true
		path.set_meta("CameraPath", true)
		add_child(path)
		path.owner = get_tree().edited_scene_root
	pathFollower = PathFollow3D.new()
	path.add_child(pathFollower)

## Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if not current or Engine.is_editor_hint(): return
	get_progress(delta)
	update_camera_position()

## Returns the goal progress for the current frame.
func get_progress(delta: float, forced: bool = false) -> void:
	if Engine.is_editor_hint() or mode in [CameraModes.FIXED, CameraModes.FIXED_FOLLOW_PLAYER]: return
	if not curve:
		curve = path.curve
		points = curve.get_baked_points()
		curveLength = curve.get_baked_length()
		pointLength = curveLength / len(points)
	if curveLength == 0: return
	get_player()
	if not player: return
	var closestOffset: float = curve.get_closest_offset(path.to_local(player.global_position))
	var distance: float = abs(currentOffset - closestOffset) * pointLength
	if distance < offsetToStartFollowing: return
	var targetOffset: float = sign(currentOffset - closestOffset) * offsetToStartFollowing + closestOffset
	var targetProgress: float = clamp(targetOffset / curveLength, 0.0, 1.0)
	progress = lerp(progress, targetProgress, followSpeed * delta) if not forced else targetProgress

## Forces camera update for lerping.
func force_update() -> void:
	get_progress(0, true)
	update_camera_position()

## Updates the camera along the rail.
func update_camera_position() -> void:
	if not currentLeashPosition:
		currentLeashPosition = global_position
	if not pathFollower:
		if mode == CameraModes.FIXED_FOLLOW_PLAYER:
			look_at_player()
	else:
		pathFollower.progress_ratio = progress
		match mode:
			CameraModes.FREE:
				global_transform = pathFollower.global_transform
				rotation += freeBaseRotation
			CameraModes.ROTATION_LOCKED:
				global_position = pathFollower.global_position
			CameraModes.FOLLOW_PLAYER:
				global_position = pathFollower.global_position
				look_at_player()
		if curve: currentOffset = curve.get_closest_offset(path.to_local(global_position))
	if leashLength == 0 or leashAxis == Vector3.ZERO: return
	if mode in [CameraModes.FREE, CameraModes.ROTATION_LOCKED, CameraModes.FOLLOW_PLAYER]: currentLeashPosition = global_position
	var leashDirection: Vector3 = (currentLeashPosition.direction_to(player.global_position) * leashAxis).normalized()
	if not Engine.is_editor_hint() or mode != CameraModes.FIXED_FOLLOW_PLAYER:
		position = currentLeashPosition + leashDirection * leashLength + (pathOffset if mode in [CameraModes.FREE, CameraModes.FOLLOW_PLAYER, CameraModes.ROTATION_LOCKED] else Vector3.ZERO)

## Does look at player with clamps.
func look_at_player() -> void:
	get_player()
	if not player: 
		global_rotation = followBaseRotation
		return
	var previousRotation = rotation
	look_at(player.global_position)
	global_rotation += followRotationOffset
	for axis in ["x", "y", "z"]: clamp_axis(axis, previousRotation[axis])

## Clamps a given axis.
func clamp_axis(axis: String, previousRotation: float) -> void:
	if followRotationLimit[axis] > 0:
		if abs(fmod(rotation[axis], 4 * PI) - followBaseRotation[axis]) > followRotationLimit[axis]:
			rotation[axis] = previousRotation

## Gets the player.
func get_player() -> void:
	if not player: 
		player = get_tree().get_first_node_in_group("Player")
