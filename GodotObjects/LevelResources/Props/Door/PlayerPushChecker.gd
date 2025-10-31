extends Area3D

@export var doorRef: PushDoor

@onready var directionMarker: Marker3D = %DirectionMarker
@onready var pushTimer: Timer = %PushTimer

var playerRef: Player
var isPlayerInRange: bool = false
var pushDir: Vector3


func _ready() -> void:
	playerRef = get_tree().get_first_node_in_group("Player")
	pushDir = global_position.direction_to(directionMarker.global_position).round()

func _physics_process(_delta: float) -> void:
	if not isPlayerInRange: return
	var playerPushing: bool = check_player_direction()
	if playerPushing:
		if pushTimer.is_stopped(): pushTimer.start()
	else:
		if not pushTimer.is_stopped(): pushTimer.stop()

func check_player_direction() -> bool:
	var isPlayerPushing: bool = false
	var playerDir: Vector3 = playerRef.get_move_direction().round()
	if playerDir == pushDir or playerDir == pushDir.rotated(Vector3.UP, deg_to_rad(45)).round() or playerDir == pushDir.rotated(Vector3.UP, deg_to_rad(-45)).round():
		isPlayerPushing = true
	else:
		isPlayerPushing = false
	return isPlayerPushing

func timer_ended() -> void:
	doorRef.open_door()
	monitoring = false

func player_in_range(body) -> void:
	if body is Player: isPlayerInRange = true

func player_out_of_range(body) -> void:
	if body is Player: isPlayerInRange = false
