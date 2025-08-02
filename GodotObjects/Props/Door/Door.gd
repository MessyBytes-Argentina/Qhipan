extends Node3D

enum Animations {SlideLeft, SlideRight, SlideUp, SlideDown, RotateToFloor, RotateToCeiling}

@export var openAnimation: Animations = Animations.SlideLeft

@onready var doorBody: DoorBody = %DoorBody
@onready var bodyShape: CollisionShape3D = %BodyShape
@onready var area3d: Area3D = %Area3D
@onready var area3d2: Area3D = %Area3D2
@onready var animationPlayer: AnimationPlayer = %AnimationPlayer

func _ready() -> void:
	doorBody.open.connect(open_door)
	area3d.set_meta("pointing", area3d.global_position.direction_to(area3d.get_node("Marker3D").global_position))
	area3d2.set_meta("pointing", area3d2.global_position.direction_to(area3d2.get_node("Marker3D").global_position))

func open_door() -> void:
	#hide()
	#bodyShape.disabled = true
	area3d.set_deferred("monitorable", false)
	area3d2.set_deferred("monitorable", false)
	animationPlayer.play(Animations.keys()[openAnimation])
