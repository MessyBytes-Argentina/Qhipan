extends Node
class_name ForcedMovement

const axisXZ: Vector3 = Vector3(1,0,1)
const DISTANCETOTARGET: float = 0.05
const jumpDuration: float = 0.375
const jumpHeight: float = 0.5
const jumpReturnControlAfter: float = 0.35
const gravityTweak: float = 0.4

@onready var player: Player = $".."

var forcingPlayer: bool = false
var targetPosition: Vector3
var pushSteps: float
var playerJumpTween: Tween
var playerStartPosition: Vector3

#func _physics_process(_delta: float) -> void:
	#if not forcingPlayer: return
	##prints(player.global_position.snappedf(0.05),"->",targetPosition)
	#player.global_position = player.global_position.lerp(targetPosition, pushSteps)
	#var targetDistance: float = Vector3(player.global_position * axisXZ).distance_to(targetPosition * axisXZ)
	#prints(targetDistance)
	#if targetDistance < DISTANCETOTARGET:
		#end_push()

func force_player_to(target: Vector3, pushForce: float, inputBlock: bool = true ) -> void:
	#print("forcing started")
	forcingPlayer = true
	player.forcedNoGravity = true
	targetPosition = target
	pushSteps = pushForce
	playerStartPosition = player.global_position
	if inputBlock:
		player.block_inputs()
	playerJumpTween = create_tween()
	playerJumpTween.tween_method(jump, 0.0, 1.0, jumpDuration).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
	playerJumpTween.finished.connect(end_push)
	playerJumpTween.play()

func jump(progress: float) -> void:
	var newPosition: Vector3 = lerp(playerStartPosition, targetPosition, progress)
	var newHeight: float = (-4 * pow(progress, 2.0) + 4 * progress) * jumpHeight
	player.global_position = newPosition * axisXZ + (playerStartPosition.y + newHeight) * Vector3.UP
	if progress >= jumpReturnControlAfter and forcingPlayer:
		forcingPlayer = false
		player.enable_inputs()
		player.forcedNoGravity = false

func end_push() -> void:
	#print("forcing ended")
	#player.lastInvoluntarySpeed.y = player.gravity * jumpDuration * jumpHeight * -gravityTweak
	player.forcedNoGravity = false
