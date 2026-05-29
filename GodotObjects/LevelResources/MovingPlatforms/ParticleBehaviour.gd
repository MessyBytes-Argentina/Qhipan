extends Node3D

@export var stateSwitchParticleOn : MultipleParticle3DEmitter
@export var stateSwitchParticleOff : MultipleParticle3DEmitter
@export var movingPlatformParent : MovingPlatform

##TODO: Create two particles that represent the state of the platform
## to and from ON or OFF.

func _ready() -> void:
	movingPlatformParent.state_switched.connect(animate_particles)
	

func animate_particles(state : bool):
	if state: stateSwitchParticleOn.emit_animator()
	else: stateSwitchParticleOff.emit_animator()
