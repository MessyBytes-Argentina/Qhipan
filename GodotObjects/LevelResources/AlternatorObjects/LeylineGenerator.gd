@tool
extends Path3D
class_name LeylinePath

## Animation speed.
const SPEED: float = 15.0
## Leylien width
const WIDTH: float = 0.5

## Is the leyline on by default
@export var startsFull: bool = false:
	set(value):
		startsFull = value
		if Engine.is_editor_hint() and is_node_ready():
			if startsFull: loadPath.curve = curve.duplicate()
			else: loadPath.curve.clear_points()
## The material to use for the leyline off.
@export var stencilMaterial: Material
## The material to use for yhe leyline glow
@export var glowMaterial: Material
## Resets the path state to off
@export_tool_button("Reset Path", "Clear") var resetPath: Callable = reset_path
## Shows the path filling animation
@export_tool_button("Do The Thing", "ArrowRight") var doTheThing: Callable = follow_path
## Shows the path emptying animation
@export_tool_button("Undo The Thing", "ArrowLeft") var undoTheThing: Callable = unfollow_path

## The path to use for the leyline progress.
var loadPath: Path3D
## The tween to animate the progress of the leyline
var progressTween: Tween
## Distance covered on previous tween instance
var lastDistance: float = 0
## Point covered on previous tween instance
var lastPoint: int = 0
## Distance covered up to last point covered on previous tween instance
var lastPointDistance: float = 0

## Executed when node first enters the scene tree.
func _ready() -> void:
	reset_shapes()
	if startsFull:
		loadPath.curve = curve.duplicate()

## Resets the path to off state.
func reset_path() -> void:
	if progressTween:
		progressTween.kill()
	loadPath.curve.clear_points()

## Resets path shapes.
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

## Starts animation for filling path.
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

## Animation for positive progress of the path.
func add_path_points(distance: float) -> void:
	var lastPointPosition: Vector3 = curve.get_point_position(lastPoint)
	var nextPointPosition: Vector3 = curve.get_point_position(lastPoint + 1)
	if lastPointDistance + lastPointPosition.distance_to(nextPointPosition) < distance:
		loadPath.curve.add_point(nextPointPosition)
		lastPointDistance += lastPointPosition.distance_to(nextPointPosition) 
		lastPoint += 1
	loadPath.curve.add_point(curve.sample_baked(distance))
	lastDistance = distance

## Starts animationfor emptying path.
func unfollow_path() -> void:
	loadPath.curve = curve.duplicate()
	if progressTween:
		progressTween.kill()
	lastDistance = curve.get_baked_length()
	lastPoint = curve.point_count - 1
	lastPointDistance = lastDistance
	progressTween = create_tween()
	progressTween.tween_method(remove_path_points, lastDistance, 0.0, lastDistance / SPEED).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	progressTween.finished.connect(loadPath.curve.clear_points)
	progressTween.play()

## Animation for negative progress of the path
func remove_path_points(distance: float) -> void:
	var lastPointPosition: Vector3 = curve.get_point_position(lastPoint)
	var nextPointPosition: Vector3 = curve.get_point_position(lastPoint - 1)
	loadPath.curve.remove_point(loadPath.curve.point_count - 1)
	if lastPointDistance - lastPointPosition.distance_to(nextPointPosition) > distance:
		lastPointDistance -= lastPointPosition.distance_to(nextPointPosition) 
		loadPath.curve.remove_point(loadPath.curve.point_count - 1)
		lastPoint -= 1
	loadPath.curve.add_point(curve.sample_baked(distance))
	lastDistance = distance
