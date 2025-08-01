extends StickerBase

@onready var animationPlayer: AnimationPlayer = %AnimationPlayer

func place_sticker(pos: Vector3, direction: Vector3) -> void:
	super(pos, direction)
	animationPlayer.play("SpinUp")

func grab(node: Node3D) -> void:
	super(node)
	animationPlayer.play("RESET")
