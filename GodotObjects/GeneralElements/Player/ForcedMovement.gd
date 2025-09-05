extends Node
class_name ForcedMovement

const axisMultiplier: Vector3 = Vector3(1,0,1)

@onready var player: Player = $".."

var forcingPlayer: bool = false
var targetPosition: Vector3
var pushSteps: float


func _physics_process(delta: float) -> void:
	if not forcingPlayer: return
	#print(player.global_position.snappedf(0.05),"->",targetPosition)
	player.global_position = player.global_position.lerp(targetPosition, pushSteps * delta)
	if player.global_position.snappedf(0.05) * axisMultiplier == targetPosition * axisMultiplier:
		end_push()

func force_player_to(target: Vector3, pushForce: float, inputBlock: bool = true ) -> void:
	#print("forcing started")
	forcingPlayer = true
	targetPosition = target
	pushSteps = pushForce
	if inputBlock:
		player.block_inputs()

func end_push() -> void:
	#print("forcing ended")
	player.enable_inputs()
	forcingPlayer = false
