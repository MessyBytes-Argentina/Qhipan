@tool
extends CharacterBody3D
class_name AlternatingObject

const MATERIALS: Dictionary = {
	"ON": preload("uid://dlsrpuw0cb45d"),
	"OFF": preload("uid://wc5r2fxnxpug")
}
const ANIMATIONPARAMETERS: Dictionary[String, Variant] = {"time": 0.5, "ease": Tween.EaseType.EASE_OUT, "trans": Tween.TransitionType.TRANS_BOUNCE}

@export var isOff: bool = false:
	set(value):
		isOff = value
		if not Engine.is_editor_hint() or not is_node_ready(): return
		if isOff:
			objMesh.set_surface_override_material(0, MATERIALS.OFF)
		else:
			objMesh.set_surface_override_material(0, MATERIALS.ON)
		progress = 1.0 if isOff else 0.0
		material.set_shader_parameter("progress", progress)

@onready var objMesh: MeshInstance3D = %ObjectMesh
@onready var objCollider: CollisionShape3D = %ObjectCollider
@onready var mesh: MeshInstance3D = %MeshInstance3D

var groupParent: AlternatingGroup
var tween: Tween
var progress: float = 0.0
var material: ShaderMaterial

func _ready() -> void:
	material = mesh.get_surface_override_material(0).duplicate()
	mesh.set_surface_override_material(0, material)
	progress = 1.0 if isOff else 0.0
	material.set_shader_parameter("progress", progress)
	if Engine.is_editor_hint():
		if isOff:
			objMesh.set_surface_override_material(0, MATERIALS.OFF)
		else:
			objMesh.set_surface_override_material(0, MATERIALS.ON)
		return
	if isOff:
		turn_off()
	else:
		turn_on()
	var parent = get_parent()
	if parent is AlternatingGroup: 
		groupParent = parent

func switch_state() -> void:
	if isOff:
		turn_on()
	else:
		turn_off()
	isOff = !isOff
	animate()

func turn_on() -> void:
	objMesh.set_surface_override_material(0, MATERIALS.ON)
	objCollider.set_deferred("disabled", false)
	await get_tree().process_frame
	get_tree().call_deferred("call_group", "Fog", "update_collision_shape")

func turn_off() -> void:
	objMesh.set_surface_override_material(0, MATERIALS.OFF)
	objCollider.set_deferred("disabled", true)
	await get_tree().process_frame
	get_tree().call_deferred("call_group", "Fog", "update_collision_shape")

func animate() -> void:
	if tween: if tween.is_running(): tween.kill()
	tween = create_tween()
	var goal: float = 0.0 if isOff else 1.0
	var time: float = ((1.0 - progress) if not isOff else progress) * ANIMATIONPARAMETERS.time
	tween.tween_method(_animation_tick, progress, goal, time).set_ease(ANIMATIONPARAMETERS.ease as Tween.EaseType).set_trans(ANIMATIONPARAMETERS.trans as Tween.TransitionType)
	tween.play()

func _animation_tick(currentProgress: float) -> void:
	progress = currentProgress
	material.set_shader_parameter("progress", progress)
