extends Node3D
class_name LedgeDetection

## Distance from the edge that activates the jump
const JUMPDISTANCE: float = 0.40
## Jump Distance
const FANPUSHDISTANCE: float = 1.5

## Player reference
@export var player: Player

## Forced movement node reference
@onready var forcedMovement: ForcedMovement = %ForcedMovement
## Jump sound
@onready var jumpSound: RandomSoundPlayer = %Jump

## Flag that turns on when the player has a sticker on hand
var stickerOnHand: bool = false
## Flag for detection state
var detecting: bool = false
## Flag for enabling jumping
var ableToJump: bool = false
## Collection of Detection Raycasts
var raycastCollection: Array

## Called when the node enters the scene tree for the first time
func _ready() -> void:
	raycastCollection = get_children()

## Executed once per physics frame
func _physics_process(_delta: float) -> void:
	var canDetect: bool = not player.check_falling() and stickerOnHand
	if not canDetect:
		set_raycasts_detection(false)
		detecting = false
		return
	elif not detecting and canDetect:
		ableToJump = true
		set_raycasts_detection(true)
		detecting = true
		return
	var zeroCount: int = 0
	for raycast: DetectionRaycast in raycastCollection:
		if raycast.previousDistance == 0 : zeroCount += 1
	if zeroCount == raycastCollection.size(): return
	for raycast: DetectionRaycast in raycastCollection:
		if raycast.currentDistance < JUMPDISTANCE and raycast.currentDistance <= raycast.previousDistance:
			var normalDirection: Vector3 = raycast.get_collision_normal()
			if normalDirection == Vector3.ZERO or player.forcedNoGravity : return
			if not check_player_direction(normalDirection.round()): continue
			do_player_jump(normalDirection)
			return

## Makes the player jump in the given direction by FANPUSHDISTANCE
func do_player_jump(direction: Vector3) -> void:
	if not ableToJump: return
	ableToJump = false
	set_raycasts_detection(false)
	jumpSound.play_sound()
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

## Sets the detecting flag on the detection raycast to the given value
func set_raycasts_detection(value: bool) -> void:
	for raycast: DetectionRaycast in raycastCollection:
		raycast.set_detecting(value)
		raycast.windParticles.emitting = false

## Sets necessary flags to true
func enable_push() -> void:
	stickerOnHand = true

## Sets necessary flags to false
func disable_push() -> void:
	stickerOnHand = false
