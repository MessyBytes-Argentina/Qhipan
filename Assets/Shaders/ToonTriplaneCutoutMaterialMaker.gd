@tool
extends Resource

## Handles creating the materials with the toon shader.
class_name ToonMaterialMaker

## The ToonTriplaneCutout shader script.
const ttcShader: String = "uid://j67qewi23t7g"
## The DecalToonTriplaneCutout shader script.
const dttcShader: String = "uid://d70se0jvv0xj"
## The ToonCutout shader script.
const tcShader: String = "uid://dsnxr718iap3n"
## The list of texture types.
const textureTypes: Array[String] = ["albedo_texture", "roughness_texture", "metallic_texture", "emission_texture", "normal_texture", "clearcoat_texture", "anisotropy_flowmap", "ao_texture"]
## The list of texture types alias.
const textureTypesAlias: Array[String] = ["albedo", "roughness", "metallic", "emission", "normal", "clearcoat", "anisotropy_flowmap", "ambient_occlusion"]
## The list of special value parameters.
const specialValueParameters: Array[String] = ["metallic", "metallic_specular", "roughness", "emission", "emission_energy_multiplier", "normal_scale", "clearcoat", "clearcoat_roughness", "anisotropy", "ao_light_affect"]
## The list of toggles to exclude.
const excludeToggleParameters: Array[String] = ["roughness", "metallic"]

## The types of materials to make.
enum MaterialModes {GRIDMAP, DECAL, OTHER}
## The currently chosen material type.
@export var materialMode: MaterialModes = MaterialModes.GRIDMAP:
	set(value):
		materialMode = value
		if Engine.is_editor_hint(): notify_property_list_changed()
## The surface of the piece for other objects.
var surfaceMaterial: StandardMaterial3D
## The UV size for decals.
var UVSize: Vector2 = Vector2.ONE
## The UV mask for decals.
var UVMask: Texture2D
## The top surface of the piece.
var topSurfaceMaterial: StandardMaterial3D
## The top surface albedo size.
var topAlbedoSize: float = 1
## The top surface detail size.
var topDetailSize: float = 1
## The bottom surface of the piece.
var bottomSurfaceMaterial: StandardMaterial3D
## The bottom surface albedo size.
var bottomAlbedoSize: float = 1
## The bottom surface detail size.
var bottomDetailSize: float = 1
## The side surface of the piece.
var sideSurfaceMaterial: StandardMaterial3D
## The side surface albedo size.
var sideAlbedoSize: float = 1
## The side surface detail size.
var sideDetailSize: float = 1
## Toon shader color gradient
var lightGradient: GradientTexture1D = load("uid://cg15s1jf3mbcd")
## Toon shader fresnel gradient
var fresnelGradient: GradientTexture1D = load("uid://cg26alu2ef7we")
## Press when you are ready.
var finalizeExecute: Callable = make_material
## The produced material. Saving this as a resource is recommended.
var finalizeShaderMaterial: ShaderMaterial

## Updates the property list.
func _get_property_list() -> Array[Dictionary]:
	var props: Array[Dictionary] = []
	match materialMode:
		MaterialModes.GRIDMAP:
			props.append_array(_get_ttc_properties())
		MaterialModes.DECAL:
			props.append({
				"name": "UVMask",
				"type": TYPE_OBJECT,
				"hint": PROPERTY_HINT_RESOURCE_TYPE,
				"hint_string": "Texture2D",
			})
			props.append_array(_get_ttc_properties())
		MaterialModes.OTHER:
			props.append({
				"name": "surfaceMaterial",
				"type": TYPE_OBJECT,
				"hint": PROPERTY_HINT_RESOURCE_TYPE,
				"hint_string": "StandardMaterial3D",
			})
			props.append({
				"name": "UVSize",
				"type": TYPE_VECTOR2,
				"hint": PROPERTY_HINT_RANGE,
				"hint_string": "0.01,10.0,0.01",
			})
	for gradient in ["light", "fresnel"]:
		props.append({
			"name": gradient + "Gradient",
			"type": TYPE_OBJECT,
			"hint": PROPERTY_HINT_RESOURCE_TYPE,
			"hint_string": "Texture2D",
		})
	props.append({
		"name": "Finalize",
		"type": TYPE_NIL,
		"usage": PROPERTY_USAGE_CATEGORY,
		"hint_string": "Press when you are ready"
	})
	finalizeExecute = make_material
	props.append({
		"name": "finalizeExecute",
		"type": TYPE_CALLABLE,
		"usage": PROPERTY_USAGE_EDITOR,
		"hint": PROPERTY_HINT_TOOL_BUTTON,
		"hint_string": "Press when you are ready,StandardMaterial3D"
	})
	props.append({
		"name": "finalizeShaderMaterial",
		"type": TYPE_OBJECT,
		"hint": PROPERTY_HINT_RESOURCE_TYPE,
		"hint_string": "ShaderMaterial",
	})
	return props

