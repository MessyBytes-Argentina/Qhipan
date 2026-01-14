@tool
extends StickerBase
## Sticker that lights up darkness-blocked areas.
class_name LampSticker

signal light_updated()

## Range of the light while grabbed
const LIGHTRANGEGRABED: float = 1.5
## Range of the light while placed
const LIGHTRANGEPLACED: float = 5.0
## Energy of the light while placed or grabbed
const LIGHTENERGY: float = 1.0
## Light fade animation time
const LIGHTFADETIME: float = 0.3
## Light area fade animation time
const LIGHTAREAFADETIME: float = 2.0
## Sticker textures
const stickerTextures: Dictionary[String, Texture2D] = {
	"on": preload("uid://da3qteoalmnj6"),
	"off": preload("uid://k8c3uc7gxr4w")
}
## Light shine parameters
const SHINEPARAMETERS: Dictionary[String, Variant] = {"interval": 0.5, "animationTime": 0.5, "transIn": Tween.TRANS_CUBIC, "easeIn": Tween.EASE_IN_OUT, "transOut": Tween.TRANS_QUART, "easeOut": Tween.EASE_OUT, "heldSize": Vector2.ONE * 1.5, "defaultSize": Vector2.ONE * 2.0}

## The floating mesh with no lighting on.
@onready var floatingMesh: MeshInstance3D = %FloatingMesh
## The light to turn on and of.
@onready var light: OmniLight3D = %Light
## Light area of effect
@onready var lightArea: Area3D = %LightArea
## Light area of effect shape
@onready var lightShape: CollisionShape3D = %LightShape
## Area3d container
@onready var shapes: Node3D = %Shapes
## Light area for dropping stickers
@onready var stickerLightArea: Area3D = %StickerLightArea
## Light shine
@onready var shine: MeshInstance3D = %Shine

## Reference to the player character
var player: Player
## Reference to camera
var camera: Camera3D
## Reference to the player character darkness manager
var playerDarknessManager: DarknessBlockerModule
## Light animation tween.
var lightTween: Tween
## Last light range.
var lastLightValue: float = 0.0
## Next light range.
var nextLightValue: float = 0.0
## Current light update count
var lightUpdated: int = 0
## Check to make sure we dont tween the light on startup.
var isReadyToTween: bool = false
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

## Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super()
	if Engine.is_editor_hint(): return
	while not player:
		player = get_tree().get_first_node_in_group("Player")
		await get_tree().process_frame
	playerDarknessManager = player.get_node("DarknessBlockerModule")
	shapes.top_level = true
	lightShape.shape = lightShape.shape.duplicate()
	await get_tree().create_timer(0.5).timeout
	isReadyToTween = true
	camera = get_tree().get_first_node_in_group("Camera")
	shineMaterial = shine.get_surface_override_material(0).duplicate()
	shine.set_surface_override_material(0, shineMaterial)

## Executed every process frame
func _process(delta: float) -> void:
	if nextLightValue > 0:
		timePassed += delta
		if timePassed < SHINEPARAMETERS.interval: return
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
	else:
		if shineAnimationMode not in ["AnimatingOut", "Off"]: animate_shine(false)

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

func set_shine(value: float) -> void:
	shineMaterial.set_shader_parameter("alpha_override", value)
	shineAlpha = value

## Changes the current state and visuals to the given mode
func set_size(mode: ScaleModes) -> void:
	super(mode)
	match mode:
		ScaleModes.GRABBED:
			floatingMesh.hide()
			animate_light_fade(LIGHTRANGEGRABED)
			lightShape.shape.radius = 0
			lightArea.set_collision_layer_value(5, false)
			lightArea.set_collision_mask_value(2, false)
			stickerLightArea.set_collision_mask_value(2, false)
			light.position.y = -GRABHEIGHT / 2.0
			light.light_size = 1.0
			light.shadow_bias = 10.0
			shine.mesh.size = SHINEPARAMETERS.heldSize
			set_assets("on")
		ScaleModes.DROPPED:
			floatingMesh.show()
			mesh.hide()
			animate_light_fade(0.0)
			light.position.y = 0.0
			shine.mesh.size = SHINEPARAMETERS.defaultSize
			set_assets("off")
		ScaleModes.PLACED:
			floatingMesh.hide()
			mesh.show()
			animate_light_fade(LIGHTRANGEPLACED)
			lightArea.set_collision_layer_value(5, true)
			lightArea.set_collision_mask_value(2, true)
			stickerLightArea.set_collision_mask_value(2, true)
			light.position.y = 0.0
			light.light_size = 0.0
			light.shadow_bias = 0.1
			shine.mesh.size = SHINEPARAMETERS.defaultSize
			set_assets("on")
		ScaleModes.ZOOMEDOUT:
			floatingMesh.hide()
	await get_tree().physics_frame
	shapes.global_position = global_position

