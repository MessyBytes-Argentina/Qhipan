extends StickerBase

const LIGHTRANGEGRABED: float = 1.5
const LIGHTRANGEPLACED: float = 3.5
const LIGHTENERGY: float = 1.0
const LIGHTFADETIME: float = 0.3

## The floating mesh with no lighting on.
@onready var floatingMesh: MeshInstance3D = %FloatingMesh
## The light to turn on and of.
@onready var light: OmniLight3D = %Light

## Light animation tween.
var lightTween: Tween
## Last light range.
var lastLightValue: float = 0.0

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
		ScaleModes.DROPPED:
			floatingMesh.show()
			mesh.hide()
			animate_light_fade(0.0)
		ScaleModes.PLACED:
			floatingMesh.hide()
			mesh.show()
			animate_light_fade(LIGHTRANGEPLACED)
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
	pass

## Deactivates the sticker effect when held by the player
func deactivate_on_player_effect() -> void:
	pass
