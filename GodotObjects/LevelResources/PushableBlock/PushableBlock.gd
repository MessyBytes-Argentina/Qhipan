extends AnimatableBody3D
class_name PushableBlock

@export var gridMapRef: GridMap

var moveTween: Tween
var isMoving: bool = false
var isFalling: bool = false
var pushingForces: Dictionary[Node3D, Vector3] = {}
var currentDirection: Vector3
var currentGridPos: Vector3i

func _ready() -> void:
	currentGridPos = gridMapRef.local_to_map(gridMapRef.to_local(global_position))

func start_move_tween() -> void:
	if moveTween: moveTween.kill()
	isMoving = true
	moveTween = create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	moveTween.tween_property(self, "global_position", global_position + currentDirection, 1.0)
	moveTween.connect("finished", end_push)

func end_push() -> void:
	if pushingForces.is_empty():
		isMoving = false
		return
	if get_current_direction():
		start_move_tween()

func get_current_direction() -> bool:
	var direction: Vector3 = Vector3.ZERO
	var sumOfForces: Vector3 = Vector3.ZERO
	for object in pushingForces:
		sumOfForces += pushingForces[object]
	if sumOfForces == Vector3.ZERO: return false
	for object in pushingForces:
		if gridMapRef.get_cell_item(currentGridPos + Vector3i(pushingForces[object])) == -1:
			currentDirection = direction
			return true
	return false

func push(node: Node3D, direction: Vector3) -> void:
	if pushingForces.has(node) or direction.y != 0: return
	pushingForces[node] = direction
	if not isMoving:
		if get_current_direction():
			start_move_tween()

func stop_pushing(node: Node3D) -> void:
	pushingForces.erase(node)
