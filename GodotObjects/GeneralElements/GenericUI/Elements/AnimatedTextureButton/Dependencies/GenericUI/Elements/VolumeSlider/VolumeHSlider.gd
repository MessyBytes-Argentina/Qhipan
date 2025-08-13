@icon("./Volume.svg")
@tool
extends HBoxContainer

## A custom slider container for volumes. Horizontal container.
class_name VolumeHSlider

## A controller step multiplier.
const CONTROLLERSTEPMULTIPLIER: float = 7.5

## New volume was set.
signal updated
## The new volume that was just set.
signal new_volume(newVolume: float)

## A reference to the button node.
@export var _button: BaseButton
## A reference to the slider node.
@export var _slider: HSlider
## Sound to play after updating volume.
@export var soundOnChange: AudioStream
## The bus this slider affects.
var bus: int

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

## Drops the slider focus after sliding has ended.
func drop_slider_focus(_finalValue: float) -> void:
	if not GeneralVariables.usingGamepad: _slider.release_focus()

## Set volume with controller.
func _process(_delta: float) -> void:
	if not GeneralVariables.usingGamepad: return
	if not _slider.has_focus(): return
	if Input.is_action_pressed("ui_left"): _slider.set_value(_slider.value - _slider.step * CONTROLLERSTEPMULTIPLIER)
	if Input.is_action_pressed("ui_right"): _slider.set_value(_slider.value + _slider.step * CONTROLLERSTEPMULTIPLIER)

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
	if not Engine.is_editor_hint():
		_button.toggled.connect(_button_pressed)
		_slider.value_changed.connect(_slider_updated)
		_slider.drag_ended.connect(drop_slider_focus)
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
