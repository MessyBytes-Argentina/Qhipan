@tool
extends Node3D

## Material albedo color
@export var albedo: Color = Color.WHITE:
	set(value):
		albedo = value
		if Engine.is_editor_hint(): set_color_changes()
## Material emission color.
@export var emission: Color = Color.WHITE:
	set(value):
		emission = value
		if Engine.is_editor_hint(): set_color_changes()
## Light color.
@export var lightColor: Color = Color.WHITE:
	set(value):
		lightColor = value
		if Engine.is_editor_hint(): set_color_changes()
## Light shine gradient.
@export var shineGradient: GradientTexture1D = preload("uid://fvxwq20uhuo1"):
	set(value):
		shineGradient = value
		if Engine.is_editor_hint(): set_color_changes()
## Tests color changes.
@export_tool_button("Refresh", "Reload") var refresh: Callable = set_color_changes
## References group
@export_group("References")
## Reference to the meshes to recolor.
@export var meshes: Array[MeshInstance3D] = []
## Reference to the omnilights
@export var omniLights: Array[OmniLight3D] = []
## Reference to the shine mesh.
@export var shine: MeshInstance3D

## Accumulator for time to check light visibility.
var timePassed: float = 0
## Shine tween.
var shineTween: Tween
## Shine material
var shineMaterial: ShaderMaterial
## Current shine animation mode.
var shineAnimationMode: String = "Off"

## Called when the node enters the scene tree for the first time.
func _ready() -> void:
	set_color_changes()
	if Engine.is_editor_hint(): return

## Sets all color changes
func set_color_changes() -> void:
	if not is_node_ready():
		await ready
	shineMaterial = shine.get_surface_override_material(0).duplicate()
	shine.set_surface_override_material(0, shineMaterial)
	for mesh in meshes:
		var material: ShaderMaterial = mesh.get_surface_override_material(0).duplicate()
		material.set_shader_parameter("albedo", albedo)
		material.set_shader_parameter("emission", emission)
		mesh.set_surface_override_material(0, material)
	for light in omniLights:
		light.light_color = lightColor
