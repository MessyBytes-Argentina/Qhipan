@tool
extends Area3D

class_name GlowDetectionArea

## AmmountOfLightsToProcess.
const LIGHTAMOUNT: int = 6

## Minimum alpha
@export_range(0.0, 1.0, 0.01) var minimumAlpha: float = 0.0

## Reference to shaders.
var shaders: Array[ShaderMaterial] = []
## Reference to lights.
var lights: Array[LampSticker] = []
## Reference to player
var player: Player
## Reference to pickup handler
var pickupHandler: PickupHandler

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	await get_parent().ready
	_get_shaders(get_parent())
	if Engine.is_editor_hint():
		for shader in shaders:
			shader.set_shader_parameter("minAlpha", 1.0)
		return
	for shader in shaders:
		shader.set_shader_parameter("minAlpha", minimumAlpha)
	player = get_tree().get_first_node_in_group("Player")
	pickupHandler = player.grabArea

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if Engine.is_editor_hint(): return
	var lightsParameters: PackedVector4Array = []
	lightsParameters.resize(LIGHTAMOUNT)
	var j: int = 0
	for i in range(max(0, len(lights) - LIGHTAMOUNT), len(lights)):
		lightsParameters[j] = Vector4(lights[i].global_position.x, lights[i].global_position.y, lights[i].global_position.z, lights[i].lightShape.shape.radius)
		j += 1
	for shader in shaders:
		shader.set_shader_parameter("lights", lightsParameters)
		shader.set_shader_parameter("playerHoldsLight", pickupHandler.currentPickup is LampSticker)
		shader.set_shader_parameter("actualPlayerPosition", player.global_position)

func _get_shaders(node: Node) -> void:
	if node is MultiMeshInstance3D: _store_shaders(node.multimesh.mesh)
	if node is MeshInstance3D: _store_shaders(node.mesh)
	for child in node.get_children():
		_get_shaders(child)

func _store_shaders(mesh: Mesh) -> void:
	if mesh is PrimitiveMesh:
		if mesh.material is ShaderMaterial:
			var material: ShaderMaterial = mesh.material.duplicate()
			shaders.append(material)
			mesh.material = material
		return
	for i in mesh.get_surface_count():
		if mesh.surface_get_material(i) is ShaderMaterial:
			var material: ShaderMaterial = mesh.surface_get_material(i).duplicate()
			if not material: continue
			shaders.append(material)
			mesh.surface_set_material(i, material)

## Adds lights to list
func _on_light_entered(area: Area3D) -> void:
	if not area.has_meta("Parent"): return
	var light: LampSticker = area.get_node(area.get_meta("Parent"))
	if light not in lights: lights.append(light)

## Removes light from list
func _on_light_exited(area: Area3D) -> void:
	if not area.has_meta("Parent"): return
	var light: LampSticker = area.get_node(area.get_meta("Parent"))
	lights.erase(light)
