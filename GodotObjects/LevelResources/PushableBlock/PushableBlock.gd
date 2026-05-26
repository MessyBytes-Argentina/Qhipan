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
var fallDistance: float = 0
var destination: Vector3
var fanAreasInRange: Array[Area3D]
var waitingToMove: bool = false
var waiting: bool = true
var blockCaller: PushableBlock = null

signal moving
signal falling

func _ready() -> void:
	start_wait()

#func _physics_process(_delta: float) -> void:
func check_movement() -> void:
	if pushingForces.is_empty(): return
	if waiting: return
	if isFalling: return
	if isMoving: return
	check_state()
	if waitingToMove:
		if check_for_collisions():
			start_move_tween()

func start_move_tween() -> void:
	if moveTween: if moveTween.is_running(): moveTween.kill()
	prints(name,"to:",destination,isFalling,"f:",get_tree().get_frame())
	isMoving = true
	waitingToMove = false
	emit_signal("moving")
	moveTween = create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	moveTween.tween_property(self, "global_position:x", destination.x, moveTime * currentPushDistance)
	moveTween.parallel().tween_property(self, "global_position:z", destination.z, moveTime * currentPushDistance)
	moveTween.finished.connect(check_state)

func start_fall_tween() -> void:
	if fallTween: if fallTween.is_running(): fallTween.kill()
	#prints(name,"falling :",fallDistance,"f:",get_tree().get_frame())
	emit_signal("falling", self)
	isMoving = false
	fallTween = create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	fallTween.tween_property(self, "global_position:y", global_position.y - fallDistance, fallTime * fallDistance)
	fallTween.finished.connect(end_fall)

func end_fall(caller: PushableBlock = self) -> void:
	if caller.falling.is_connected(end_fall):
		caller.falling.disconnect(end_fall)
	if check_hole():
		isFalling = true
		start_fall_tween()
	else:
		isFalling = false

func check_hole() -> bool:
	verticalDetector.position.x = 0
	verticalDetector.position.z = 0
	verticalDetector.force_raycast_update()
	if verticalDetector.is_colliding():
		var distanceToCollision: float = verticalDetector.global_position.distance_to(verticalDetector.get_collision_point())
		distanceToCollision -= verticalDetector.position.y
		if distanceToCollision < 0.1:
			var object = verticalDetector.get_collider()
			if object is PushableBlock:
				object.falling.connect(end_fall)
			return false
		else:
			fallDistance =  snappedf(distanceToCollision, 0.5) 
			return true
	else:
		fallDistance = abs(verticalDetector.target_position.y)
		return true

func check_state() -> void:
	check_fan_areas()
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

func check_fan_areas() -> void:
	var areasToRemove: Array = []
	for area: Fan in pushingForces:
		if not area.monitorable:
			areasToRemove.append(area)
	for area in areasToRemove:
		stop_pushing(area)

func check_for_collisions() -> bool:
	for direction in actualPushingForces:
		currentDirection = direction
		currentPushDistance = actualPushingForces[direction]
		set_destination()
		# -- pre check --
		blockDetector.target_position = to_local(destination)
		blockDetector.force_raycast_update()
		if blockDetector.is_colliding():
			var collidingBlock: PushableBlock = blockDetector.get_collider()
			var distanceToBlock: int = int(global_position.distance_to(collidingBlock.global_position))
			if distanceToBlock <= 1 and collidingBlock != blockCaller and not collidingBlock.isMoving:
				blockCaller = collidingBlock
				blockCaller.moving.connect(check_movement)
				#prints(name,"connecting to:",blockCaller.name)
				return false
			elif blockCaller != null:
				#prints(name,"disconnecting:",blockCaller.name)
				if blockCaller.moving.is_connected(check_movement):
					blockCaller.moving.disconnect(check_movement)
				blockCaller = null
		# -- Floor detection --
		# gets maximum amount of movement in this direction
		floorDetector.target_position = to_local(destination)
		floorDetector.force_raycast_update()
		if floorDetector.is_colliding():
			var distanceToPoint: int = int(global_position.distance_to(floorDetector.get_collision_point()))
			if distanceToPoint < 1: continue
			currentPushDistance = distanceToPoint
			set_destination()
		# -- Hole Detection --
		# gets every hole and depth in this direction
		var holeCollection: Dictionary[Vector3, float] = {}
		for n in range(currentPushDistance):
			verticalDetector.position.x = currentDirection.x * (n + 1)
			verticalDetector.position.z = currentDirection.z * (n + 1)
			verticalDetector.force_raycast_update()
			if not verticalDetector.is_colliding():
				holeCollection[global_position + Vector3(currentDirection * (n + 1))] = abs(verticalDetector.target_position.y)
			else:
				var distanceToCollision: float = verticalDetector.global_position.distance_to(verticalDetector.get_collision_point())
				distanceToCollision -= verticalDetector.position.y
				if distanceToCollision < 0.1: 
					var object = verticalDetector.get_collider()
					if object is PushableBlock:
						if object.isFalling and object.fallDistance - 1 > 0:
							holeCollection[global_position + Vector3(currentDirection * (n + 1))] = object.fallDistance - 1
					continue
				else:
					holeCollection[global_position + Vector3(currentDirection * (n + 1))] = snappedf(distanceToCollision, 0.5) 
		# -- Block detection --
		if blockDetector.is_colliding():
			var block: PushableBlock = blockDetector.get_collider()
			var distanceToBlock: int = int(global_position.distance_to(block.global_position))
			if block.isMoving:
				if block.isFalling:
					match  block.fallDistance:
						0.5:
							set_destination(block.destination - Vector3(currentDirection))
							holeCollection.clear()
						1.0:
							for posKey in holeCollection:
								if block.destination.distance_to(posKey) < 0.2:
									holeCollection.erase(posKey)
									break
						_:
							for posKey in holeCollection:
								if block.destination.distance_to(posKey) < 0.2:
									holeCollection[posKey] = holeCollection[posKey] - 1
									break
				else:
					if destination.distance_to(block.destination) < 0.2:
						currentPushDistance -= 1
						set_destination()
			else:
				if distanceToBlock <= 1: 
					continue
				else:
					currentPushDistance = distanceToBlock - 1
					set_destination()
		if not holeCollection.is_empty():
			for posKey in holeCollection:
				destination = posKey
				fallDistance = holeCollection[posKey]
				isFalling = true
				break
		return true
	return false

func set_destination(override: Vector3 = global_position + Vector3(currentDirection * currentPushDistance)) -> void:
	destination = override

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
		tempKey = pushingForces.find_key(Vector3i(sumOfForces.x,0,0))
		if tempKey != null:
			add_push(tempKey)
		tempKey = pushingForces.find_key(Vector3i(0,0,sumOfForces.z))
		if tempKey != null:
			add_push(tempKey)
	return true

func add_push(fan: Fan) -> void:
	actualPushingForces[pushingForces[fan]] = int(fan.areaHeight - int(global_position.distance_to(fan.global_position)))

func push(area: Area3D) -> void:
	var direction: Vector3i = Vector3i(area.get_fan_direction())
	if pushingForces.has(area) or direction.y != 0 or direction == Vector3i.ZERO: return
	pushingForces[area] = direction
	check_movement()

func stop_pushing(area: Area3D) -> void:
	pushingForces.erase(area)

func start_wait(time: float = moveTime) -> void:
	waiting = true
	#prints(name,"waiting:",time,"secs ","f:",get_tree().get_frame()) 
	get_tree().create_timer(time).timeout.connect(end_wait)

func end_wait() -> void:
	waiting = false
