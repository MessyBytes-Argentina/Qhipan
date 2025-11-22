extends RayCast3D
class_name DetectionRaycast

const MINLENGTH: float = 0.1
const LENGTH: float = 0.75

@onready var verticalRaycast: RayCast3D = %VerticalRayCast
@onready var meshSphere: MeshInstance3D = %MeshInstance3D

var material: ORMMaterial3D
var previousDistance: float = 0
var isDetecting: bool = false
var currentDistance: float = 1

func _ready() -> void:
	material = meshSphere.get_surface_override_material(0)

func set_detecting(value: bool) -> void:
	isDetecting = value

func _physics_process(_delta: float) -> void:
	if not isDetecting: return
	
	var collisionPoint: Vector3
	if is_colliding():
		collisionPoint = get_collision_point()
		if collisionPoint.distance_to(global_position) < MINLENGTH:
			material.albedo_color = Color.TRANSPARENT
			previousDistance = 0
			return
		var raycast2NewPosition = to_local(collisionPoint) * Vector3(1, 0, 1)
		verticalRaycast.position = raycast2NewPosition + verticalRaycast.position * Vector3.UP - raycast2NewPosition.normalized() * MINLENGTH
	else:
		previousDistance = 0
		return
	if verticalRaycast.is_colliding():
		material.albedo_color = Color.TRANSPARENT
		previousDistance = 0
		return
	
	meshSphere.global_position = get_collision_point() * Vector3(1, 0, 1) + Vector3(0, meshSphere.global_position.y, 0)
	material.albedo_color = Color.GREEN
	
	currentDistance = LENGTH - collisionPoint.distance_to(global_position)
	if currentDistance < 0:
		previousDistance = 0
		return
	
	previousDistance = currentDistance
