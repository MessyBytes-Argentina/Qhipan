extends Area3D

## Reference to the door ofr opening and closing
@export var doorRef: PushDoor

## Direction marker reference for pushing direction
@onready var directionMarker: Marker3D = %DirectionMarker
## Push timer reference to open the door on timeout
@onready var pushTimer: Timer = %PushTimer
## Close timer reference to close the door on timeout (for one way door)
@onready var closeTimer: Timer = %CloseTimer

## Player reference to get movement direction
var playerRef: Player
## Flag that turns true when the player is next to the door
var isPlayerInRange: bool = false
## Direction the doors opens
var pushDir: Vector3
## Flag that turns true when the door is down
var isDoorDown: bool = false

## Executed when node first enters the scene tree
func _ready() -> void:
	playerRef = get_tree().get_first_node_in_group("Player")
	pushDir = global_position.direction_to(directionMarker.global_position).round()

## Executed once per physics frame
func _physics_process(_delta: float) -> void:
	if not isPlayerInRange: 
		if not doorRef.isOneWay: return
		if closeTimer.is_stopped() and isDoorDown:
			closeTimer.start()
		else: return
	if isDoorDown: return
	var playerPushing: bool = check_player_direction()
	if playerPushing:
		if pushTimer.is_stopped(): pushTimer.start()
	else:
		if not pushTimer.is_stopped(): pushTimer.stop()

## Returns true if the player is moving in the direction the door opens
func check_player_direction() -> bool:
	var isPlayerPushing: bool = false
	var playerDir: Vector3 = playerRef.get_move_direction().round()
	if playerDir == pushDir or playerDir == pushDir.rotated(Vector3.UP, deg_to_rad(45)).round() or playerDir == pushDir.rotated(Vector3.UP, deg_to_rad(-45)).round():
		isPlayerPushing = true
	else:
		isPlayerPushing = false
	return isPlayerPushing

## Called on push timer timeout to open the door
func push_timer_ended() -> void:
	if not doorRef.isOneWay: monitoring = false
	doorRef.open_door()
	isDoorDown = true

## Called on close timer timeout to close the door
func close_timer_ended() -> void:
	if not doorRef.isOneWay: monitoring = true
	doorRef.close_door()
	isDoorDown = false

## Switches the isPlayerInRange to true when the body that enters the area is a player
func player_in_range(body) -> void:
	if body is Player: isPlayerInRange = true
## Switches the isPlayerInRange to false when the body that exits the area is a player
func player_out_of_range(body) -> void:
	if body is Player: isPlayerInRange = false
