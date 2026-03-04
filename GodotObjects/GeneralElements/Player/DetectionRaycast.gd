extends RayCast3D
class_name DetectionRaycast

## Minimum length for the detection raycasts
const MINLENGTH: float = 0.1
## Maximum length for the detection raycasts
const LENGTH: float = 0.75

## Vertical raycast reference
@onready var verticalRaycast: RayCast3D = %VerticalRayCast
## Obstacle detecting raycast
@onready var pathRayCast: RayCast3D = $PathRayCast
## Wind particles
@onready var windParticles: GPUParticles3D = %WindJumpParticles

## Last detected distance to an edge
var previousDistance: float = 0
## Flag that enables or disables the detection of the raycasts
var isDetecting: bool = false
## Current detected distance to an edge
var currentDistance: float = 1

## Sets isDetecting to the value given
func set_detecting(value: bool) -> void:
	isDetecting = value

## Executed once per physics frame
func _physics_process(_delta: float) -> void:
	if not isDetecting: 
		windParticles.emitting = false
		return
	var collisionPoint: Vector3
	if verticalRaycast.is_colliding() or pathRayCast.is_colliding():
		windParticles.emitting = false
	if is_colliding():
		collisionPoint = get_collision_point()
		if collisionPoint.distance_to(global_position) < MINLENGTH:
			windParticles.emitting = false
			previousDistance = 0
			return
		var raycast2NewPosition = to_local(collisionPoint) * Vector3(1, 0, 1)
		verticalRaycast.position = raycast2NewPosition + verticalRaycast.position * Vector3.UP - raycast2NewPosition.normalized() * MINLENGTH
	else:
		previousDistance = 0
		return
	if verticalRaycast.is_colliding() or pathRayCast.is_colliding():
		previousDistance = 0
		return
	windParticles.global_position = get_collision_point() * Vector3(1, 0, 1) + Vector3(0, windParticles.global_position.y, 0)
	windParticles.emitting = true
	currentDistance = LENGTH - collisionPoint.distance_to(global_position)
	if currentDistance < 0:
		previousDistance = 0
		return
	previousDistance = currentDistance
