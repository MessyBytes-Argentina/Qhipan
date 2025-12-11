extends Node
class_name ForcedMovement

## Duration of the jump
const jumpDuration: float = 0.3
## Angle of the jump
const jumpAngle: float = PI / 4

## Player reference
@onready var player: Player = $".."
## Flag that turns on when pushing the player
var forceApplied: bool = false

## Makes the player jump to the given position, blocking player input by default
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

## Called when the jump ends unlocking player input
func end_jump() -> void:
	player.lastInvoluntarySpeed = Vector3(0,player.lastInvoluntarySpeed.y,0)
	player.enable_inputs()
	forceApplied = false
	player.jumping = false
