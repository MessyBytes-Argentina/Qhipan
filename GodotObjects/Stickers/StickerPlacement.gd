extends Area3D

@onready var target: Marker3D = %Target


func get_target_position() -> Vector3:
	return target.global_position
