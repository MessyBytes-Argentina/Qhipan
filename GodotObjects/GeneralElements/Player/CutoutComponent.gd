extends Node

## This class updates shader parameters for objects that need to be cut off when they obstructs the player.
class_name CutoutCube

## Cone base radius.
const CONEBASE: float = 1.0
## Cone tip radius.
const CONETIP: float = 0.5
## Cone extra length.
const CONEEXTRA: float = 2.0
## Collision layers to block raycast.
const RAYCOLLISIONLAYERS: Array[int] = [4]

## Reference to the cutout player floor.
@onready var playerFloor: Node3D = %SpritePivot
## Reference to the ray markers container.
@onready var raycastMarkers: Node3D = %RaycastMarkers

## Reference to the player.
var player: Player
## Layers turned into usable mask.
var layerMask: int
## The up direction.
var up: Node3D
## Reference to the ray markers.
var rayMarkers: Array[Marker3D] = []

## Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if Engine.is_editor_hint(): return
	player = get_tree().get_first_node_in_group("Player")
	if not player.is_node_ready(): await player.ready
	up = Node3D.new()
	player.add_child(up)
	up.name = "Up"
	up.position = Vector3.UP
	for marker in raycastMarkers.get_children():
		if marker is Marker3D: rayMarkers.append(marker)
	layerMask = RAYCOLLISIONLAYERS.reduce(func(accum: int, a: int = 0): return accum + pow(2, a - 1), 0)
	for updateMaterial: ShaderMaterial in GeneralVariables.cutoutMaterials:
		updateMaterial.set_shader_parameter("cylinderRadius2", CONEBASE)
		updateMaterial.set_shader_parameter("cylinderRadius1", CONETIP)

## Called during the processing step of the main loop.
func _physics_process(_delta: float) -> void:
	if Engine.is_editor_hint(): return
	var spaceState: PhysicsDirectSpaceState3D = player.get_world_3d().direct_space_state
	if not player.currentCamera: return
	var anyRaycast: bool = rayMarkers.any(func(a: Marker3D):
		var raycast = PhysicsRayQueryParameters3D.create(player.currentCamera.global_position, a.global_position)
		raycast.collision_mask = layerMask
		return not not spaceState.intersect_ray(raycast)
	)
	for updateMaterial: ShaderMaterial in GeneralVariables.uniqueCutoutMaterials: update_material(updateMaterial, anyRaycast)
	for fog in get_tree().get_nodes_in_group("Fog"): update_material(fog.material, anyRaycast)

## Updates the cutout parameters to match the current cylinder and cube positions and rotations.
func update_material(updateMaterial: ShaderMaterial, anyRaycast: bool) -> void:
	updateMaterial.set_shader_parameter("cylinderCutout", anyRaycast)
	updateMaterial.set_shader_parameter("cylinderHeight", player.currentCamera.global_position.distance_to(player.global_position) + CONEEXTRA)
	var cylinderPosition: Vector3 = player.currentCamera.global_position + player.currentCamera.global_position.direction_to(player.global_position) * (player.currentCamera.global_position.distance_to(player.global_position) / 2.0)
	updateMaterial.set_shader_parameter("cylinderPosition", cylinderPosition)
	updateMaterial.set_shader_parameter("cylinderRotation", player.currentCamera.global_position - up.global_position)
	updateMaterial.set_shader_parameter("playerPosition", playerFloor.global_position)
	updateMaterial.set_shader_parameter("globalPlayerPosition", player.global_position)
	updateMaterial.set_shader_parameter("cameraMiddleRotation", playerFloor.global_rotation.y)
	updateMaterial.set_shader_parameter("player_sticker_radius", LampSticker.LIGHTRANGEGRABED if player.darknessBlockerModule.holdingLight else 0.0)
