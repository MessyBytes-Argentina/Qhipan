extends Node3D

## Plays all provided particles and sounds to make sure godot prebakes them.

## Sounds to play
@export var sounds: Array[AudioStream] = []

## Reference to the particle collection.
@onready var particles: Node3D = %Particles
## Reference to the particle emitter collection.
@onready var particleEmiters: Node3D = %ParticleEmitters

## Called when the node enters the scene tree for the first time.
func _ready() -> void:
	MusicManager.set_synchro_clip_volume("main",[1],-60.0,0.1)
	for particle in particles.get_children(): particle.emitting = true
	for particleEmmitter in particleEmiters.get_children(): particleEmmitter.emit_particles()
	var sceneManager: StoryWriterSceneManager = null
	while not sceneManager:
		await get_tree().process_frame
		sceneManager = get_tree().get_first_node_in_group("SceneManager")
	sceneManager.load_scene("StartScreen", "uid://3iena3lvxxgn")
	for audioStream in sounds:
		AudioServer.register_stream_as_sample(audioStream)
