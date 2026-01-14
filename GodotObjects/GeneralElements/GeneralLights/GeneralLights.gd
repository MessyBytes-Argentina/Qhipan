@tool
extends Node3D

## Light shine parameters
const SHINEPARAMETERS: Dictionary[String, Variant] = {"interval": 0.5, "animationTime": 0.5, "transIn": Tween.TRANS_CUBIC, "easeIn": Tween.EASE_IN_OUT, "transOut": Tween.TRANS_QUART, "easeOut": Tween.EASE_OUT}

@export var albedo: Color = Color.WHITE:
	set(value):
		albedo = value
		if Engine.is_editor_hint(): set_color_changes()
@export var emission: Color = Color.WHITE:
	set(value):
		emission = value
		if Engine.is_editor_hint(): set_color_changes()
@export var lightColor: Color = Color.WHITE:
	set(value):
		lightColor = value
		if Engine.is_editor_hint(): set_color_changes()
@export var shineGradient: GradientTexture1D = preload("uid://fvxwq20uhuo1"):
	set(value):
		shineGradient = value
		if Engine.is_editor_hint(): set_color_changes()
@export_tool_button("Refresh", "Reload") var refresh: Callable = set_color_changes
@export_group("References")
@export var meshes: Array[MeshInstance3D] = []
@export var omniLights: Array[OmniLight3D] = []
@export var shine: MeshInstance3D

## Reference to camera
var camera: Camera3D
## Accumulator for time to check light visibility.
var timePassed: float = 0
## Shine tween.
var shineTween: Tween
## Shine material
var shineMaterial: ShaderMaterial
## Current shine alpha.
var shineAlpha: float = 0.0
## Current shine animation mode.
var shineAnimationMode: String = "Off"
## Random extra time to make  sure light shines arent recalculated all at the same time.
var randomTime: float = 0.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	set_color_changes()
	if Engine.is_editor_hint(): return
	randomize()
	randomTime = randf_range(0.0, 0.1)
	camera = get_tree().get_first_node_in_group("Camera")

## Sets all color changes
func set_color_changes() -> void:
	if not is_node_ready():
		await ready
	shineMaterial = shine.get_surface_override_material(0).duplicate()
	shine.set_surface_override_material(0, shineMaterial)
	for mesh in meshes:
		var material: ShaderMaterial = mesh.get_surface_override_material(0).duplicate()
		material.set_shader_parameter("albedo", albedo)
		material.set_shader_parameter("emission", emission)
		mesh.set_surface_override_material(0, material)
	for light in omniLights:
		light.light_color = lightColor

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Engine.is_editor_hint(): return
	timePassed += delta
	if timePassed < SHINEPARAMETERS.interval + randomTime: return
	timePassed = 0
	var spaceState: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	var raycast = PhysicsRayQueryParameters3D.create(camera.global_position, global_position)
	raycast.hit_from_inside = false
	raycast.hit_back_faces = false
	raycast.collision_mask = 1
	if spaceState.intersect_ray(raycast):
		if shineAnimationMode not in ["AnimatingOut", "Off"]: animate_shine(false)
	else:
		if shineAnimationMode not in ["AnimatingIn", "On"]: animate_shine(true)

## Animates shine parameters.
func animate_shine(on: bool) -> void:
	if shineTween: if shineTween.is_running(): shineTween.kill()
	shineTween = create_tween()
	if on:
		shineAnimationMode = "AnimatingIn"
		var newTime: float = SHINEPARAMETERS.animationTime * inverse_lerp(1.0, 0.0, shineAlpha)
		shineTween.tween_method(set_shine, shineAlpha, 1.0, newTime).set_trans(SHINEPARAMETERS.transIn as Tween.TransitionType).set_ease(SHINEPARAMETERS.easeIn as Tween.EaseType)
		shineTween.finished.connect(set.bind("shineAnimationMode", "On"))
	else:
		shineAnimationMode = "AnimatingOut"
		var newTime: float = SHINEPARAMETERS.animationTime * shineAlpha
		shineTween.tween_method(set_shine, shineAlpha, 0.0, newTime).set_trans(SHINEPARAMETERS.transOut as Tween.TransitionType).set_ease(SHINEPARAMETERS.easeOut as Tween.EaseType)
		shineTween.finished.connect(set.bind("shineAnimationMode", "Off"))
	shineTween.play()

## Sets shine value.
func set_shine(value: float) -> void:
	shineMaterial.set_shader_parameter("alpha_override", value)
	shineAlpha = value
