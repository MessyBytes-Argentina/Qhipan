@tool
extends StickerBase
## Fan sticker class.
class_name FanSticker

## Default fan range.
const DEFAULTFANRANGE: float = 3.0

## Fan range. Use only on fixed fans.
@export_range(1.0, 20.0, 1.0) var fanRange = 3.0

## AnimationPlayer reference.
@onready var animationPlayer: AnimationPlayer = %AnimationPlayer
## Spinup sound player.
@onready var spinupSound: RandomPitchPlayer = %SpinupSound
## Pushing area reference.
@onready var fan: Fan = %Fan

## OnPlayerEffect node reference.
var onPlayerEffectRef: LedgeDetection

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
func place_sticker(pos: Vector3, direction: Vector3, overrideSize: Vector3 = Vector3.ONE) -> void:
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
