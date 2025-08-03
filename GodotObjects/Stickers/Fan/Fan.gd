extends StickerBase

@onready var animationPlayer: AnimationPlayer = %AnimationPlayer
@onready var fanParticles: GPUParticles3D = %FanParticles
@onready var spinupSound: RandomPitchPlayer = %SpinupSound

var grabed: bool = false

func _ready() -> void:
	super()

func place_sticker(area: Area3D, direction: Vector3) -> void:
	super(area, direction)
	animationPlayer.play("SpinUp")
	if grabed:
		spinupSound.play_sound()

func grab(node: Node3D) -> void:
	super(node)
	animationPlayer.play("RESET")
	grabed = true
