extends Button


#@export var levelList: Array[PackedScene]

## Called when the node enters the scene tree for the first time.
func _ready() -> void:
	GeneralVariables.input_mode_changed.connect(set_controller_mode)
	set_controller_mode(GeneralVariables.usingGamepad)
	pressed.connect(restart)

## Switches between mouse and controller for selection
func set_controller_mode(isController: bool) -> void:
	if isController: grab_focus()
	else: release_focus()

## Calls the LevelManager to load the first level of the current list
func restart() -> void:
	LevelManager.change_to_id(0)
