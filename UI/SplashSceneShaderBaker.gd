extends Node3D

@onready var poof: GPUParticles3D = %Poof
@onready var particles_1: GPUParticles3D = %Particles1
@onready var fan_particles: GPUParticles3D = %FanParticles

func _ready() -> void:
	poof.emitting = true
	particles_1.emitting = true
	fan_particles.emitting = true
