extends TextureProgressBar

## Animated [TextureProgressBar] node. Call [method set_new_value] to set new values.
class_name AnimatedTextureProgressBar

## A reference to the background [TextureProgressBar].
@onready var _secondBar: TextureProgressBar = TextureProgressBar.new()
## A reference to the [Timer] used to start animations.
@onready var _timer: Timer

## Animation parameters for the foreground [TextureProgressBar].
@export_group("First Bar Animation")
## Time of the animation.
@export_range(0,10,0.1,"or_greater") var firstAnimationTime: float = 0.2
## Easing of the animation.
@export var firstAnimationEasing: Tween.EaseType = Tween.EaseType.EASE_OUT
## Transition of the animation.
@export var firstAnimationTransition: Tween.TransitionType = Tween.TransitionType.TRANS_CUBIC
## Parameters to set on the background [TextureProgressBar].
@export_group("Second Bar")
## The texture of the background [TextureProgressBar].
@export var _secondBarTexture: Texture2D
## The tint of the background [TextureProgressBar].
@export var _secondBarTint: Color = Color.WHITE
## Animation parameters for the background [TextureProgressBar].
@export_subgroup("Animation")
## Time to wait before animating the background [TextureProgressBar].
@export_range(0,10,0.1,"or_greater") var timeToStartSecondAnimation: float = 1
## Time of the animation.
@export_range(0,10,0.1,"or_greater") var secondAnimationTime: float = 1
## Easing of the animation.
@export var secondAnimationEasing: Tween.EaseType = Tween.EaseType.EASE_OUT
## Transition of the animation.
@export var secondAnimationTransition: Tween.TransitionType = Tween.TransitionType.TRANS_CUBIC

## The [Tween] for the foreground [TextureProgressBar].
var _firstTweener: Tween
## The [Tween] for the background [TextureProgressBar].
var _secondTweener: Tween

## Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_setup_second_bar()
	if timeToStartSecondAnimation > 0:
		_timer = Timer.new()
		_timer.wait_time = timeToStartSecondAnimation
		_timer.timeout.connect(_animate_second_bar)
		add_child(_timer)

## Sets up the background [TextureProgressBar].
func _setup_second_bar() -> void:
	_secondBar.min_value = min_value
	_secondBar.max_value = max_value
	_secondBar.step = step
	_secondBar.page = page
	_secondBar.value = value
	_secondBar.fill_mode = fill_mode
	_secondBar.nine_patch_stretch = nine_patch_stretch
	if nine_patch_stretch:
		_secondBar.stretch_margin_left = stretch_margin_left
		_secondBar.stretch_margin_top = stretch_margin_top
		_secondBar.stretch_margin_right = stretch_margin_right
		_secondBar.stretch_margin_bottom = stretch_margin_bottom
	_secondBar.texture_progress_offset = texture_progress_offset
	_secondBar.texture_progress = _secondBarTexture
	_secondBar.tint_progress = _secondBarTint
	_secondBar.tint_under = tint_under
	tint_under = Color.WHITE
	_secondBar.texture_under = texture_under
	texture_under = null
	_secondBar.show_behind_parent = true
	_secondBar.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_secondBar)
	_secondBar.size = size

## Main function to set the new [param value] of the [TextureProgressBar].
func set_new_value(newValue: float) -> void:
	if newValue > value:
		value = newValue
		_secondBar.value = newValue
	else:
		if secondAnimationTime > 0:
			_animate_first_bar(newValue)
		else:
			value = newValue
			_time_second_bar()

## Animates the foreground [TextureProgressBar].
func _animate_first_bar(newValue: float) -> void:
	if _secondTweener:
		_secondTweener.stop()
	if firstAnimationTime > 0:
		if _firstTweener:
			_firstTweener.finished.disconnect(_time_second_bar)
			_firstTweener.stop()
		_firstTweener = create_tween().set_ease(firstAnimationEasing).set_trans(firstAnimationTransition)
		_firstTweener.tween_property(self, "value", newValue, firstAnimationTime)
		_firstTweener.finished.connect(_time_second_bar)
		_firstTweener.play()
	else:
		_time_second_bar()

## Wait before animating the background [TextureProgressBar].
func _time_second_bar() -> void:
	if timeToStartSecondAnimation > 0:
		_timer.start()
	else:
		_animate_second_bar()

## Animates the background [TextureProgressBar].
func _animate_second_bar() -> void:
	_secondTweener = create_tween().set_ease(secondAnimationEasing).set_trans(secondAnimationTransition)
	_secondTweener.tween_property(_secondBar, "value", value, secondAnimationTime)
	_secondTweener.play()
