@tool
extends Resource

## Handles creating the materials for the gridmap.
class_name TTCMaterialMaker

## The ToonTriplaneCutout shader script.
const ttcShader: String = "uid://j67qewi23t7g"
## The list of texture types.
const textureTypes: Array[String] = ["albedo_texture", "roughness_texture", "metallic_texture", "emission_texture", "normal_texture", "clearcoat_texture", "anisotropy_flowmap", "ao_texture"]
## The list of texture types alias.
const textureTypesAlias: Array[String] = ["albedo", "roughness", "metallic", "emission", "normal", "clearcoat", "anisotropy_flowmap", "ambient_occlusion"]
## The list of special value parameters.
const specialValueParameters: Array[String] = ["metallic", "metallic_specular", "roughness", "emission", "emission_energy_multiplier", "normal_scale", "clearcoat", "clearcoat_roughness", "anisotropy", "ao_light_affect"]
## The list of toggles to exclude.
const excludeToggleParameters: Array[String] = ["roughness", "metallic"]

## The top surface of the pieces.
@export var topSurfaceMaterial: StandardMaterial3D
## The top surface albedo size.
@export var topAlbedoSize: float = 1
## The top surface detail size.
@export var topDetailSize: float = 1
## The bottom surface of the pieces.
@export var bottomSurfaceMaterial: StandardMaterial3D
## The bottom surface albedo size.
@export var bottomAlbedoSize: float = 1
## The bottom surface detail size.
@export var bottomDetailSize: float = 1
## The side surface of the pieces.
@export var SideSurfaceMaterial: StandardMaterial3D
## The side surface albedo size.
@export var sideAlbedoSize: float = 1
## The side surface detail size.
@export var sideDetailSize: float = 1
## Toon shader color gradient
@export var colorGradient: GradientTexture1D = load("uid://cg15s1jf3mbcd")
## Toon shader fresnel gradient
@export var fresnelGradient: GradientTexture1D = load("uid://cg26alu2ef7we")

@export_category("Press when ready")
## Make the material.
@export_tool_button("Make Material", "StandardMaterial3D") var execute: Callable = make_material
## The produced material.
@export var shaderMaterial: ShaderMaterial

## Make the material.
func make_material() -> void:
	shaderMaterial = ShaderMaterial.new()
	shaderMaterial.shader = load(ttcShader)
	shaderMaterial.set_shader_parameter("color_gradient", colorGradient)
	shaderMaterial.set_shader_parameter("fresnel_gradient", fresnelGradient)
	var baseMaterials: Dictionary[String, StandardMaterial3D] = {
		"top": topSurfaceMaterial,
		"bottom": bottomSurfaceMaterial,
		"side": SideSurfaceMaterial
	}
	var validModes: Dictionary[String, bool] = {}
	textureTypesAlias.map(func(a: String): if a not in excludeToggleParameters: validModes[a] = false)
	for surface in baseMaterials:
		shaderMaterial.set_shader_parameter(surface + "_texture_scale", get(surface + "AlbedoSize"))
		shaderMaterial.set_shader_parameter(surface + "_detail_texture_scale", get(surface + "DetailSize"))
		for i in range(len(textureTypes)):
			if not baseMaterials[surface][textureTypes[i]]: continue
			shaderMaterial.set_shader_parameter(surface + "_texture_" + textureTypesAlias[i], baseMaterials[surface][textureTypes[i]])
			if textureTypesAlias[i] in validModes.keys(): validModes[textureTypesAlias[i]] = true
		for prop in specialValueParameters:
			shaderMaterial.set_shader_parameter(surface + "_" + prop, baseMaterials[surface][prop])
	for mode in validModes:
		shaderMaterial.set_shader_parameter("enable_" + mode if mode != "anisotropy_flowmap" else "anisotropy", validModes[mode])
	
