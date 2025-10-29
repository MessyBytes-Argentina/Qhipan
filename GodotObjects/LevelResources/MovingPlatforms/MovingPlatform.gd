extends AnimatableBody3D
class_name MovingPlatform

const waitTimer: float = 0.5

@export var railReference: PlatformRail
@export var isPermanent: bool = false
@export var powered: bool = false

@onready var stopCheck: Area3D = %StopCheck
@onready var playerChecker: Area3D = %PlayerChecker

func _ready() -> void:
	playerChecker.body_entered.connect(check_power)
	stopCheck.body_entered.connect(stop_moving)

func check_power(_body) -> void:
	if powered or isPermanent:
		await get_tree().create_timer(waitTimer).timeout
		railReference.start_moving()

func stop_moving(body) -> void:
	if body == self: return
	railReference.stop_moving()

func switch_state() -> void:
	powered = !powered
