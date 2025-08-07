extends MeshInstance3D
class_name CutoutCylinder

@export var materials: Array[ShaderMaterial]
var up: Marker3D

func _ready() -> void:
	if not up:
		up = Marker3D.new()
		add_child(up)
		up.position = Vector3.UP

func _process(_delta: float) -> void:
	for material in materials: update_material(material)

func update_material(updateMaterial: ShaderMaterial) -> void:
	updateMaterial.set_shader_parameter("cylinderPosition", global_position)
	updateMaterial.set_shader_parameter("cylinderRadius", mesh.top_radius)
	updateMaterial.set_shader_parameter("cylinderHeight", mesh.height)
	updateMaterial.set_shader_parameter("cylinderRotation", global_position - up.global_position)
