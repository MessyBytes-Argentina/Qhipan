extends CharacterBody3D
class_name StickerBase

@export_range(0, 5, 0.1) var height: float = 0.4

var sceneParent: Node

func _ready() -> void:
	sceneParent = get_parent()

func grab(node: Node3D) -> void:
	global_position = node.global_position
	global_position.y = global_position.y + height

func drop() -> void:
	reparent(sceneParent)
	global_position.y = global_position.y - height
	
