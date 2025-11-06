@tool
extends Path3D
class_name WallGenerator

const WALLWIDTH: float = 0.01
const PATHINTERVAL: float = 0.15
const PATHSIMPLIFYANGLE: float = 15

@export_range(2.0, 10.0, 1.0) var wallHeight: float = 5.0
@export var material: Material
@export_custom(PROPERTY_HINT_LAYERS_3D_PHYSICS, "") var collisionLayer: int = 0
@export_tool_button("Flip Path", "AnimationAutoFit") var flipPath: Callable = flip_path

var polygon: CSGPolygon3D

func _ready() -> void:
	regenerate_wall_shape()

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

func regenerate_wall_shape() -> void:
	var wallShape: PackedVector2Array = [Vector2(0.0, -WALLWIDTH), Vector2(0.0, wallHeight), Vector2(WALLWIDTH, wallHeight), Vector2(WALLWIDTH, -WALLWIDTH)]
	if not polygon:
		polygon = CSGPolygon3D.new()
		add_child(polygon)
		polygon.mode = CSGPolygon3D.MODE_PATH
		polygon.path_node = "../"
		polygon.path_interval = PATHINTERVAL
		polygon.path_simplify_angle = PATHSIMPLIFYANGLE
		polygon.path_rotation = CSGPolygon3D.PATH_ROTATION_PATH_FOLLOW
		polygon.path_local = true
		polygon.calculate_tangents = true
		polygon.use_collision = true
		polygon.collision_mask = 0
	polygon.material = material
	polygon.collision_layer = collisionLayer
	polygon.polygon = wallShape
