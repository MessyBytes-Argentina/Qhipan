extends StickerBase

const REMOVETIMER: float = 0.2

@onready var heldAreaChecker: Area3D = %HeldAreaChecker
@onready var placedAreaChecker: Area3D = %PlacedAreaChecker
@onready var pivot: Node3D = %Pivot

var objectCollection: Array = []
var activatedGroups: Array[AlternatingGroup]
var disablingArea: bool = false

func add_alternating_object(obj) -> void:
	if placed: return
	if objectCollection.has(obj): return
	if obj is AlternatingObject or obj is MovingPlatform:
		objectCollection.append(obj)
		switch_object(obj)

func remove_alternating_object(obj) -> void:
	if disablingArea: return
	if objectCollection.has(obj): objectCollection.erase(obj)
	switch_object(obj)

func clear_alternating_objects() -> void:
	for obj in objectCollection:
		switch_object(obj)
	objectCollection.clear()

func switch_object(obj) -> void:
	obj.switch_state()

func activate_group(objList: Array) -> void:
	activatedGroups.clear()
	var groupsToActivate: Array[AlternatingGroup] = []
	for obj in objList:
		if not groupsToActivate.has(obj.groupParent):
			groupsToActivate.append(obj.groupParent)
	activatedGroups = groupsToActivate
	for group in groupsToActivate:
		group.switch_children(objectCollection)
	objectCollection.clear()

func deactivate_group() -> void:
	var objectsInRange: Array = await force_area_check(false)
	for group: AlternatingGroup in activatedGroups:
		group.switch_children(objectsInRange)
	objectCollection.append_array(objectsInRange)
	enable_area()

func place_sticker(area: Area3D, direction: Vector3, isPlaceholderArea: bool = false) -> void:
	disablingArea = true
	disable_area()
	super(area,direction,isPlaceholderArea)
	disablingArea = false
	var objectsInRange: Array = await force_area_check(true)
	if objectsInRange.is_empty(): clear_alternating_objects()
	activate_group(objectsInRange)

func grab(node: Node3D) -> void:
	if placed and not activatedGroups.is_empty(): 
		super(node)
		deactivate_group()
		return
	super(node)
	enable_area()
	add_obj_list(await force_area_check(false))

func drop() -> void:
	super()
	disable_area()
	placed = false
	clear_alternating_objects()

func force_area_check(checkAreas:bool) -> Array:
	heldAreaChecker.monitoring = true
	await get_tree().physics_frame
	await get_tree().physics_frame
	var objList: Array = heldAreaChecker.get_overlapping_bodies() if not checkAreas else []
	if checkAreas: objList.append_array(placedAreaChecker.get_overlapping_areas())
	return objList

func add_obj_list(objList: Array) -> void:
	for obj in objList:
		add_alternating_object(obj)

func set_size(mode: ScaleModes) -> void:
	super(mode)
	match mode:
		ScaleModes.GRABBED:
			pivot.top_level = false
		_:
			pivot.top_level = true
	await get_tree().physics_frame
	pivot.global_position = global_position

func enable_area() -> void:
	heldAreaChecker.monitoring = true
	heldAreaChecker.body_entered.connect(add_alternating_object)
	heldAreaChecker.body_exited.connect(remove_alternating_object)

func disable_area() -> void:
	heldAreaChecker.monitoring = false
	if heldAreaChecker.body_entered.is_connected(add_alternating_object):
		heldAreaChecker.body_entered.disconnect(add_alternating_object)
	if heldAreaChecker.body_exited.is_connected(remove_alternating_object):
		heldAreaChecker.body_exited.disconnect(remove_alternating_object)
