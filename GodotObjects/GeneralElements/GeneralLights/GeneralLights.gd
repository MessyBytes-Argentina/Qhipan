@tool
extends Node3D

## Material albedo color
@export var albedo: Color = Color.WHITE:
	set(value):
		albedo = value
		if Engine.is_editor_hint(): set_color_changes()
## Material emission color.
@export var emission: Color = Color.WHITE:
	set(value):
		emission = value
		if Engine.is_editor_hint(): set_color_changes()
## Light color.
@export var lightColor: Color = Color.WHITE:
	set(value):
		lightColor = value
		if Engine.is_editor_hint(): set_color_changes()
## Light shine gradient.
@export var shineGradient: GradientTexture1D = preload("uid://fvxwq20uhuo1"):
	set(value):
		shineGradient = value
		if Engine.is_editor_hint(): set_color_changes()
## Direction to the wall in local coordinates if this goes against the wall
@export_custom(PROPERTY_HINT_RANGE, "-1.0, 1.0, 1.0") var localWallDirection: Vector3
## Tests color changes.
@export_tool_button("Refresh", "Reload") var refresh: Callable = set_color_changes
## References group
@export_group("References")
## Reference to the meshes to recolor.
@export var meshes: Array[MeshInstance3D] = []
## Reference to the omnilights
@export var omniLights: Array[OmniLight3D] = []
## Reference to the shine mesh.
@export var shine: MeshInstance3D

## Shine material.
var shineMaterial: ShaderMaterial
## Occlude on camera angles.
var invalidAngles: Array[float] = [-0.25, 0.0, 0.25]

## Called when the node enters the scene tree for the first time.
func _ready() -> void:
	set_color_changes()
	if Engine.is_editor_hint(): return
	if localWallDirection == Vector3.ZERO: return
	var appliedRotationToWall: float = abs(rotation.y / PI) + abs(Vector2(localWallDirection.x, localWallDirection.z).angle_to(Vector2.DOWN) / PI)
	for i in range(len(invalidAngles)):
		invalidAngles[i] = abs(snappedf(invalidAngles[i] + appliedRotationToWall, 0.01))
	var player: Player = get_tree().get_first_node_in_group("Player")
	if not player.is_node_ready():
		await player.ready
	if not player.camera_rotating.is_connected(check_camera_angle):
		player.camera_rotating.connect(check_camera_angle)
	check_camera_angle(player.cameraPivot.rotation.y)

## Checks for obstacles.
func check_camera_angle(angle: float) -> void:
	angle = snappedf(abs(angle) / PI, 0.01)
	if angle > 2.01: angle = fmod(angle, 2.0)
	if angle in invalidAngles:
		hide()
	else:
		show()

## Sets all color changes
func set_color_changes() -> void:
	if not is_node_ready():
		await ready
	shineMaterial = shine.get_surface_override_material(0).duplicate()
	shine.set_surface_override_material(0, shineMaterial)
	for mesh in meshes:
		var material: ShaderMaterial = mesh.get_surface_override_material(0).duplicate()
		material.set_shader_parameter("albedo", albedo)
		material.set_shader_parameter("emission", emission)
		mesh.set_surface_override_material(0, material)
	for light in omniLights:
		light.light_color = lightColor
