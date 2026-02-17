extends Node

## Component class for objects that can be pushed around by fans
class_name InvoluntaryPushModule

## Accumultation of non voluntary movements and forces.
var pushingForces: Dictionary[Node3D, Vector3] = {}
## Is currently blocking voluntary movement.
var blockingMovement: int = 0

#region Player to Fan center
## Player reference
var player: Player = null
## Speed to the center point when pushed by a Fan
var lerpSpeed: float = 0.1
## Center point for Fans
var fanCenter: Vector3 = Vector3.ZERO
## Flag thats true when pushing the Player to the center point of a Fan
var pushToCenter: bool = false
## Current Fan pushing the Player
var currentFan: Node3D
## Current direction of the Fan pushing the Player
var currentFanDirection: Vector3
## Cut off distance to the center
var centerMargin: float = 0.05

## Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var parent = get_parent()
	if parent is Player: player = parent

## Called during the physics processing step of the main loop.
func _physics_process(_delta: float) -> void:
	if player == null: return
	if pushToCenter:
		var centerPoint: Vector3 = get_fan_center()
		if centerPoint.distance_to(player.global_position) <= centerMargin:
			pushToCenter = false
			return
		player.global_position = player.global_position.lerp(centerPoint,lerpSpeed)

## Returns the point to the center of the current Fan ignoring the direction axis
func get_fan_center() -> Vector3:
	var center: Vector3 = currentFan.global_position
	if currentFanDirection.x == 1.0 or currentFanDirection.x == -1.0:
		center.x = player.global_position.x
	if currentFanDirection.y == 1.0 or currentFanDirection.y == -1.0:
		center.y = player.global_position.y
	if currentFanDirection.z == 1.0 or currentFanDirection.z == -1.0:
		center.z = player.global_position.z
	return center
#endregion

## Adds a push force to the pushingForces list
func push(node: Node3D, direction: Vector3, force: float, blocksMovement: bool) -> void:
	pushingForces[node] = direction * force
	if blocksMovement: blockingMovement += 1
	if node is Fan:
		currentFan = node
		currentFanDirection = direction
		pushToCenter = true

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
