extends Button

@export var settingsScene: Control

func _ready() -> void:
	pressed.connect(open_settings)

func open_settings() -> void:
	PopupManager.show_popup("Settings")
	release_focus()
