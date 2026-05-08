extends AnimatableBody3D
class_name PushableBlock

@export var gridMapRef: GridMap

@onready var fanChecker: Area3D = $FanChecker
@onready var blockDetector: RayCast3D = $BlockDetector
@onready var verticalDetector: RayCast3D = $VerticalDetector

const moveTime: float = 0.2
const fallTime: float = 0.1

var moveTween: Tween
var fallTween: Tween
var isMoving: bool = false
var isFalling: bool = false
var pushingForces: Dictionary[Node3D, Vector3] = {}
var currentDirection: Vector3i
var currentPushDistance: int = 0
var fallDistance: int = 0
var destination: Vector3
var fanAreasInRange: Array[Area3D]
var waitingToMove: bool = false
var startWait: bool = true
var ignoreHole: bool = false

func _ready() -> void:
	start_wait()

func _physics_process(_delta: float) -> void:
	if startWait: return
	if isFalling: return
	if isMoving: return
	get_fan_areas()
	check_fan_areas()
	check_state()
	if waitingToMove:
		if check_for_blocks():
			start_move_tween()

func start_move_tween() -> void:
	if moveTween: if moveTween.is_running(): moveTween.kill()
	prints(name,"from:",global_position,"to:",destination)
	isMoving = true
	waitingToMove = false
	moveTween = create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	moveTween.tween_property(self, "global_position:x", destination.x, moveTime * currentPushDistance)
	moveTween.parallel().tween_property(self, "global_position:z", destination.z, moveTime * currentPushDistance)
	moveTween.finished.connect(check_state)

func start_fall_tween() -> void:
	if fallTween: return
	isMoving = false
	var fallDestination: Vector3 = global_position + Vector3(Vector3.DOWN * fallDistance)
	prints("fd:",fallDestination,"gp:", global_position, name)
	fallTween = create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	fallTween.tween_property(self, "global_position:y", fallDestination.y, fallTime * fallDistance)
	fallTween.finished.connect(end_fall)

func end_fall() -> void:
	isFalling = false
	startWait = true

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

func check_state() -> void:
	if isFalling:
		prints("cs-gp:", global_position, name)
		start_fall_tween()
		return
	if pushingForces.is_empty():
		isMoving = false
		waitingToMove = false
		return
	if get_current_direction():
		waitingToMove = true
	isMoving = false

func check_for_blocks() -> bool:
	destination = global_position + Vector3(currentDirection * currentPushDistance)
	blockDetector.target_position = to_local(destination)
	blockDetector.force_raycast_update()
	if blockDetector.is_colliding():
		var block: PushableBlock = blockDetector.get_collider()
		var distanceToBlock: float = global_position.distance_to(block.global_position)
		if destination.distance_to(block.destination) < 0.5 and block.isFalling:
			ignoreHole = true
			get_current_direction()
			return true
		if distanceToBlock > 1:
			if block.isMoving:
				if destination.distance_to(block.destination) < 0.5 and currentDirection == block.currentDirection and not block.isFalling:
					destination -= Vector3(currentDirection)
			else:
				currentPushDistance = int(distanceToBlock) - 1
				destination = global_position + Vector3(currentDirection * currentPushDistance)
			return true
		else:
			if block.isMoving:
				if destination.distance_to(block.destination) < 0.5 and not block.isFalling:
					destination -= Vector3(currentDirection)
				return true
			else:
				start_wait()
				return false
	else:
		return true

func get_current_direction() -> bool:
	var sumOfForces: Vector3 = Vector3.ZERO
	for object in pushingForces:
		sumOfForces += pushingForces[object]
	if Vector3i(sumOfForces) == Vector3i.ZERO: 
		isMoving = false
		return false
	for fan:Fan in pushingForces:
		var actualPushDistance: int = 0
		currentDirection = Vector3i(pushingForces[fan])
		@warning_ignore("narrowing_conversion")
		currentPushDistance = fan.areaHeight - int(global_position.distance_to(fan.global_position))
		for n in range(currentPushDistance):
			var gridPos: Vector3i = get_grid_position(global_position + Vector3(currentDirection * int(n+1)))
			if gridMapRef.get_cell_item(gridPos) == -1 and gridMapRef.get_cell_item(gridPos + Vector3i.UP) == -1:
				actualPushDistance += 1
				if gridMapRef.get_cell_item(gridPos + Vector3i.DOWN) == -1 and not ignoreHole:
					verticalDetector.position = Vector3(currentDirection * int(n+1))
					verticalDetector.force_raycast_update()
					if verticalDetector.is_colliding():
						@warning_ignore("narrowing_conversion")
						var collisionDistance: int = verticalDetector.global_position.distance_to(verticalDetector.get_collision_point())
						if collisionDistance < 1:
							continue
						else:
							isFalling = true
							fallDistance = collisionDistance
							break
			elif ignoreHole:
				ignoreHole = false
				continue
			else:
				break
		if actualPushDistance > 0:
			currentPushDistance = actualPushDistance
			destination = global_position + Vector3(currentDirection * currentPushDistance)
			return true
	isMoving = false
	return false

func get_grid_position(globalPos: Vector3 = Vector3.ZERO) -> Vector3i:
	return gridMapRef.local_to_map(gridMapRef.to_local(globalPos))

func push(area: Area3D, direction: Vector3) -> void:
	if pushingForces.has(area) or Vector3i(direction).y != 0.0: return
	pushingForces[area] = direction

func stop_pushing(area: Area3D) -> void:
	pushingForces.erase(area)
	if not isMoving and not isFalling:
		check_state()

func start_wait() -> void:
	startWait = true
	get_tree().create_timer(moveTime).timeout.connect(end_wait)

func end_wait() -> void:
	startWait = false
