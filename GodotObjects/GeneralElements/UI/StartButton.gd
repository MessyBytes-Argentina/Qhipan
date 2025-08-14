extends Button

@export var levelList: Array[String]
@onready var settingsButton: Button = $"../Settings"

func _ready() -> void:
	pressed.connect(start)
	GeneralVariables.input_mode_changed.connect(set_controller_mode)
	PopupManager.closed_popup.connect(_on_settings_closed)
	set_controller_mode(GeneralVariables.usingGamepad)

func set_controller_mode(isController: bool) -> void:
	if isController: grab_focus()
	else: 
		release_focus()
		settingsButton.release_focus()

func start() -> void:
	LevelManager.set_list(levelList)

func _on_settings_closed(popupName: String) -> void:
	if popupName != "Settings": return
	if GeneralVariables.usingGamepad: settingsButton.grab_focus()
