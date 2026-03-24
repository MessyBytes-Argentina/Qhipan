extends Area3D

## Class that handles transitioning active cameras.
class_name CameraSwapArea

## Target camera to swap to.
@export var targetCamera: Camera3D
## Time for the transition.
@export var transitionTime: float = 0.5

## Executed when node first enters the scene tree.
func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	body_entered.connect(player_entered)

## Called when the player enters this area.
func player_entered(body: Node3D) -> void:
	if body is not Player: return
	if not targetCamera:
		push_error("No target camera was set")
		return
	CameraLerper.switch_to(targetCamera, transitionTime)
