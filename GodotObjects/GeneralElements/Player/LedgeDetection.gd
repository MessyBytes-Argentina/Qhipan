extends Node3D
class_name LedgeDetection

const JUMPDISTANCE: float = 0.40

const FANPUSHDISTANCE: float = 1.5

@onready var player: Player = $".."

@onready var forcedMovement: ForcedMovement = %ForcedMovement

var stickerOnHand: bool = false
var ableToPush: bool = false
var raycastCollection: Array

func _ready() -> void:
	raycastCollection = get_children()

func _physics_process(_delta: float) -> void:
	if not stickerOnHand: return
	if not ableToPush:
		if not player.check_falling() or len(player.noGravityZones) > 0:
			ableToPush = true
			set_raycasts_detection(true)
			return
		else:
			return
	var zeroCount: int = 0
	for raycast: DetectionRaycast in raycastCollection:
		if raycast.previousDistance == 0 : zeroCount += 1
	if zeroCount == raycastCollection.size(): return
	
	for raycast: DetectionRaycast in raycastCollection:
		if raycast.currentDistance < JUMPDISTANCE and raycast.currentDistance <= raycast.previousDistance:
			var normalDirection: Vector3 = raycast.get_collision_normal()
			if normalDirection == Vector3.ZERO or player.forcedNoGravity : return
			if not check_player_direction(normalDirection): continue
			yeet_the_player(normalDirection)
			return

func yeet_the_player(direction: Vector3) -> void:
	ableToPush = false
	set_raycasts_detection(false)
	var targetPosition: Vector3 = player.global_position + (direction * FANPUSHDISTANCE)
	forcedMovement.push_player(targetPosition)

## Returns true if the player is moving in the direction the door opens
func check_player_direction(direction: Vector3) -> bool:
	var isSameDirection: bool = false
	var playerDir: Vector3 = player.get_move_direction().round()
	if playerDir == direction or playerDir == direction.rotated(Vector3.UP, deg_to_rad(45)).round() or playerDir == direction.rotated(Vector3.UP, deg_to_rad(-45)).round():
		isSameDirection = true
	else:
		isSameDirection = false
	return isSameDirection

func set_raycasts_detection(value: bool) -> void:
	for raycast: DetectionRaycast in raycastCollection:
		raycast.set_detecting(value)

func enable_push() -> void:
	stickerOnHand = true
	ableToPush = true
	set_raycasts_detection(true)

func disable_push() -> void:
	stickerOnHand = false
	ableToPush = false
	set_raycasts_detection(false)
