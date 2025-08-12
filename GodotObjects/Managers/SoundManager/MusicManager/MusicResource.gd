@icon("../Music.svg")
@tool
extends Resource

## This resource is used to load the [MusicManagerObject] to populate the [param MusicManagerObject.jukebox].
class_name MusicResource

## The name of the song. Used by [MusicManagerObject] to play the song.
@export var songName: String
## The intro of the song. To be played upon switching to this song. If none exists then the music will start at the loop.
@export var intro: AudioStream
## The loop of the song. Plays in a loop.
@export var loop: AudioStream

## Returns this resource as a dictionary. Used by [MusicManagerObject] to populate the [param MusicManagerObject.jukebox].
func get_as_dictionary() -> Dictionary:
	var dictionary: Dictionary = {"intro": null, "loop": null}
	if intro:
		dictionary.intro = intro
	if loop:
		dictionary.loop = loop
	return dictionary
