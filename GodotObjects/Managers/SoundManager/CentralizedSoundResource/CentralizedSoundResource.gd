extends Resource

## This class handles centralized sound managing.
class_name CentralizedSoundResource

## Collection of sound to pick from when this effect is called.
## The second parameter is a weight value used to skew the randomness. The higher the value, the more likely it will play instead of others.
@export var soundCollection: Dictionary[SoundResource, int] = {}

## The whaeighted list of sounds.
var weightedSoundList: Array[SoundResource] = []

## Gets a random sound based on weights.
func get_sound() -> SoundResource:
	if len(soundCollection.keys()) == 1: return soundCollection.keys()[0]
	if len(weightedSoundList) == 0: _create_weighted_sound_list()
	randomize()
	return weightedSoundList.pick_random()

## Creates weighted sound list.
func _create_weighted_sound_list() -> void:
	if len(weightedSoundList) > 0: return
	for sound in soundCollection: range(soundCollection[sound]).map(func(_a: int): weightedSoundList.append(sound))
