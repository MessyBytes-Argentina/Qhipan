extends Node3D

@onready var doorBody: DoorBody = %DoorBody
@onready var bodyShape: CollisionShape3D = %BodyShape
@onready var areaShape: CollisionShape3D = %AreaShape1
@onready var areaShape2: CollisionShape3D = %AreaShape2

func _ready() -> void:
	doorBody.open.connect(open_door)

func open_door() -> void:
	hide()
	bodyShape.disabled = true
	areaShape.disabled = true
	areaShape2.disabled = true
