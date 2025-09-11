extends Node
class_name ForcedMovement

const axisXZ: Vector3 = Vector3(1,0,1)
const DISTANCETOTARGET: float = 0.05
const jumpDuration: float = 0.375
const jumpHeight: float = 0.5
const jumpReturnControlAfter: float = 0.35
const gravityTweak: float = 0.4

@onready var player: Player = $".."

var targetPosition: Vector3
var playerStartPosition: Vector3

func force_player_to(target: Vector3, inputBlock: bool = true) -> void:
	player.forcedNoGravity = true
	targetPosition = target
	playerStartPosition = player.global_position
	if inputBlock:
		player.block_inputs()
	var playerJumpTween: Tween = create_tween()
	playerJumpTween.tween_method(jump, 0.0, 1.0, jumpDuration).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
	playerJumpTween.play()

func jump(progress: float) -> void:
	var newPosition: Vector3 = lerp(playerStartPosition, targetPosition, progress)
	var newHeight: float = (-4 * pow(progress, 2.0) + 4 * progress) * jumpHeight
	player.global_position = newPosition * axisXZ + (playerStartPosition.y + newHeight) * Vector3.UP
	if progress >= jumpReturnControlAfter and player.forcedNoGravity:
		player.enable_inputs()
		player.forcedNoGravity = false
