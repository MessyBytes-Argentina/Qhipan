extends AnimatableBody3D
class_name PushableBlock

## Reference to the FanChecker Area3D
@onready var fanChecker: Area3D = $FanChecker
## Reference to the BlockDetector RayCast3D
@onready var blockDetector: RayCast3D = $BlockDetector
## Reference to the FloorDetector RayCast3D
@onready var floorDetector: RayCast3D = $FloorDetector
## Reference to the VerticalDetector RayCast3D
@onready var verticalDetector: RayCast3D = $VerticalDetector
## Reference to the LeylineArea Checker
@onready var leyLineChecker: Area3D = $LeylineChecker

## Time it takes a block to move 1 unit of distance
const moveTime: float = 0.2
## Time it takes a block to fall 1 unit of distance
const fallTime: float = 0.1

## Reference to the tween for moving
var moveTween: Tween
## Reference to the tween for falling
var fallTween: Tween
## Flag that turns true when moving
var isMoving: bool = false
## Flag that turns true when the
var isFalling: bool = false
## Reference to the Fan node that is pushing the block
var pushingFanNode: Fan = null
## Direction in wich the fan is pushing
var pushingFanDirection: Vector3i = Vector3i.ZERO
## Int that stores the distance a block is has to move
var currentPushDistance: int = 0
## Float that stores the amount of distance the block has to fall
var fallDistance: float = 0
## Vector3 that stores the global coordinates for the destiantion of movement
var destination: Vector3
## Flag that stops movement checks when true
var waiting: bool = true
## Reference to other pushable blocks to disconnect signals
var blockCaller: PushableBlock = null
## Flag that turns true when a LeylineArea is detected
var onLeylineArea: bool = false
## Reference to the LeylineArea node (if the block is on top of one)
var leylineAreaNode: LeylineCubeCheck = null

## Emitted at the start of movement
signal moving
## Emitted at the start of a fall
signal falling

## Called when the node enters the scene tree for the first time.
func _ready() -> void:
	start_wait()
	end_fall(true)

## Checks for leylineAreas when called
func check_leylines() -> void:
	var leylines: Array[Area3D] = leyLineChecker.get_overlapping_areas()
	if leylines.is_empty(): return
	onLeylineArea = true
	leylineAreaNode = leylines[0]
	leylineAreaNode.alternating_cube_finished_moving()

## Starts the move tween when called and emits the moving signal
func start_move_tween() -> void:
	if moveTween: if moveTween.is_running(): moveTween.kill()
	disconnect_move_signals()
	#prints(name,"to:",destination,"d:",moveTime * currentPushDistance,"is falling:",isFalling,"f:",get_tree().get_frame())
	isMoving = true
	emit_signal("moving")
	if onLeylineArea:
		onLeylineArea = false
		leylineAreaNode.alternating_cube_left()
		leylineAreaNode = null
	moveTween = create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	moveTween.tween_property(self, "global_position:x", destination.x, moveTime * currentPushDistance)
	moveTween.parallel().tween_property(self, "global_position:z", destination.z, moveTime * currentPushDistance)
	moveTween.finished.connect(check_state)
	moveTween.finished.connect(check_leylines)

## Starts the check for movement when called
func check_movement(waitFlag: bool = false) -> void:
	if pushingFanNode == null: return
	if waiting: return
	if isFalling: return
	if isMoving: return
	if waitFlag:
		await get_tree().create_timer(fallTime).timeout
	check_state()

## Checks the current state of the block to fall or move when called
func check_state() -> void:
	check_pushing_fan()
	if isFalling:
		start_fall_tween()
		return
	if pushingFanNode == null:
		isMoving = false
		return
	isMoving = false
	if check_for_collisions():
		start_move_tween()

## Checks if the pushing fan is disabled to remove it when called
func check_pushing_fan() -> void:
	if pushingFanNode != null:
		if not pushingFanNode.monitorable:
			stop_pushing(pushingFanNode)

