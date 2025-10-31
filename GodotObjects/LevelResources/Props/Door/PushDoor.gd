extends Node3D
class_name PushDoor

## Door animation names.
enum Animations {SlideLeft, SlideRight, SlideUp, SlideDown, RotateToFloor, RotateToCeiling}

## Selected animation name.
@export var openAnimation: Animations = Animations.SlideLeft
## Flag that closes the door after activation
@export var isOneWay: bool = false

## Node reference to connect open signal.
@onready var doorBody: DoorBody = %DownPivot
## AnimationPlayer reference.
@onready var animationPlayer: AnimationPlayer = %AnimationPlayer
## SoundPlayer for the open sound
@onready var openSound: RandomPitchPlayer = %OpenSound

## Called when the node enters the scene tree for the first time.
func _ready() -> void:
	doorBody.open.connect(open_door)

## Opens the door.
func open_door() -> void:
	animationPlayer.play(Animations.keys()[openAnimation])
	openSound.play_sound()

## Closes the door.
func close_door() -> void:
	animationPlayer.play_backwards(Animations.keys()[openAnimation])
	openSound.play_sound()
