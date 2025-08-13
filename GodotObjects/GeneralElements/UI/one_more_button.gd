extends Button

@export var levelList: Array[PackedScene]

func _ready() -> void:
	GeneralVariables.input_mode_changed.connect(set_controller_mode)
	set_controller_mode(GeneralVariables.usingGamepad)
	pressed.connect(next)

func set_controller_mode(isController: bool) -> void:
	if isController: grab_focus()
	else: release_focus()

func next() -> void:
	LevelManager.next_level()
