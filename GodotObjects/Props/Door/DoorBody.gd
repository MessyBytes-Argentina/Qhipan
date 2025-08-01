extends StaticBody3D
class_name DoorBody

signal open

func open_door() -> void:
	emit_signal("open")
