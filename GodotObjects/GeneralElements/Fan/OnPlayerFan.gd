extends Node3D
class_name OnPlayerFan

@onready var pushArea: Fan = %PushArea


var canPush: bool = false
var playerRef: Player
var currentPosition: Vector3
var currentDirection: Vector3
var directionTarget: Vector3
## Reference to the current gridmap.
var gridmap: GridMap

func _ready() -> void:
	playerRef = get_parent()
	playerRef.onPlayerEffectRef = self
	reparent.call_deferred(playerRef.get_parent())
	pushArea.body_exited.connect(end_push)

func _physics_process(_delta: float) -> void:
	if canPush:
		get_player_position()
		get_player_direction()
		get_target_direction()
		rotate_push_direction()
		global_position = currentPosition + directionTarget

func rotate_push_direction() -> void:
	match directionTarget:
		Vector3(1,0,0):
			global_rotation_degrees.y = 90
		Vector3(-1,0,0):
			global_rotation_degrees.y = -90
		Vector3(0,0,1):
			global_rotation_degrees.y = 0
		Vector3(0,0,-1):
			global_rotation_degrees.y = 180

func get_target_direction() -> void:
	directionTarget = Vector3.ZERO
	if abs(currentDirection.x) > abs(currentDirection.z):
		directionTarget.x = currentDirection.x
	elif abs(currentDirection.z) > abs(currentDirection.x):
		directionTarget.z = currentDirection.z
	directionTarget = directionTarget.normalized()

func get_player_direction() -> void:
	currentDirection = currentPosition.direction_to(playerRef.global_position)

func get_player_position() -> void:
	if not gridmap:
		gridmap = playerRef.gridmap
	var verticalDistance: float = (currentPosition * Vector3(0,1,0)).distance_squared_to(playerRef.global_position * Vector3(0,1,0))
	var horizontalDistance: float = (currentPosition * Vector3(1,0,1)).distance_squared_to(playerRef.global_position * Vector3(1,0,1))
	if horizontalDistance > 0.8 or verticalDistance > 0.5:
		currentPosition = Vector3(gridmap.local_to_map(playerRef.global_position - gridmap.global_position)) * gridmap.cell_size + gridmap.global_position + gridmap.cell_size / 2.0

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
