extends AudioStreamPlayer

## Random sound player without direction.
class_name RandomSoundPlayer

## Sound resource collection.
@export var soundResource: CentralizedSoundResource

## Plays sound
func play_sound(from_position: float = 0.0) -> void:
	if soundResource:
		var currentSound: SoundResource = soundResource.get_sound()
		stream = currentSound.sound
		pitch_scale = currentSound.get_pitch_scale()
		volume_db = currentSound.get_volume_dB()
	play(from_position)
