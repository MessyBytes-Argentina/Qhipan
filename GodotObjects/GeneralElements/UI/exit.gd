extends Button

#@export var settingsScene: Control

## Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pressed.connect(exit_game)

## When pressed opens the settings window
func exit_game() -> void:
	get_tree().quit()
