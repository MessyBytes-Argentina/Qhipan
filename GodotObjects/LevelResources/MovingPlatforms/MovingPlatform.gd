extends AnimatableBody3D
class_name MovingPlatform

## Color and animation parameters for the platform.
const EMISSION: Dictionary[String, Variant] = {
	"offColor": Color("cc4f6d"),
	"offRange": Vector2(0.0, 1.0),
	"onColor": Color("4df9fe"),
	"onRange": Vector2(0.2, 3.0),
	"permanentColor": Color("97db60"),
	"permanentRange": Vector2(0.2, 3.0),
	"tweenToTime": 0.5,
	"tweenTime": 2.0,
	"tweenEases": [Tween.EaseType.EASE_OUT, Tween.EaseType.EASE_IN],
	"tweenTrans": [Tween.TransitionType.TRANS_SINE, Tween.TransitionType.TRANS_SINE]
}

## Reference to the platforms rail for movement.
@export var railReference: PlatformRail
## Flag that if true removes the need of a placed alternator sticker.
@export var isPermanent: bool = false
## Flag that if true allows the platform to move.
@export var powered: bool = false
## Reference to the mesh.
@onready var mesh: MeshInstance3D = %Mesh

## Reference to the player checker.
@onready var playerChecker: Area3D = %PlayerChecker

## Is currently waiting for player to remain on the platform.
var doingWait: bool = false
## Current mode for color.
var mode: String
## Reference to the platform material.
var material: ShaderMaterial
## Reference to the tween
var tween: Tween
## Current color.
var currentColor: Color
## Current emission.
var currentEmission: float

## Executed when node first enters the scene.
func _ready() -> void:
	material = mesh.get_surface_override_material(1).duplicate()
	mesh.set_surface_override_material(1, material)
	GeneralVariables.queue_to_cutout_materials([material], true)
	mode = "permanent" if isPermanent else "on" if powered else "off"
	animate()

## Called when the Player is detected. Checks if movement is possible, starts moving if true.
func check_power(body: Node3D) -> void:
	if powered or isPermanent and not doingWait:
		doingWait = true
		await transition_color(false, false, false)
		if body in playerChecker.get_overlapping_bodies():
			railReference.start_moving()
			if tween: if tween.is_running(): tween.kill()
		else: transition_color(true)
		await get_tree().physics_frame
		doingWait = false
	else: transition_color(false, false, false)

## Called when the player gets off.
func player_off(_body: Node3D) -> void:
	if doingWait: return
	transition_color(true)

## When a block is detected stops the movement.
func stop_moving(body: Node3D) -> void:
	if body == self: return
	if body is AlternatingObject: if not body.isOff: railReference.stop_moving()

## Switches the powered flag to the opposite.
func switch_state() -> void:
	powered = !powered
	mode = "on" if powered else "off"
	transition_color()

## Transitions to another mode.
func transition_color(longTime: bool = false, doLoop: bool = true, startRange: bool = true) -> void:
	if tween: if tween.is_running(): tween.kill()
	tween = create_tween()
	tween.tween_method(_animation_tick_color, currentColor, EMISSION[mode + "Color"], EMISSION.tweenToTime if not longTime else EMISSION.tweenTime)
	tween.parallel().tween_method(_animation_tick_emission, currentEmission, EMISSION[mode + "Range"].x if startRange else EMISSION[mode + "Range"].y, EMISSION.tweenToTime if not longTime else EMISSION.tweenTime).set_ease(EMISSION.tweenEases[0 if startRange else 1] as Tween.EaseType).set_trans(EMISSION.tweenTrans[0 if startRange else 1] as Tween.TransitionType)
	tween.play()
	if doLoop: tween.finished.connect(animate)
	else: await tween.finished; return

## Animates color breathing.
func animate() -> void:
	if tween: if tween.is_running(): tween.kill()
	_animation_tick_color(EMISSION[mode + "Color"])
	_animation_tick_emission(EMISSION[mode + "Range"].x)
	tween = create_tween()
	tween.tween_method(_animation_tick_emission, EMISSION[mode + "Range"].x, EMISSION[mode + "Range"].y, EMISSION.tweenTime).set_ease(EMISSION.tweenEases[1] as Tween.EaseType).set_trans(EMISSION.tweenTrans[1] as Tween.TransitionType)
	tween.tween_method(_animation_tick_emission, EMISSION[mode + "Range"].y, EMISSION[mode + "Range"].x, EMISSION.tweenTime).set_ease(EMISSION.tweenEases[0] as Tween.EaseType).set_trans(EMISSION.tweenTrans[0] as Tween.TransitionType)
	tween.set_loops()
	tween.play()

## One animation tick for material color.
func _animation_tick_color(newColor: Color) -> void:
	material.set_shader_parameter("emission", newColor)
	currentColor = newColor

## One animation tick for material emission.
func _animation_tick_emission(newEmission: float) -> void:
	material.set_shader_parameter("emission_energy_multiplier", newEmission)
	currentEmission = newEmission

## Cleans unique materials.
func _notification(what) -> void:
	if what == NOTIFICATION_PREDELETE:
		GeneralVariables.queue_to_cutout_materials([material], false)
