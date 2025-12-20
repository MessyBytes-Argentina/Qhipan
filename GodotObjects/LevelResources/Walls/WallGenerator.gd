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
@export_range(2.0, 10.0, 1.0) var wallHeight: float = 5.0:
	set(value):
		wallHeight = value
		if Engine.is_editor_hint() and is_node_ready():
			regenerate_wall_shape()
## Create a second wall going down for when looking the other way around.
@export var wallMode: WallModes = WallModes.ONLY_UP:
	set(value):
		wallMode = value
		if Engine.is_editor_hint() and is_node_ready():
			regenerate_wall_shape()
## Wall material.
@export var material: Material:
	set(value):
		material = value
		if Engine.is_editor_hint() and is_node_ready():
			regenerate_wall_shape()
## Wall collision layer.
@export_custom(PROPERTY_HINT_LAYERS_3D_PHYSICS, "") var collisionLayer: int = 32
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
	regenerate_wall_shape()
	if Engine.is_editor_hint():
		curve_changed.connect(regenerate_wall_shape)

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

## Regenerates the wall with current parameters.
func regenerate_wall_shape() -> void:
	if downPolygon: downPolygon.queue_free()
	var wallShape: PackedVector2Array = [Vector2(0.0, -WALLWIDTH), Vector2(0.0, wallHeight), Vector2(WALLWIDTH, wallHeight), Vector2(WALLWIDTH, -WALLWIDTH)]
	if not polygon:
		polygon = _create_polygon()
		shadowPolygon = polygon.duplicate()
		add_child(polygon)
		add_child(shadowPolygon)
		polygon.use_collision = true
		polygon.collision_mask = 0
		polygon.layers = 2
		shadowPolygon.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
	polygon.material = material
	polygon.collision_layer = collisionLayer
	polygon.polygon = wallShape
	shadowPolygon.polygon = [Vector2(0.0, -SHADOWWALLWIDTH), Vector2(0.0, wallHeight), Vector2(SHADOWWALLWIDTH, wallHeight), Vector2(SHADOWWALLWIDTH, -SHADOWWALLWIDTH)]
	match wallMode:
		WallModes.BOTH_WAYS:
			downPolygon = polygon.duplicate()
			add_child(downPolygon)
			downPolygon.polygon = [Vector2(0.0, -WALLWIDTH), Vector2(0.0, -wallHeight), Vector2(WALLWIDTH, -wallHeight), Vector2(WALLWIDTH, -WALLWIDTH)]
			downPolygon.use_collision = false
			downPolygon.material = downPolygon.material.duplicate()
			downPolygon.material.set_shader_parameter("goesDown", true)
		WallModes.ONLY_DOWN:
			polygon.polygon = [Vector2(0.0, -WALLWIDTH), Vector2(0.0, -wallHeight), Vector2(WALLWIDTH, -wallHeight), Vector2(WALLWIDTH, -WALLWIDTH)]
			polygon.material = material.duplicate()
			polygon.material.set_shader_parameter("goesDown", true)
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
			child.hide()
			duplicated.show()
		else:
			child.reparent(polygon)
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
