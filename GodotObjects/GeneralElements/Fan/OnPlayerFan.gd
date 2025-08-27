extends Node3D

@onready var pushArea: Fan = %PushArea


var canPush: bool = false
var playerRef: Player
var currentPosition: Vector3
var currentDirection: Vector3


func _physics_process(delta: float) -> void:
	if canPush:
		currentPosition = get_player_position()
		currentDirection = get_player_direction()
		rotate_push_direction()
		global_position = currentPosition + currentDirection

func rotate_push_direction() -> void:
	pass

func get_player_position() -> Vector3:
	return playerRef.global_position.snapped(Vector3(1, 0.5, 1))

func get_player_direction() -> Vector3:
	return currentPosition.direction_to(playerRef.global_position.snapped(Vector3(0.1, 0.5, 0.1)))

func replenish_push() -> void:
	canPush = true

func disable_push() -> void:
	canPush = false

func activate_push() -> void:
	if canPush:
		pushArea.switch_fan(canPush)
		canPush = false
	else :
		return
