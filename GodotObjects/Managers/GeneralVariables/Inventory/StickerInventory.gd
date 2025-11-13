extends Node
## This class handles holding and managing Stickers that go into the inventory.
class_name StickerInventory

## Signals the the inventory was updated.
signal updated_inventory()

## List of valid medium stickers and their path.
var currentInventory: Array[PocketSticker] = []

## Add sticker to inventory.
func add_sticker(sticker: PocketSticker) -> void:
	currentInventory.append(sticker)
	updated_inventory.emit()

## Check for sticker.
func has_sticker(stickerName: String) -> PocketSticker:
	var validStickers: Array[PocketSticker] = currentInventory.filter(func(a: PocketSticker): return a.name == stickerName)
	if len(validStickers) > 0: return validStickers[0]
	else: return null

## Removes existing sticker.
func remove_sticker(stickerName: String) -> PocketSticker:
	var toRemove: PocketSticker = has_sticker(stickerName)
	if toRemove:
		currentInventory.erase(toRemove)
		return toRemove
	else: return null
