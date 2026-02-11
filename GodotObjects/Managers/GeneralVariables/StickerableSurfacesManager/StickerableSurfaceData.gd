extends Resource
## Resource that tracks current valid surfaces for stickers.
class_name StickerableSurfaceData

## Reference to the surface node.
var node: StickerMarker
## The node position.
var globalPosition: Vector3
## The node direction.
var direction: Vector3
## Stores stickers stuck to this surface.
var used: StickerBase = null
## Stores valid stickers bitflag.
var validStickers: int = 15
## Stores sticker scale when placed.
var specialScale: Vector3 = Vector3.ONE
## Special flags.
var specialFlags: int = 0

func _init(surface: StickerMarker = null, pointingTo: Node3D = null) -> void:
	if not surface: return
	node = surface
	direction = surface.global_position.direction_to(pointingTo.global_position)
	globalPosition = surface.global_position
	validStickers = surface.validStickers
	specialScale = Vector3.ONE * surface.specialStickerScale
	specialFlags = surface.specialFlags
