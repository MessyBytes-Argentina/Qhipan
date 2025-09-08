extends StickerBase

## Sticker that lights up darkness-blocked areas.
class_name LampSticker

## Range of the light while grabbed
const LIGHTRANGEGRABED: float = 1.5
## Range of the light while placed
const LIGHTRANGEPLACED: float = 3.5
## Energy of the light while placed or grabbed
const LIGHTENERGY: float = 1.0
## Light fade animation time
const LIGHTFADETIME: float = 0.3

## The floating mesh with no lighting on.
@onready var floatingMesh: MeshInstance3D = %FloatingMesh
## The light to turn on and of.
@onready var light: OmniLight3D = %Light
## Light area of effect
@onready var lightArea: Area3D = %LightArea
## Area3d container
@onready var shapes: Node3D = %Shapes
## Light area for dropping stickers
@onready var stickerLightArea: Area3D = %StickerLightArea

## Reference to the player character
var player: Player
## Reference to the player character darkness manager
var playerDarknessManager: DarknessBlockerModule
## Light animation tween.
var lightTween: Tween
## Last light range.
var lastLightValue: float = 0.0
## Tracks if player inside this lights effect.
var hasPlayer: bool = false

## Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super()
	while not player:
		player = get_tree().get_first_node_in_group("Player")
		await get_tree().process_frame
	playerDarknessManager = player.get_node("DarknessBlockerModule")
	shapes.top_level = true

## Changes the current state and visuals to the given mode
func set_size(mode: ScaleModes) -> void:
	super(mode)
	match mode:
		ScaleModes.GRABBED:
			floatingMesh.hide()
			animate_light_fade(LIGHTRANGEGRABED)
			lightArea.set_collision_layer_value(5, false)
			lightArea.set_collision_mask_value(2, false)
			stickerLightArea.set_collision_mask_value(2, false)
			light.position.y = -GRABHEIGHT / 2.0
		ScaleModes.DROPPED:
			floatingMesh.show()
			mesh.hide()
			animate_light_fade(0.0)
			light.position.y = 0.0
		ScaleModes.PLACED:
			floatingMesh.hide()
			mesh.show()
			animate_light_fade(LIGHTRANGEPLACED)
			lightArea.set_collision_layer_value(5, true)
			lightArea.set_collision_mask_value(2, true)
			stickerLightArea.set_collision_mask_value(2, true)
			light.position.y = 0.0
		ScaleModes.ZOOMEDOUT:
			floatingMesh.hide()
	await get_tree().physics_frame
	shapes.global_position = global_position

## Animates the light area
func animate_light_fade(newValue: float) -> void:
	light.show()
	if lightTween:
		lightTween.kill()
	var energyGoal: float = 0.0 if newValue == 0.0 else LIGHTENERGY
	var goalTime: float = LIGHTFADETIME * inverse_lerp(newValue, lastLightValue, light.omni_range)
	lightTween = create_tween()
	lightTween.tween_property(light, "light_energy", energyGoal, goalTime).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUINT)
	lightTween.parallel().tween_property(light, "omni_range", newValue, goalTime).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUINT)
	lightTween.play()
	lightTween.finished.connect(_on_light_fade_finish)

## Executed after light fade tween finishes.
func _on_light_fade_finish() -> void:
	lastLightValue = light.omni_range
	if lastLightValue == 0.0: light.hide()

## Cabeza fix to load visuals
func prerender() -> void:
	mesh.show()
	floatingMesh.show()
	back.show()
	billboard.show()
	billboardZoomedOut.show()
	await get_tree().create_timer(0.01).timeout
	mesh.hide()
	floatingMesh.hide()
	back.hide()
	billboard.hide()
	billboardZoomedOut.hide()
	await get_tree().create_timer(0.01).timeout
	mesh.show()
	floatingMesh.show()
	back.show()
	billboard.show()
	billboardZoomedOut.show()
	await get_tree().create_timer(0.01).timeout
	floatingMesh.show()
	mesh.hide()
	billboard.hide()
	billboardZoomedOut.hide()

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
