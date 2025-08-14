extends Button

@export var levelList: Array[PackedScene]

func _ready() -> void:
	GeneralVariables.input_mode_changed.connect(set_controller_mode)
	set_controller_mode(GeneralVariables.usingGamepad)
	pressed.connect(restart)

func set_controller_mode(isController: bool) -> void:
	if isController: grab_focus()
	else: release_focus()

func restart() -> void:
	LevelManager.change_to_id(0)
