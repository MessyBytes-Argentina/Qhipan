extends StickerBase

const REMOVETIMER: float = 0.2

@onready var heldAreaChecker: Area3D = %HeldAreaChecker
@onready var pivot: Node3D = %Pivot

var objectCollection: Array = []

var stickerPlaced: bool = false
var activatedGroups: Array[AlternatingGroup]

func add_alternating_object(obj: AlternatingObject) -> void:
	if stickerPlaced: return
	if objectCollection.has(obj): return
	if obj is AlternatingObject:
		objectCollection.append(obj)
		switch_object(obj)

func remove_alternating_object(obj) -> void:
	if stickerPlaced: return
	if objectCollection.has(obj): objectCollection.erase(obj)
	switch_object(obj)

func switch_object(obj) -> void:
	if stickerPlaced: return
	obj.switch_state()

func activate_group(objList: Array[Node3D]) -> void:
	var groupsToActivate: Array[AlternatingGroup] = []
	for obj in objList:
		if not groupsToActivate.has(obj.groupParent):
			groupsToActivate.append(obj.groupParent)
	activatedGroups = groupsToActivate
	for group in groupsToActivate:
		group.switch_children(objectCollection)
	objectCollection.clear()

func deactivate_group() -> void:
	for group: AlternatingGroup in activatedGroups:
		for obj in group.altChildren:
			remove_alternating_object(obj)
	var objectsInRange: Array[Node3D] = await force_area_check(false)
	add_obj_list(objectsInRange)
	enable_area()

func place_sticker(area: Area3D, direction: Vector3, isPlaceholderArea: bool = false) -> void:
	stickerPlaced = true
	disable_area()
	super(area,direction,isPlaceholderArea)
	var objectsInRange: Array[Node3D] = await force_area_check(true)
	activate_group(objectsInRange)

func grab(node: Node3D) -> void:
	super(node)
	if stickerPlaced: 
		stickerPlaced = false
		deactivate_group()
		return
	enable_area()
	add_obj_list(await force_area_check(false))

func drop() -> void:
	super()
	disable_area()
	stickerPlaced = false
	for obj in objectCollection:
		remove_alternating_object(obj)

func force_area_check(checkAreas:bool) -> Array[Node3D]:
	heldAreaChecker.monitoring = true
	await get_tree().physics_frame
	await get_tree().physics_frame
	var objList: Array[Node3D] = heldAreaChecker.get_overlapping_bodies()
	if checkAreas: objList.append_array(heldAreaChecker.get_overlapping_areas())
	return objList
#
func add_obj_list(objList: Array[Node3D]) -> void:
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
	heldAreaChecker.body_entered.disconnect(add_alternating_object)
	heldAreaChecker.body_exited.disconnect(remove_alternating_object)
