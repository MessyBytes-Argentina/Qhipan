extends AnimatableBody3D
class_name PushableBlock

@export var gridMapRef: GridMap

@onready var fanChecker: Area3D = $FanChecker

const moveTime: float = 0.2

var moveTween: Tween
var isMoving: bool = false
var isFalling: bool = false
var pushingForces: Dictionary[Node3D, Vector3] = {}
var currentDirection: Vector3
var fanAreasInRange: Array[Area3D]


func _physics_process(_delta: float) -> void:
	if isFalling: return
	get_fan_areas()
	check_fan_areas()
	if not isMoving:
		check_state()

func check_fan_areas() -> void:
	var areasToRemove: Array = []
	for area in pushingForces:
		if not fanAreasInRange.has(area):
			areasToRemove.append(area)
	for area in areasToRemove:
		stop_pushing(area)

func get_fan_areas() -> void:
	fanAreasInRange = fanChecker.get_overlapping_areas()
	for fan: Fan in fanAreasInRange:
		push(fan, fan.get_fan_direction())

func start_move_tween() -> void:
	if moveTween: moveTween.kill()
	isMoving = true
	moveTween = create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	moveTween.tween_property(self, "global_position", global_position + currentDirection, moveTime)
	moveTween.connect("finished", check_state)

func check_state() -> void:
	if pushingForces.is_empty():
		isMoving = false
		return
	if get_current_direction():
		start_move_tween()

func get_current_direction() -> bool:
	var sumOfForces: Vector3 = Vector3.ZERO
	for object in pushingForces:
		sumOfForces += pushingForces[object]
	if Vector3i(sumOfForces) == Vector3i.ZERO: 
		isMoving = false
		return false
	for object in pushingForces:
		if gridMapRef.get_cell_item(get_grid_position(pushingForces[object])) == -1:
			currentDirection = Vector3i(pushingForces[object])
			return true
	isMoving = false
	return false

func get_grid_position(direction: Vector3 = Vector3.ZERO) -> Vector3i:
	return gridMapRef.local_to_map(gridMapRef.to_local(global_position + direction))

func push(area: Area3D, direction: Vector3) -> void:
	if pushingForces.has(area) or Vector3i(direction).y != 0.0: return
	pushingForces[area] = direction
	if not isMoving:
		if get_current_direction():
			start_move_tween()

func stop_pushing(area: Area3D) -> void:
	pushingForces.erase(area)
