@tool
extends StaticBody3D
## Node handles triggering pedestal events.
class_name SmallPedestal

## Debug texture for this pedestal
@export var texture: Texture2D:
	set(value):
		texture = value
		if Engine.is_editor_hint() and is_node_ready(): update_texture()
## Used to identify which objects to trigger
@export var pedestalName: String

## Reference to the pedestal wall.
@onready var mesh: MeshInstance3D = %Wall

## Executed when node first enters scene tree.
func _ready() -> void:
	update_texture()

## Activates pedestal.
func activate_pedestal() -> void:
	get_tree().call_group("Metaprogression", "pedestal_activated", pedestalName)

## Updates debug texture.
func update_texture() -> void:
	var material: ShaderMaterial = mesh.get_surface_override_material(0).duplicate()
	material.set_shader_parameter("top_texture_albedo", texture)
	material.set_shader_parameter("bottom_texture_albedo", texture)
	material.set_shader_parameter("side_texture_albedo", texture)
	mesh.set_surface_override_material(0, material)

## Notifies when sticker is placed
func _on_sticker(placed: bool) -> void:
	if placed: activate_pedestal()
