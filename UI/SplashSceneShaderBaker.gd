extends Node3D

@export var sounds: Array[AudioStream] = []

@onready var poof: GPUParticles3D = %Poof
@onready var particles_1: GPUParticles3D = %Particles1
@onready var fan_particles: GPUParticles3D = %FanParticles
@onready var poof_2: MultipleParticle3DEmitter = %Poof2

func _ready() -> void:
	MusicManager.set_synchro_clip_volume("main",[1],-60.0,0.1)
	poof.emitting = true
	particles_1.emitting = true
	fan_particles.emitting = true
	poof_2.emit_particles()
	var sceneManager: StoryWriterSceneManager = null
	while not sceneManager:
		await get_tree().process_frame
		sceneManager = get_tree().get_first_node_in_group("SceneManager")
	sceneManager.load_scene("StartScreen", "res://UI/StartScreen.tscn")
	for audioStream in sounds:
		AudioServer.register_stream_as_sample(audioStream)
