extends Node
## This class handles holding and managing Stickers that go into the inventory.
class_name StickerInventory

## Signals the the inventory was updated.
signal updated_inventory()

## List of valid medium stickers and their path.
var currentInventory: Array[PocketSticker] = []
## List of already used pedestals.
var activePedestals: PackedStringArray = []

## TEMPORARY BOOK CODE
var book: StickerBook

## Add sticker to inventory.
func add_sticker(sticker: PocketSticker) -> void:
	currentInventory.append(sticker)
	updated_inventory.emit()
	
	## TEMPORARY BOOK CODE
	book.sticker_added()

## Check for sticker.
func has_sticker(stickerName: String) -> PocketSticker:
	var validStickers: Array[PocketSticker] = currentInventory.filter(func(a: PocketSticker): return a.name == stickerName)
	if len(validStickers) > 0: return validStickers[0]
	else: return null

## Removes existing sticker.
func remove_sticker(stickerName: String) -> PocketSticker:
	var toRemove: PocketSticker = has_sticker(stickerName)
	if toRemove:
		
		## TEMPORARY BOOK CODE
		book.sticker_removed(toRemove)
		
		currentInventory.erase(toRemove)
		return toRemove
	else: return null

## TEMPORARY BOOK CODE
func _ready() -> void:
	book = load("uid://knl3pi3ldyma").instantiate()
	add_child(book)
