extends Area3D
class_name Checkpoint

const LIGHTTIME: float = 0.5
const LIGHTENERGY: float = 0.25

@onready var offTexture: Texture2D = preload("res://Assets/CheckPoint Totem/Checkpoint-Off.png")
@onready var onTexture: Texture2D = preload("res://Assets/CheckPoint Totem/Material Base Color.png")

@onready var light: OmniLight3D = %Light
@onready var llamaTotem: MeshInstance3D = %LlamaTotem
@onready var particles1: GPUParticles3D = %Particles1
@onready var particles2: GPUParticles3D = %Particles2
@onready var activationSound: RandomPitchPlayer = %ActivationSound

var lightTween: Tween
var material: StandardMaterial3D
var soundEnabled: bool = false

func _ready() -> void:
	material = llamaTotem.get_surface_override_material(0).duplicate()
	llamaTotem.set_surface_override_material(0, material)

func activate() -> void:
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

func deactivate() -> void:
	material.albedo_texture = offTexture
	llamaTotem.set_surface_override_material(0, material)
	lightTween = create_tween()
	lightTween.tween_property(light, "light_energy", 0.0, (1.0 - inverse_lerp(LIGHTENERGY, 0.0, light.light_energy)) * LIGHTTIME).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUART)
	lightTween.play()
	await lightTween.finished
	light.hide()

func enable_sounds() -> void:
	soundEnabled = true
