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
var currentDirection: int = 1
## Tween used for movement
var moveTween: Tween
## Flag that turns true when called
var wasCalled: bool = false

## Executed when node first enters the scene tree
func _ready() -> void:
	pathFollower.loop = false
	remoteTransform3d.remote_path = platformReference.get_path()
	returnTimer.connect("timeout",return_to_origin)
	returnTimer.wait_time = blockedTime

## Starts the move tween, tweening the progress ratio to the given value
func start_tween(direction: int) -> void:
	if moveTween: moveTween.kill()
	moveTween = create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	moveTween.tween_property(pathFollower,"progress_ratio", direction, get_time())
	moveTween.connect("finished", switch_direction)

## Switches the current direction to the opposite
func switch_direction() -> void:
	wasCalled = false
	match currentDirection:
		1:
			currentDirection = 0
		0:
			currentDirection = 1

## Returns the amount of time to tween
func get_time() -> float:
	var remainingLength = curve.get_baked_length()
	match currentDirection:
		1:
			remainingLength *= 1 - pathFollower.progress_ratio
		0:
			remainingLength *= pathFollower.progress_ratio
	var time: float = remainingLength / (speed if not wasCalled else returnSpeed)
	return time

## Starts the movement of the platform (called from the moving platform)
func start_moving() -> void:
	start_tween(currentDirection)

## Stops movement and starts the return timer
func stop_moving() -> void:
	if moveTween: moveTween.kill()
	returnTimer.start()

## Starts moving towards the origin (called when the path is blocked)
func return_to_origin() -> void:
	match currentDirection:
		1:
			start_tween(0)
		0:
			start_tween(1)

## Calls the platform to the given point
func call_platform(caller: int) -> void:
	match caller:
		1:
			if pathFollower.progress_ratio == 1.0: return
		0:
			if pathFollower.progress_ratio == 0.0: return
	currentDirection = caller
	wasCalled = true
	start_tween(currentDirection)
