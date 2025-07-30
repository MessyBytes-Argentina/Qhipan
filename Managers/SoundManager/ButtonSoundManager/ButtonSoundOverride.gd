@icon("../Sound.svg")
extends Node

## This class holds sounds for buttons that override the generic sounds from the [ButtonSoundManagerObject]. Add this object as a child of a button to override.
class_name ButtonSoundOverride

## The sound to play on hovering the button
@export_file("*.ogg", "*.mp3") var hoverSound: String
## The sound to play on clicking the button
@export_file("*.ogg", "*.mp3") var clickSound: String

## The hovering audio player
@onready var loadedHoverSound: AudioStreamPlayer = AudioStreamPlayer.new()
## The click audio player
@onready var loadedClickSound: AudioStreamPlayer = AudioStreamPlayer.new()

## Set up audio stream players and load sound files.
func _ready() -> void:
	loadedHoverSound.stream = load(hoverSound)
	loadedHoverSound.bus = ButtonSoundManager.busName
	loadedClickSound.stream = load(clickSound)
	loadedClickSound.bus = ButtonSoundManager.busName
