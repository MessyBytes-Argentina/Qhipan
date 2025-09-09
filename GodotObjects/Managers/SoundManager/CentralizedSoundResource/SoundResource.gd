extends Resource

## This class handles individual sound managing.
class_name SoundResource

## The sound this resource handles.
@export var sound: AudioStream
## The base volume this sound is played at, in decibels. This is added to the bus effect, so default is 0.
@export_range(-80, 24, 0.01) var baseVolumeDB: float = 0
## The amount of decibels this sound can vary, up or down, on each playback.
@export_range(0, 10, 0.01) var volumeDBVariation: float = 0
## The base pitch scale this sound is played at. Default is 1.
@export_range(0.01, 4, 0.01) var basePitchScale: float = 1
## The amount of pitch scale this sound can vary, up or down, on each playback.
@export_range(0, 2, 0.01) var pitchScaleVariation: float = 0

## This function outputs current execution volume in decibels.
func get_volume_dB() -> float:
	return clampf(baseVolumeDB + randf_range(-volumeDBVariation, volumeDBVariation), -80, 24)

## This function outputs current execution pitch scale.
func get_pitch_scale() -> float:
	return clampf(basePitchScale + randf_range(-pitchScaleVariation, pitchScaleVariation), 0.01, 4)
