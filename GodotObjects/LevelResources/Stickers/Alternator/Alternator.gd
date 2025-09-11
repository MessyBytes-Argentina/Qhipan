extends StickerBase

@onready var heldAreaChecker: Area3D = %HeldAreaChecker

var objectCollection: Array[AlternatingObject] = []
var removalQueue: Array[AlternatingObject] = []

var stickerPlaced: bool = false
var activatedGroups: Array[AlternatingGroup]

func _ready() -> void:
	super()
	heldAreaChecker.body_entered.connect(add_alternating_object)
	heldAreaChecker.body_exited.connect(remove_alternating_object)

func add_alternating_object(obj: AlternatingObject) -> void:
	if objectCollection.has(obj): return
	objectCollection.append(obj)
	switch_object(obj)

func remove_alternating_object(obj: AlternatingObject) -> void:
	if removalQueue.has(obj): return
	removalQueue.append(obj)
	await get_tree().create_timer(0.1).timeout
	if not removalQueue.has(obj): return
	if heldAreaChecker.monitoring:
		if heldAreaChecker.get_overlapping_bodies().has(obj): 
			removalQueue.erase(obj)
			return
	removalQueue.erase(obj)
	objectCollection.erase(obj)
	prints(obj.name," removed")
	switch_object(obj)

func switch_object(obj: AlternatingObject) -> void:
	if stickerPlaced: return
	prints(obj.name," switched")
	obj.switch_state()

func switch_group() -> void:
	force_area_check()
	var groupsToActivate: Array[AlternatingGroup] = []
	for obj in objectCollection:
		if not groupsToActivate.has(obj.groupParent):
			groupsToActivate.append(obj.groupParent)
	activatedGroups = groupsToActivate
	for group in groupsToActivate:
		group.switch_children(objectCollection)


func force_area_check() -> void:
	objectCollection.clear()
	await get_tree().create_timer(0.1).timeout
	var altObjects: Array = heldAreaChecker.get_overlapping_bodies()
	for obj in altObjects:
		add_alternating_object(obj)

func place_sticker(area: Area3D, direction: Vector3, isPlaceholderArea: bool = false) -> void:
	stickerPlaced = true
	super(area,direction,isPlaceholderArea)
	prints(objectCollection,"||",removalQueue)
	for obj in objectCollection:
		if removalQueue.has(obj):
			removalQueue.erase(obj)
	switch_group()

func grab(node: Node3D) -> void:
	super(node)
	heldAreaChecker.monitoring = true
	if stickerPlaced: 
		switch_group()
	else:
		force_area_check()
	stickerPlaced = false

func drop() -> void:
	super()
	heldAreaChecker.monitoring = false
	stickerPlaced = false
	for obj in objectCollection:
		remove_alternating_object(obj)
