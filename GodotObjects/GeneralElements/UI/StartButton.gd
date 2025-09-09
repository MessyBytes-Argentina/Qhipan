extends Button

## List of scene paths for the levels to be loaded.
@export var levelList: Array[String]
## Setting button reference.
@onready var settingsButton: Button = $"../Settings"

## Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pressed.connect(start)
	GeneralVariables.input_mode_changed.connect(set_controller_mode)
	PopupManager.closed_popup.connect(_on_settings_closed)
	set_controller_mode(GeneralVariables.usingGamepad)

## Switches between mouse and controller for selection
func set_controller_mode(isController: bool) -> void:
	if isController: grab_focus()
	else: 
		release_focus()
		settingsButton.release_focus()

## Calls LevelManager to assaing the list of levels and load the first one
func start() -> void:
	LevelManager.set_list(levelList)

## Returns the focus to the button if a settings popup was closed and using a controller
func _on_settings_closed(popupName: String) -> void:
	if popupName != "Settings": return
	if GeneralVariables.usingGamepad: settingsButton.grab_focus()
