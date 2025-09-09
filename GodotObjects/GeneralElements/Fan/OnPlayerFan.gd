extends Node3D
class_name OnPlayerFan

@onready var pushArea: Fan = %PushArea


var canPush: bool = false
var playerRef: Player
var playerSnappedPos: Vector3
var currentPosition: Vector3
var currentDirection: Vector3


func _ready() -> void:
	playerRef = get_parent()
	playerRef.onPlayerEffectRef = self
	reparent.call_deferred(playerRef.get_parent())
	pushArea.body_exited.connect(end_push)

func _physics_process(_delta: float) -> void:
	if canPush:
		currentPosition = get_player_position()
		currentDirection = get_player_direction()
		rotate_push_direction()
		global_position = currentPosition + currentDirection

func rotate_push_direction() -> void:
	rotation.y = rad_to_deg(currentPosition.angle_to(playerSnappedPos))

func get_player_position() -> Vector3:
	return playerRef.global_position.snapped(Vector3(1, 0.5, 1))

func get_player_direction() -> Vector3:
	playerSnappedPos = playerRef.global_position.snapped(Vector3(0.25, 0.5, 0.25))
	return currentPosition.direction_to(playerSnappedPos)

func replenish_push() -> void:
	canPush = true

func activate_push() -> void:
	if canPush:
		pushArea.switch_fan(canPush)
		canPush = false
	else :
		return

func disable_push() -> void:
	canPush = false
	pushArea.switch_fan(canPush)

func end_push(_body) -> void:
	disable_push()
