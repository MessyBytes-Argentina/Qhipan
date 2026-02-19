extends Node

## Component class for objects that can be pushed around by fans
class_name InvoluntaryPushModule

## Turn lerp to center on or off.
@export var doLerpToCenter: bool = false
## Parent reference
@export var parent: Node3D
## Speed to the center point when pushed by a Fan
@export var lerpSpeed: float = 0.12

## Accumultation of non voluntary movements and forces.
var pushingForces: Dictionary[Node3D, Vector3] = {}
## Is currently blocking voluntary movement.
var blockingMovement: int = 0
## Center point of involuntary movement.
var forceCenter: Vector3 = Vector3.ZERO
## Flag thats true when pushing the Player to the center point of a Fan
var pushToCenter: bool = false
## Current Fan pushing the Player
var currentForce: Node3D
## Current direction of the Fan pushing the Player
var currentForceDirection: Vector3
## Cut off distance to the center
var centerMargin: float = 0.05

## Called during the physics processing step of the main loop.
func _physics_process(_delta: float) -> void:
	if pushToCenter:
		var centerPoint: Vector3 = forceCenter * (Vector3.ONE - abs(currentForceDirection)) + parent.global_position * abs(currentForceDirection)
		if centerPoint.distance_to(parent.global_position) <= centerMargin:
			pushToCenter = false
			return
		parent.global_position = parent.global_position.lerp(centerPoint, lerpSpeed)

## Adds a push force to the pushingForces list
func push(node: Node3D, direction: Vector3, force: float, blocksMovement: bool, lerpsToCenter: bool = false) -> void:
	pushingForces[node] = direction * force
	if blocksMovement: blockingMovement += 1
	if node is Fan:
		currentForce = node
		currentForceDirection = direction
		forceCenter = node.global_position
		pushToCenter = doLerpToCenter and lerpsToCenter

## Removes a push force from the pushingForces list
func stop_pushing(node: Node3D, blockedMovement: bool) -> void:
	pushingForces.erase(node)
	if blockedMovement: blockingMovement -= 1
	if node is Fan: pushToCenter = false

## Returns current push forces
func get_current_push() -> Vector3:
	var pushForce: Vector3 = Vector3.ZERO
	for object in pushingForces:
		pushForce += pushingForces[object]
	return pushForce

## Clears pushing forces
func clear() -> void:
	pushingForces.clear()