## Sets assets to on or off state
func set_assets(state: String) -> void:
	floatingMesh.get_surface_override_material(0).albedo_texture = stickerTextures[state]
	mesh.get_surface_override_material(0).albedo_texture = stickerTextures[state]
	back.get_surface_override_material(0).albedo_texture = stickerTextures[state]
	billboard.texture = stickerTextures[state]
	billboard.texture = stickerTextures[state]

## Animates the light area
func animate_light_fade(newValue: float) -> void:
	light.show()
	if lightTween:
		lightTween.finished.disconnect(_on_light_fade_finish)
		lastLightValue = nextLightValue
		lightTween.kill()
	nextLightValue = newValue
	var energyGoal: float = 0.0 if newValue == 0.0 else LIGHTENERGY
	if not isReadyToTween:
		light.light_energy = energyGoal
		light.omni_range = newValue
		if newValue == LIGHTRANGEPLACED:
			lightShape.shape.radius = newValue
		else:
			lightShape.shape.radius = 0.0001
		return
	var goalTime: float = (LIGHTFADETIME if newValue != LIGHTRANGEPLACED else LIGHTAREAFADETIME) * inverse_lerp(newValue, lastLightValue, light.omni_range)
	lightTween = create_tween()
	lightTween.tween_property(light, "light_energy", energyGoal, goalTime).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUINT)
	lightTween.parallel().tween_property(light, "omni_range", newValue, goalTime).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUINT)
	if newValue == LIGHTRANGEPLACED:
		lightTween.parallel().tween_property(lightShape.shape, "radius", newValue, LIGHTAREAFADETIME).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUINT)
		lightTween.parallel().tween_method(check_darkness_update, 0, DarknessArea.ONLIGHTUPDATETIMES, LIGHTAREAFADETIME)
	else:
		lightShape.shape.radius = 0.0001
	lightTween.play()
	lightTween.finished.connect(_on_light_fade_finish)

## Checks to trigger darkness recalculation.
func check_darkness_update(times: float):
	if int(times) > lightUpdated:
		lightUpdated = int(times)
		light_updated.emit()

## Executed after light fade tween finishes.
func _on_light_fade_finish() -> void:
	lightUpdated = 0
	lastLightValue = nextLightValue
	if lastLightValue == 0.0: light.hide()

## Cabeza fix to load visuals
func prerender() -> void:
	billboardZoomedOut.no_depth_test = false
	billboardZoomedOut.fixed_size = false
	var zoomsize = billboardZoomedOut.pixel_size
	billboardZoomedOut.pixel_size = 0.0001
	var billboardsize = billboard.pixel_size
	billboard.pixel_size = 0.0001
	set_assets("on")
	mesh.show()
	floatingMesh.show()
	back.show()
	billboard.show()
	billboardZoomedOut.show()
	set_assets("off")
	await get_tree().physics_frame
	mesh.hide()
	floatingMesh.hide()
	back.hide()
	billboard.hide()
	billboardZoomedOut.hide()
	await get_tree().physics_frame
	mesh.show()
	floatingMesh.show()
	back.show()
	billboard.show()
	billboardZoomedOut.show()
	await get_tree().physics_frame
	floatingMesh.show()
	mesh.hide()
	billboard.hide()
	billboardZoomedOut.hide()
	billboardZoomedOut.no_depth_test = true
	billboardZoomedOut.fixed_size = true
	billboardZoomedOut.pixel_size = zoomsize
	billboard.pixel_size = billboardsize

## Activates the sticker effect when held by the player
func activate_on_player_effect() -> void:
	player.get_node("DarknessBlockerModule").holding_light(true)

## Deactivates the sticker effect when held by the player
func deactivate_on_player_effect() -> void:
	player.get_node("DarknessBlockerModule").holding_light(false)

## Signals that the body entered the light area
func _light_body_entered(body: Node3D) -> void:
	if body.has_node("DarknessBlockerModule"): 
		body.get_node("DarknessBlockerModule").light_area(self, true)

## Signals that the body exited the light area
func _light_body_exited(body: Node3D) -> void:
	if body.has_node("DarknessBlockerModule"): 
		body.get_node("DarknessBlockerModule").light_area(self, false)

## Signals that the body entered the sticker light area
func _sticker_light_body_entered(body: Node3D) -> void:
	if body.has_node("DarknessBlockerModule"): 
		body.get_node("DarknessBlockerModule").sticker_light_area(self, true)

## Signals that the body exited the sticker light area
func _sticker_light_body_exited(body: Node3D) -> void:
	if body.has_node("DarknessBlockerModule"): 
		body.get_node("DarknessBlockerModule").sticker_light_area(self, false)
