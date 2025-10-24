@tool
extends Node3D

## The valid stickerable pieces.
const VALIDFACES: PackedStringArray = ["CornerRemovedUpsideDown", "CornerRemoved", "Cube", "RampUpsideDown", "Ramp", "SlabCornerRemovedUpsideDown", "SlabRampUpsideDown", "Slab", "Wedge"]

## Visual material to apply to the collection
@export var collectionMaterial: Material
## If the material is stickereable removes invalid pieces. This is not reversible
@export var isStickerable: bool = false
## When pressed applies the visual material to the children
@export_tool_button("Apply Properties")
var button: Callable = _apply_material

## Gets all the MeshInstance3D children and applies the collectionMaterial to them
func _apply_material() -> void:
	if isStickerable and not name.begins_with("Sticker-"):
		name = "Sticker-" + name
	for child in get_children():
		if child is MeshInstance3D:
			child.set_surface_override_material(0, collectionMaterial)
			child.name = child.name.get_slice("__", 0) + "__" + name
			if isStickerable:
				if child.name.get_slice("__", 0) not in VALIDFACES:
					child.queue_free()
