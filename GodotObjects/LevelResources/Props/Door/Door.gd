extends Node3D

## Door animation names.
enum Animations {SlideLeft, SlideRight, SlideUp, SlideDown, RotateToFloor, RotateToCeiling}

## Selected animation name.
@export var openAnimation: Animations = Animations.SlideLeft

## Node reference to connect open signal.
@onready var doorBody: DoorBody = %DownPivot
## Area3D for key placement.
@onready var area3d: Area3D = %Area3D
## Area3D for key placement.
@onready var area3d2: Area3D = %Area3D2
## AnimationPlayer reference.
@onready var animationPlayer: AnimationPlayer = %AnimationPlayer
## SoundPlayer for the open sound
@onready var openSound: RandomPitchPlayer = %OpenSound

## Called when the node enters the scene tree for the first time.
func _ready() -> void:
	doorBody.open.connect(open_door)
	area3d.set_meta("pointing", area3d.global_position.direction_to(area3d.get_node("Marker3D").global_position))
	area3d2.set_meta("pointing", area3d2.global_position.direction_to(area3d2.get_node("Marker3D").global_position))

## Opens the door and deactivates the placement areas.
func open_door() -> void:
	area3d.set_deferred("monitorable", false)
	area3d2.set_deferred("monitorable", false)
	animationPlayer.play(Animations.keys()[openAnimation])
	openSound.play_sound()
