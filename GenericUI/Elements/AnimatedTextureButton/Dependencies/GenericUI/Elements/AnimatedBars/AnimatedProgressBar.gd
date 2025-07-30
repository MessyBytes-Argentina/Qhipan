extends ProgressBar

## Animated [ProgressBar] node. Call [method set_new_value] to set new values.
class_name AnimatedProgressBar

## A reference to the background [ProgressBar].
@onready var _secondBar: ProgressBar = ProgressBar.new()
## A reference to the [Timer] used to start animations.
@onready var _timer: Timer

## Animation parameters for the foreground [ProgressBar].
@export_group("First Animation")
## Time of the animation.
@export_range(0,10,0.1,"or_greater") var firstAnimationTime: float = 0.2
## Easing of the animation.
@export var firstAnimationEasing: Tween.EaseType = Tween.EaseType.EASE_OUT
## Transition of the animation.
@export var firstAnimationTransition: Tween.TransitionType = Tween.TransitionType.TRANS_CUBIC
## Animation parameters for the background [ProgressBar].
@export_group("Second Animation")
## Time to wait before animating the background [ProgressBar].
@export_range(0,10,0.1,"or_greater") var timeToStartSecondAnimation: float = 1
## Time of the animation.
@export_range(0,10,0.1,"or_greater") var secondAnimationTime: float = 1
## Easing of the animation.
@export var secondAnimationEasing: Tween.EaseType = Tween.EaseType.EASE_OUT
## Transition of the animation.
@export var secondAnimationTransition: Tween.TransitionType = Tween.TransitionType.TRANS_CUBIC

## The [Tween] for the foreground [ProgressBar].
var _firstTweener: Tween
## The [Tween] for the background [ProgressBar].
var _secondTweener: Tween

## Called when the node enters the scene tree for the first time.
func _ready():
	_setup_second_bar()
	if timeToStartSecondAnimation > 0:
		_timer = Timer.new()
		_timer.wait_time = timeToStartSecondAnimation
		_timer.timeout.connect(_animate_second_bar)
		add_child(_timer)

## Sets up the background [ProgressBar].
func _setup_second_bar() -> void:
	_secondBar.min_value = min_value
	_secondBar.max_value = max_value
	_secondBar.step = step
	_secondBar.page = page
	_secondBar.value = value
	_secondBar.fill_mode = fill_mode
	_secondBar.show_percentage = false
	_secondBar.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_secondBar)
	_secondBar.size = size

## Main function to set the new [param value] of the [ProgressBar].
func set_new_value(newValue: float):
	if newValue > value:
		value = newValue
		_secondBar.value = newValue
	else:
		if firstAnimationTime > 0:
			_animate_first_bar(newValue)
		else:
			value = newValue
			_time_second_bar()

## Animates the foreground [ProgressBar].
func _animate_first_bar(newValue: float):
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

## Wait before animating the background [ProgressBar].
func _time_second_bar() -> void:
	if timeToStartSecondAnimation > 0:
		_timer.start()
	else:
		_animate_second_bar()

## Animates the background [ProgressBar].
func _animate_second_bar() -> void:
	_secondTweener = create_tween().set_ease(secondAnimationEasing).set_trans(secondAnimationTransition)
	_secondTweener.tween_property(_secondBar, "value", value, secondAnimationTime)
	_secondTweener.play()
