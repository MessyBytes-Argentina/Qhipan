extends Node
class_name SaveManager

var currentSave: SaveResource

@onready var stickerBases: Dictionary[String, PackedScene] = {"ALTERNATOR": preload("uid://djwsba7job37w"), "FAN": preload("uid://cjg3u8idl755x"), "KEY": preload("uid://5y3mxiemv321"), "LAMP": preload("uid://obi7mybs0j53")} 

func _ready() -> void:
	currentSave = SaveResource.new()

func store_change(changedObject: Node, sceneParent: Node) -> void:
	currentSave.store_change(changedObject, sceneParent)

func delete_sticker(sticker: StickerBase) -> void:
	if sticker is InventorySticker:
		currentSave.delete_inventory_sticker(sticker)
	else: currentSave.delete_sticker(sticker)

func request_scene_load(scene: Node) -> void:
	currentSave.load_changes(scene)
