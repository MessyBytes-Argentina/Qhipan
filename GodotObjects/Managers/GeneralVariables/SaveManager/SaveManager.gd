extends Node

## This class handles saves for global saves and local changes from chunk loading.
class_name SaveManager

## Currently loaded save.
var currentSave: SaveResource

## Prealoaded sticker packed scenes for instancing.
@onready var stickerBases: Dictionary[String, PackedScene] = {"ALTERNATOR": preload("uid://djwsba7job37w"), "FAN": preload("uid://cjg3u8idl755x"), "KEY": preload("uid://5y3mxiemv321"), "LAMP": preload("uid://obi7mybs0j53")} 

## Creates empty save resource to begin with.
func _ready() -> void:
	GeneralVariables.new_gamestate.connect(_on_new_gamestate)

## Saves environment parameters.
func save_environment(environment: EnvironmentParameters, light: LightParameters) -> void:
	currentSave.store_environment(environment, light)

## Stores object changes.
func store_change(changedObject: Node, sceneParent: Node) -> void:
	currentSave.store_change(changedObject, sceneParent)

## Deletes a sticker from a save.
func delete_sticker(sticker: StickerBase) -> void:
	if sticker is InventorySticker:
		currentSave.delete_inventory_sticker(sticker)
	else: currentSave.delete_sticker(sticker)

## Loads a scene changes. Make sure that scene root nodes all have unique names.
func request_scene_load(scene: Node, loadEnvironment: bool = false) -> void:
	currentSave.load_changes(scene, loadEnvironment)

## Resets a scene's save.
func reset_saved_scene(sceneName: String, toReset: Array[String] = ["stickerModifications", "removedStickers", "openDoors", "objectHiders"]) -> void:
	currentSave.reset_saved_scene(sceneName, toReset)

## Refreshes save on restart DEMO SHIT
func _on_new_gamestate(isPlaying: bool) -> void:
	if isPlaying: currentSave = SaveResource.new()
