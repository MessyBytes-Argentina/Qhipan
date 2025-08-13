extends Button

@export var popupName: String = "Settings"

func _ready() -> void:
	pressed.connect(_on_pressed)

func _on_pressed() -> void:
	get_tree().call_group("Player", "set", "onSettings", false)
	PopupManager.close_popup_by_name(popupName)

func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("pause"): _on_pressed()
