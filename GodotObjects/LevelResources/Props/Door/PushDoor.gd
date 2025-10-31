extends Node3D
class_name PushDoor

## Door animation names.
enum Animations {SlideLeft, SlideRight, SlideUp, SlideDown, RotateToFloor, RotateToCeiling}

## Selected animation name.
@export var openAnimation: Animations = Animations.SlideLeft

## Node reference to connect open signal.
@onready var doorBody: DoorBody = %DownPivot
## Area3D for Player detection.
@onready var playerPushChecker: Area3D = %PlayerPushChecker
## AnimationPlayer reference.
@onready var animationPlayer: AnimationPlayer = %AnimationPlayer
## SoundPlayer for the open sound
@onready var openSound: RandomPitchPlayer = %OpenSound

## Called when the node enters the scene tree for the first time.
func _ready() -> void:
	doorBody.open.connect(open_door)

## Opens the door and deactivates the placement areas.
func open_door() -> void:
	animationPlayer.play(Animations.keys()[openAnimation])
	openSound.play_sound()
