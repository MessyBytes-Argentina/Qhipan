@tool
extends StickerBase
## Alternator sticker class
class_name AlternatorSticker

## Area that checks for alternating objets when held
@onready var heldAreaChecker: Area3D = %HeldAreaChecker
## Pivot node reference for placement
@onready var pivot: Node3D = %Pivot
## Held effect when grabbed
@onready var heldEffect: MeshInstance3D = %HeldEffect

## List of alternating objects currently in range when held
var objectCollection: Array = []
## List of alternating groups activated when placed
var activatedGroups: Array[AlternatingGroup]
## Flag that turns on when disabling the held area
var disablingArea: bool = false

## Adds an alternating object to the list and switches it's state
func add_alternating_object(obj) -> void:
	if placed: return
	if objectCollection.has(obj): return
	if obj is AlternatingObject or obj is MovingPlatform:
		objectCollection.append(obj)
		switch_object(obj)

## Removes an alternating object from the list and switches it's state
func remove_alternating_object(obj) -> void:
	if disablingArea: return
	if objectCollection.has(obj): objectCollection.erase(obj)
	switch_object(obj)

## Empties the list of alternating objects
func clear_alternating_objects() -> void:
	for obj in objectCollection:
		switch_object(obj)
	objectCollection.clear()

## Switches the state of the given object
func switch_object(obj) -> void:
	obj.switch_state()

## Checks for alternating objects not on the activating groups and switches them
func check_out_of_group(groups: Array) -> void:
	for obj in objectCollection:
		if not groups.has(obj.groupParent): switch_object(obj)

## Places the sticker, disables the held area and clears the list of objects
func place_sticker(pos: Vector3, direction: Vector3, overrideSize: Vector3 = Vector3.ONE, _specialFlags: int = 0) -> void:
	disablingArea = true
	disable_area()
	super(pos, direction, overrideSize)
	disablingArea = false
	clear_alternating_objects()

## Places the sticker on the player and enables the held area
func grab(node: Node3D) -> void:
	super(node)
	if placed and not activatedGroups.is_empty(): return
	enable_area()
	add_obj_list(await force_area_check())

## Drops the sticker and disables the held area and clears the list of objects
func drop() -> void:
	super()
	disable_area()
	placed = false
	clear_alternating_objects()

## Returns a list of alternating bodies in range
func force_area_check() -> Array:
	heldAreaChecker.monitoring = true
	await get_tree().physics_frame
	await get_tree().physics_frame
	var objList: Array = heldAreaChecker.get_overlapping_bodies()
	return objList

## Adds the given list of objects to the objectCollection and switches them
func add_obj_list(objList: Array) -> void:
	for obj in objList:
		add_alternating_object(obj)

## Positions the cheking areas in the correct position
func set_size(mode: ScaleModes) -> void:
	super(mode)
	match mode:
		ScaleModes.GRABBED:
			pivot.top_level = false
		_:
			pivot.top_level = true
	await get_tree().physics_frame
	pivot.global_position = global_position

## Enables the heldAreaChecker
func enable_area() -> void:
	heldAreaChecker.position.y = -GRABHEIGHT
	heldEffect.show()
	heldAreaChecker.monitoring = true
	heldAreaChecker.monitorable = true
	heldAreaChecker.body_entered.connect(add_alternating_object)
	heldAreaChecker.body_exited.connect(remove_alternating_object)

## Disables the heldAreaChecker
func disable_area() -> void:
	heldEffect.hide()
	heldAreaChecker.monitoring = false
	heldAreaChecker.monitorable = false
	if heldAreaChecker.body_entered.is_connected(add_alternating_object):
		heldAreaChecker.body_entered.disconnect(add_alternating_object)
	if heldAreaChecker.body_exited.is_connected(remove_alternating_object):
		heldAreaChecker.body_exited.disconnect(remove_alternating_object)

## Deprecated group activation
#func activate_group(objList: Array) -> void:
	#activatedGroups.clear()
	#var groupsToActivate: Array[AlternatingGroup] = []
	#for obj in objList:
		#if not groupsToActivate.has(obj.groupParent):
			#groupsToActivate.append(obj.groupParent)
	#activatedGroups = groupsToActivate
	#for group in groupsToActivate:
		#group.switch_children(objectCollection)
	#check_out_of_group(groupsToActivate)
	#objectCollection.clear()

## Deprecated group deactivation
#func deactivate_group() -> void:
	#var objectsInRange: Array = await force_area_check()
	#for group: AlternatingGroup in activatedGroups:
		#group.switch_children(objectsInRange)
	#objectCollection.append_array(objectsInRange)
	#enable_area()
