extends FogVolume

## Darkness volume that blocks areas until a light is shined through it.
class_name DarknessArea

## The amount of vertices per meter that the fog collision is broken up into.
## Higher means higher collision quality but poorer performance.
const DARKNESSCOLLISIONRESOLUTION: int = 8
## The amount of lights that can affect the fog shader. This must match the value set up in the shader.
const SHADERLIGHTSTRACKED: int = 6

## Reference to the collision shape of the fog
@onready var darknessCollisionShape: CollisionShape3D = %DarknessCollisionShape
## Reference to the collision shape of the area of effect for the fog
@onready var darknessAreaShape: CollisionShape3D = %DarknessAreaShape
## Reference to the collision heightmap used on the fog
var collisionMap: HeightMapShape3D
## Reference to the fog shader
var fogShader: ShaderMaterial

## Lights currently affecting the fog
var lights: Array[Area3D] = []

## Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if Engine.is_editor_hint(): return
	_collision_shape_set()

## Sets up the collision shape for the fog
func _collision_shape_set() -> void:
	if not is_node_ready():
		await ready
	darknessAreaShape.shape = BoxShape3D.new()
	darknessAreaShape.shape.size = size
	collisionMap = darknessCollisionShape.shape
	fogShader = material.duplicate()
	material = fogShader
	update_collision_shape()

## Resets the collision shape details.
func reset_collision_shape() -> void:
	collisionMap.map_width = int(size.x * float(DARKNESSCOLLISIONRESOLUTION))
	collisionMap.map_depth = int(size.z * float(DARKNESSCOLLISIONRESOLUTION))
	darknessCollisionShape.scale = Vector3.ONE / float(DARKNESSCOLLISIONRESOLUTION)
	for i in range(len(collisionMap.map_data)):
		if i < collisionMap.map_width or i % collisionMap.map_width == 0 or (i + 1) % collisionMap.map_width == 0 or i + collisionMap.map_width >= len(collisionMap.map_data): collisionMap.map_data[i] = 0.0
		else: collisionMap.map_data[i] = size.y * (1.0 / darknessCollisionShape.scale.y)
	darknessCollisionShape.position.y = - size.y / 2.0

## Updates the collision shape details to match shiningh lights
func update_collision_shape() -> void:
	reset_collision_shape()
	var flatStartGlobalPosition: Vector2 = Vector2(global_position.x, global_position.z) - Vector2(size.x, size.z) / 2.0
	var lightDistances: Dictionary[Vector2, float]
	var lightPoints: PackedVector2Array = []
	var lightRanges: PackedFloat32Array = []
	for lightArea in lights: 
		lightDistances[Vector2(lightArea.global_position.x, lightArea.global_position.z)] = lightArea.get_node("CollisionShape3D").shape.radius
	for lightPoint in lightDistances:
		lightPoints.append(lightPoint)
		lightRanges.append(lightDistances[lightPoint])
	for i in range(len(collisionMap.map_data)):
		if collisionMap.map_data[i] == 0.0: continue
		var vertexFlatGlobalPosition = flatStartGlobalPosition + Vector2((size.x / float(collisionMap.map_width)) * (i % collisionMap.map_width), (size.z / float(collisionMap.map_depth)) * floorf(i / float(collisionMap.map_width)))
		for lightStart in lightDistances:
			if lightStart.distance_to(vertexFlatGlobalPosition) <= lightDistances[lightStart]:
				collisionMap.map_data[i] = 0.0
				break
	if len(lightPoints) > SHADERLIGHTSTRACKED:
		lightPoints.resize(SHADERLIGHTSTRACKED)
		lightRanges.resize(SHADERLIGHTSTRACKED)
	else:
		for _i in range(SHADERLIGHTSTRACKED - len(lightPoints)):
			lightPoints.append(Vector2.ZERO)
			lightRanges.append(0.0)
	fogShader.set_shader_parameter("light_sources", lightPoints)
	fogShader.set_shader_parameter("light_ranges", lightRanges)

## Notifies when a light is shone up on the darkness area
func _on_area_entered(area: Area3D) -> void:
	if area not in lights and area.get_collision_layer_value(5): 
		lights.append(area)
		update_collision_shape()

## Notifies when a light is no longer shining up on the darkness area
func _on_area_exited(area: Area3D) -> void:
	if area in lights:
		lights.erase(area)
		update_collision_shape()

## Notifies when a body enters the darkness
func _on_body_entered(body: Node3D) -> void:
	if Engine.is_editor_hint(): return
	if body.has_node("DarknessBlockerModule"): body.get_node("DarknessBlockerModule").darkness_area(self, true)

## Notifies when a body exits the darkness
func _on_body_exited(body: Node3D) -> void:
	if Engine.is_editor_hint(): return
	if body.has_node("DarknessBlockerModule"): body.get_node("DarknessBlockerModule").darkness_area(self, false)
