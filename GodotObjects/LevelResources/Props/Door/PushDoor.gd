@tool
extends Node3D
class_name PushDoor

## Door animation names.
enum Animations {SlideLeft, SlideRight, SlideUp, SlideDown, RotateToFloor, RotateToCeiling}

## Selected animation name.
@export var openAnimation: Animations = Animations.SlideLeft
## Flag that closes the door after activation
@export var isOneWay: bool = false
## Group to hide storage only variables because export storage doesn't seem to do the thing.
@export_group("Root Reference")
## Parent node reference for placement.
@export var sceneParent: Node

## AnimationPlayer reference.
@onready var animationPlayer: AnimationPlayer = %AnimationPlayer
## SoundPlayer for the open sound
@onready var openSound: RandomSoundPlayer = %OpenSound
## Reference to the push checker.
@onready var playerPushChecker: Area3D = %PlayerPushChecker

## Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if Engine.is_editor_hint():
		sceneParent = get_tree().edited_scene_root

## Opens the door.
func open_door(update: bool = true) -> void:
	if update: 
		animationPlayer.play(Animations.keys()[openAnimation])
		openSound.play_sound()
		if not isOneWay: 
			GeneralVariables.saveManager.store_change(self, sceneParent)
			playerPushChecker.queue_free()
	else:
		animationPlayer.play("Opened")
		playerPushChecker.queue_free()

## Closes the door.
func close_door() -> void:
	animationPlayer.play_backwards(Animations.keys()[openAnimation])
	openSound.play_sound()
