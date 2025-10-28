extends Area3D
class_name PlatformCaller

@export_range(0, 1, 1) var callTo: int = 0
@export var railReference: PlatformRail

func _ready() -> void:
	body_entered.connect(call_platform)

func call_platform(_body) -> void:
	railReference.call_platform(callTo)
