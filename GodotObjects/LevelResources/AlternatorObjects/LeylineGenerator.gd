@tool
extends Path3D

const SPEED: float = 15.0
const WIDTH: float = 0.5

@export var startsFull: bool = false:
	set(value):
		startsFull = value
		if Engine.is_editor_hint() and is_node_ready():
			if startsFull: loadPath.curve = curve.duplicate()
			else: loadPath.curve.clear_points()
@export var stencilMaterial: Material
@export var glowMaterial: Material
@export_tool_button("Reset Path", "Clear") var resetPath: Callable = reset_path
@export_tool_button("Do The Thing", "ArrowRight") var doTheThing: Callable = follow_path

var loadPath: Path3D
var progressTween: Tween
var lastDistance: float = 0
var lastPoint: int = 0
var lastPointDistance: float = 0

func _ready() -> void:
	reset_shapes()
	if startsFull:
		loadPath.curve = curve.duplicate()

func reset_path() -> void:
	if progressTween:
		progressTween.kill()
	loadPath.curve.clear_points()

func reset_shapes() -> void:
	for child in get_children(): child.queue_free()
	loadPath = Path3D.new()
	loadPath.curve = Curve3D.new()
	add_child(loadPath)
	loadPath.name = "loadPath"
	var stencilPolygon: CSGPolygon3D = CSGPolygon3D.new()
	stencilPolygon.mode = CSGPolygon3D.MODE_PATH
	stencilPolygon.path_interval = 0.01
	stencilPolygon.path_simplify_angle = 1.0
	stencilPolygon.path_rotation = CSGPolygon3D.PATH_ROTATION_PATH_FOLLOW
	stencilPolygon.path_local = true
	var glowPolygon: CSGPolygon3D = stencilPolygon.duplicate()
	stencilPolygon.polygon = [Vector2(WIDTH, 0.01), Vector2(WIDTH, 0.0), Vector2(-WIDTH, 0.0), Vector2(-WIDTH, 0.01)]
	stencilPolygon.material = stencilMaterial
	stencilPolygon.position.y = 0.01
	glowPolygon.polygon = [Vector2(WIDTH * 2.0, 0.01), Vector2(WIDTH * 2.0, 0.0), Vector2(-WIDTH * 2.0, 0.0), Vector2(-WIDTH * 2.0, 0.01)]
	glowPolygon.material = glowMaterial
	glowPolygon.position.y = 0.02
	add_child(stencilPolygon)
	stencilPolygon.path_node = "../"
	add_child(glowPolygon)
	glowPolygon.path_node = "../loadPath"

func follow_path() -> void:
	loadPath.curve.clear_points()
	if progressTween:
		progressTween.kill()
	lastDistance = 0
	lastPoint = 0
	lastPointDistance = 0
	loadPath.curve.add_point(curve.get_point_position(0))
	progressTween = create_tween()
	progressTween.tween_method(add_path_points, 0.0, curve.get_baked_length(), curve.get_baked_length() / SPEED).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	progressTween.finished.connect(loadPath.set.bind("curve", curve.duplicate()))
	progressTween.play()

func add_path_points(distance: float) -> void:
	var lastPointPosition: Vector3 = curve.get_point_position(lastPoint)
	var nextPointPosition: Vector3 = curve.get_point_position(lastPoint + 1)
	if lastPointDistance + lastPointPosition.distance_to(nextPointPosition) < distance:
		loadPath.curve.add_point(nextPointPosition)
		lastPointDistance += lastPointPosition.distance_to(nextPointPosition) 
		lastPoint += 1
	loadPath.curve.add_point(curve.sample_baked(distance))
	lastDistance = distance
	
