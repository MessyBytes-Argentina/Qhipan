extends Node3D
class_name OnPlayerFan

const horizontalBias: float = 0.85
const verticalBias: float = 0.3

@onready var pushArea: Fan = %PushArea

var isPushActive: bool = false
var canPush: bool = false
var playerRef: Player
var currentPosition: Vector3
var currentDirection: Vector3
var directionTarget: Vector3
## Reference to the current gridmap.
var gridmap: GridMap

func _ready() -> void:
	playerRef = get_parent()
	reparent.call_deferred(playerRef.get_parent())
	pushArea.body_exited.connect(end_push)

func _physics_process(_delta: float) -> void:
	if not isPushActive: return
	
	var isPlayerFalling: bool = playerRef.check_falling()
	if isPlayerFalling and canPush:
		activate_push()
	elif not isPlayerFalling and not canPush:
		replenish_push()
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
	if horizontalDistance > horizontalBias or verticalDistance > verticalBias:
		currentPosition = Vector3(gridmap.local_to_map(playerRef.global_position - gridmap.global_position)) * gridmap.cell_size + gridmap.global_position + gridmap.cell_size / 2.0

func replenish_push() -> void:
	canPush = true

func activate_push() -> void:
	switch_push()
	canPush = false
	playerRef.block_inputs()
	isPushActive = false
	get_tree().create_timer(0.5).timeout.connect(end_push)

func end_push(_body = null) -> void:
	canPush = false
	switch_push()
	playerRef.enable_inputs()
	await get_tree().create_timer(0.3).timeout
	isPushActive = true

func enable_push() -> void:
	isPushActive = true
	replenish_push()

func switch_push() -> void:
	pushArea.switch_fan(canPush)

func disable_push() -> void:
	isPushActive = false
	canPush = false
	switch_push()
