@tool
extends StaticBody3D
class_name Pedestal

@export var texture: Texture2D:
	set(value):
		texture = value
		if Engine.is_editor_hint() and is_node_ready(): update_texture()
@export var pedestalName: String

@onready var mesh: MeshInstance3D = %Wall
@onready var area3d: Area3D = %Area3D

func _ready() -> void:
	update_texture()
	area3d.set_meta("pointing", area3d.global_position.direction_to(area3d.get_node("Marker3D").global_position))

## Activates pedestal.
func activate_pedestal() -> void:
	area3d.set_deferred("monitorable", false)
	get_tree().call_group("Metaprogression", "pedestal_activated", pedestalName)

func update_texture() -> void:
	var material: ShaderMaterial = mesh.get_surface_override_material(0).duplicate()
	material.set_shader_parameter("top_texture_albedo", texture)
	material.set_shader_parameter("bottom_texture_albedo", texture)
	material.set_shader_parameter("side_texture_albedo", texture)
	mesh.set_surface_override_material(0, material)
