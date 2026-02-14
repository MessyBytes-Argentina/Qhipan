extends Node

## Which stickers can be placed here.
@export_flags("Alternator", "Fan", "Key", "Lamp") var validStickers: int = 15
## Scale of the placed sticker
@export_range(0.0, 5.0, 0.01) var specialStickerScale: float = 1.0
## Special Flags.
@export_flags("noPlayerFan", "NoPlayerAntigravity") var specialFlags: int = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	process_children(self)

func process_children(node: Node) -> void:
	if node is StickerMarker:
		node.validStickers = validStickers
		node.specialStickerScale = specialStickerScale
		node.specialFlags = specialFlags
	for child in node.get_children(): process_children(child)
