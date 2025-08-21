extends Resource

## This class handles centralized sound managing.
class_name CentralizedSoundResource

## Collection of sound to pick from when this effect is called.
## The second parameter is a weight value used to skew the randomness. The higher the value, the more likely it will play instead of others.
@export var soundCollection: Dictionary[AudioStream, float] = {}
