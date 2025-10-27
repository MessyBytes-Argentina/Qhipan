extends Path3D
class_name PlatformRail

enum STATE {MOVING, STOPPED, RETURNING}

@export var platformReference: MovingPlatform
@export_range(0.1, 5, 0.05) var speed: float = 1
@export_range(0.1, 5, 0.05) var returnSpeed: float = 5
@export_range(0.1, 10, 0.05) var blockedTime: float = 3

@onready var pathFollower: PathFollow3D = %PathFollower
@onready var remoteTransform3d: RemoteTransform3D = %RemoteTransform3D
@onready var returnTimer: Timer = %ReturnTimer

var currentDirection: int = 1
var moveTween: Tween
var wasCalled: bool = false

func _ready() -> void:
	pathFollower.loop = false
	remoteTransform3d.remote_path = platformReference.get_path()
	returnTimer.connect("timeout",return_to_origin)
	returnTimer.wait_time = blockedTime

func start_tween(direction: int) -> void:
	if moveTween: moveTween.kill()
	moveTween = create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	moveTween.tween_property(pathFollower,"progress_ratio", direction, get_time())
	moveTween.connect("finished", switch_direction)

func switch_direction() -> void:
	wasCalled = false
	match currentDirection:
		1:
			currentDirection = 0
		0:
			currentDirection = 1

func get_time() -> float:
	var remainingLength = curve.get_baked_length()
	match currentDirection:
		1:
			remainingLength *= 1 - pathFollower.progress_ratio
		0:
			remainingLength *= pathFollower.progress_ratio
	var time: float = remainingLength / (speed if not wasCalled else returnSpeed)
	return time

func start_moving() -> void:
	start_tween(currentDirection)

func stop_moving() -> void:
	if moveTween: moveTween.kill()
	returnTimer.start()

func return_to_origin() -> void:
	match currentDirection:
		1:
			start_tween(0)
		0:
			start_tween(1)

func call_platform(caller: int) -> void:
	wasCalled = true
	match caller:
		1:
			if pathFollower.progress_ratio == 1: return
			currentDirection = 1
			start_tween(1)
		0:
			if pathFollower.progress_ratio == 0: return
			currentDirection = 0
			start_tween(0)
