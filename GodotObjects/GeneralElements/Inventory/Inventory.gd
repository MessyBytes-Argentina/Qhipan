extends Node
class_name Inventory

## List of valid medium stickers and their path
@onready var mediumStickersList: StickersList = preload("uid://3g2wpeak0ule")

## Collection of medium stickers
var mediumStickerCollection: Dictionary = {}

## Adds the sticker with the given key to the collection if valid
func add_medium_sticker(stickerKey: String) -> void:
	if not mediumStickersList.is_valid(stickerKey):
		prints("Key doesn't exist.")
		return
	if mediumStickerCollection.has(stickerKey):
		prints("Sticker already collected.")
		return
	mediumStickerCollection[stickerKey] = mediumStickersList.get_sticker_scene_path(stickerKey)

## Removes the given sticker from the collection if valid
func remove_medium_sticker(stickerKey: String) -> void:
	if not mediumStickerCollection.erase(stickerKey):
		prints("Key doesn't exist.")

## Returns the list of available stickers
func get_available_stickers() -> Array:
	return mediumStickerCollection.keys()
