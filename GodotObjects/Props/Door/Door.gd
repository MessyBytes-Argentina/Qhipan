extends Node3D

@onready var doorBody: DoorBody = %DoorBody
@onready var bodyShape: CollisionShape3D = %BodyShape
@onready var doorArea: Area3D = %Area3D
@onready var areaShape: CollisionShape3D = %AreaShape

func _ready() -> void:
	doorBody.open.connect(open_door)

func open_door() -> void:
	hide()
	bodyShape.disabled = true
	areaShape.disabled = true
