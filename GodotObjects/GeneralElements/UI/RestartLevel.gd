extends Button

@export var music: VolumeHSlider
@export var sound: VolumeHSlider
@export var closeButton: Button

func _ready() -> void:
	GeneralVariables.input_mode_changed.connect(set_controller_mode)
	if not get_tree().get_first_node_in_group("Player"):
		hide()
		sound._slider.focus_neighbor_bottom = ""
	set_controller_mode(GeneralVariables.usingGamepad)
	pressed.connect(_on_pressed)

func _on_pressed() -> void:
	LevelManager.do_restart()
	PopupManager.close_popup_by_name("Settings")

func set_controller_mode(isController: bool) -> void:
	if isController: music._slider.grab_focus()
	else: 
		release_focus()
		music._slider.release_focus()
		sound._slider.release_focus()
		closeButton.release_focus()
