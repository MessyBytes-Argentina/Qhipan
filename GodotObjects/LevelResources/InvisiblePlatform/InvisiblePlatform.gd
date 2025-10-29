extends MeshInstance3D

const fadeTime: float = 0.5

var material: StandardMaterial3D
var startAlbedo: float
var currentProgress: float = 0
var tween: Tween

func _ready() -> void:
	material = get_surface_override_material(0).duplicate()
	set_surface_override_material(0, material)
	startAlbedo = material.albedo_color.a
	material.albedo_color.a = 0

func tween_material(progress: float) -> void:
	material.albedo_color.a = startAlbedo * progress
	currentProgress = progress

func _on_player_entered(_body: Node3D) -> void:
	if tween: if tween.is_running(): tween.kill()
	tween = create_tween()
	tween.tween_method(tween_material, currentProgress, 1.0, (1.0 - currentProgress) * fadeTime).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUART)
	tween.play()

func _on_player_exited(_body: Node3D) -> void:
	if tween: if tween.is_running(): tween.kill()
	tween = create_tween()
	tween.tween_method(tween_material, currentProgress, 0.0, currentProgress * fadeTime).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUART)
	tween.play()
