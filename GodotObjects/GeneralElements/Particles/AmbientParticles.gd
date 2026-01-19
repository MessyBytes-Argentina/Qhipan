@tool
extends CSGBox3D

## Class that handles permanent ambient particles. Uses box for uniform resizing.
class_name AmbientParticles

## The particles to use.
@export var particleScene: PackedScene
## Test button.
@export_tool_button("TestParticles", "ParticleProcessMaterial") var test: Callable = _spawn_particles

## Called when the node enters the scene tree for the first time.
func _ready() -> void:
	layers = 0
	await _spawn_particles()
	if not Engine.is_editor_hint():
		get_child(0).reparent(get_parent())
		queue_free()

## Calls forth the particles.
func _spawn_particles() -> void:
	for child in get_children(): child.queue_free()
	if not particleScene: return
	var particles: GPUParticles3D = particleScene.instantiate()
	await get_tree().process_frame
	add_child(particles)
	particles.process_material = particles.process_material.duplicate()
	particles.amount = int(round((size / 2.0).length() / particles.process_material.emission_box_extents.length() * particles.amount))
	particles.process_material.emission_box_extents = size / 2.0
	particles.visibility_aabb = get_aabb()
	particles.restart()
