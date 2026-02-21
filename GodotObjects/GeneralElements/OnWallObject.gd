extends Node3D

## Direction to the wall in local coordinates if this goes against the wall
@export_range(-1, 360, 1, "radians_as_degrees") var localWallDirection: float = 0

## Occlude on camera angles.
var invalidAngles: Array[float] = [1.75, 2.0, 0.25]

## Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if localWallDirection == -1: return
	var appliedRotationToWall: float = global_rotation.y / PI + localWallDirection / PI
	while appliedRotationToWall < 0: appliedRotationToWall += 2.0
	if appliedRotationToWall > 2.0: appliedRotationToWall = fmod(appliedRotationToWall, 2.0)
	for i in range(len(invalidAngles)):
		invalidAngles[i] = abs(snappedf(invalidAngles[i] + appliedRotationToWall, 0.01))
		if invalidAngles[i] > 2.0: invalidAngles[i] = fmod(invalidAngles[i], 2.0)
		if invalidAngles[i] == 2.0: invalidAngles[i] = 0.0
	var player: Player = get_tree().get_first_node_in_group("Player")
	if not player.is_node_ready():
		await player.ready
	if not player.camera_rotating.is_connected(check_camera_angle):
		player.camera_rotating.connect(check_camera_angle)
	check_camera_angle(player.cameraPivot.rotation.y)

## Checks for obstacles.
func check_camera_angle(angle: float) -> void:
	while angle < 0: angle += PI * 2.0
	angle = fmod(angle, PI * 2.0)
	angle = snappedf(angle / PI, 0.01)
	if angle == 2.0: angle = 0.0
	if angle > 2.0: angle = fmod(angle, 2.0)
	if angle in invalidAngles:
		hide()
	else:
		show()
