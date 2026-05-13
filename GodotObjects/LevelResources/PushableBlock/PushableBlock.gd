extends AnimatableBody3D
class_name PushableBlock

@onready var fanChecker: Area3D = $FanChecker
@onready var blockDetector: RayCast3D = $BlockDetector
@onready var floorDetector: RayCast3D = $FloorDetector
@onready var verticalDetector: RayCast3D = $VerticalDetector

const moveTime: float = 0.2
const fallTime: float = 0.1

var moveTween: Tween
var fallTween: Tween
var isMoving: bool = false
var isFalling: bool = false
var pushingForces: Dictionary[Node3D, Vector3i] = {}
var actualPushingForces: Dictionary[Vector3i, int] = {}
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
	check_fan_areas()
	check_state()
	if waitingToMove:
		if check_for_collisions():
			start_move_tween()
		else:
			start_wait()

func start_move_tween() -> void:
	if moveTween: if moveTween.is_running(): moveTween.kill()
	prints(name, "moving to:", destination)
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
	fallTween = create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	fallTween.tween_property(self, "global_position:y", fallDestination.y, fallTime * fallDistance)
	fallTween.finished.connect(end_fall)

func end_fall() -> void:
	isFalling = false
	startWait = true

func check_fan_areas() -> void:
	var areasToRemove: Array = []
	for area: Fan in pushingForces:
		if not area.monitorable:
			areasToRemove.append(area)
	for area in areasToRemove:
		stop_pushing(area)

func check_state() -> void:
	if isFalling:
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
	var block: PushableBlock = blockDetector.get_collider()
	var distanceToBlock: int = int(global_position.distance_to(block.global_position))
	if not block.isMoving:
		if distanceToBlock <= 1: 
			return false
		else:
			currentPushDistance = distanceToBlock - 1
			set_destination()
			return true
	else:
		if destination.distance_to(block.destination) < 0.2 and not block.isFalling:
			currentPushDistance -= 1
			set_destination()
		return true

func check_for_collisions() -> bool:
	for direction in actualPushingForces:
		currentDirection = direction
		currentPushDistance = actualPushingForces[direction]
		set_destination()
		blockDetector.target_position = to_local(destination)
		blockDetector.force_raycast_update()
		floorDetector.target_position = to_local(destination)
		floorDetector.force_raycast_update()
		if floorDetector.is_colliding():
			var distanceToPoint: int = int(global_position.distance_to(floorDetector.get_collision_point()))
			if distanceToPoint < 1: continue
			currentPushDistance = distanceToPoint
			set_destination()
		if blockDetector.is_colliding():
			if not check_for_blocks(): continue
		
		return true
	return false

func set_destination() -> void:
	destination = global_position + Vector3(currentDirection * currentPushDistance)

func get_current_direction() -> bool:
	var sumOfForces: Vector3i = Vector3i.ZERO
	for object in pushingForces:
		sumOfForces += Vector3i(pushingForces[object])
	if sumOfForces == Vector3i.ZERO: 
		isMoving = false
		return false
	actualPushingForces.clear()
	var tempKey
	if sumOfForces.length() == 1:
		tempKey = pushingForces.find_key(sumOfForces)
		if tempKey != null:
			add_push(pushingForces.find_key(sumOfForces))
	else:
		tempKey = pushingForces.find_key(Vector3(sumOfForces.x,0,0))
		if tempKey != null:
			add_push(tempKey)
		tempKey = pushingForces.find_key(Vector3(0,0,sumOfForces.z))
		if tempKey != null:
			add_push(tempKey)
	return true

func add_push(fan: Fan) -> void:
	actualPushingForces[pushingForces[fan]] = int(fan.areaHeight - int(global_position.distance_to(fan.global_position)))

func push(area: Area3D) -> void:
	prints("push")
	var direction: Vector3i = Vector3i(area.get_fan_direction())
	if pushingForces.has(area) or direction.y != 0: return
	pushingForces[area] = direction

func stop_pushing(area: Area3D) -> void:
	prints("stop")
	pushingForces.erase(area)

func start_wait() -> void:
	startWait = true
	get_tree().create_timer(moveTime).timeout.connect(end_wait)

func end_wait() -> void:
	startWait = false
