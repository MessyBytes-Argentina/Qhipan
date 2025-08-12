extends AudioStreamPlayer
class_name RandomPitchPlayer

@export var minPitchScale: float = 0.9
@export var maxPitchScale: float = 1.5

func play_sound(from_position: float = 0.0) -> void:
	pitch_scale = randf_range(minPitchScale, maxPitchScale)
	play(from_position)
