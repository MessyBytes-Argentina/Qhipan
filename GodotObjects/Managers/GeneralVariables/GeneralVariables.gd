extends Node
## Handles general variables that are required more than once throught the game.

## Signals when input mode has been changed.
signal input_mode_changed(isGamepad: bool)

## Reference to the cutout materials [ResourceGroup].
const materialsResourceGroup: String = "uid://b0jco1ngdo5fe"
## Threshold to consider the mouse movement into inputs.
const MOUSEMOVEMENTTHRESHOLD: float = 15

## Is the player using a gamepad.
var usingGamepad: bool = false
## The collection of materials that have a cutout mode.
var cutoutMaterials: Array[ShaderMaterial] = []
## The Sticker inventory.
var inventory: StickerInventory

## Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var materials: ResourceGroup = load(materialsResourceGroup)
	materials.load_all_into(cutoutMaterials)
	inventory = StickerInventory.new()
	inventory.name = "Inventory"
	add_child(inventory)

## Handles switching input modes from keyboard to gamepad.
func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion: if event.relative.length() < MOUSEMOVEMENTTHRESHOLD: return
	var currentlyGamepad: bool = event is InputEventJoypadButton or event is InputEventJoypadMotion
	if usingGamepad != currentlyGamepad:
		usingGamepad = currentlyGamepad
		input_mode_changed.emit(usingGamepad)
