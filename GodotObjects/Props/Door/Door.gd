extends Node3D

@onready var doorBody: DoorBody = %DoorBody

func _ready() -> void:
	doorBody.open.connect(open_door)

func open_door() -> void:
	hide()
