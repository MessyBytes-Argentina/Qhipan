extends Resource
class_name SaveResource

enum StickerTypes {ALTERNATOR, FAN, KEY, LAMP}

var sceneChanges: Dictionary[String, SceneSave] = {}

class StickerSave:
	var nodePath: NodePath
	var stickerType: StickerTypes
	var position: Vector3
	var placed: bool = false
	
	func _init(changedSticker: StickerBase) -> void:
		nodePath = changedSticker.originalParentPath
		placed = changedSticker.placed
		position = changedSticker.position
		if changedSticker is AlternatorSticker: stickerType = StickerTypes.ALTERNATOR
		if changedSticker is FanSticker: stickerType = StickerTypes.FAN
		if changedSticker is KeySticker: stickerType = StickerTypes.KEY
		if changedSticker is LampSticker: stickerType = StickerTypes.LAMP

class InventoryPedestalSave:
	var nodePath: NodePath
	var sticker: PocketSticker
	
	func _init(changedPedestal: InventoryPedestal) -> void:
		nodePath = changedPedestal.get_path().slice(1)
		sticker = changedPedestal.sticker

class SceneSave:
	var stickerModifications: Dictionary[int, StickerSave] = {}
	var removedStickers: Array[NodePath]
	var activePedestals: Array[InventoryPedestalSave]
	var openDoors: Array[NodePath]

func store_change(changedObject: Node, sceneParent: Node) -> void:
	var currentScene: SceneSave
	if sceneChanges.has(sceneParent.name): currentScene = sceneChanges[sceneParent.name]
	else:
		currentScene = SceneSave.new()
		sceneChanges[sceneParent.name] = currentScene
	if changedObject is StickerBase: save_sticker(currentScene, changedObject); return
	if changedObject is InventoryPedestal: currentScene.activePedestals.append(InventoryPedestalSave.new(changedObject)); return
	if changedObject is PushDoor: currentScene.openDoors.append(changedObject.get_path().slice(1)); return

func save_sticker(currentScene: SceneSave, sticker: StickerBase) -> void:
	var save: StickerSave = StickerSave.new(sticker)
	if sticker.isSaveCreated:
		for scene in sceneChanges:
			if sceneChanges[scene].stickerModifications.has(sticker.UUID):
				sceneChanges[scene].stickerModifications.erase(sticker.UUID)
	elif not sticker.hasBeenMoved:
		if not sceneChanges.has(sticker.originalParent): sceneChanges[sticker.originalParent] = SceneSave.new()
		sceneChanges[sticker.originalParent].removedStickers.append(save.nodePath)
	currentScene.stickerModifications[sticker.UUID] = save
	sticker.isSaveCreated = true

func delete_inventory_sticker(sticker: InventorySticker) -> void:
	var currentScene: SceneSave
	if sceneChanges.has(sticker.sceneParent.name): currentScene = sceneChanges[sticker.sceneParent.name]
	else:
		currentScene = SceneSave.new()
		sceneChanges[sticker.sceneParent.name] = currentScene
	sceneChanges[sticker.sceneParent.name].removedStickers.append(NodePath(sticker.originalParentPath))
	print(sceneChanges)

func delete_sticker(sticker: StickerBase) -> void:
	var currentScene: SceneSave
	var sceneParent: Node = sticker.sceneParent if sticker.sceneParent else sticker.get_parent()
	if sceneChanges.has(sceneParent.name): currentScene = sceneChanges[sceneParent.name]
	else:
		currentScene = SceneSave.new()
		sceneChanges[sceneParent.name] = currentScene
	if sticker.isSaveCreated:
		for scene in sceneChanges:
			if sceneChanges[scene].stickerModifications.has(sticker.UUID):
				sceneChanges[scene].stickerModifications.erase(sticker.UUID)
	elif not sticker.hasBeenMoved:
		if not sceneChanges.has(sticker.originalParent): sceneChanges[sticker.originalParent] = SceneSave.new()
		if NodePath(sticker.originalParentPath) in sceneChanges[sticker.originalParent].removedStickers: return
		sceneChanges[sticker.originalParent].removedStickers.append(NodePath(sticker.originalParentPath))

func load_changes(scene: Node) -> void:
	if not sceneChanges.has(scene.name): return
	var currentSave: SceneSave = sceneChanges[scene.name]
	for sticker in currentSave.removedStickers:
		print(sticker)
		GeneralVariables.get_tree().root.get_node(sticker).queue_free()
	for sticker in currentSave.stickerModifications:
		new_sticker(sticker, currentSave.stickerModifications[sticker], scene)
	for pedestal in currentSave.activePedestals:
		var pedestalNode: InventoryPedestal = GeneralVariables.get_tree().root.get_node(pedestal.nodePath)
		pedestalNode.sticker = pedestal.sticker
		pedestalNode.activate_pedestal()
	for door in currentSave.openDoors:
		var doorNode: PushDoor = GeneralVariables.get_tree().root.get_node(door)
		doorNode.open_door(false)

func new_sticker(UUID: int, sticker: StickerSave, scene: Node) -> void:
	var newSticker: StickerBase = GeneralVariables.saveManager.stickerBases[StickerTypes.keys()[sticker.stickerType]].instantiate()
	newSticker.placed = sticker.placed
	newSticker.isSaveCreated = true
	newSticker.hasBeenMoved = true
	newSticker.UUID = UUID
	newSticker.originalParentPath = sticker.nodePath
	newSticker.sceneParent = scene
	scene.add_child(newSticker)
	newSticker.position = sticker.position
