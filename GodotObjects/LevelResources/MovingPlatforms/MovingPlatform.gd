extends AnimatableBody3D
class_name MovingPlatform

## Amount of time the platform waits before moving
const waitTimer: float = 0.5

## Reference to the platforms rail for movement
@export var railReference: PlatformRail
## Flag that if true removes the need of a placed alternator sticker
@export var isPermanent: bool = false
## Flag that if true allows the platform to move
@export var powered: bool = false

## When the Player is detected checks if movement is possible, starts moving if true
func check_power(_body) -> void:
	if powered or isPermanent:
		await get_tree().create_timer(waitTimer).timeout
		railReference.start_moving()

## When a block is detected stops the movement
func stop_moving(body) -> void:
	if body == self: return
	if body is AlternatingObject: if not body.isOff: railReference.stop_moving()

## Switches the powered flag to the opposite
func switch_state() -> void:
	powered = !powered
