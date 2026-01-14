extends Node
## This class handles holding and managing Stickers that go into the inventory.
class_name StickerInventory

## Signals the the inventory was updated.
signal updated_inventory()

## List of valid medium stickers and their path.
var currentInventory: Array[PocketSticker] = []

## TEMPORARY DEBUG CODE
#var inventoryUI: HBoxContainer

## TEMPORARY BOOK CODE
var book: StickerBook

## Add sticker to inventory.
func add_sticker(sticker: PocketSticker) -> void:
	currentInventory.append(sticker)
	updated_inventory.emit()
	
	## TEMPORARY DEBUG CODE
	#var stickerImage: TextureRect = TextureRect.new()
	#stickerImage.texture = sticker.image
	#stickerImage.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	#stickerImage.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	#stickerImage.name = sticker.name
	#inventoryUI.add_child(stickerImage)
	
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
		currentInventory.erase(toRemove)
		
		## TEMPORARY DEBUG CODE
		#for child in inventoryUI.get_children():
			#if child.name.contains(stickerName):
				#child.queue_free()
				#break
		
		return toRemove
	else: return null

## TEMPORARY DEBUG CODE
#func _ready() -> void:
	#inventoryUI = HBoxContainer.new()
	#inventoryUI.name = "inventoryUI"
	#inventoryUI.custom_minimum_size.y = 64
	#var inventoryLayer: CanvasLayer = CanvasLayer.new()
	#inventoryLayer.name = "InventoryLayer"
	#add_child(inventoryLayer)
	#inventoryLayer.add_child(inventoryUI)
	#inventoryUI.set_anchors_preset(Control.PRESET_TOP_LEFT)

## TEMPORARY BOOK CODE
func _ready() -> void:
	book = load("uid://knl3pi3ldyma").instantiate()
	add_child(book)
