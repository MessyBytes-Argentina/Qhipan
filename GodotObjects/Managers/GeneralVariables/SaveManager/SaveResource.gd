extends Resource

## NOTE
## Missing for full save:
##    - Player position storage
##    - Loaded scenes storage
##    - Instance save
##    - Instance load
##    - Packaging and encrypting save

## Handles storing and loading changes.
class_name SaveResource

## Enum for sticker types.
enum StickerTypes {ALTERNATOR, FAN, KEY, LAMP}

## Current scene changes.
var sceneChanges: Dictionary[String, SceneSave] = {}
## Current environment changes.
var environmentChange: EnvironmentParameters = EnvironmentParameters.new()
## Current sun changes.
var lightChange: LightParameters = LightParameters.new()

## Local class for sticker saves.
class StickerSave:
	## [NodePath] to sticker.
	var nodePath: NodePath
	## Sticker type.
	var stickerType: StickerTypes
	## Local sticker position.
	var position: Vector3
	## Is the sticker placed.
	var placed: bool = false
	
	## Main setup of class.
	func _init(changedSticker: StickerBase) -> void:
		nodePath = changedSticker.originalParentPath
		placed = changedSticker.placed
		position = changedSticker.position
		if changedSticker is AlternatorSticker: stickerType = StickerTypes.ALTERNATOR
		if changedSticker is FanSticker: stickerType = StickerTypes.FAN
		if changedSticker is KeySticker: stickerType = StickerTypes.KEY
		if changedSticker is LampSticker: stickerType = StickerTypes.LAMP

## Local class for pedestal saves.
class PedestalSave:
	## [NodePath] to pedestal.
	var nodePath: NodePath
	## Sticker stuck to pedestal if any.
	var sticker: PocketSticker
	
	## Main setup of class.
	func _init(changedPedestal: Node) -> void:
		nodePath = changedPedestal.get_path().slice(1)
		if changedPedestal is InventoryPedestal:
			sticker = changedPedestal.sticker

## Local class for scene saves.
class SceneSave:
	## Sticker modifications.
	var stickerModifications: Dictionary[int, StickerSave] = {}
	## Deleted stickers.
	var removedStickers: Array[NodePath] = []
	## Deleted inventory stickers.
	var removedInventoryStickers: Array[NodePath] = []
	## Activated pedestals.
	var activePedestals: Array[PedestalSave] = []
	## Permanently open doors.
	var openDoors: Array[NodePath] = []
	## Object hiders status.
	var objectHiders: Dictionary[NodePath, bool] = {}

## Stores change in current save.
func store_change(changedObject: Node, sceneParent: Node) -> void:
	var currentScene: SceneSave
	if sceneChanges.has(sceneParent.name): currentScene = sceneChanges[sceneParent.name]
	else:
		currentScene = SceneSave.new()
		sceneChanges[sceneParent.name] = currentScene
	if changedObject is StickerBase: save_sticker(currentScene, changedObject); return
	if changedObject is InventoryPedestal or changedObject is SmallPedestal: currentScene.activePedestals.append(PedestalSave.new(changedObject)); return
	if changedObject is PushDoor: currentScene.openDoors.append(changedObject.get_path().slice(1)); return
	if changedObject is ObjectHider: currentScene.objectHiders[changedObject.get_path().slice(1)] = changedObject.isActive; return

## Stores environment changes.
func store_environment(environment: EnvironmentParameters, light: LightParameters) -> void:
	environmentChange = environment
	lightChange = light

## Stores sticker changes.
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

## Stores inventry sticker removal.
func delete_inventory_sticker(sticker: InventorySticker) -> void:
	var currentScene: SceneSave
	if sceneChanges.has(sticker.sceneParent.name): currentScene = sceneChanges[sticker.sceneParent.name]
	else:
		currentScene = SceneSave.new()
		sceneChanges[sticker.sceneParent.name] = currentScene
	sceneChanges[sticker.sceneParent.name].removedInventoryStickers.append(NodePath(sticker.originalParentPath))

## Stores sticker removal.
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

## Loads changes to a scene.
func load_changes(scene: Node, loadEnvironment: bool = false) -> void:
	if not sceneChanges.has(scene.name): return
	var currentSave: SceneSave = sceneChanges[scene.name]
	for hider in currentSave.objectHiders:
		GeneralVariables.get_tree().root.get_node(hider).restore_save(currentSave.objectHiders[hider])
	for sticker in currentSave.removedStickers:
		GeneralVariables.get_tree().root.get_node(sticker).queue_free()
	for sticker in currentSave.removedInventoryStickers:
		GeneralVariables.get_tree().root.get_node(sticker).queue_free()
	for pedestal in currentSave.activePedestals:
		var pedestalNode: Node = GeneralVariables.get_tree().root.get_node(pedestal.nodePath)
		if pedestalNode is InventoryPedestal:
			pedestalNode.sticker = pedestal.sticker
		pedestalNode.activate_pedestal(true)
	for door in currentSave.openDoors:
		var doorNode: PushDoor = GeneralVariables.get_tree().root.get_node(door)
		doorNode.open_door(false)
	for sticker in currentSave.stickerModifications:
		new_sticker(sticker, currentSave.stickerModifications[sticker], scene)
	if loadEnvironment:
		var environmentObjects: EnvironmentObjects = GeneralVariables.get_tree().get_first_node_in_group("EnvironmentObjects")
		environmentChange.set_environment(environmentObjects.environment.environment, environmentObjects.colorCorrectionMaterial)
		lightChange.set_sun(environmentObjects.sun)

## Creates sticker changes storage.
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

## Resets a scene save.
func reset_saved_scene(sceneName: String, toReset: Array[String] = ["stickerModifications", "removedStickers", "openDoors", "objectHiders"]) -> void:
	if not sceneChanges.has(sceneName): return
	for param in toReset: sceneChanges[sceneName][param].clear()
