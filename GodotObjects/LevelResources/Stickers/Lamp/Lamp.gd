extends StickerBase

const LIGHTRANGEGRABED: float = 1.5
const LIGHTRANGEPLACED: float = 3.5
const LIGHTENERGY: float = 1.0
const LIGHTFADETIME: float = 0.3

## The floating mesh with no lighting on.
@onready var floatingMesh: MeshInstance3D = %FloatingMesh
## The light to turn on and of.
@onready var light: OmniLight3D = %Light
## Light area of effect
@onready var lightArea: Area3D = %LightArea

## Light animation tween.
var lightTween: Tween
## Last light range.
var lastLightValue: float = 0.0

## Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super()
	light.position.y = -GRABHEIGHT / 2.0

## Changes the current state and visuals to the given mode
func set_size(mode: ScaleModes) -> void:
	super(mode)
	match mode:
		ScaleModes.GRABBED:
			floatingMesh.hide()
			animate_light_fade(LIGHTRANGEGRABED)
			lightArea.set_deferred("monitoring", false)
		ScaleModes.DROPPED:
			floatingMesh.show()
			mesh.hide()
			animate_light_fade(0.0)
		ScaleModes.PLACED:
			floatingMesh.hide()
			mesh.show()
			animate_light_fade(LIGHTRANGEPLACED)
			lightArea.set_deferred("monitoring", true)
		ScaleModes.ZOOMEDOUT:
			floatingMesh.hide()

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
	lastLightValue = newValue
	if newValue == 0.0: lightTween.finished.connect(light.hide)

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
	_light_body_entered(get_tree().get_first_node_in_group("Player"))

## Deactivates the sticker effect when held by the player
func deactivate_on_player_effect() -> void:
	_light_body_exited(get_tree().get_first_node_in_group("Player"))

func _light_body_entered(body: Node3D) -> void:
	if body.has_node("DarknessBlockerModule"): body.get_node("DarknessBlockerModule").light_area_entered(self)

func _light_body_exited(body: Node3D) -> void:
	if body.has_node("DarknessBlockerModule"): body.get_node("DarknessBlockerModule").light_area_exited(self)
