@tool
extends MeshInstance3D
class_name CutoutCube

@export var materials: Array[ShaderMaterial]
@export var offset: float = 0.0
@export_tool_button("Align") var allignAction: Callable = align_position

@onready var cylinder: MeshInstance3D = %CutoutCylinder
@onready var playerFloor: Marker3D = %PlayerFloor
@onready var cameraRayCast1: RayCast3D = %CameraRayCast1
@onready var cameraRayCast2: RayCast3D = %CameraRayCast2

var up: Marker3D
var zoomedOut: bool = false

func _ready() -> void:
	if Engine.is_editor_hint(): return
	hide()
	cylinder.hide()
	if not up:
		up = Marker3D.new()
		cylinder.add_child(up)
		up.position = Vector3.UP
	for updateMaterial in materials: 
		updateMaterial.set_shader_parameter("boxSize", mesh.size)
		updateMaterial.set_shader_parameter("cylinderRadius2", cylinder.mesh.bottom_radius)
		updateMaterial.set_shader_parameter("cylinderRadius1", cylinder.mesh.top_radius)
		updateMaterial.set_shader_parameter("cylinderHeight", cylinder.mesh.height)

func _process(_delta: float) -> void:
	if Engine.is_editor_hint(): return
	for updateMaterial in materials: update_material(updateMaterial)

func update_material(updateMaterial: ShaderMaterial) -> void:
	updateMaterial.set_shader_parameter("cylinderCutout", cameraRayCast1.is_colliding() and cameraRayCast2.is_colliding() and not zoomedOut)
	updateMaterial.set_shader_parameter("boxPosition", global_position)
	updateMaterial.set_shader_parameter("boxRotation", global_transform.basis)
	updateMaterial.set_shader_parameter("cylinderPosition", cylinder.global_position)
	updateMaterial.set_shader_parameter("cylinderRotation", cylinder.global_position - up.global_position)
	updateMaterial.set_shader_parameter("playerPosition", playerFloor.global_position)

func align_position() -> void:
	cylinder.position = (cylinder.mesh.height / 2 + offset) * Vector3.FORWARD
