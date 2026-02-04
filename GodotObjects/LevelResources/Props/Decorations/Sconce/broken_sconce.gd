extends Node3D

const SPACING: Vector2 = Vector2(2.0, 5.0)

@onready var animationPlayer: AnimationPlayer = $AnimationPlayer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	while true:
		randomize()
		await get_tree().create_timer(randf_range(SPACING.x, SPACING.y)).timeout
		animationPlayer.play("idle")
		await animationPlayer.animation_finished
