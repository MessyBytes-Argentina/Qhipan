extends StaticBody3D

## Class that exists for lit pieces of glass.
class_name LitGlass

## Range of the light that shines on the glass surface.
@export var lightRange: float = 5.0
## Light attenuation of the light that shines on the glass surface.
@export var lightAttenuation: float = 3.0

## Reference to the glass mesh.
@onready var mesh: MeshInstance3D = %MeshInstance3D
## Reference to the light that shines on the glass surface.
@onready var light: OmniLight3D = %OmniLight3D

## Current state.
var state: bool = false
## Glass material.
var material: ShaderMaterial

## Called when the node enters the scene tree for the first time.
func _ready() -> void:
	material = mesh.get_surface_override_material(0).duplicate()
	mesh.set_surface_override_material(0, material)
	light.omni_range = lightRange
	light.omni_attenuation = lightAttenuation

## Switches glass state.
func switch_state() -> void:
	state = not state
	material.set_shader_parameter("is_lit", state)
	light.visible = state
