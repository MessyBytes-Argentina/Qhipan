@icon("./Particle3D.svg")
@tool
extends Node3D

## A [Node3D] that holds multiple [GPUParticles3D] and instantiates on demand at set delays. All non one shot particles will be turned one shot to avoid memory leaks.
class_name MultipleParticle3DEmitter

signal finished

## The [GPUParticles3D] to emit. Taken as [PackedScene]s. All non [GPUParticles3D] scenes will be ignored.
@export var particles: Array[PackedScene]:
	set(value):
		particles = value
		notify_property_list_changed()
## The delays between particle emittions.
var delay: PackedFloat32Array = []:
	set(value):
		if len(value) == len(particles) - 1:
			delay = value
## A button to test the particle emittion
var _testParticles: String = "": set = _test_particles

## Populates the resource in the editor.
func _get_property_list() -> Array:
	var properties: Array = []
	
	# particlesDelay
	if len(particles) > 1:
		if len(delay) == len(particles):
			var tempDelay: Array = Array(delay)
			tempDelay.pop_back()
			delay = PackedFloat32Array(tempDelay)
		else:
			delay.resize(len(particles) - 1)
		properties.append({
			"name": "delay",
			"type": TYPE_PACKED_FLOAT32_ARRAY,
			"usage": PROPERTY_USAGE_DEFAULT,
			"hint": PROPERTY_HINT_RANGE,
			"hint_string": "0,10,0.01,or_greater",
		})
	if len(particles) > 0:
		properties.append({
			"name": "_testParticles",
			"type": TYPE_STRING,
			"usage": PROPERTY_USAGE_DEFAULT,
			"hint_string": "ActionProperty",
		})
	
	return properties

## Called when the node enters the scene tree for the first time.
func _ready():
	if not Engine.is_editor_hint():
		_testParticles = ""

## Runs the particles i nthe editor.
func _test_particles(value:String) -> void:
	if value.length() > 0:
		emit_particles()

func scale_primitive_mesh(mesh: PrimitiveMesh, newScale: float) -> PrimitiveMesh:
	match mesh.get_class():
		"SphereMesh", "CapsuleMesh":
			mesh.radius *= newScale
			mesh.height *= newScale
		"BoxMesh", "PlaneMesh", "PrismMesh":
			mesh.size *= newScale
		"CylinderMesh":
			mesh.top_radius *= newScale
			mesh.bottom_radius *= newScale
			mesh.height *= newScale
		"RibbonTrailMesh":
			mesh.size *= newScale
			mesh.section_length *= newScale
		"TorusMesh":
			mesh.inner_radius *= newScale
			mesh.outer_radius *= newScale
		"TubeTrailMesh":
			mesh.radius *= newScale
			mesh.section_length *= newScale
	return mesh

## Emits the particles in the set time delays
func emit_particles(newPosition: Vector3 = global_position, newRotation: Vector3 = global_rotation) -> void:
	global_position = newPosition
	global_rotation = newRotation
	for i in range(len(particles)):
		var currentParticle: GPUParticles3D = particles[i].instantiate()
		if currentParticle:
			add_child(currentParticle)
			if scale != Vector3.ONE:
				for j in range(currentParticle.draw_passes):
					if currentParticle["draw_pass_" + str(j + 1)] is PrimitiveMesh:
						currentParticle["draw_pass_" + str(j + 1)] = scale_primitive_mesh(currentParticle["draw_pass_" + str(j + 1)].duplicate(), min(scale.x, scale.y, scale.z))
			currentParticle.one_shot = true
			if i == len(particles) - 1:
				currentParticle.finished.connect(finished.emit)
			currentParticle.finished.connect(currentParticle.queue_free)
			currentParticle.global_position = newPosition
			currentParticle.global_rotation = newRotation
			currentParticle.emitting = true
			if len(particles) > 1 and i < len(particles) - 1:
				if delay[i] > 0:
					await get_tree().create_timer(delay[i]).timeout
