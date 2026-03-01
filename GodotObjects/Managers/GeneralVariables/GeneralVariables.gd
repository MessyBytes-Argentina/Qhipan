extends Node
## Handles general variables that are required more than once throught the game.

## Signals when input mode has been changed.
signal input_mode_changed(isGamepad: bool)
## Signals that the game state changed.
signal new_gamestate(playing: bool)

## Reference to the cutout materials [ResourceGroup].
const materialsResourceGroup: String = "uid://b0jco1ngdo5fe"
## Threshold to consider the mouse movement into inputs.
const MOUSEMOVEMENTTHRESHOLD: float = 15
## Root nodes to ignore for root tagging.
const IGNOREROOTNODES: PackedStringArray = ["EnvironmentObjects", "Player"]
## Maximimum frames for stagger.
const FRAMESTAGGERMAX: int = 60
## Stagger wait time.
const STAGGERWAIT: float = 0.1

## Reference to the scene manager if it's loaded.
var sceneManager: SceneManager
## Is the player using a gamepad.
var usingGamepad: bool = false
## The collection of standard cutout materials.
var standardCutoutMaterials: Array[ShaderMaterial] = []
## The collection of materials that have a cutout mode in queue.
var queueCutoutMaterials: Array[Dictionary] = []
## The collection of materials that have a cutout mode.
var cutoutMaterials: Array[ShaderMaterial] = []
## Cutout Stagger Timer.
var cutoutStaggerTimer: SceneTreeTimer
## Non duplicate cutout materials.
var uniqueCutoutMaterials: Array[ShaderMaterial] = []
## The Sticker inventory.
var inventory: StickerInventory
## The Stickerable Surface Manager.
var stickerableSurfacesManager: StickerableSurfacesManager
## The save manager.
var saveManager: SaveManager
## The queue of functions to stagger.
var toStagger: Array[Callable] = []
## Stagger Timer.
var staggerTimer: SceneTreeTimer
## Stagger flag.
var staggerFlag: bool = false

## Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var materials: ResourceGroup = load(materialsResourceGroup)
	materials.load_all_into(standardCutoutMaterials)
	cutoutMaterials = standardCutoutMaterials.duplicate()
	inventory = StickerInventory.new()
	inventory.name = "Inventory"
	add_child(inventory)
	stickerableSurfacesManager = StickerableSurfacesManager.new()
	stickerableSurfacesManager.name = "StickerableSurfacesManager"
	add_child(stickerableSurfacesManager)
	saveManager = SaveManager.new()
	saveManager.name = "SaveManager"
	add_child(saveManager)
	tag_first_scene()

## Tags first loaded scene with meta tag for scene roots.
func tag_first_scene() -> void:
	await get_tree().process_frame
	if get_parent().get_children().any(func(a: Node): return a is SceneManager):
		return
	for node in get_parent().get_children():
		if node is Node3D:
			for child in node.get_children():
				if child is Node3D and child.name not in IGNOREROOTNODES:
					child.set_meta("isRoot", true)

## Handles switching input modes from keyboard to gamepad.
func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion: if event.relative.length() < MOUSEMOVEMENTTHRESHOLD: return
	var currentlyGamepad: bool = event is InputEventJoypadButton or event is InputEventJoypadMotion
	if usingGamepad != currentlyGamepad:
		usingGamepad = currentlyGamepad
		input_mode_changed.emit(usingGamepad)

## Adds material to cutout list queue.
func queue_to_cutout_materials(materials: Array[ShaderMaterial], doAdd: bool) -> void:
	queueCutoutMaterials.append({"materials": materials, "doAdd": doAdd})
	if cutoutStaggerTimer: return
	cutoutStaggerTimer = get_tree().create_timer(0.5)
	cutoutStaggerTimer.timeout.connect(do_cutout_materials_queue)

## Executes cutout material queue.
func do_cutout_materials_queue() -> void:
	if cutoutStaggerTimer: staggerTimer = null
	while staggerFlag: await get_tree().process_frame
	for queuedCall in queueCutoutMaterials: _to_cutout_materials(queuedCall.materials, queuedCall.doAdd)
	queueCutoutMaterials.clear()
	make_unique_cutout_materials()

## Adds material to cutout list.
func _to_cutout_materials(materials: Array[ShaderMaterial], doAdd: bool) -> void:
	if doAdd: cutoutMaterials.append_array(materials)
	else: for material in materials: cutoutMaterials.erase(material)

## Makes a list with unique cutout materials.
func make_unique_cutout_materials() -> void:
	uniqueCutoutMaterials = standardCutoutMaterials.duplicate()
	for material in cutoutMaterials: if material not in uniqueCutoutMaterials: uniqueCutoutMaterials.append(material)

## Staggers function calls by frames.
func add_to_stagger_queue(callable: Callable) -> void:
	toStagger.append(callable)
	if staggerTimer: return
	staggerTimer = get_tree().create_timer(0.1)
	staggerTimer.timeout.connect(_execute_queue)
	staggerFlag = true

## Does the queue stagger.
func _execute_queue() -> void:
	if staggerTimer: staggerTimer = null
	var staggerArray: Array[Array] = []
	while len(toStagger) > FRAMESTAGGERMAX:
		staggerArray.append(toStagger.slice(0, FRAMESTAGGERMAX))
		toStagger.reverse()
		toStagger.resize(len(toStagger) - FRAMESTAGGERMAX)
		toStagger.reverse()
	staggerArray.append(toStagger.duplicate())
	toStagger.clear()
	for i in range(len(staggerArray[0])):
		for j in range(len(staggerArray)):
			if len(staggerArray[j]) > i:
				if not staggerArray[j][i]: continue
				if not staggerArray[j][i].get_object(): continue
				staggerArray[j][i].call()
		await get_tree().process_frame
	staggerFlag = false
