extends FogVolume

## Darkness volume that blocks areas until a light is shined through it.
class_name DarknessArea

## The amount of vertices per meter that the fog collision is broken up into.
## Higher means higher collision quality but poorer performance.
const DARKNESSCOLLISIONRESOLUTION: int = 4
## Times to update the darkness during light expansion.
const ONLIGHTUPDATETIMES: int = 5
## Darkness margin for releasing stickers.
const MARGIN: float = 0.5
## Darkness margin for detecting light.
const DARKMARGIN: float = 0.25
## Collision layers to block raycast.
const RAYCOLLISIONLAYERS: Array[int] = [1, 6, 7]

## Reference to the collision shape of the fog.
@onready var darknessCollisionShape: CollisionShape3D = %DarknessCollisionShape
## Reference to the collision shape of the area of effect for the fog.
@onready var darknessAreaShape: CollisionShape3D = %DarknessAreaShape
## Reference to the outline blocker.
@onready var outlineBlocker: MeshInstance3D = %OutlineBlocker
## Reference to the detection area.
@onready var darknessArea: Area3D = %DarknessArea
## Reference to the collision heightmap used on the fog.
var collisionMap: HeightMapShape3D
## Reference to the fog shader.
var fogShader: ShaderMaterial
## Reference to the player.
var player: Player

## Lights currently affecting the fog.
var lights: Array[Area3D] = []
## Light stickers currently tweening that are affecting the fog.
var lightsTweening: Array[LampSticker] = []
## Is ready to check for lights.
var isReadyToCheck: bool = false
## Outline blocker material.
var outlineMaterial: ShaderMaterial
## Layers turned into usable mask.
var layerMask: int

## Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if Engine.is_editor_hint(): return
	layerMask = RAYCOLLISIONLAYERS.reduce(func(accum: int, a: int = 0): return accum + pow(2, a - 1), 0)
	outlineBlocker.mesh = outlineBlocker.mesh.duplicate(true)
	outlineMaterial = outlineBlocker.get_surface_override_material(0).duplicate()
	outlineBlocker.set_surface_override_material(0, outlineMaterial)
	await get_tree().create_timer(0.5).timeout
	lights = darknessArea.get_overlapping_areas()
	_collision_shape_set()
	player = get_tree().get_first_node_in_group("Player")

## Sets up the collision shape for the fog.
func _collision_shape_set() -> void:
	if not is_node_ready():
		await ready
	darknessAreaShape.shape = BoxShape3D.new()
	darknessAreaShape.shape.size = size + Vector3(MARGIN, 0, MARGIN)
	collisionMap = darknessCollisionShape.shape.duplicate()
	darknessCollisionShape.shape = collisionMap
	fogShader = material.duplicate()
	material = fogShader
	outlineBlocker.mesh.size = Vector2(size.x, size.z)
	outlineBlocker.mesh.subdivide_width = int(size.x * float(DARKNESSCOLLISIONRESOLUTION))
	outlineBlocker.mesh.subdivide_depth = int(size.z * float(DARKNESSCOLLISIONRESOLUTION))
	outlineBlocker.position.y = -size.y / 2.0
	outlineMaterial.set_shader_parameter("size", size)
	await get_tree().create_timer(0.5).timeout
	isReadyToCheck = true
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

## Updates the collision shape details to match shining lights
func update_collision_shape() -> void:
	if not isReadyToCheck: return
	isReadyToCheck = false
	await get_tree().process_frame
	reset_collision_shape()
	var shaderMask: Image = Image.create(collisionMap.map_width, collisionMap.map_depth, false, Image.Format.FORMAT_L8)
	shaderMask.fill(Color.WHITE)
	var flatStartGlobalPosition: Vector2 = Vector2(global_position.x, global_position.z) - (Vector2(size.x, size.z) / 2.0).rotated(-rotation.y)
	var lightDistances: Dictionary[Vector3, float]
	var lightAbsoluteDistances: Dictionary[Vector3, float]
	var spaceState: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	for lightArea in lights: 
		if lightArea.has_node("LightShape"): 
			var lightShape: CollisionShape3D = lightArea.get_node("LightShape")
			var parent: Node = lightArea.get_node(lightArea.get_meta("Parent"))
			lightDistances[lightArea.global_position] = lightShape.shape.radius
			if parent is LampSticker:
				lightAbsoluteDistances[lightArea.global_position] = parent.currentOverrideLength if parent.placed else LampSticker.LIGHTRANGEGRABED
			else:
				lightAbsoluteDistances[lightArea.global_position] = lightShape.shape.radius
			if parent.lightTween: 
				if parent.lightTween.is_running(): 
					if parent not in lightsTweening: lightsTweening.append(parent)
				else:
					lightsTweening.erase(parent)
			else:
				lightsTweening.erase(parent)
	for i in range(len(collisionMap.map_data)):
		var vertexFlatGlobalPosition: Vector2 = Vector2((size.x / float(collisionMap.map_width)) * (i % collisionMap.map_width), (size.z / float(collisionMap.map_depth)) * floorf(i / float(collisionMap.map_width)))
		vertexFlatGlobalPosition = flatStartGlobalPosition + vertexFlatGlobalPosition.rotated(-rotation.y)
		for lightStart in lightDistances:
			var relativeGlobalPosition: Vector3 = Vector3(vertexFlatGlobalPosition.x, lightStart.y, vertexFlatGlobalPosition.y)
			if lightStart.distance_to(relativeGlobalPosition) <= lightAbsoluteDistances[lightStart]:
				var raycast = PhysicsRayQueryParameters3D.create(lightStart, relativeGlobalPosition)
				raycast.hit_from_inside = false
				raycast.hit_back_faces = false
				raycast.collision_mask = layerMask
				if spaceState.intersect_ray(raycast): continue
				collisionMap.map_data[i] = 0.0
				if lightStart.distance_to(relativeGlobalPosition) <= lightDistances[lightStart]:
					shaderMask.set_pixel(i % collisionMap.map_width, floori(i / float(collisionMap.map_width)), Color.BLACK)
					break
	var mask: ImageTexture = ImageTexture.create_from_image(shaderMask)
	fogShader.set_shader_parameter("light_mask", mask)
	outlineMaterial.set_shader_parameter("light_mask", mask)
	isReadyToCheck = true

## Notifies when a light is shone up on the darkness area
func _on_area_entered(area: Area3D) -> void:
	if area not in lights and area.get_collision_layer_value(5):
		var areaParent: Node = area.get_node(area.get_meta("Parent"))
		if areaParent is not LampSticker: return
		if not areaParent.placed: return
		lights.append(area)
		areaParent.light_updated.connect(update_collision_shape)
		update_collision_shape()

## Notifies when a light is no longer shining up on the darkness area
func _on_area_exited(area: Area3D) -> void:
	if area in lights:
		lights.erase(area)
		area.get_node(area.get_meta("Parent")).light_updated.disconnect(update_collision_shape)
		update_collision_shape()

## Notifies when a body enters the darkness
func _on_body_entered(body: Node3D) -> void:
	if Engine.is_editor_hint(): return
	if body.has_node("DarknessBlockerModule"): body.get_node("DarknessBlockerModule").darkness_area(self, true)

## Notifies when a body exits the darkness
func _on_body_exited(body: Node3D) -> void:
	if Engine.is_editor_hint(): return
	if body.has_node("DarknessBlockerModule"): body.get_node("DarknessBlockerModule").darkness_area(self, false)
