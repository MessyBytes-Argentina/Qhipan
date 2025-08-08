@tool
extends MeshInstance3D
class_name CutoutCylinder

@export var materials: Array[ShaderMaterial]
@export var offset: float = 0.0
@export_tool_button("Align") var allignAction: Callable = align_position
var up: Marker3D

func _ready() -> void:
	if Engine.is_editor_hint(): return
	if not up:
		up = Marker3D.new()
		add_child(up)
		up.position = Vector3.UP

func _process(_delta: float) -> void:
	if Engine.is_editor_hint(): return
	for material in materials: update_material(material)

func update_material(updateMaterial: ShaderMaterial) -> void:
	updateMaterial.set_shader_parameter("cylinderPosition", global_position)
	updateMaterial.set_shader_parameter("cylinderRadius2", mesh.bottom_radius)
	updateMaterial.set_shader_parameter("cylinderRadius1", mesh.top_radius)
	updateMaterial.set_shader_parameter("cylinderHeight", mesh.height)
	updateMaterial.set_shader_parameter("cylinderRotation", global_position - up.global_position)

func align_position() -> void:
	position = (mesh.height / 2 + offset) * Vector3.FORWARD
