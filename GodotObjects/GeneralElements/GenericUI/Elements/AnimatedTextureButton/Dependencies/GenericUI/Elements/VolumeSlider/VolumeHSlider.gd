@icon("./Volume.svg")
@tool
extends HBoxContainer

## A custom slider container for volumes. Horizontal container.
class_name VolumeHSlider

## New volume was set.
signal updated
## The new volume that was just set.
signal new_volume(newVolume: float)

## The scene for the mute/unmute button.
@export var buttonScene: PackedScene:
	set(value):
		buttonScene = value
		_set_button()
## The custom minimum size of the button.
@export var buttonCustomMinimumSize: Vector2 = Vector2.ZERO:
	set(value):
		buttonCustomMinimumSize = value
		_set_button()
## The scene of the slider.
@export var sliderScene: PackedScene:
	set(value):
		sliderScene = value
		_set_slider()
## If true the button will be after the slider in the container.
@export var buttonAfterSlider: bool = false:
	set(value):
		buttonAfterSlider = value
		_set_button()
		_set_slider()
## Sound to play after updating volume.
@export var soundOnChange: AudioStream
## The bus this slider affects.
var bus: int

## A reference to the button node.
var _button: BaseButton
## A reference to the slider node.
var _slider: HSlider
## A reference to the sound player node.
var _soundPlayer: AudioStreamPlayer

## Populates the resource in the editor.
func _get_property_list() -> Array:
	var properties: Array = []
	
	# busName
	var busNames: Array = []
	for i in range(AudioServer.bus_count):
		busNames.append(AudioServer.get_bus_name(i))
	properties.append({
		"name": "bus",
		"type": TYPE_INT,
		"usage": PROPERTY_USAGE_DEFAULT,
		"hint": PROPERTY_HINT_ENUM,
		"hint_string": ",".join(busNames),
	})
	
	return properties

## Sets the button scene in place.
func _set_button() -> void:
	if buttonScene:
		var loadedScene = buttonScene.instantiate()
		if loadedScene is BaseButton:
			_button = loadedScene
			_button.custom_minimum_size = buttonCustomMinimumSize
			if not _button.toggled.is_connected(_button_pressed):
				_button.toggled.connect(_button_pressed)
		else:
			_button = null
			buttonScene = null
	_update_layout()

## Sets the slider scene in place.
func _set_slider() -> void:
	if sliderScene:
		var loadedScene = sliderScene.instantiate()
		if loadedScene is HSlider:
			_slider = loadedScene
			if not _slider.value_changed.is_connected(_slider_updated):
				_slider.value_changed.connect(_slider_updated)
				_slider.drag_ended.connect(drop_slider_focus)
		else:
			_slider = null
			sliderScene = null
	_update_layout()

## Drops the slider focus after sliding has ended.
func drop_slider_focus(_finalValue: float) -> void:
	_slider.release_focus()

## Adds the scenes as childs in the order determined by [param buttonAfterSlider].
func _update_layout() -> void:
	if not buttonScene:
		_button = null
	if not sliderScene:
		_slider = null
	for child in get_children():
		remove_child(child)
	if not buttonAfterSlider:
		if _button:
			add_child(_button)
		if _slider:
			add_child(_slider)
	else:
		if _slider:
			add_child(_slider)
		if _button:
			add_child(_button)

## Updates slider and button to match the current volume set.
func _update_values():
	var currentVolume: float = VolumeManager.get_bus_volume(bus)
	if currentVolume == -60:
		currentVolume = VolumeManager.get_bus_saved_volume(bus)
		_button.button_pressed = true
	else:
		_button.button_pressed = false
	_slider.value = currentVolume

## Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_set_button()
	_set_slider()
	if not Engine.is_editor_hint():
		_update_values()
		_soundPlayer = AudioStreamPlayer.new()
		_soundPlayer.bus = AudioServer.get_bus_name(bus)
		_soundPlayer.stream = soundOnChange
		add_child(_soundPlayer)

## Mutes and unmutes the audio bus.
func _button_pressed(toggled: bool) -> void:
	VolumeManager.mute_bus(bus, toggled)
	updated.emit()
	new_volume.emit(VolumeManager.get_bus_volume(bus))
	_play_sound()

## Updates the audio bus volume.
func _slider_updated(newValue: float) -> void:
	if newValue == _slider.min_value:
		VolumeManager.mute_bus(bus, true)
		_button.button_pressed = true
	elif _button.button_pressed == true:
		_button.button_pressed = false
		VolumeManager.mute_bus(bus, false)
	VolumeManager.update_bus_volume(bus, newValue)
	updated.emit()
	new_volume.emit(newValue)
	_play_sound()

## Plays associated sound.
func _play_sound():
	if _soundPlayer:
		_soundPlayer.play()
