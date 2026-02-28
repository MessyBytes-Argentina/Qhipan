@tool
extends StaticBody3D

## Standard particle amount
const PARTICLES: int = 6
## Minimum particle amount
const MINPARTICLES: int = 6
## Standard particle duration
const PARTICLESLIFE: float = 2.0
## Time to disappear
const ANIMATIONTIME: float = 1.0

## Placeholderr color for the block.
@export var color: Color = Color.WHITE:
	set(value):
		color = value
		if Engine.is_editor_hint() and is_node_ready(): update_texture()
## Placeholder texture for the block.
@export var texture: Texture2D:
	set(value):
		texture = value
		if Engine.is_editor_hint() and is_node_ready(): update_texture()
## Placeholder scale.
@export var forceScale: Vector3 = Vector3.ONE:
	set(value):
		forceScale = value
		if Engine.is_editor_hint() and is_node_ready(): update_texture()
## Used to identify which objects to trigger when a pedestarl triggers with this same name.
@export var pedestalName: String

## Reference to the main mesh of the block.
@onready var mesh: MeshInstance3D = %MeshInstance3D
## Reference to the collision shape.
@onready var collisionShape: CollisionShape3D = %CollisionShape3D
## Referernce to the gpu particles.
@onready var gpuParticles3d: GPUParticles3D = %GPUParticles3D

## Executed when node first enters the scene tree.
func _ready() -> void:
	update_texture()

##  Updates the debug texture.
func update_texture() -> void:
	var material: ShaderMaterial = mesh.get_surface_override_material(0).duplicate()
	material.set_shader_parameter("color", color)
	mesh.set_surface_override_material(0, material)
	var particleMaterial: StandardMaterial3D = gpuParticles3d.get_material_override().duplicate()
	particleMaterial.albedo_texture = texture
	gpuParticles3d.set_material_override(particleMaterial)
	mesh.scale = forceScale
	collisionShape.shape = collisionShape.shape.duplicate()
	collisionShape.shape.size = forceScale
	gpuParticles3d.lifetime = PARTICLESLIFE * forceScale.y
	gpuParticles3d.process_material = gpuParticles3d.process_material.duplicate()
	gpuParticles3d.process_material.emission_shape_scale = forceScale
	gpuParticles3d.amount = max(MINPARTICLES, PARTICLES * round(forceScale.x * forceScale.y * forceScale.z))
	scale = Vector3.ONE
	mesh.position.y = forceScale.y / 2.0
	collisionShape.position.y = forceScale.y / 2.0

## Called when pedestal is activated.
func pedestal_activated(activatedPedestal: String, skip: bool = false) -> void:
	if activatedPedestal == pedestalName:
		if not skip:
			gpuParticles3d.emitting = false
			mesh.mesh = mesh.mesh.duplicate()
			var tween: Tween = create_tween()
			tween.tween_property(mesh.mesh, "size", Vector3(1.0, 0.0, 1.0), ANIMATIONTIME).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
			tween.parallel().tween_property(mesh, "position", Vector3(0.0, 0.0, 0.0), ANIMATIONTIME).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
			tween.play()
			await tween.finished
		queue_free()
