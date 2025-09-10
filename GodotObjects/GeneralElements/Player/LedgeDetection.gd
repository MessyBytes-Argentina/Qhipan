extends Node3D
class_name LedgeDetection

const MINLENGTH: float = 0.1
const LENGTH: float = 0.75
const JUMPDISTANCE: float = 0.15

const FANPUSHDISTANCE: float = 2
const FANPUSHSTEPS: float = 0.065

@onready var raycast: RayCast3D = $RayCast3D
@onready var raycast2: RayCast3D = $RayCast3D/RayCast3D2
@onready var meshSphere: MeshInstance3D = $RayCast3D/MeshInstance3D
@onready var player: Player = $".."

@onready var forcedMovement: ForcedMovement = %ForcedMovement

var material: ORMMaterial3D
var previousDistance: float = 0
var stickerOnHand: bool = false
var ableToPush: bool = false

func _ready() -> void:
	material = meshSphere.get_surface_override_material(0)

func _physics_process(_delta: float) -> void:
	if not stickerOnHand: return
	
	if not ableToPush:
		if not player.check_falling():
			ableToPush = true
		else:
			return
	
	if (player.moveDirection * Vector3(1, 0, 1)).length() > MINLENGTH:
		raycast.position = LENGTH * player.moveDirection
		raycast.target_position = -raycast.position
	var collisionPoint: Vector3
	if raycast.is_colliding():
		collisionPoint = raycast.get_collision_point()
		if collisionPoint.distance_to(raycast.global_position) < MINLENGTH:
			material.albedo_color = Color.TRANSPARENT
			previousDistance = 0
			return
		var raycast2NewPosition = raycast.to_local(collisionPoint) * Vector3(1, 0, 1)
		raycast2.position = raycast2NewPosition + raycast2.position * Vector3.UP - raycast2NewPosition.normalized() * MINLENGTH
	else:
		previousDistance = 0
		return
	if raycast2.is_colliding():
		material.albedo_color = Color.TRANSPARENT
		previousDistance = 0
		return
	
	meshSphere.global_position = raycast.get_collision_point() * Vector3(1, 0, 1) + Vector3(0, meshSphere.global_position.y, 0)
	material.albedo_color = Color.GREEN
	
	var currentDistance: float = LENGTH - collisionPoint.distance_to(raycast.global_position)
	if currentDistance < 0:
		previousDistance = 0
		return
	
	if currentDistance < JUMPDISTANCE and currentDistance < previousDistance:
		
		var normalDirection: Vector3 = raycast.get_collision_normal()
		if normalDirection == Vector3.ZERO or forcedMovement.forcingPlayer: return
		yeet_the_player(normalDirection)
	
	previousDistance = currentDistance

func yeet_the_player(direction: Vector3) -> void:
	ableToPush = false
	var targetPosition: Vector3 = player.get_grid_position() + (direction * FANPUSHDISTANCE)
	forcedMovement.force_player_to(targetPosition,FANPUSHSTEPS)

func enable_push() -> void:
	stickerOnHand = true
	ableToPush = true

func disable_push() -> void:
	stickerOnHand = false
	ableToPush = false
