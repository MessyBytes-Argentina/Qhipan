@tool
extends Node3D

## Environment objects collector.
class_name EnvironmentObjects

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
