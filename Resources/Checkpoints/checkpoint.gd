extends Area3D
class_name Checkpoint

const LIGHTTIME: float = 0.5
const LIGHTENERGY: float = 1.0

@onready var light: OmniLight3D = %Light

var lightTween: Tween

func activate() -> void:
	light.show()
	if lightTween: lightTween.kill()
	lightTween = create_tween()
	print((1.0 - inverse_lerp(0.0, LIGHTENERGY, light.light_energy)) * LIGHTTIME)
	lightTween.tween_property(light, "light_energy", LIGHTENERGY, (1.0 - inverse_lerp(0.0, LIGHTENERGY, light.light_energy)) * LIGHTTIME).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUINT)
	lightTween.play()

func deactivate() -> void:
	lightTween = create_tween()
	print((1.0 - inverse_lerp(LIGHTENERGY, 0.0, light.light_energy)) * LIGHTTIME)
	lightTween.tween_property(light, "light_energy", 0.0, (1.0 - inverse_lerp(LIGHTENERGY, 0.0, light.light_energy)) * LIGHTTIME).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUART)
	lightTween.play()
	await lightTween.finished
	light.hide()
