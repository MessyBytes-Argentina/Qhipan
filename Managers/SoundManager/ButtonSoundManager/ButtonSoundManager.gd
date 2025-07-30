@icon("../Sound.svg")
@tool
extends Node

## This object installs sounds to all buttons that share the global group "SoundButtons". It should be used as an autoload.
class_name ButtonSoundManagerObject

## The sound to play on hovering buttons.
@export_file("*.ogg", "*.mp3") var hoverSound: String
## The sound to play on clicking buttons.
@export_file("*.ogg", "*.mp3") var clickSound: String
## The bus to use for playing sounds.
var busName: StringName = &"UI"

## The hovering audio player.
@onready var loadedHoverSound: AudioStreamPlayer = AudioStreamPlayer.new()
## The clicking audio player.
@onready var loadedClickSound: AudioStreamPlayer = AudioStreamPlayer.new()

## Populates [prop busName] in the editor.
func _get_property_list() -> Array:
	var properties: Array = []
	var busNames: Array = []
	for i in range(AudioServer.bus_count):
		busNames.append(AudioServer.get_bus_name(i))
	properties.append({
		"name": "busName",
		"type": TYPE_STRING_NAME,
		"usage": PROPERTY_USAGE_DEFAULT,
		"hint": PROPERTY_HINT_ENUM,
		"hint_string": ",".join(busNames),
	})
	return properties

## Set up audio stream players and load sound files.
func _ready() -> void:
	if not Engine.is_editor_hint():
		if hoverSound:
			loadedHoverSound.stream = load(hoverSound)
			loadedHoverSound.bus = busName
		if clickSound:
			loadedClickSound.stream = load(clickSound)
			loadedHoverSound.bus = busName

## Connects the buttons to the [func play_check] function.
func install_sounds() -> void:
	var buttons: Array[Node] = get_tree().get_nodes_in_group("SoundButtons")
	for button in buttons:
		if not button.mouse_entered.is_connected(play_check):
			button.mouse_entered.connect(play_check.bind("Hover", button))
			button.button_up.connect(play_check.bind("Click", button))

## Checks for special cases and calls the [func play_sound] function.
func play_check(sound : String, button: Node) -> void:
	if button != null:
		if "disableSounds" in button:
			if not sound in button.get_disabled_sounds():
				if not (sound == "Hover" and button.disabled):
					play_sound(sound, button)
		elif not (sound == "Hover" and button.disabled):
			play_sound(sound, button)

## Checks for [ButtonSoundOverride] as child of the the triggering button. Plays the corresponding sound.
func play_sound(sound : String, button: Node) -> void:
	var override: ButtonSoundOverride = button.get_node("ButtonSoundOverride")
	match sound:
		"Hover":
			if override:
				if override.hoverSound:
					override.loadedHoverSound.play()
			elif hoverSound:
				loadedHoverSound.play()
		"Click":
			if override:
				if override.clickSound:
					override.loadedClickSound.play()
			elif clickSound:
				loadedClickSound.play()
