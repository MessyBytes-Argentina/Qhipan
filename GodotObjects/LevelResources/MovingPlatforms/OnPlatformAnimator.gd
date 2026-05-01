extends AnimationPlayer
class_name OnPlatformAnimator

@export var platformReference: MovingPlatform
@export var areaReference: Area3D

var turnedOn: bool = false
var playerIsOn: bool = false

## Called when the node enters the scene tree for the first time.
func _ready() -> void:
	platformReference.state_switched.connect(check_animation.unbind(1))
	platformReference.player_step.connect(check_animation.unbind(1))
	areaReference.body_entered.connect(on_player_entered.unbind(1))
	areaReference.body_exited.connect(on_player_exited.unbind(1))
	check_animation()

func check_animation() -> void:
	print(platformReference.playerOnTop)
	if platformReference.mode in ["on", "permanent"] and (playerIsOn or platformReference.playerOnTop) and not turnedOn:
		turnedOn = true
		play("On")
	elif ((not playerIsOn and not platformReference.playerOnTop) or platformReference.mode == "off") and turnedOn:
		turnedOn = false
		play("Off")

func on_player_entered() -> void:
	playerIsOn = true
	check_animation()

func on_player_exited() -> void:
	playerIsOn = false
	check_animation()
