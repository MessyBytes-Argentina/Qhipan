@tool
extends Path3D
## This class handles creations of one way walls with gradients and solid collitions from a single path
class_name WallGenerator

## The width of the wall polygon.
const WALLWIDTH: float = 0.01
## The width of the wall that projects shadows.
const SHADOWWALLWIDTH: float = 1.0
## How ofthen to generate polygons for smooth walls.
const PATHINTERVAL: float = 0.01
## Simplifies path angles for aproximation.
const PATHSIMPLIFYANGLE: float = 15
## Wall modes.
enum WallModes {ONLY_UP, ONLY_DOWN, BOTH_WAYS}

## How tall is the wall.
@export_range(1.0, 100.0, 0.5) var wallHeight: float = 5.0
## Create a second wall going down for when looking the other way around.
@export var wallMode: WallModes = WallModes.ONLY_UP
## Wall material.
@export var material: Material
## Custom shape group.
@export_group("Custom Shape Parameters")
## Custom wall shape.
@export var customProfileShape: Curve
## Custom wall mode
@export var customProfileShapeDown: Curve
## Custom wall width.
@export_range(0.1, 20, 0.1) var customWallWidth: float = 1.0
## Custom wall width.
@export_range(0.1, 20, 0.1) var customDownWallWidth: float = 1.0
## Wall resolution.
@export_range(0, 5, 1) var resolution: float = 0
## Collider parameters
@export_category("Collider Parameters")
## Does this model block phisical light? For effect light use colliders.
@export var blocksLight: bool = true
## Wall collision layer.
@export_custom(PROPERTY_HINT_LAYERS_3D_PHYSICS, "") var collisionLayer: int = 32
@export_tool_button("Regenerate Wall", "ArrayMesh") var regenerateWall: Callable = regenerate_wall_shape
## Flips the path in case the wall is drawn on the opposite side.
@export_tool_button("Flip Path", "AnimationAutoFit") var flipPath: Callable = flip_path
## Updates cut shapes.
@export_tool_button("Update Cut Shapes", "ActionCut") var cutShapes: Callable = organize_cut_shapes

## Reference to the wall polygon.
var polygon: CSGPolygon3D
## Reference to the duplicate wall polygon.
var downPolygon: CSGPolygon3D
## Reference to the shadow proyecting polygon.
var shadowPolygon: CSGPolygon3D

## Executed when node first enters the scene.
func _ready() -> void:
	if not Engine.is_editor_hint(): 
		add_material_to_cutout(material)
		GeneralVariables.add_to_stagger_queue(regenerate_wall_shape)
	else: regenerate_wall_shape()

## Reverts the path points.
func flip_path() -> void:
	var flippedPathPoints: PackedVector3Array = []
	var flippedPathIn: PackedVector3Array = []
	var flippedPathOut: PackedVector3Array = []
	var flippedPathTilts: PackedFloat32Array = []
	for i in range(curve.point_count - 1, -1, -1):
		flippedPathPoints.append(curve.get_point_position(i))
		flippedPathTilts.append(curve.get_point_tilt(i))
		flippedPathIn.append(curve.get_point_out(i))
		flippedPathOut.append(curve.get_point_in(i))
	for i in range(curve.point_count):
		curve.set_point_position(i, flippedPathPoints[i])
		curve.set_point_tilt(i, flippedPathTilts[i])
		curve.set_point_in(i, flippedPathIn[i])
		curve.set_point_out(i, flippedPathOut[i])
	regenerate_wall_shape()

## Makes the material update with cutout.
func add_material_to_cutout(materialToStore: Material) -> void:
	if material is not ShaderMaterial: return
	if Engine.is_editor_hint(): return
	if not GeneralVariables.is_node_ready(): await GeneralVariables.ready
	if materialToStore not in GeneralVariables.cutoutMaterials: GeneralVariables.cutoutMaterials.append(materialToStore)

