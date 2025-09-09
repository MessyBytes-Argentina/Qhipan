extends Button

#@export var settingsScene: Control

## Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pressed.connect(open_settings)

## When pressed opens the settings window
func open_settings() -> void:
	PopupManager.show_popup("Settings")
	release_focus()
