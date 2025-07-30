@icon("./Particle2D.svg")
@tool
extends Node2D

## A [Node2D] that holds multiple [GPUParticles2D] and instantiates on demand at set delays. All non one shot particles will be turned one shot to avoid memory leaks.
class_name MultipleParticle2DEmitter

## The [GPUParticles2D] to emit. Taken as [PackedScene]s. All non [GPUParticles2D] scenes will be ignored.
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
var _testParticles: String = "": 
	set(value):
		if value.length() > 0:
			emit_particles()
## A white pixel texture used to resize particles with no texture.
var whitePixel: GradientTexture2D

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
func _ready() -> void:
	_create_white_pixel()
	if not Engine.is_editor_hint():
		_testParticles = ""

## Runs the particles i nthe editor.
func _test_particles(value:String) -> void:
	if value.length() > 0:
		emit_particles()

## Creates the white pixel.
func _create_white_pixel() -> void:
	whitePixel = GradientTexture2D.new()
	whitePixel.gradient = Gradient.new()
	whitePixel.gradient.colors = PackedColorArray([Color.WHITE])
	whitePixel.width = 1
	whitePixel.height = 1

## Emits the particles in the set time delays
func emit_particles() -> void:
	for i in range(len(particles)):
		var currentParticle: GPUParticles2D = particles[i].instantiate()
		if currentParticle:
			add_child(currentParticle)
			if scale != Vector2.ONE:
				if currentParticle.texture:
					var newImage: Image = currentParticle.texture.get_image().duplicate()
					currentParticle.texture = ImageTexture.create_from_image(newImage)
				else:
					var newPixel: GradientTexture2D = whitePixel.duplicate()
					newPixel.width = int(scale.x)
					newPixel.height = int(scale.y)
					currentParticle.texture = newPixel
			currentParticle.one_shot = true
			currentParticle.finished.connect(currentParticle.queue_free)
			currentParticle.emitting = true
			if len(particles) > 1 and i < len(particles) - 1:
				if delay[i] > 0:
					await get_tree().create_timer(delay[i]).timeout
