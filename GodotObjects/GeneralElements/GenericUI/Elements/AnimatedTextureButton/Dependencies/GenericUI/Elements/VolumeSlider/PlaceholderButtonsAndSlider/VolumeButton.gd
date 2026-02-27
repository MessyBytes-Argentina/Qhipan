extends TextureButton

const ANIMATION: Dictionary[String, Variant] = {
	"scale": 1.2,
	"time": 0.5,
	"ease": Tween.EaseType.EASE_OUT, 
	"trans": Tween.TransitionType.TRANS_BACK,
	"rotation": deg_to_rad(30)
}

@export var pivotOffset: Vector2 = Vector2.ZERO

var tween: Tween
var progress: float = 0.0
var goalAngle: float

## Called when the node enters the scene tree for the first time.
func _ready() -> void:
	focus_entered.connect(_on_focus)
	mouse_entered.connect(_on_focus)
	focus_exited.connect(_on_focus_lost)
	mouse_exited.connect(_on_focus_lost)
	pivot_offset = size / 2.0 + pivotOffset

func _on_focus() -> void:
	if tween: if tween.is_running(): tween.kill()
	tween = create_tween()
	var time: float = ANIMATION.time * (1.0 - progress)
	goalAngle = [-1, 1].pick_random() * ANIMATION.rotation
	tween.tween_method(_animation_tick, progress, 1.0, time).set_ease(ANIMATION.ease as Tween.EaseType). set_trans(ANIMATION.trans as Tween.TransitionType)
	tween.play()

func _on_focus_lost() -> void:
	if tween: if tween.is_running(): tween.kill()
	tween = create_tween()
	var time: float = ANIMATION.time * progress
	tween.tween_method(_animation_tick, progress, 0.0, time).set_ease(ANIMATION.ease as Tween.EaseType). set_trans(ANIMATION.trans as Tween.TransitionType)
	tween.play()

func _animation_tick(currentProgress: float) -> void:
	progress = currentProgress
	rotation = lerp(0.0, goalAngle, progress)
	scale = Vector2.ONE * lerp(1.0, ANIMATION.scale, progress)
