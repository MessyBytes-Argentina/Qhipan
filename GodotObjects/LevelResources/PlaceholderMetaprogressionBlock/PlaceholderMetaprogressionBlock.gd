@tool
extends StaticBody3D

## Placeholder texture for the block.
@export var texture: Texture2D:
	set(value):
		texture = value
		if Engine.is_editor_hint() and is_node_ready(): update_texture()
## Used to identify which objects to trigger when a pedestarl triggers with this same name.
@export var pedestalName: String

## Reference to the main mesh of the block.
@onready var mesh: MeshInstance3D = %MeshInstance3D

## Executed when node first enters the scene tree.
func _ready() -> void:
	update_texture()

##  Updates the debug texture.
func update_texture() -> void:
	var material: ShaderMaterial = mesh.get_surface_override_material(0).duplicate()
	material.set_shader_parameter("top_texture_albedo", texture)
	material.set_shader_parameter("bottom_texture_albedo", texture)
	material.set_shader_parameter("side_texture_albedo", texture)
	mesh.set_surface_override_material(0, material)

## Called when pedestal is activated.
func pedestal_activated(activatedPedestal: String) -> void:
	if activatedPedestal == pedestalName:
		queue_free()
