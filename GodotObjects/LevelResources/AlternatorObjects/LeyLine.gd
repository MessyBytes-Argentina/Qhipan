extends Node3D

var groupParent: AlternatingGroup

@onready var stickerMarker: StickerMarker = %StickerMarker

## Executed when node first enters the scene tree.
func _ready() -> void:
	var parent = get_parent()
	if parent is AlternatingGroup: 
		groupParent = parent
	else:
		prints(name," isn't in a group")

## Triggered when a sticker is placed or removed.
func _on_sticker(_placed: bool) -> void:
	if stickerMarker.data.used is not AlternatorSticker: return
	groupParent.switch_children()
