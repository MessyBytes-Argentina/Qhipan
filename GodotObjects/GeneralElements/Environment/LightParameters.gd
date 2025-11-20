extends Resource
class_name LightParameters

@export var color: Color = Color.WHITE
@export_range(0.0, 10.0, 0.001) var energy: float = 0.05
@export_range(0.0, 10.0, 0.001) var indirect_energy: float = 1.0
@export_range(0.0, 10.0, 0.001) var specular: float = 1.0

func set_sun(sun: DirectionalLight3D) -> void:
	sun.light_color = color
	sun.light_energy = energy
	sun.light_indirect_energy = indirect_energy
	sun.light_specular = specular

func lerp_to(goal: LightParameters, progress: float) -> LightParameters:
	var res: LightParameters = LightParameters.new()
	res.color = lerp(color, goal.color, progress)
	res.energy = lerp(energy, goal.energy, progress)
	res.indirect_energy = lerp(indirect_energy, goal.indirect_energy, progress)
	res.specular = lerp(specular, goal.specular, progress)
	return res
