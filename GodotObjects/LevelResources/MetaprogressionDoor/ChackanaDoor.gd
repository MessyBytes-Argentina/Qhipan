extends Node3D

## Used to identify which objects to trigger when a pedestarl triggers with this same name.
@export var pedestalName: String

## Reference to the AnimationPlayer.
@onready var animationPlayer: AnimationPlayer = %AnimationPlayer

## Called when pedestal is activated.
func pedestal_activated(activatedPedestal: String, skip: bool = false) -> void:
	if activatedPedestal == pedestalName:
		if not skip:
			animationPlayer.play("DoorOpens")
		else:
			animationPlayer.play("OpenedDoor")
