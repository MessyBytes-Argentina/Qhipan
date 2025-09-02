extends Node3D

const MINLENGTH: float = 0.1
const LENGTH: float = 0.75
const JUMPDISTANCE: float = 0.25

@onready var raycast: RayCast3D = $RayCast3D
@onready var raycast2: RayCast3D = $RayCast3D/RayCast3D2
@onready var meshSphere: MeshInstance3D = $RayCast3D/MeshInstance3D
@onready var player: Player = $".."

var material: ORMMaterial3D

func _ready() -> void:
	material = meshSphere.get_surface_override_material(0)

func _physics_process(_delta: float) -> void:
	if (player.moveDirection * Vector3(1, 0, 1)).length() > MINLENGTH:
		raycast.position = LENGTH * player.moveDirection
		raycast.target_position = -raycast.position
	if raycast2.is_colliding():
		material.albedo_color = Color.TRANSPARENT
		return
	if raycast.get_collision_point().distance_to(raycast.global_position) > LENGTH - JUMPDISTANCE: print("doJump")
	if raycast.is_colliding():
		if raycast.get_collision_point().distance_to(raycast.global_position) < MINLENGTH:
			material.albedo_color = Color.TRANSPARENT
			return
		meshSphere.global_position = raycast.get_collision_point() * Vector3(1, 0, 1) + Vector3(0, meshSphere.global_position.y, 0)
		material.albedo_color = Color.RED
	else: material.albedo_color = Color.TRANSPARENT
