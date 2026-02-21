extends StaticBody3D
class_name LitGlass

@export var lightRange: float = 5.0

@onready var mesh: MeshInstance3D = %MeshInstance3D
@onready var light: OmniLight3D = %OmniLight3D

var state: bool = false
var material: ShaderMaterial

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	material = mesh.get_surface_override_material(0).duplicate()
	mesh.set_surface_override_material(0, material)
	light.omni_range = lightRange

func switch_state() -> void:
	state = not state
	material.set_shader_parameter("is_lit", state)
	light.visible = state
