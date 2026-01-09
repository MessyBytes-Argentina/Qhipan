@tool
extends Area3D

## This class manages interpolating environment and light parameters.
class_name EnvironmentLerper

## Constant for debug appearance.
const SHAPEPARAMETERS: Dictionary[String, Variant] = {"areaColor": Color.BLUE_VIOLET * Color(Color.WHITE, 0.5), "shapeSize": Vector3.ONE * 0.25, "shapeRotation": Vector3(35.4, 60.2, 45.3), "startColor": Color.CHARTREUSE * Color(Color.WHITE, 0.85), "endColor": Color.CRIMSON * Color(Color.WHITE, 0.85)}

## The environment for the start of the lerper.
@export var startEnvironment: EnvironmentParameters
## The light for the start of the lerper.
@export var startLight: LightParameters
## The environment for the end of the lerper.
@export var endEnvironment: EnvironmentParameters
## The light for the end of the lerper.
@export var endLight: LightParameters
## Minimum distance from the start of the lerper to start lerping to the end.
@export_range(0.0, 1.0, 0.01) var startSkyLerp: float = 0.0
## Maximum distance from the start of the lerper to end lerping to the end.
@export_range(0.0, 1.0, 0.01) var endSkyLerp: float = 1.0

## Reference to the area shape.
var areaShape: CollisionShape3D
## Reference to the start debug marker.
var startMarker: Node3D
## Reference to the end debug marker.
var endMarker: Node3D
## Flag that is on while the player is inside the lerper area.
var playerInside: bool = false
## Reference to the player.
var player: Player
## Reference to the environment object.
var environment: WorldEnvironment
## Reference to the sun object.
var sun: DirectionalLight3D

## Executed when node first enters the scene tree.
func _ready() -> void:
	if Engine.is_editor_hint():
		set_collision_layer_value(1, false)
		set_collision_mask_value(1, false)
		set_collision_mask_value(2, true)
		monitorable = false
		if not has_node("AreaShape"):
			areaShape = CollisionShape3D.new()
			areaShape.name = "AreaShape"
			areaShape.debug_color = Color.BLUE_VIOLET * Color(Color.WHITE, 0.5)
			add_child(areaShape)
			areaShape.owner = get_tree().edited_scene_root
		for marker: String in ["start", "end"]:
			var currentMarker: Node3D
			if not has_node(marker.capitalize() + "Marker"):
				currentMarker = Node3D.new()
				currentMarker.name = marker.capitalize() + "Marker"
				add_child(currentMarker)
				currentMarker.owner = get_tree().edited_scene_root
				set(marker + "Marker", currentMarker)
			else:
				currentMarker = get_node(marker.capitalize() + "Marker")
			var currentMaterial: ORMMaterial3D = ORMMaterial3D.new()
			currentMaterial.albedo_color = SHAPEPARAMETERS[marker + "Color"]
			currentMaterial.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_DEPTH_PRE_PASS
			var currentShape: BoxMesh = BoxMesh.new()
			currentShape.size = SHAPEPARAMETERS.shapeSize
			currentShape.material = currentMaterial
			var currentMesh: MeshInstance3D = MeshInstance3D.new()
			currentMesh.mesh = currentShape
			currentMarker.add_child(currentMesh)
			currentMesh.rotation_degrees = SHAPEPARAMETERS.shapeRotation
	else:
		if has_node("AreaShape"):
			areaShape = get_node("AreaShape")
		if has_node("StartMarker"):
			startMarker = get_node("StartMarker")
		if has_node("EndMarker"):
			endMarker = get_node("EndMarker")
		body_entered.connect(_body_entered)
		body_exited.connect(_body_exited)
		await get_tree().process_frame
		player = get_tree().get_first_node_in_group("Player")
		var environmentObjects: Node3D = get_tree().get_first_node_in_group("EnvironmentObjects")
		environment = environmentObjects.get_node(environmentObjects.get_meta("Environment"))
		sun = environmentObjects.get_node(environmentObjects.get_meta("Sun"))

## Executed when player enters the area.
func _body_entered(body: Node3D) -> void:
	if body is not Player: return
	playerInside = true

## Executed when player exits the area.
func _body_exited(body: Node3D) -> void:
	if body is not Player: return
	playerInside = false
	if startMarker.global_position.distance_to(player.global_position) < endMarker.global_position.distance_to(player.global_position):
		startEnvironment.set_environment(environment.environment)
		startLight.set_sun(sun)
		GeneralVariables.saveManager.save_environment(startEnvironment, startLight)
	else:
		endEnvironment.set_environment(environment.environment)
		endLight.set_sun(sun)
		GeneralVariables.saveManager.save_environment(endEnvironment, endLight)

## Executed on every physics frame.
func _physics_process(_delta: float) -> void:
	if not playerInside: return
	var projection: Vector3 = project_point_on_line(player.global_position, startMarker.global_position, endMarker.global_position)
	var progress: float = inverse_lerp(0.0, startMarker.global_position.distance_to(endMarker.global_position), startMarker.global_position.distance_to(projection))
	lerp_environment(progress)

## Projects player position to lerp line.
func project_point_on_line(P : Vector3, A : Vector3, B : Vector3) -> Vector3:
	var line_direction = B - A
	var line_length = line_direction.length()
	line_direction = line_direction.normalized()
	var change = P-A
	var project_length : float = clampf(change.dot(line_direction), 0, line_length)
	return A + line_direction*project_length

## Lerps the environment and light parameters.
func lerp_environment(progress: float) -> void:
	startLight.lerp_to(endLight, progress).set_sun(sun)
	startEnvironment.lerp_to(endEnvironment, progress, clampf(inverse_lerp(startSkyLerp, endSkyLerp, progress), 0.0, 1.0)).set_environment(environment.environment)
