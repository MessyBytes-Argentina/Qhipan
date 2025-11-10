extends Node
class_name StickersList

## List of Stickers and their Path
@export var stickersList: Dictionary[String,String] = {"Sticker Name":"Path"}

## Checks if the given key is on the list
func is_valid(key: String) -> bool:
	return stickersList.has(key)

## Returns the scene path from the given key
func get_sticker_scene_path(key: String) -> String:
	return stickersList[key]
