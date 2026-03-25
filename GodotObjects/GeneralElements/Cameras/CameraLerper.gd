extends Camera3D

## This standalone instance of a camera transitions between different cameras and swaps the player's current camera.

## Animation parameters.
const AnimationEaseTrans: Dictionary[String, int] = {
	"ease": Tween.EASE_IN_OUT,
	"trans": Tween.TRANS_CUBIC
}

## Reference to the player.
var player: Player
## The current camera.
var currentCamera: Camera3D
## The animation tween.
var tween: Tween
## Transitioning flag.
var transitioning: bool = false
## The previous position.
var previousPosition: Vector3
## The previous quaternion.
var previousQuaternion: Quaternion
## The goal position.
var goalPosition: Vector3
## The goal quaternion.
var goalQuaternion: Quaternion

## Called when the node enters the scene tree for the first time.
func _ready() -> void:
	set_cull_mask_value(18, false)
	set_cull_mask_value(19, false)
	while not currentCamera:
		for camera: Camera3D in get_tree().get_nodes_in_group("Camera"):
			if camera.current:
				currentCamera = camera
				break
		await get_tree().process_frame
	while not player:
		player = get_tree().get_first_node_in_group("Player")
		await get_tree().process_frame
	player.currentCamera = currentCamera

## Animates and swaps to a given camera in a given timeframe.
func switch_to(targetCamera: Camera3D, time: float) -> void:
	if time == 0:
		currentCamera = targetCamera
		currentCamera.current = true
		player.currentCamera = currentCamera
		return
	if not transitioning:
		fov = currentCamera.fov
		global_transform = currentCamera.global_transform
		current = true
		player.currentCamera = self
		transitioning = true
	if tween: if tween.is_running(): tween.kill()
	previousPosition = global_position
	previousQuaternion = global_transform.basis
	goalPosition = targetCamera.global_position
	goalQuaternion = targetCamera.global_transform.basis
	tween = create_tween()
	tween.tween_method(animation_tick, 0.0, 1.0, time).set_ease(AnimationEaseTrans.ease as Tween.EaseType).set_trans(AnimationEaseTrans.trans as Tween.TransitionType)
	tween.play()
	tween.finished.connect(finish_transition.bind(targetCamera))

## An animation tick.
func animation_tick(progress: float) -> void:
	global_position = lerp(previousPosition, goalPosition, progress)
	global_transform.basis = Basis(previousQuaternion.slerp(goalQuaternion, progress))

## Once finished finishes the camera swap.
func finish_transition(targetCamera: Camera3D) -> void:
	currentCamera = targetCamera
	player.currentCamera = targetCamera
	targetCamera.current = true
	transitioning = false
