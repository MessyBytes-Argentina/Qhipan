@tool
extends StaticBody3D

@export var texture: Texture2D:
	set(value):
		texture = value
		if Engine.is_editor_hint() and is_node_ready(): update_texture()
@export var pedestalName: String

@onready var mesh: MeshInstance3D = %MeshInstance3D

func _ready() -> void:
	update_texture()

func update_texture() -> void:
	var material: ShaderMaterial = mesh.get_surface_override_material(0).duplicate()
	material.set_shader_parameter("top_texture_albedo", texture)
	material.set_shader_parameter("bottom_texture_albedo", texture)
	material.set_shader_parameter("side_texture_albedo", texture)
	mesh.set_surface_override_material(0, material)

func pedestal_activated(activatedPedestal: String) -> void:
	if activatedPedestal == pedestalName:
		queue_free()
