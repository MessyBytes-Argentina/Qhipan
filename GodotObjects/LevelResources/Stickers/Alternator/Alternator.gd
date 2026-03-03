@tool
extends StickerBase
## Alternator sticker class
class_name AlternatorSticker

## Area that checks for alternating objets when held
@onready var heldAreaChecker: Area3D = %HeldAreaChecker

## Reference to the player.
var player: Player
## List of alternating objects currently in range when held
var objectCollection: Array = []
## List of alternating groups activated when placed
var activatedGroups: Array[AlternatingGroup]
## Flag that turns on when disabling the held area
var disablingArea: bool = false

## Executed when node enters scene tree.
func _ready() -> void:
	super()
	player = get_tree().get_first_node_in_group("Player")

## Adds an alternating object to the list and switches it's state
func add_alternating_object(obj: Node) -> void:
	if placed: return
	if objectCollection.has(obj): return
	if obj is Area3D:
		obj = obj.get_parent()
	if obj is AlternatingObject or obj is MovingPlatform:
		objectCollection.append(obj)
		obj.switch_state()

## Removes an alternating object from the list and switches it's state
func remove_alternating_object(obj: Node) -> void:
	if disablingArea: return
	if obj is Area3D:
		obj = obj.get_parent()
	if objectCollection.has(obj): objectCollection.erase(obj)
	obj.switch_state()

## Empties the list of alternating objects
func clear_alternating_objects() -> void:
	for obj in objectCollection:
		obj.switch_state()
	objectCollection.clear()

## Checks for alternating objects not on the activating groups and switches them
func check_out_of_group(groups: Array) -> void:
	for obj in objectCollection:
		if not groups.has(obj.groupParent): obj.switch_object()

## Places the sticker, disables the held area and clears the list of objects
func place_sticker(pos: Vector3, direction: Vector3, overrideSize: Vector3 = Vector3.ONE, _specialFlags: int = 0, _extraParameters: Dictionary = {}) -> void:
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

## Enables the heldAreaChecker
func enable_area() -> void:
	player.alternatorHeldEffect.show()
	heldAreaChecker.set_deferred("monitoring", true)
	heldAreaChecker.set_deferred("monitorable", true)
	heldAreaChecker.body_entered.connect(add_alternating_object)
	heldAreaChecker.body_exited.connect(remove_alternating_object)
	heldAreaChecker.area_entered.connect(add_alternating_object)
	heldAreaChecker.area_exited.connect(remove_alternating_object)

## Disables the heldAreaChecker
func disable_area() -> void:
	player.alternatorHeldEffect.hide()
	heldAreaChecker.set_deferred("monitoring", false)
	heldAreaChecker.set_deferred("monitorable", false)
	if heldAreaChecker.body_entered.is_connected(add_alternating_object):
		heldAreaChecker.body_entered.disconnect(add_alternating_object)
	if heldAreaChecker.body_exited.is_connected(remove_alternating_object):
		heldAreaChecker.body_exited.disconnect(remove_alternating_object)
	if heldAreaChecker.area_entered.is_connected(add_alternating_object):
		heldAreaChecker.area_entered.disconnect(add_alternating_object)
	if heldAreaChecker.area_exited.is_connected(remove_alternating_object):
		heldAreaChecker.area_exited.disconnect(remove_alternating_object)

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
