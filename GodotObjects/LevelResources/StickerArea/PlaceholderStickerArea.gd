extends Node3D

## Which stickers can be placed here.
@export_flags("Alternator", "Fan", "Key", "Lamp") var validStickers: int = 15
## Scale of the placed sticker
@export_range(0.0, 5.0, 0.01) var specialStickerScale: float = 1.0
## Special Flags.
@export_flags("noPlayerFan", "NoPlayerAntigravity") var specialFlags: int = 0

## Reference to the sticker marker.
@onready var stickerMarker: StickerMarker = $MeshInstance3D/StickerMarker

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	stickerMarker.validStickers = validStickers
	stickerMarker.specialStickerScale = specialStickerScale
	stickerMarker.specialFlags = specialFlags
