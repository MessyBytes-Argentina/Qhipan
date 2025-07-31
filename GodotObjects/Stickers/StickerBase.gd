extends CharacterBody3D
class_name StickerBase

@export_range(0, 5, 0.1) var height: float = 0.4
@export_range(0, 20, 0.1) var gravity: float = 6

var sceneParent: Node
var isActive: bool = true

func _ready() -> void:
	sceneParent = get_parent()

func _physics_process(delta: float) -> void:
	if not is_on_floor() and isActive:
		velocity += Vector3.DOWN * gravity * delta
	else :
		velocity = Vector3.ZERO
	move_and_slide()

func toggle_active() -> void:
	isActive = !isActive

func grab(node: Node3D) -> void:
	toggle_active()
	global_position = node.global_position
	global_position.y = global_position.y + height

func drop() -> void:
	toggle_active()
	reparent(sceneParent)
	global_position.y = global_position.y - height
	
