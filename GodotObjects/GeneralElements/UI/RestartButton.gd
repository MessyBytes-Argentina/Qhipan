extends Button

const playScreen: String = "uid://3iena3lvxxgn"
## Exit button reference.
@onready var surveyButton: Button = $"../SurveyButton"

## Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pressed.connect(restart)
	GeneralVariables.input_mode_changed.connect(set_controller_mode)
	set_controller_mode(GeneralVariables.usingGamepad)
	## BULLSHIT FOR THE DEMO
	GeneralVariables.inventory.book.get_parent().hide()

## Switches between mouse and controller for selection
func set_controller_mode(isController: bool) -> void:
	if isController: grab_focus()
	else: 
		release_focus()
		surveyButton.release_focus()

## Calls the LevelManager to load the first level of the current list
func restart() -> void:
	GeneralVariables.sceneManager.shaderColorRect.color = Color.BLACK
	GeneralVariables.sceneManager.load_and_switch(playScreen)
