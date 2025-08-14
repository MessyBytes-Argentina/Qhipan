extends StickerBase

@onready var animationPlayer: AnimationPlayer = %AnimationPlayer
@onready var fanParticles: GPUParticles3D = %FanParticles
@onready var spinupSound: RandomPitchPlayer = %SpinupSound
@onready var fan: Fan = %Fan

func _ready() -> void:
	fanParticles.emitting = true
	super()
	if not placed:
		await get_tree().create_timer(0.5).timeout
		fanParticles.emitting = false

func place_sticker(area: Area3D, direction: Vector3) -> void:
	if grabed:
		spinupSound.play_sound()
	super(area, direction)
	animationPlayer.play("SpinUp")

func grab(node: Node3D) -> void:
	super(node)
	animationPlayer.play("RESET")
	fanParticles.emitting = false
	fan.switch_fan(false)
	grabed = true

func _process(delta: float) -> void:
	if not grabed and fan.isOn:
		fan.switch_fan(false)
