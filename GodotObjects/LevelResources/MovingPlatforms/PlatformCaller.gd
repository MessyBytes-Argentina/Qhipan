extends Area3D
class_name PlatformCaller

## Position to which this caller send the platform
@export_range(0, 1, 1) var callTo: int = 0
## Reference to the platform rail to call
@export var railReference: PlatformRail

## Executed when node first enters the scene tree.
func _ready() -> void:
	body_entered.connect(call_platform)

## Calls the platform to the set position
func call_platform(_body) -> void:
	railReference.call_platform(callTo)
