@tool
extends Resource

## Resource class that holds, lerps, and sets environment parameters.
class_name EnvironmentParameters

## The sky to use.
@export var sky_panorama: Texture2D
## Sky energy.
@export_range(0.0, 128.0, 0.001) var sky_energy_multiplier: float = 0.75
## Background color for extra ambient light.
@export var background_color: Color = Color.LIGHT_SLATE_GRAY
## Background energy.
@export_range(0.0, 16.0, 0.001) var background_energy_multiplier: float = 0.6
## Ambient light color.
@export var ambient_light_color: Color = Color.LIGHT_SLATE_GRAY
## Ambient energy.
@export_range(0.0, 16.0, 0.001) var ambient_light_energy: float = 1.5
## Postprocessing exposure.
@export_range(0.0, 16.0, 0.001) var tonemap_exposure: float = 1.5
## Postprocessing white levels.
@export_range(0.0, 16.0, 0.001) var tonemap_white: float = 1.0
## Glow intensity (keep low for better results).
@export_range(0.0, 8.0, 0.001) var glow_intensity: float = 0.8
## Glow strength (keep low for better results).
@export_range(0.0, 2.0, 0.001) var glow_strength: float = 0.4
## Glow bloom (keep low to not look like a ps2 game).
@export_range(0.0, 1.0, 0.001) var glow_bloom: float = 0.5
## Group for color adjustments.
@export_group("Adjustments")
## Postprocessing brightness.
@export_range(0.1, 8.0, 0.001) var brightness: float = 1.0
## Postprocessing contrast.
@export_range(0.1, 8.0, 0.001) var contrast: float = 1.0
## Postprocessing brightness.
@export_range(0.1, 8.0, 0.001) var saturation: float = 1.0
## Postprocessing brightness.
@export var color_correction: Texture = GradientTexture2D.new()
## Affects darkness, keep at default if darkness is in the scene.
@export_range(0.5, 0.99, 0.01) var temporal_reprojection: float = 0.95

## Storage for lerping to another sky.
var secondPanorama: Texture2D
## Panorama progress for lerping.
var panoramaProgress: float
## Storage for lerping to another color correction texture.
var secondColorCorrection: Texture
## Progress for lerping
var lerpProgress: float

## Sets environment to have the parameters of this resource.
func set_environment(environment: Environment, colorCorrection: ShaderMaterial) -> void:
	environment.background_color = background_color
	environment.background_energy_multiplier = background_energy_multiplier
	environment.ambient_light_color = ambient_light_color
	environment.ambient_light_energy = ambient_light_energy
	environment.tonemap_exposure = tonemap_exposure
	environment.tonemap_white = tonemap_white
	environment.glow_intensity = glow_intensity
	environment.glow_strength = glow_strength
	environment.glow_bloom = glow_bloom
	environment.adjustment_brightness = brightness
	environment.adjustment_contrast = contrast
	environment.adjustment_saturation = saturation
	environment.volumetric_fog_temporal_reprojection_amount = temporal_reprojection
	var skyMaterial: ShaderMaterial = environment.sky.sky_material
	skyMaterial.set_shader_parameter("startPanorama", sky_panorama)
	skyMaterial.set_shader_parameter("goalPanorama", secondPanorama)
	skyMaterial.set_shader_parameter("panoramaProgress", panoramaProgress)
	skyMaterial.set_shader_parameter("skyContribution", sky_energy_multiplier)
	colorCorrection.set_shader_parameter("startTexture", color_correction)
	colorCorrection.set_shader_parameter("goalTexture", secondColorCorrection)
	colorCorrection.set_shader_parameter("textureProgress", lerpProgress)

## Lerps to a different [EnvironmentParameters] by shyProgress and returns the new [EnvironmentParameters] object.
func lerp_to(goal: EnvironmentParameters, progress: float, skyProgress: float) -> EnvironmentParameters:
	var res: EnvironmentParameters = EnvironmentParameters.new()
	res.sky_panorama = sky_panorama
	res.secondPanorama = goal.sky_panorama
	res.panoramaProgress = skyProgress
	res.color_correction = color_correction
	res.secondColorCorrection = goal.color_correction
	res.lerpProgress = progress
	res.sky_energy_multiplier = lerp(sky_energy_multiplier, goal.sky_energy_multiplier, progress)
	res.background_color = lerp(background_color, goal.background_color, progress)
	res.background_energy_multiplier = lerp(background_energy_multiplier, goal.background_energy_multiplier, progress)
	res.ambient_light_color = lerp(ambient_light_color, goal.ambient_light_color, progress)
	res.ambient_light_energy = lerp(ambient_light_energy, goal.ambient_light_energy, progress)
	res.tonemap_exposure = lerp(tonemap_exposure, goal.tonemap_exposure, progress)
	res.tonemap_white = lerp(tonemap_white, goal.tonemap_white, progress)
	res.glow_intensity = lerp(glow_intensity, goal.glow_intensity, progress)
	res.glow_strength = lerp(glow_strength, goal.glow_strength, progress)
	res.glow_bloom = lerp(glow_bloom, goal.glow_bloom, progress)
	res.brightness = lerp(brightness, goal.brightness, progress)
	res.contrast = lerp(contrast, goal.contrast, progress)
	res.saturation = lerp(saturation, goal.saturation, progress)
	res.temporal_reprojection = lerp(temporal_reprojection, goal.temporal_reprojection, progress)
	return res
