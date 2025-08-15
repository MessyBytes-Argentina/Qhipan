extends Area3D
## The checkpoint object.
class_name Checkpoint

## Time multiplier for light animation
const LIGHTTIME: float = 0.5
## Minimum light energy for activation animation
const LIGHTENERGY: float = 0.25

## Albedo texture for the checkpoint material when it turns off
@onready var offTexture: Texture2D = preload("uid://d0nk04f8gsnwg")
## Albedo texture for the checkpoint material when it turns on
@onready var onTexture: Texture2D = preload("uid://bttfw724v68fi")

## Checkpoint light
@onready var light: OmniLight3D = %Light
## Checkpoint 3D Mesh
@onready var llamaTotem: MeshInstance3D = %LlamaTotem
## Eye particle emmiter
@onready var particles1: GPUParticles3D = %Particles1
## Eye particle emmiter
@onready var particles2: GPUParticles3D = %Particles2
## Activation sound player
@onready var activationSound: RandomPitchPlayer = %ActivationSound

## Tween for light animation
var lightTween: Tween
## Checkpoint material
var material: StandardMaterial3D
## Stops sound from being played multiple times
var soundEnabled: bool = false
## Is the checkpoint active?
var activated: bool = false

## Called when the node enters the scene tree for the first time.
func _ready() -> void:
	material = llamaTotem.get_surface_override_material(0).duplicate()
	llamaTotem.set_surface_override_material(0, material)
	particles1.emitting = true
	particles2.emitting = true
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

## Turns on visual effects of the checkpoint.
## Sets the activated flag on and calls reset_aura on the Player.
func activate() -> void:
	activated = true
	material.albedo_texture = onTexture
	llamaTotem.set_surface_override_material(0, material)
	light.show()
	if lightTween: lightTween.kill()
	lightTween = create_tween()
	lightTween.tween_property(light, "light_energy", LIGHTENERGY, (1.0 - inverse_lerp(0.0, LIGHTENERGY, light.light_energy)) * LIGHTTIME).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUINT)
	lightTween.play()
	particles1.emitting = true
	particles2.emitting = true
	if soundEnabled:
		activationSound.play_sound()
	get_tree().call_group("Player","reset_aura")

## Turns off visual effects of the checkpoint and sets the activated flag off.
func deactivate() -> void:
	material.albedo_texture = offTexture
	llamaTotem.set_surface_override_material(0, material)
	lightTween = create_tween()
	lightTween.tween_property(light, "light_energy", 0.0, (1.0 - inverse_lerp(LIGHTENERGY, 0.0, light.light_energy)) * LIGHTTIME).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUART)
	lightTween.play()
	await lightTween.finished
	light.hide()
	activated = false

## Sets the soundEnabled flag true to allow sound to be played.
func enable_sounds() -> void:
	soundEnabled = true

## Calls checkpoint_entered() on the Player when they enter the checkpoint area.
func _on_body_entered(body: Node3D) -> void:
	if body is Player: body.checkpoint_entered()

## Calls checkpoint_exited() on the Player when they exit the checkpoint area.
func _on_body_exited(body: Node3D) -> void:
	if body is Player: body.checkpoint_exited()
