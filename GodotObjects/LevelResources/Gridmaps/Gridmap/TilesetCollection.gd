@tool
extends Node3D

## Visual material to apply to the collection
@export var collectionMaterial: Material
## When pressed applies the visual material to the children
@export_tool_button("Apply Properties")
var button: Callable = _apply_material

## Gets all the MeshInstance3D children and applies the collectionMaterial to them
func _apply_material() -> void:
	for child in get_children():
		if child is MeshInstance3D:
			child.set_surface_override_material(0, collectionMaterial)
			child.name = child.name.get_slice("__", 0) + "__" + name
