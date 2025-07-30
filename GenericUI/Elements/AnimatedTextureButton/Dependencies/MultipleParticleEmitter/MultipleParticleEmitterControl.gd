@icon("./ParticleControl.svg")
@tool
extends Control

## A [Control] node that holds multiple [GPUParticles2D] and instantiates them at the center of this node on demand at set delays. All non one shot particles will be turned one shot to avoid memory leaks.
class_name MultipleParticleEmitterControl

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
	mouse_filter = MouseFilter.MOUSE_FILTER_IGNORE
	_create_white_pixel()
	if not Engine.is_editor_hint():
		_testParticles = ""

## Creates the white pixel.
func _create_white_pixel() -> void:
	if custom_minimum_size != Vector2.ZERO:
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
			if custom_minimum_size != Vector2.ZERO:
				currentParticle.scale = size / custom_minimum_size
				if currentParticle.texture:
					currentParticle.texture.get_image().resize(int(currentParticle.texture.get_width() * currentParticle.scale.x), int(currentParticle.texture.get_height() * currentParticle.scale.y))
				else:
					var newPixel: GradientTexture2D = whitePixel.duplicate()
					newPixel.width = int(currentParticle.scale.x)
					newPixel.height = int(currentParticle.scale.y)
					currentParticle.texture = newPixel
			currentParticle.position = size / 2
			currentParticle.one_shot = true
			currentParticle.finished.connect(currentParticle.queue_free)
			currentParticle.emitting = true
			if len(particles) > 1 and i < len(particles) - 1:
				if delay[i] > 0:
					await get_tree().create_timer(delay[i]).timeout
