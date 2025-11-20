@tool
extends Area3D
class_name EnvironmentLerper

const SHAPEPARAMETERS: Dictionary[String, Variant] = {"areaColor": Color.BLUE_VIOLET * Color(Color.WHITE, 0.5), "shapeSize": Vector3.ONE * 0.25, "shapeRotation": Vector3(35.4, 60.2, 45.3), "startColor": Color.CHARTREUSE * Color(Color.WHITE, 0.85), "endColor": Color.CRIMSON * Color(Color.WHITE, 0.85)}

@export var startEnvironment: EnvironmentParameters
@export var startLight: LightParameters
@export var endEnvironment: EnvironmentParameters
@export var endLight: LightParameters
@export_range(0.0, 1.0, 0.01) var startSkyLerp: float = 0.0
@export_range(0.0, 1.0, 0.01) var endSkyLerp: float = 1.0

var areaShape: CollisionShape3D
var startMarker: Node3D
var endMarker: Node3D
var playerInside: bool = false
var player: Player
var environment: WorldEnvironment
var sun: DirectionalLight3D

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

func _body_entered(_body: Node3D) -> void:
	playerInside = true

func _body_exited(_body: Node3D) -> void:
	playerInside = false
	if startMarker.global_position.distance_to(player.global_position) < endMarker.global_position.distance_to(player.global_position):
		startEnvironment.set_environment(environment.environment)
		startLight.set_sun(sun)
	else:
		endEnvironment.set_environment(environment.environment)
		endLight.set_sun(sun)

func _physics_process(_delta: float) -> void:
	if not playerInside: return
	var projection: Vector3 = project_point_on_line(player.global_position, startMarker.global_position, endMarker.global_position)
	var progress: float = inverse_lerp(0.0, startMarker.global_position.distance_to(endMarker.global_position), startMarker.global_position.distance_to(projection))
	lerp_environment(progress)

func project_point_on_line(P : Vector3, A : Vector3, B : Vector3) -> Vector3:
	var line_direction = B - A
	var line_length = line_direction.length()
	line_direction = line_direction.normalized()
	var change = P-A
	var project_length : float = clampf(change.dot(line_direction), 0, line_length)
	return A + line_direction*project_length

func lerp_environment(progress: float) -> void:
	startLight.lerp_to(endLight, progress).set_sun(sun)
	startEnvironment.lerp_to(endEnvironment, progress, clampf(inverse_lerp(startSkyLerp, endSkyLerp, progress), 0.0, 1.0)).set_environment(environment.environment)
