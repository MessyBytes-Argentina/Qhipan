extends Node
## Handles general variables that are required more than once throught the game.

## Signals when input mode has been changed.
signal input_mode_changed(isGamepad: bool)

## Reference to the cutout materials [ResourceGroup].
const materialsResourceGroup: String = "uid://b0jco1ngdo5fe"
## Threshold to consider the mouse movement into inputs.
const MOUSEMOVEMENTTHRESHOLD: float = 15
## Root nodes to ignore for root tagging.
const IGNOREROOTNODES: PackedStringArray = ["EnvironmentObjects", "Player"]
## Maximimum frames for stagger
const FRAMESTAGGERMAX: int = 60

## Is the player using a gamepad.
var usingGamepad: bool = false
## The collection of materials that have a cutout mode.
var cutoutMaterials: Array[ShaderMaterial] = []
## The Sticker inventory.
var inventory: StickerInventory
## The Stickerable Surface Manager
var stickerableSurfacesManager: StickerableSurfacesManager
## The save manager
var saveManager: SaveManager

## Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var materials: ResourceGroup = load(materialsResourceGroup)
	materials.load_all_into(cutoutMaterials)
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
