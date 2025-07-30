@tool
extends Node3D

@export var collectionMaterial: Material
@export_tool_button("Apply Material")
var button: Callable = _apply_material

func _apply_material() -> void:
	for child in get_children():
		if child is MeshInstance3D:
			child.material_override = collectionMaterial
