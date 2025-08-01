extends CharacterBody3D
class_name StickerBase

@export_range(0, 5, 0.1) var height: float = 0.8
@export_range(0, 20, 0.1) var gravity: float = 6

@onready var areaChecker: Area3D = %AreaChecker
@onready var mesh: MeshInstance3D = %Mesh

var sceneParent: Node
var onPlayer: bool = false
var placed: bool = false

func _ready() -> void:
	sceneParent = get_parent()
	mesh.set_surface_override_material(0, mesh.get_surface_override_material(0).duplicate())

func place_sticker(pos: Vector3, direction: Vector3) -> void:
	global_position = pos + direction * 0.01
	onPlayer = false
	placed = true
	if not Vector3.UP.cross(global_position - direction).is_zero_approx():
		look_at(global_position - direction)
	# here goes sticker interactions and stuff

func _physics_process(_delta: float) -> void:
	#if not is_on_floor() and not onPlayer:
		#velocity += Vector3.DOWN * gravity * delta
	#else :
		#velocity = Vector3.ZERO
	#move_and_slide()
	pass

func grab(node: Node3D) -> void:
	onPlayer = true
	global_position = node.global_position
	global_position.y = global_position.y + height

func drop() -> void:
	global_position.y = global_position.y - height
	onPlayer = false
	placed = false
	reparent(sceneParent)
