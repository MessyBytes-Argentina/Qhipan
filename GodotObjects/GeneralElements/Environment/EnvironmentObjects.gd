@tool
extends Node3D

## Environment objects collector.
class_name EnvironmentObjects

## Starting environment
@export var startEnvironment: EnvironmentParameters:
	set(value):
		startEnvironment = value
		if Engine.is_editor_hint() and is_node_ready(): setup()
## Starting sun
@export var startLight: LightParameters:
	set(value):
		startLight = value
		if Engine.is_editor_hint() and is_node_ready(): setup()

## Reference to the environment.
@onready var environment: WorldEnvironment = %WorldEnvironment
## Reference to the sun.
@onready var sun: DirectionalLight3D = %DirectionalLight3D
## Reference to the color correction [SubViewport].
@onready var colorCorrectionSubViewport: SubViewport = %ColorCorrectionSubViewport
## Reference to the color correction [TextureRect].
@onready var colorCorrectionTextureRect: TextureRect = %ColorCorrectionTextureRect

## Color correction material
var colorCorrectionMaterial: ShaderMaterial

## Called when the node enters the scene tree for the first time.
func _ready() -> void:
	colorCorrectionMaterial = colorCorrectionTextureRect.material
	setup()

## Sets up start environment and sun.
func setup() -> void:
	if startEnvironment: startEnvironment.set_environment(environment.environment, colorCorrectionMaterial)
	if startLight: startLight.set_sun(sun)
