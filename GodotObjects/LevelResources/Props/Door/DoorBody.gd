extends Node3D
class_name DoorBody

signal open

## Called when the key animation ends
func open_door() -> void:
	emit_signal("open")
