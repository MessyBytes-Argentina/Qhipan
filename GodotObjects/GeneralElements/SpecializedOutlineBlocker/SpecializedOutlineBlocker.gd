extends MeshInstance3D

var shader: ShaderMaterial

func _ready() -> void:
	shader = get_surface_override_material(0).duplicate()
	set_surface_override_material(0, shader)
	shader.set_shader_parameter("override", -5.0)

func player_entered(body: Node) -> void:
	if body is not Player: return
	shader.set_shader_parameter("override", 5.0)

func player_exited(body: Node) -> void:
	if body is not Player: return
	shader.set_shader_parameter("override", -5.0)
