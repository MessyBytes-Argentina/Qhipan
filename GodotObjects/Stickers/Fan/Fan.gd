extends StickerBase

@onready var animationPlayer: AnimationPlayer = %AnimationPlayer
@onready var fanParticles: GPUParticles3D = %FanParticles

func _ready() -> void:
	super()

func place_sticker(area: Area3D, direction: Vector3) -> void:
	super(area, direction)
	animationPlayer.play("SpinUp")

func grab(node: Node3D) -> void:
	super(node)
	animationPlayer.play("RESET")
