extends StaticBody3D
## Placeholder invisible platform.

## Time for animation.
const fadeTime: float = 0.5

## Mesh Reference
@onready var mesh: MeshInstance3D = %Mesh

## Reference to the material.
var material: StandardMaterial3D
## The starting albedo value.
var startAlbedo: float
## The current animation progress.
var currentProgress: float = 0
## The tween used to animate platform.
var tween: Tween

## Executed when node first enters the scene tree.
func _ready() -> void:
	material = mesh.get_surface_override_material(0).duplicate()
	mesh.set_surface_override_material(0, material)
	startAlbedo = material.albedo_color.a
	material.albedo_color.a = 0

## Animates material.
func tween_material(progress: float) -> void:
	material.albedo_color.a = startAlbedo * progress
	currentProgress = progress

## Triggers when the player steps on the platform.
func _on_player_entered(_body: Node3D) -> void:
	set_collision_layer_value(1, true)
	set_collision_mask_value(1, true)
	if tween: if tween.is_running(): tween.kill()
	tween = create_tween()
	tween.tween_method(tween_material, currentProgress, 1.0, (1.0 - currentProgress) * fadeTime).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUART)
	tween.play()

## Triggers when player exits the platform.
func _on_player_exited(_body: Node3D) -> void:
	set_collision_layer_value(1, false)
	set_collision_mask_value(1, true)
	if tween: if tween.is_running(): tween.kill()
	tween = create_tween()
	tween.tween_method(tween_material, currentProgress, 0.0, currentProgress * fadeTime).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUART)
	tween.play()
