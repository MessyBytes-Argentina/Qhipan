extends OmniLight3D

## Energy of the light while placed or grabbed
const LIGHTENERGY: float = 1.0
## Range of the light while placed
const LIGHTRANGE: float = 3.0
## Light area fade animation time
const LIGHTAREAFADETIME: float = 2.0

## Light area of effect
@onready var lightArea: Area3D = %LightArea
## Light area of effect shape
@onready var lightShape: CollisionShape3D = %LightShape
## Light area for dropping stickers
@onready var stickerLightArea: Area3D = %StickerLightArea

## Reference to the player character darkness manager
var playerDarknessManager: DarknessBlockerModule
## Light animation tween.
var lightTween: Tween
## Last light range.
var lastLightValue: float = 0.0
## Next light range.
var nextLightValue: float = 0.0
## Tracks if player inside this lights effect.
var hasPlayer: bool = false

## Executed when node first enters the scene tree.
func _ready() -> void:
	var player: Player = get_tree().get_first_node_in_group("Player")
	while not player:
		player = get_tree().get_first_node_in_group("Player")
		await get_tree().process_frame
	playerDarknessManager = player.get_node("DarknessBlockerModule")
	lightShape.shape.radius = 0.0001

## To trigger form alternating surfaces.
func switch_state(state: bool) -> void:
	animate_light_fade(LIGHTRANGE if state else 0.0)
	lightArea.set_collision_layer_value(5, state)
	lightArea.set_collision_mask_value(2, state)
	stickerLightArea.set_collision_mask_value(2, state)

## Animates the light area
func animate_light_fade(newValue: float) -> void:
	show()
	if lightTween:
		lightTween.finished.disconnect(_on_light_fade_finish)
		lastLightValue = nextLightValue
		lightTween.kill()
	nextLightValue = newValue
	var energyGoal: float = 0.0 if newValue == 0.0 else LIGHTENERGY
	var goalTime: float = LIGHTAREAFADETIME * inverse_lerp(newValue, lastLightValue, self.omni_range)
	lightTween = create_tween()
	lightTween.tween_property(self, "light_energy", energyGoal, goalTime).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUINT)
	lightTween.parallel().tween_property(self, "omni_range", newValue, goalTime).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUINT)
	if newValue > 0.0:
		lightTween.parallel().tween_property(lightShape.shape, "radius", newValue, LIGHTAREAFADETIME).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUINT)
	else:
		lightShape.shape.radius = 0.0001
	lightTween.play()
	lightTween.finished.connect(_on_light_fade_finish)

## Executed after light fade tween finishes.
func _on_light_fade_finish() -> void:
	lastLightValue = nextLightValue
	if lastLightValue == 0.0: hide()

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
