extends Resource

## Resource class that holds, lerps, and sets sun parameters.
class_name LightParameters

## Sun color.
@export var color: Color = Color.WHITE
## Sun energy.
@export_range(0.0, 10.0, 0.001) var energy: float = 0.05
## Sun indirect energy (for light bounces, and hard to reach corners).
@export_range(0.0, 10.0, 0.001) var indirect_energy: float = 1.0
## Light specular.
@export_range(0.0, 10.0, 0.001) var specular: float = 1.0

## Sets sun parameters to match the ones of this object.
func set_sun(sun: DirectionalLight3D) -> void:
	sun.light_color = color
	sun.light_energy = energy
	sun.light_indirect_energy = indirect_energy
	sun.light_specular = specular

## Lerps to goal [LightParameters] by progress. Returns the newly created [LightParameters].
func lerp_to(goal: LightParameters, progress: float) -> LightParameters:
	var res: LightParameters = LightParameters.new()
	res.color = lerp(color, goal.color, progress)
	res.energy = lerp(energy, goal.energy, progress)
	res.indirect_energy = lerp(indirect_energy, goal.indirect_energy, progress)
	res.specular = lerp(specular, goal.specular, progress)
	return res
