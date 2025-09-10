extends Node
class_name ForcedMovement

const axisXZ: Vector3 = Vector3(1,0,1)
const DISTANCETOTARGET: float = 0.05

@onready var player: Player = $".."

var forcingPlayer: bool = false
var targetPosition: Vector3
var pushSteps: float


func _physics_process(_delta: float) -> void:
	if not forcingPlayer: return
	#prints(player.global_position.snappedf(0.05),"->",targetPosition)
	player.global_position = player.global_position.lerp(targetPosition, pushSteps)
	var targetDistance: float = Vector3(player.global_position * axisXZ).distance_to(targetPosition * axisXZ)
	prints(targetDistance)
	if targetDistance < DISTANCETOTARGET:
		end_push()

func force_player_to(target: Vector3, pushForce: float, inputBlock: bool = true ) -> void:
	#print("forcing started")
	forcingPlayer = true
	player.forcedNoGravity = true
	targetPosition = target
	pushSteps = pushForce
	if inputBlock:
		player.block_inputs()

func end_push() -> void:
	#print("forcing ended")
	player.enable_inputs()
	forcingPlayer = false
	player.forcedNoGravity = false
