@tool
extends MeshInstance3D

## This class updates shader parameters for objects that need to be cut off when they obstructs the player.
class_name CutoutCube

## Value to offset the cutout cylinder to after the camera.
const offset: float = 0.0

## Auto aligns the cutout cylinder.
@export_tool_button("Align") var allignAction: Callable = align_position

## Reference to the cutout cylinder.
@onready var cylinder: MeshInstance3D = %CutoutCylinder
## Reference to the cutout player floor.
@onready var playerFloor: Marker3D = %PlayerFloor
## Reference to the camera ray casts group.
@onready var cameraRayCasts: Node3D = %CameraRayCasts
## Reference to the fog ray casts group.
@onready var fogRayCasts: Node3D = %FogRayCasts
## Reference to the secondary cutout cube.
@onready var cubeCutoutAux: MeshInstance3D = %CubeCutoutAux

## The up reference for the camera.
var up: Marker3D
## Is the player zooming out.
var zoomedOut: bool = false
## Should we use the secondary cube for the cutout. Used for 45 degree angles to prevent cutting out blocks diagonally.
var auxMode: bool = false
## Reference to the player.
var player: Player
## Rotating camera.
var rotatingCamera: bool = false

## Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if Engine.is_editor_hint(): return
	hide()
	player = get_tree().get_first_node_in_group("Player")
	if not player.is_node_ready(): await player.ready
	cylinder.hide()
	if not up:
		up = Marker3D.new()
		cylinder.add_child(up)
		up.position = Vector3.UP
	for updateMaterial: ShaderMaterial in GeneralVariables.cutoutMaterials: 
		updateMaterial.set_shader_parameter("boxSize", mesh.size)
		updateMaterial.set_shader_parameter("cylinderRadius2", cylinder.mesh.bottom_radius)
		updateMaterial.set_shader_parameter("cylinderRadius1", cylinder.mesh.top_radius)
		updateMaterial.set_shader_parameter("cylinderHeight", cylinder.mesh.height)
		updateMaterial.set_shader_parameter("squareSize", abs(player.cameraCubeWallCutout.position.z) / sqrt(2.0))

## Called during the processing step of the main loop.
func _physics_process(_delta: float) -> void:
	if Engine.is_editor_hint(): return
	var anyRaycast: bool = not cameraRayCasts.get_children().any(func(a: RayCast3D): return not a.is_colliding())
	var anyFogRaycast: bool = not fogRayCasts.get_children().any(func(a: RayCast3D): return not a.is_colliding())
	for updateMaterial: ShaderMaterial in GeneralVariables.uniqueCutoutMaterials: update_material(updateMaterial, anyRaycast)
	for fog in get_tree().get_nodes_in_group("Fog"): update_material(fog.material, anyFogRaycast)

## Updates the cutout parameters to match the current cylinder and cube positions and rotations.
func update_material(updateMaterial: ShaderMaterial, anyRaycast: bool) -> void:
	updateMaterial.set_shader_parameter("cylinderCutout", anyRaycast and not zoomedOut)
	updateMaterial.set_shader_parameter("boxPosition", global_position)
	updateMaterial.set_shader_parameter("boxRotation", global_rotation.y)
	updateMaterial.set_shader_parameter("cylinderPosition", cylinder.global_position)
	updateMaterial.set_shader_parameter("cylinderRotation", cylinder.global_position - up.global_position)
	updateMaterial.set_shader_parameter("playerPosition", playerFloor.global_position)
	updateMaterial.set_shader_parameter("globalPlayerPosition", player.global_position)
	updateMaterial.set_shader_parameter("cameraMiddlePoint", player.cameraCubeWallCutout.global_position)
	updateMaterial.set_shader_parameter("cameraMiddleRotation", global_rotation.y)
	updateMaterial.set_shader_parameter("auxMode", auxMode)
	updateMaterial.set_shader_parameter("rotating", rotatingCamera)
	updateMaterial.set_shader_parameter("auxBoxPosition", cubeCutoutAux.global_position)
	updateMaterial.set_shader_parameter("auxBoxRotation", cubeCutoutAux.global_rotation.y)
	updateMaterial.set_shader_parameter("player_sticker_radius", LampSticker.LIGHTRANGEGRABED if player.darknessBlockerModule.holdingLight else 0.0)

## Aligns the cylinder position using the provided offset.
func align_position() -> void:
	cylinder.position = (cylinder.mesh.height / 2 + offset) * Vector3.FORWARD
