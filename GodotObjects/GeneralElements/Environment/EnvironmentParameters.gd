extends Resource
class_name EnvironmentParameters

@export var sky_panorama: Texture2D
@export_range(0.0, 128.0, 0.001) var sky_energy_multiplier: float = 0.75
@export var background_color: Color = Color.LIGHT_SLATE_GRAY
@export_range(0.0, 16.0, 0.001) var background_energy_multiplier: float = 0.6
@export var ambient_light_color: Color = Color.LIGHT_SLATE_GRAY
@export_range(0.0, 16.0, 0.001) var ambient_light_energy: float = 1.5
@export_range(0.0, 16.0, 0.001) var tonemap_exposure: float = 1.5
@export_range(0.0, 16.0, 0.001) var tonemap_white: float = 1.0
@export_range(0.0, 8.0, 0.001) var glow_intensity: float = 0.8
@export_range(0.0, 2.0, 0.001) var glow_strength: float = 0.4
@export_range(0.0, 1.0, 0.001) var glow_bloom: float = 0.5

var secondPanorama: Texture2D
var panoramaProgress: float

func set_environment(environment: Environment) -> void:
	environment.background_color = background_color
	environment.background_energy_multiplier = background_energy_multiplier
	environment.ambient_light_color = ambient_light_color
	environment.ambient_light_energy = ambient_light_energy
	environment.tonemap_exposure = tonemap_exposure
	environment.tonemap_white = tonemap_white
	environment.glow_intensity = glow_intensity
	environment.glow_strength = glow_strength
	environment.glow_bloom = glow_bloom
	var skyMaterial: ShaderMaterial = environment.sky.sky_material
	skyMaterial.set_shader_parameter("startPanorama", sky_panorama)
	skyMaterial.set_shader_parameter("goalPanorama", secondPanorama)
	skyMaterial.set_shader_parameter("panoramaProgress", panoramaProgress)
	skyMaterial.set_shader_parameter("skyContribution", sky_energy_multiplier)

func lerp_to(goal: EnvironmentParameters, progress: float, skyProgress: float) -> EnvironmentParameters:
	var res: EnvironmentParameters = EnvironmentParameters.new()
	res.sky_panorama = sky_panorama
	res.secondPanorama = goal.sky_panorama
	res.panoramaProgress = skyProgress
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
	return res
