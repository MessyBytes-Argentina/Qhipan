extends Button

## Music Volume Slider reference.
@export var music: VolumeHSlider
## SFX Volume Slider reference.
@export var sound: VolumeHSlider 
## CloseButton reference.
@export var closeButton: Button

## Called when the node enters the scene tree for the first time.
func _ready() -> void:
	GeneralVariables.input_mode_changed.connect(set_controller_mode)
	if not get_tree().get_first_node_in_group("Player"):
		hide()
		sound._slider.focus_neighbor_bottom = ""
	set_controller_mode(GeneralVariables.usingGamepad)
	pressed.connect(_on_pressed)

## Restarts the level and closes the popup when pressed
func _on_pressed() -> void:
	LevelManager.do_restart()
	PopupManager.close_popup_by_name("Settings")

## Switches between mouse and controller for selection
func set_controller_mode(isController: bool) -> void:
	if isController: music._slider.grab_focus()
	else: 
		release_focus()
		music._slider.release_focus()
		sound._slider.release_focus()
		closeButton.release_focus()
