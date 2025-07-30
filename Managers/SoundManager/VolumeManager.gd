@icon("./Sound.svg")
extends Node

## Handles setting and getting volumes of the different buses.
class_name VolumeManagerObject

## The preset buses used by this suite of scripts.
var buses: Array[String] = []
## The current nonmuted volume of each bus.
var busesVolume: Dictionary = {}

## Sets up the [param busesVolume] dictionary.
func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	for i in range(AudioServer.bus_count):
		buses.append(AudioServer.get_bus_name(i))
	for i in range(len(buses)):
		busesVolume[buses[i]] = get_bus_volume(i)

## Mutes and unmutes a bus using the [param busesVolume] dictionary.
func mute_bus(bus: int, mute: bool) -> void:
	if mute:
		update_bus_volume(bus, -60)
	else:
		update_bus_volume(bus, busesVolume[buses[bus]])

## Updates the volume of a bus. Example use: volume slider.
func update_bus_volume(bus: int, newValue: float) -> void:
	AudioServer.set_bus_volume_db(bus as int, newValue)
	if newValue != -60:
		busesVolume[buses[bus]] = newValue

## Gets the current volume of a bus.
func get_bus_volume(bus: int) -> float:
	return AudioServer.get_bus_volume_db(bus as int)

## Gets the saved volume of a bus.
func get_bus_saved_volume(bus: int) -> float:
	return busesVolume[buses[bus]]
