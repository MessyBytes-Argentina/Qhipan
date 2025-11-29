extends Node
class_name ForcedMovement

const jumpDuration: float = 0.3
const jumpAngle: float = PI / 4

@onready var player: Player = $".."

var forceApplied: bool = false

func push_player(target: Vector3, inputBlock: bool = true) -> void:
	if forceApplied: return
	forceApplied = true
	if inputBlock:
		player.block_inputs()
	var jumpDirection: Vector3 = player.global_position.direction_to(target)
	var velocity2D: Vector2 = sqrt(player.global_position.distance_to(target) * player.gravity) / sin(2 * jumpAngle) * Vector2.RIGHT.rotated(-jumpAngle)
	jumpDirection *= velocity2D.x
	var pushVector: Vector3  = Vector3(jumpDirection.x, -velocity2D.y , jumpDirection.z)
	player.velocity = Vector3.ZERO
	player.lastVoluntarySpeed = Vector3.ZERO
	player.jumping = true
	player.lastInvoluntarySpeed = pushVector
	get_tree().create_timer(player.global_position.distance_to(target) / velocity2D.x).timeout.connect(end_jump)


func end_jump() -> void:
	player.lastInvoluntarySpeed = Vector3(0,player.lastInvoluntarySpeed.y,0)
	player.enable_inputs()
	forceApplied = false
	player.jumping = false