## Returns true when movement is possible, false when not
## and connects corresponding signal when needed
func check_for_collisions() -> bool:
	currentPushDistance = int(pushingFanNode.areaHeight - int(global_position.distance_to(pushingFanNode.global_position)))
	set_destination()
	blockDetector.target_position = to_local(destination)
	blockDetector.force_raycast_update()
	# -- Block pre check --
	# check for blocks to connect signals when needed
	if blockDetector.is_colliding():
		var collidingBlock: PushableBlock = blockDetector.get_collider()
		var distanceToBlock: int = int(global_position.distance_to(collidingBlock.global_position))
		if distanceToBlock <= 1: 
			if collidingBlock.global_position.distance_to(collidingBlock.destination) <= 0.1 or not collidingBlock.isMoving:
				disconnect_move_signals()
				blockCaller = collidingBlock
				if collidingBlock.isFalling:
					blockCaller.falling.connect(check_movement.bind(true))
				else:
					blockCaller.moving.connect(check_movement)
				return false
	# -- Floor detection --
	# gets maximum amount of movement in this direction
	floorDetector.target_position = to_local(destination)
	floorDetector.force_raycast_update()
	if floorDetector.is_colliding():
		var distanceToPoint: int = int(global_position.distance_to(floorDetector.get_collision_point()))
		if distanceToPoint < 1: return false
		currentPushDistance = distanceToPoint
		set_destination()
	# -- Hole Detection --
	# gets every hole and depth in this direction
	var holeCollection: Dictionary[Vector3, float] = {}
	for n in range(currentPushDistance):
		verticalDetector.position.x = pushingFanDirection.x * (n + 1)
		verticalDetector.position.z = pushingFanDirection.z * (n + 1)
		verticalDetector.force_raycast_update()
		if not verticalDetector.is_colliding():
			holeCollection[global_position + Vector3(pushingFanDirection * (n + 1))] = abs(verticalDetector.target_position.y)
		else:
			var distanceToCollision: float = verticalDetector.global_position.distance_to(verticalDetector.get_collision_point())
			distanceToCollision -= verticalDetector.position.y
			if distanceToCollision < 0.1: 
				var object = verticalDetector.get_collider()
				if object is PushableBlock:
					if object.isFalling and object.fallDistance - 1 > 0:
						holeCollection[global_position + Vector3(pushingFanDirection * (n + 1))] = object.fallDistance - 1
				continue
			else:
				holeCollection[global_position + Vector3(pushingFanDirection * (n + 1))] = snappedf(distanceToCollision, 0.5) 
	# -- Block detection --
	# adjust the distance the block can move when detecting other blocks
	if blockDetector.is_colliding():
		var block: PushableBlock = blockDetector.get_collider()
		var distanceToBlock: int = int(global_position.distance_to(block.global_position))
		if block.isMoving:
			if block.isFalling:
				if distanceToBlock == 1:
					set_destination(block.destination - Vector3(pushingFanDirection))
					currentPushDistance = block.currentPushDistance
					return true
				match  block.fallDistance:
					0.5:
						set_destination(block.destination - Vector3(pushingFanDirection))
						currentPushDistance = block.currentPushDistance
						return true
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
				return false
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

## Sets destination to the given value or default if not given one
func set_destination(override: Vector3 = global_position + Vector3(pushingFanDirection * currentPushDistance)) -> void:
	destination = override

## Starts the fall tween and emits the falling signal
func start_fall_tween() -> void:
	if fallTween: if fallTween.is_running(): fallTween.kill()
	#prints(name,"falling :",fallDistance,"f:",get_tree().get_frame())
	disconnect_fall_signals()
	isMoving = false
	emit_signal("falling")
	fallTween = create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	fallTween.tween_property(self, "global_position:y", global_position.y - fallDistance, fallTime * fallDistance)
	fallTween.finished.connect(end_fall)

## Called at the end of a fall to check for more movement
func end_fall(waitFlag: bool = false) -> void:
	if waitFlag:
		await get_tree().create_timer(moveTime).timeout
	if check_falling():
		isFalling = true
		start_fall_tween()
	else:
		isFalling = false
		check_leylines()
		check_movement()

## Returns true when it detects it can fall,
## returns false when it can't and connects signals when detecting a block
func check_falling() -> bool:
	verticalDetector.position.x = 0
	verticalDetector.position.z = 0
	verticalDetector.force_raycast_update()
	if verticalDetector.is_colliding():
		var distanceToCollision: float = verticalDetector.global_position.distance_to(verticalDetector.get_collision_point())
		distanceToCollision -= verticalDetector.position.y
		if distanceToCollision < 0.1:
			disconnect_fall_signals()
			var object = verticalDetector.get_collider()
			if object is PushableBlock:
				if not object.isMoving and not object.isFalling:
					object.falling.connect(end_fall)
					object.moving.connect(end_fall.bind(true))
				else:
					if object.isMoving:
						get_tree().create_timer(moveTime).timeout.connect(end_fall)
					else:
						get_tree().create_timer(fallTime).timeout.connect(end_fall)
				blockCaller = object
			return false
		else:
			fallDistance =  snappedf(distanceToCollision, 0.5) 
			return true
	else:
		fallDistance = abs(verticalDetector.target_position.y)
		return true

## Sets the pushing fan when receiving the area_entered signal
func push(area: Area3D) -> void:
	var direction: Vector3i = Vector3i(area.get_fan_direction())
	if pushingFanNode == area or direction.y != 0 or direction == Vector3i.ZERO: return
	pushingFanNode = area
	pushingFanDirection = direction
	check_movement()

## Removes the pushing fan when receiving the area_exited signal
func stop_pushing(area: Area3D) -> void:
	if area == pushingFanNode:
		set_pushing_fan(null, Vector3i.ZERO)

## Sets the pushingFanNode and pushingFanDirection with the given variables
func set_pushing_fan(fan:Fan, direction:Vector3i) -> void:
	pushingFanNode = fan
	pushingFanDirection = direction

## Disconnects signals from the check_movement function if possible
func disconnect_move_signals() -> void:
	if blockCaller != null:
		if blockCaller.moving.is_connected(check_movement):
			blockCaller.moving.disconnect(check_movement)
		if blockCaller.falling.is_connected(check_movement):
			blockCaller.falling.disconnect(check_movement)
		blockCaller = null

## Disconnects signals from the end_fall function if possible
func disconnect_fall_signals() -> void:
	if blockCaller != null:
		if blockCaller.falling.is_connected(end_fall):
			blockCaller.falling.disconnect(end_fall)
		if blockCaller.moving.is_connected(end_fall):
			blockCaller.moving.disconnect(end_fall)
		blockCaller = null

## Sets the waiting flag to true and starts a timer to call end_wait at the end
func start_wait(time: float = moveTime) -> void:
	waiting = true
	get_tree().create_timer(time).timeout.connect(end_wait)

## Sets the waiting flag to false when called
func end_wait() -> void:
	waiting = false
