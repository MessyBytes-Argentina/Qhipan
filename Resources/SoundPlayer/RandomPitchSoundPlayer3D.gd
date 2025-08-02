extends AudioStreamPlayer3D
class_name RandomPitchPlayer3D

@export var minPitchScale: float = 0.75
@export var maxPitchScale: float = 1.25

func play_sound(from_position: float = 0.0) -> void:
	pitch_scale = randf_range(minPitchScale, maxPitchScale)
	play(from_position)
