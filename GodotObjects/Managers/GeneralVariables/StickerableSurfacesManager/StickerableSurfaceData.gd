extends Resource
## Resource that tracks current valid surfaces for stickers.
class_name StickerableSurfaceData

## Reference to the surface node
var node: StickerMarker
## The node position
var globalPosition: Vector3
## The node direction.
var direction: Vector3
## Stores stickers stuck to this surface
var used: StickerBase = null
## Stores valid stickers bitflag
var validStickers: int = 15
## Stores sticker scale when placed
var specialScale: Vector3 = Vector3.ONE