## Gets TTC Material property list.
func _get_ttc_properties() -> Array[Dictionary]:
	var props: Array[Dictionary] = []
	for surface in ["top", "bottom", "side"]:
		props.append({
			"name": surface + "SurfaceMaterial",
			"type": TYPE_OBJECT,
			"hint": PROPERTY_HINT_RESOURCE_TYPE,
			"hint_string": "StandardMaterial3D",
		})
		props.append({
			"name": surface + "AlbedoSize",
			"type": TYPE_FLOAT,
			"hint": PROPERTY_HINT_RANGE,
			"hint_string": "0.01,10.0,0.01",
		})
		props.append({
			"name": surface + "DetailSize",
			"type": TYPE_FLOAT,
			"hint": PROPERTY_HINT_RANGE,
			"hint_string": "0.01,10.0,0.01",
		})
	return props

## Called upon pressing the make material button.
func make_material() -> void:
	finalizeShaderMaterial = ShaderMaterial.new()
	match materialMode:
		MaterialModes.GRIDMAP:
			finalizeShaderMaterial.shader = load(ttcShader)
			make_TTC_material()
		MaterialModes.DECAL:
			finalizeShaderMaterial.shader = load(dttcShader)
			finalizeShaderMaterial.set_shader_parameter("mask", UVMask)
			make_TTC_material()
		MaterialModes.OTHER:
			finalizeShaderMaterial.shader = load(tcShader)
			finalizeShaderMaterial.set_shader_parameter("light_gradient", lightGradient)
			finalizeShaderMaterial.set_shader_parameter("fresnel_gradient", fresnelGradient)
			finalizeShaderMaterial.set_shader_parameter("albedo", surfaceMaterial.albedo_color)
			var validModes: Dictionary[String, bool] = {}
			textureTypesAlias.map(func(a: String): if a not in excludeToggleParameters: validModes[a] = false)
			finalizeShaderMaterial.set_shader_parameter("uv1_scale", UVSize)
			for i in range(len(textureTypes)):
				var texture: String = textureTypes[i]
				finalizeShaderMaterial.set_shader_parameter(texture, surfaceMaterial[texture])
				if textureTypesAlias[i] in validModes.keys(): validModes[textureTypesAlias[i]] = true
			for prop in specialValueParameters:
				finalizeShaderMaterial.set_shader_parameter(prop, surfaceMaterial[prop])
			for mode in validModes:
				finalizeShaderMaterial.set_shader_parameter("enable_" + mode if mode != "anisotropy_flowmap" else "anisotropy", validModes[mode])

## Make a Toon Triplanar Material.
func make_TTC_material() -> void:
	finalizeShaderMaterial.set_shader_parameter("light_gradient", lightGradient)
	finalizeShaderMaterial.set_shader_parameter("fresnel_gradient", fresnelGradient)
	var baseMaterials: Dictionary[String, StandardMaterial3D] = {
		"top": topSurfaceMaterial,
		"bottom": bottomSurfaceMaterial,
		"side": sideSurfaceMaterial
	}
	var validModes: Dictionary[String, bool] = {}
	textureTypesAlias.map(func(a: String): if a not in excludeToggleParameters: validModes[a] = false)
	for surface in baseMaterials:
		finalizeShaderMaterial.set_shader_parameter(surface + "_texture_scale", get(surface + "AlbedoSize"))
		finalizeShaderMaterial.set_shader_parameter(surface + "_detail_texture_scale", get(surface + "DetailSize"))
		for i in range(len(textureTypes)):
			if not baseMaterials[surface][textureTypes[i]]: continue
			finalizeShaderMaterial.set_shader_parameter(surface + "_texture_" + textureTypesAlias[i], baseMaterials[surface][textureTypes[i]])
			if textureTypesAlias[i] in validModes.keys(): validModes[textureTypesAlias[i]] = true
		for prop in specialValueParameters:
			finalizeShaderMaterial.set_shader_parameter(surface + "_" + prop, baseMaterials[surface][prop])
	for mode in validModes:
		finalizeShaderMaterial.set_shader_parameter("enable_" + mode if mode != "anisotropy_flowmap" else "anisotropy", validModes[mode])
	
