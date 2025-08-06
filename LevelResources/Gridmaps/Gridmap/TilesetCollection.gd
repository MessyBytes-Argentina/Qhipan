@tool
extends Node3D

@export var collectionMaterial: Material
@export_tool_button("Apply Properties")
var button: Callable = _apply_material

func _apply_material() -> void:
	for child in get_children():
		if child is MeshInstance3D:
			child.set_surface_override_material(0, collectionMaterial)
			child.name = child.name.get_slice("__", 0) + "__" + name
