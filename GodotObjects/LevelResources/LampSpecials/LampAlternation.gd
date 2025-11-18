extends Node3D
## Like surfaces for alternators but used for special lamp puzzles.
class_name LampAlternatingSurface

## Reference to the sticker surface.
@onready var stickerMarker: StickerMarker = %StickerMarker

## Reference to the alternable children.
var altChildren: Array[Node] = []
## Reference to any sticked stickers.
var stickers: Array[LampSticker] = []

## Executed when node first enters the scene tree.
func _ready() -> void:
	var children: Array[Node] = recursive_get_children(self)
	for child in children:
		if child.has_meta("SpecialAlternation"):
			altChildren.append(child)

## Gets all children.
func recursive_get_children(parent: Node) -> Array[Node]:
	var children: Array[Node] = parent.get_children()
	for child in children.duplicate():
		children.append_array(recursive_get_children(child))
	return children

## Switches all children.
func switch_children(state: bool) -> void:
	for child in altChildren:
		child.switch_state(state)

## Triggers when a sticker is placed or removed.
func _on_sticker(placed: bool) -> void:
	if placed:
		if stickerMarker.data.used is LampSticker:
			switch_children(placed)
			return
		return
	switch_children(false)
