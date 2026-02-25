@tool
extends StaticBody3D
class_name AlternatingObject

## Parameter to be used for the on and off animation.
const ANIMATIONPARAMETERS: Dictionary[String, Variant] = {
	"time": 0.3,
	"ease": Tween.EaseType.EASE_OUT,
	"trans": Tween.TransitionType.TRANS_BACK,
	"offColor": Color("cc4f6d"),
	"onColor": Color("4df9fe"),
	"onSize": Vector3(0.6, 0.1, 0.6),
	"onPosition": Vector3(0.0, 0.05, 0.0),
	"offSize": Vector3(1.0, 1.0, 1.0),
	"offPosition": Vector3(0.0, 0.5, 0.0)
}

## Current state of the alternating object.
@export var isOff: bool = false:
	set(value):
		isOff = value
		if not Engine.is_editor_hint() or not is_node_ready(): return
		progress = 1.0 if isOff else 0.0
		_animation_tick(progress)
## Can be affected by held area.
@export var heldAreaEffect: bool = true

## Reference to the mesh.
@onready var mesh: MeshInstance3D = %MeshInstance3D
## Reference to the collision shape.
@onready var collisionShape: CollisionShape3D = %CollisionShape3D
## Reference to the check area.
@onready var checkArea: Area3D = %CheckArea

## Tween used for animating the block.
var tween: Tween
## Current tween progress.
var progress: float = 0.0
## Reference to the cube material.
var material: ShaderMaterial
## Reference to the cube collision shape's shape.
var shape: BoxShape3D

## Executed when node first enters the scene tree.
func _ready() -> void:
	set_collision_layer_value(14, false)
	if not heldAreaEffect: checkArea.queue_free()
	material = mesh.get_surface_override_material(0).duplicate()
	mesh.set_surface_override_material(0, material)
	GeneralVariables.to_cutout_materials([material], true, true)
	progress = 1.0 if isOff else 0.0
	shape = collisionShape.shape.duplicate()
	collisionShape.shape = shape
	set_collision_layer_value(1, not isOff)
	set_collision_layer_value(13, isOff)
	_animation_tick(progress)

## Switches state.
func switch_state() -> void:
	isOff = not isOff
	set_collision_layer_value(1, not isOff)
	set_collision_layer_value(13, isOff)
	animate()
	await get_tree().process_frame
	get_tree().call_deferred("call_group", "Fog", "update_collision_shape")

## Runs the state switch animation.
func animate() -> void:
	if tween: if tween.is_running(): tween.kill()
	tween = create_tween()
	var goal: float = 1.0 if isOff else 0.0
	var time: float = ((1.0 - progress) if isOff else progress) * ANIMATIONPARAMETERS.time
	tween.tween_method(_animation_tick, progress, goal, time).set_ease(ANIMATIONPARAMETERS.ease as Tween.EaseType).set_trans(ANIMATIONPARAMETERS.trans as Tween.TransitionType)
	tween.play()

## A single tick of animation.
func _animation_tick(currentProgress: float) -> void:
	progress = currentProgress
	material.set_shader_parameter("progress", progress)
	material.set_shader_parameter("albedo", lerp(ANIMATIONPARAMETERS.onColor, ANIMATIONPARAMETERS.offColor, progress))
	shape.size = ANIMATIONPARAMETERS.offSize.lerp(ANIMATIONPARAMETERS.onSize, progress)
	collisionShape.position = ANIMATIONPARAMETERS.offPosition.lerp(ANIMATIONPARAMETERS.onPosition, progress)

## Cleans unique materials.
func _notification(what) -> void:
	if Engine.is_editor_hint(): return
	if what == NOTIFICATION_PREDELETE:
		GeneralVariables.to_cutout_materials([material], false, true)
