extends Button

@export var levelList: Array[String]

func _ready() -> void:
	GeneralVariables.input_mode_changed.connect(set_controller_mode)
	set_controller_mode(GeneralVariables.usingGamepad)
	pressed.connect(start)

func set_controller_mode(isController: bool) -> void:
	if isController: grab_focus()
	else: 
		release_focus()
		$"../Settings".release_focus()

func start() -> void:
	LevelManager.set_list(levelList)
