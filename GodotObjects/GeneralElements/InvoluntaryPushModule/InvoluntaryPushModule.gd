extends Node

## Component class for objects that can be pushed around by fans
class_name InvoluntaryPushModule

## Accumultation of non voluntary movements and forces.
var pushingForces: Dictionary[Node3D, Vector3] = {}
## Is currently blocking voluntary movement.
var blockingMovement: int = 0

## Adds a push force to the pushingForces list
func push(node: Node3D, direction: Vector3, force: float, blocksMovement: bool) -> void:
	pushingForces[node] = direction * force
	if blocksMovement: blockingMovement += 1

## Removes a push force from the pushingForces list
func stop_pushing(node: Node3D, blockedMovement: bool) -> void:
	pushingForces.erase(node)
	if blockedMovement: blockingMovement -= 1

## Returns current push forces
func get_current_push() -> Vector3:
	var pushForce: Vector3 = Vector3.ZERO
	for object in pushingForces:
		pushForce += pushingForces[object]
	return pushForce

## Clears pushing forces
func clear() -> void:
	pushingForces.clear()
