extends Path3D
class_name PlatformRail

## Moving platform reference to link with remote transform
@export var platformReference: MovingPlatform
## Platform speed
@export_range(0.1, 5, 0.05) var speed: float = 1
## Platform speed when called
@export_range(0.1, 20, 0.05) var returnSpeed: float = 5
## Wait time to start moving after being blocked
@export_range(0.1, 10, 0.05) var blockedTime: float = 3

## Path follower reference for movement
@onready var pathFollower: PathFollow3D = %PathFollower
## Remote transform reference to link the moving platform movement
@onready var remoteTransform3d: RemoteTransform3D = %RemoteTransform3D
## Return timer reference used when the path is blocked
@onready var returnTimer: Timer = %ReturnTimer

## Current direction target (0 = start / 1 = end)
var currentDirection: float = 1
## Tween used for movement
var moveTween: Tween
## Flag that turns true when called
var wasCalled: bool = false
## Curve length
var curveLength: float
## Was the platform last going to the start position or end position.
var goingToEnd: bool = true

## Executed when node first enters the scene tree
func _ready() -> void:
	pathFollower.loop = false
	remoteTransform3d.remote_path = platformReference.get_path()
	returnTimer.connect("timeout",return_to_origin)
	returnTimer.wait_time = blockedTime
	curveLength = curve.get_baked_length()

## Starts the move tween, tweening the progress ratio to the given value
func start_tween(direction: float) -> void:
	if direction == pathFollower.progress_ratio: 
		wasCalled = false
		return
	goingToEnd = pathFollower.progress_ratio < direction
	if moveTween: moveTween.kill()
	prints(pathFollower.progress_ratio, direction, get_time(direction), wasCalled)
	moveTween = create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	moveTween.tween_property(pathFollower,"progress_ratio", direction, get_time(direction))
	wasCalled = false

## Returns the amount of time to tween
func get_time(direction: float) -> float:
	var distance: float = abs(direction - pathFollower.progress_ratio)
	var time: float = (distance * curveLength) / (speed if not wasCalled else returnSpeed)
	return time

## Starts the movement of the platform (called from the moving platform)
func start_moving() -> void:
	if pathFollower.progress_ratio == 0.0: goingToEnd = true
	elif pathFollower.progress_ratio == 1.0: goingToEnd = false
	print(pathFollower.progress_ratio)
	start_tween(1.0 if goingToEnd else 0.0)

## Stops movement and starts the return timer
func stop_moving() -> void:
	if moveTween: moveTween.kill()
	returnTimer.start()

## Starts moving towards the origin (called when the path is blocked)
func return_to_origin() -> void:
	start_tween(currentDirection)

## Calls the platform to the given point
func call_platform(caller: int) -> void:
	var goalRatio: float = clamp(curve.get_closest_offset(curve.get_point_position(caller)) / curveLength, 0.0, 1.0)
	prints(caller, curve.point_count, goalRatio)
	if pathFollower.progress_ratio == goalRatio: return
	currentDirection = pathFollower.progress_ratio
	wasCalled = true
	start_tween(goalRatio)
