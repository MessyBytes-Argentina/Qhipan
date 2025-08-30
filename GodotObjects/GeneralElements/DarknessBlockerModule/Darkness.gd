extends FogVolume

class_name DarknessArea

const DARKNESSCOLLISIONRESOLUTION: int = 8
const SHADERLIGHTSTRACKED: int = 6

@export var areaShape: Shape3D

@onready var darknessCollisionShape: CollisionShape3D = %DarknessCollisionShape
@onready var darknessAreaShape: CollisionShape3D = %DarknessAreaShape
var collisionMap: HeightMapShape3D
var fogShader: ShaderMaterial

var lights: Array[Area3D] = []

func _ready() -> void:
	if Engine.is_editor_hint(): return
	#var tween: Tween = create_tween()
	#tween.tween_method(light_test, 0.0, 1.0, 2.0)
	#tween.set_loops(0)
	#tween.play()
	_collision_shape_set()

#func light_test(progress: float) -> void:
	#light.rotation.y = lerpf(0.0, PI * 2.0, progress)
	#light.rotation.x = sinh(progress) * 0.5
	#light.rotation.z = sinh(progress * 2.0) * 0.5
	#light2.rotation.y = lerpf(PI * 2.0, 0.0, progress)
	#light2.rotation.x = sinh(-progress * 2.0) * 0.5
	#light2.rotation.z = sinh(progress * 3.0) * 0.5

func _collision_shape_set() -> void:
	if not is_node_ready():
		await ready
	darknessAreaShape.shape = BoxShape3D.new()
	darknessAreaShape.shape.size = size
	collisionMap = darknessCollisionShape.shape
	fogShader = material.duplicate()
	material = fogShader
	update_collision_shape()

func _on_body_entered(body: Node3D) -> void:
	if Engine.is_editor_hint(): return
	if body.has_node("DarknessBlockerModule"): body.get_node("DarknessBlockerModule").darkness_area_entered(self)

func _on_body_exited(body: Node3D) -> void:
	if Engine.is_editor_hint(): return
	if body.has_node("DarknessBlockerModule"): body.get_node("DarknessBlockerModule").darkness_area_exited(self)

func reset_collision_shape() -> void:
	collisionMap.map_width = int(size.x * float(DARKNESSCOLLISIONRESOLUTION))
	collisionMap.map_depth = int(size.z * float(DARKNESSCOLLISIONRESOLUTION))
	darknessCollisionShape.scale = Vector3.ONE / float(DARKNESSCOLLISIONRESOLUTION)
	for i in range(len(collisionMap.map_data)):
		if i < collisionMap.map_width or i % collisionMap.map_width == 0 or (i + 1) % collisionMap.map_width == 0 or i + collisionMap.map_width >= len(collisionMap.map_data): collisionMap.map_data[i] = 0.0
		else: collisionMap.map_data[i] = size.y * (1.0 / darknessCollisionShape.scale.y)
	darknessCollisionShape.position.y = - size.y / 2.0

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
			#prints(lightStart, vertexFlatGlobalPosition, lightDistances[lightStart], lightStart.distance_to(vertexFlatGlobalPosition) <= lightDistances[lightStart])
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

func _on_area_entered(area: Area3D) -> void:
	if area not in lights and area.get_collision_layer_value(5): 
		lights.append(area)
		update_collision_shape()

func _on_area_exited(area: Area3D) -> void:
	if area in lights:
		lights.erase(area)
		update_collision_shape()
