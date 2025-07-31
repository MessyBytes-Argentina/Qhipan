extends CharacterBody3D
class_name StickerBase

@export_range(0, 5, 0.1) var height: float = 0.4
@export_range(0, 20, 0.1) var gravity: float = 6

@onready var areaChecker: Area3D = %AreaChecker

var sceneParent: Node
var onPlayer: bool = false

func _ready() -> void:
	sceneParent = get_parent()

func place_sticker(pos: Vector3) -> void:
	global_position = pos
	# here goes sticker interactions and stuff

func _physics_process(delta: float) -> void:
	if not is_on_floor() and not onPlayer:
		velocity += Vector3.DOWN * gravity * delta
	else :
		velocity = Vector3.ZERO
	move_and_slide()

func grab(node: Node3D) -> void:
	onPlayer = true
	global_position = node.global_position
	global_position.y = global_position.y + height

func drop() -> void:
	global_position.y = global_position.y - height
	onPlayer = false
	reparent(sceneParent)
