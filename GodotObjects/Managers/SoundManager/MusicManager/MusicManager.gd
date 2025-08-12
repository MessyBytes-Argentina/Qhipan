@icon("../Music.svg")
@tool
extends Node

## This object manages music queues and fading.
class_name MusicManagerObject

## The list of songs to import.
@export var musicList: AudioStreamInteractive
## The bus to play music out of
var busName: String

## The audio player used to actually play songs
@onready var audioPlayer: AudioStreamPlayer = AudioStreamPlayer.new()
## The current song name.
var currentSong: String = ""
## Flag to indicate that the music player is muted. Used to determine whether to raise the volume when switching songs.
var silenced: bool = false
## A reference to the audio player stream playback.
var audioPlayerStreamPlayback: AudioStreamPlayback
## The music name list.
var musicNameList: Array

## Populates the resource in the editor.
func _get_property_list() -> Array:
	var properties: Array = []
	
	# busName
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

## Ready function. Loads the [param jukebox] and the music player is loaded with [param musicList].
func _ready():
	if not Engine.is_editor_hint():
		audioPlayer.bus = busName
		audioPlayer.stream = musicList
		add_child(audioPlayer)
		audioPlayer.play()
		audioPlayerStreamPlayback = audioPlayer.get_stream_playback()
		musicNameList = get_music_name_list()

## Silences the music player.
func silence() -> void:
	fade_volume(0, -80)
	silenced = true

## Changes the music that is currently playing.
func change_music(newSongName: String) -> void:
	if newSongName != currentSong:
		audioPlayerStreamPlayback.switch_to_clip_by_name(newSongName)
		currentSong = newSongName

func get_music_name_list() -> Array:
	return range(musicList.clip_count).map(func(a): return str(musicList.get_clip_name(a)))

func get_sync_music_name_list() -> Array:
	return range(musicList.clip_count).map(func(a): if musicList.get_clip_stream(a).is_class("AudioStreamSynchronized"): return str(musicList.get_clip_name(a))).filter(func(a): if a: return true)

## Sets the volume of sync streams by name and indexes. Also tweens it if needed.
func set_synchro_clip_volume(clipName: String, streamIndexes: Array[int], newVolume: float, time: float = 0):
	var stream: AudioStreamSynchronized = musicList.get_clip_stream(musicNameList.find(clipName))
	for streamIndex in streamIndexes:
		if streamIndex < stream.stream_count:
			if time > 0:
				var tweener = create_tween()
				tweener.tween_method(sync_stream_tween_method.bind(streamIndex, stream), stream.get_sync_stream_volume(streamIndex), newVolume, time)
			else:
				stream.set_sync_stream_volume(streamIndex, newVolume)

## The actual function to tween a sync stream volume because for some reason the native function takes the index first so it can't be tweened normally.
func sync_stream_tween_method(newVolume: float, streamIndex: int, stream: AudioStreamSynchronized):
	stream.set_sync_stream_volume(streamIndex, newVolume)

## Fades current song to a new volume.
func fade_volume(fadeTime: float, newMusicVolume: float) -> void:
	if not silenced:
		if fadeTime > 0:
			var tweener = create_tween()
			tweener.tween_property(audioPlayer, "volume_db", newMusicVolume, fadeTime)
			tweener.play()
			await get_tree().create_timer(fadeTime).timeout
			tweener.stop()
			if newMusicVolume == -80:
				audioPlayer.stop()
		else:
			audioPlayer.volume_db = newMusicVolume
