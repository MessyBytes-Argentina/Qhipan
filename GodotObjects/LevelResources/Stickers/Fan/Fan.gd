extends StickerBase

## AnimationPlayer reference.
@onready var animationPlayer: AnimationPlayer = %AnimationPlayer
## Spinup sound player.
@onready var spinupSound: RandomPitchPlayer = %SpinupSound
## Pushing area reference.
@onready var fan: Fan = %Fan

## OnPlayerEffect node reference.
var onPlayerEffectRef: OnPlayerFan

## Called when the node enters the scene tree for the first time.
func _ready() -> void:
	fan.switch_fan(true)
	super()
	if not placed:
		await get_tree().create_timer(0.5).timeout
		fan.switch_fan(false)

## Plays sound and places the fan then starts the fan animation.
func place_sticker(area: Area3D, direction: Vector3, isPlaceholderArea: bool = false) -> void:
	if grabed:
		spinupSound.play_sound()
	super(area, direction, isPlaceholderArea)
	animationPlayer.play("SpinUp")

## Turns off the fan and grabs it
func grab(node: Node3D) -> void:
	super(node)
	animationPlayer.play("RESET")
	fan.switch_fan(false)
	grabed = true

## Checks every frame to turn the fan off when not grabed or placed
func _process(_delta: float) -> void:
	if not grabed and not placed and fan.isOn:
		fan.switch_fan(false)

## Activates the sticker effect when held by the player
func activate_on_player_effect() -> void:
	if onPlayerEffectRef == null:
		onPlayerEffectRef = get_tree().get_first_node_in_group("OnPlayerFan")
	onPlayerEffectRef.replenish_push()

## Deactivates the sticker effect when held by the player
func deactivate_on_player_effect() -> void:
	onPlayerEffectRef.activate_push()
