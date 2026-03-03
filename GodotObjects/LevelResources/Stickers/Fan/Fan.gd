@tool
extends StickerBase
## Fan sticker class.
class_name FanSticker

## Default fan range.
const DEFAULTFANRANGE: float = 3.0
## No fan on player bitflag.
const NOPLAYERFAN: int = 1
## No antigravity on player bitflag.
const NOPLAYERANTIGRAVITY: int = 2

## Fan range. Use only on fixed fans.
@export_range(1.0, 20.0, 1.0) var fanRange = 3.0

## AnimationPlayer reference.
@onready var animationPlayer: AnimationPlayer = %AnimationPlayer
## Spinup sound player.
@onready var spinupSound: RandomSoundPlayer = %SpinupSound
## Pushing area reference.
@onready var fan: Fan = %Fan
## NoGravity area reference.
@onready var noGravity: NoGravityZone = %NoGravity

## OnPlayerEffect node reference.
var onPlayerEffectRef: LedgeDetection
## Override range for placement.
var overrideRange: float = -1

## Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if not Engine.is_editor_hint(): 
		fan.areaHeight = fanRange
		fan.set_area_size()
		fan.switch_fan(true)
	super()
	if Engine.is_editor_hint(): 
		if not fanRange: fanRange = DEFAULTFANRANGE
		return
	if not placed:
		await get_tree().create_timer(0.5).timeout
		fan.switch_fan(false)

## Plays sound and places the fan then starts the fan animation.
func place_sticker(pos: Vector3, direction: Vector3, overrideSize: Vector3 = Vector3.ONE, specialFlags: int = 0, extraParameters: Dictionary = {}) -> void:
	fan.canAffectPlayer = specialFlags & NOPLAYERFAN == 0
	if extraParameters.has("overrideFanLength"): set_override_range(extraParameters.overrideFanLength)
	noGravity.canAffectPlayer = specialFlags & NOPLAYERANTIGRAVITY == 0
	if grabed:
		spinupSound.play_sound()
	super(pos, direction, overrideSize)
	animationPlayer.play("SpinUp")

## Turns off the fan and grabs it
func grab(node: Node3D) -> void:
	super(node)
	animationPlayer.play("RESET")
	fan.switch_fan(false)
	grabed = true
	await get_tree().process_frame
	fan.canAffectPlayer = true
	noGravity.canAffectPlayer = true
	set_override_range(-1)

## Checks every frame to turn the fan off when not grabed or placed
func _process(_delta: float) -> void:
	if Engine.is_editor_hint(): return
	if not grabed and not placed and fan.isOn:
		fan.switch_fan(false)

## Activates the sticker effect when held by the player
func activate_on_player_effect() -> void:
	if onPlayerEffectRef == null:
		onPlayerEffectRef = get_tree().get_first_node_in_group("OnPlayerFan")
	onPlayerEffectRef.enable_push()

## Deactivates the sticker effect when held by the player
func deactivate_on_player_effect() -> void:
	onPlayerEffectRef.disable_push()

## Sets override range.
func set_override_range(newRange: float) -> void:
	overrideRange = newRange
	fanRange = overrideRange if overrideRange > -1 else DEFAULTFANRANGE
	fan.set_area_size()