## Regenerates the wall with current parameters.
func regenerate_wall_shape() -> void:
	if downPolygon: downPolygon.queue_free()
	var wallShape: PackedVector2Array = _create_wall_shape(false, false)
	if not polygon:
		polygon = _create_polygon()
		shadowPolygon = polygon.duplicate()
		add_child(polygon)
		add_child(shadowPolygon)
		polygon.use_collision = true
		polygon.collision_mask = 0
		polygon.layers = 2
		shadowPolygon.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
	if not blocksLight:
		polygon.layers = 2
	polygon.material = material
	if customProfileShape and material is ShaderMaterial: 
		polygon.material = material.duplicate()
		polygon.material.set_shader_parameter("height", wallHeight)
		add_material_to_cutout(polygon.material)
	polygon.collision_layer = collisionLayer
	polygon.polygon = wallShape
	polygon.show()
	if wallMode != WallModes.ONLY_DOWN:
		shadowPolygon.polygon = _create_wall_shape(true, false)
		shadowPolygon.show()
	elif shadowPolygon: shadowPolygon.queue_free()
	match wallMode:
		WallModes.BOTH_WAYS:
			downPolygon = polygon.duplicate()
			add_child(downPolygon)
			downPolygon.polygon = _create_wall_shape(false, true)
			downPolygon.use_collision = false
			downPolygon.material = downPolygon.material.duplicate()
			downPolygon.material.set_shader_parameter("goesDown", true)
			if not blocksLight:
				downPolygon.layers = 2
		WallModes.ONLY_DOWN:
			downPolygon = polygon.duplicate()
			add_child(downPolygon)
			downPolygon.polygon = _create_wall_shape(false, true)
			downPolygon.use_collision = false
			downPolygon.material = downPolygon.material.duplicate()
			downPolygon.material.set_shader_parameter("goesDown", true)
			if not blocksLight:
				downPolygon.layers = 2
			polygon.collision_layer = 0
			polygon.hide()
			shadowPolygon.hide()
	organize_cut_shapes()

## Moves cut shapes to polygon wall.
func organize_cut_shapes() -> void:
	for child in polygon.get_children(): child.queue_free()
	for child in get_children():
		if child in [polygon, shadowPolygon, downPolygon]: continue
		if child is not CSGShape3D: continue
		if Engine.is_editor_hint():
			var duplicated: CSGShape3D = child.duplicate()
			polygon.add_child(duplicated)
			duplicated.material = polygon.material
			child.hide()
			duplicated.show()
		else:
			child.reparent(polygon)
			child.material = polygon.material
			child.show()

## Creates the wall polygon
func _create_polygon() -> CSGPolygon3D:
	var newPolygon = CSGPolygon3D.new()
	newPolygon.mode = CSGPolygon3D.MODE_PATH
	newPolygon.path_node = "../"
	newPolygon.path_interval = PATHINTERVAL
	newPolygon.path_simplify_angle = PATHSIMPLIFYANGLE
	newPolygon.path_rotation = CSGPolygon3D.PATH_ROTATION_PATH_FOLLOW
	newPolygon.path_local = true
	newPolygon.calculate_tangents = true
	return newPolygon

## Create wall shape
func _create_wall_shape(isShadowPolygon: bool, isDownWall: bool) -> PackedVector2Array:
	if not customProfileShape or (isDownWall and not customProfileShapeDown):
		if not isShadowPolygon: 
			if isDownWall: return [Vector2.ZERO, Vector2(0.0, -wallHeight), Vector2(WALLWIDTH, -wallHeight), Vector2(WALLWIDTH, 0.0)]
			else: return [Vector2.ZERO, Vector2(0.0, wallHeight), Vector2(WALLWIDTH, wallHeight), Vector2(WALLWIDTH, 0.0)]
		else: return [Vector2.ZERO, Vector2(0.0, wallHeight), Vector2(SHADOWWALLWIDTH, wallHeight), Vector2(SHADOWWALLWIDTH, 0.0)]
	else:
		var shape = customProfileShape if not isDownWall else customProfileShapeDown
		var sizeMultiplier: Vector2 = Vector2(customWallWidth if not isDownWall else customDownWallWidth, wallHeight)
		var res: PackedVector2Array = [Vector2.ZERO]
		for i in shape.point_count:
			if i == 0:
				if shape.get_point_position(i) != res[0]:
					res.append(shape.get_point_position(i) * sizeMultiplier)
				continue
			if resolution > 0 and (shape.get_point_right_mode(i - 1) == Curve.TANGENT_FREE or shape.get_point_left_tangent(i) == Curve.TANGENT_FREE):
				var start: float = shape.get_point_position(i - 1).x
				var segment: float = (shape.get_point_position(i).x - start) / resolution
				for j in range(1, resolution):
					var currentX: float = start + segment * j
					res.append(Vector2(currentX, shape.sample_baked(currentX)) * sizeMultiplier)
				res.append(shape.get_point_position(i) * sizeMultiplier)
			else:
				res.append(shape.get_point_position(i) * sizeMultiplier)
		if not isDownWall:
			if res[len(res) - 1] != sizeMultiplier: res.append(sizeMultiplier)
			res.append(sizeMultiplier * Vector2.RIGHT)
			for i in len(res):
				res[i].x -= customWallWidth
		else:
			for i in len(res): 
				res[i].x *= -1
				if wallMode == WallModes.BOTH_WAYS:
					res[i].x += customDownWallWidth - customWallWidth
				else:
					res[i].x += customDownWallWidth
				res[i].y -= wallHeight
			downPolygon.flip_faces = true
			res[0] = Vector2(res[1].x, 0.0)
		return res

## Cleans unique materials.
func _exit_tree():
	if Engine.is_editor_hint(): return
	if customProfileShape and material is ShaderMaterial:
		GeneralVariables.cutoutMaterials.erase(polygon.material)
