@tool
extends Path3D
## Class that extrudes a shape from a 3D path
class_name PathExtruder

## Valid extrude directions.
enum Directions {UP, DOWN, FORWARD, BACK, LEFT, RIGHT}
## Direction to extrude towards.
@export var extrudeDirection: Directions = Directions.DOWN
## How far to extrude shape.
@export_range(0.01, 1000, 0.01) var shapeThickness: float = 1.0
## Does this model block phisical light? For effect light use colliders.
@export var blocksLight: bool = true
## Shape material.
@export var material: Material
## Make material unique on instance.
@export var uniqueMaterial: bool = false
## Collision layer for a provided collider.
@export_custom(PROPERTY_HINT_LAYERS_3D_PHYSICS, "") var collisionLayer: int = 0
## Curve resolution, how many subdivisions to create between curved points.
@export_range(0, 50, 1) var resolution: float = 0
## Collapses path into one layer and extrudes it.
@export_tool_button("Flatten and extrude path", "PhysicsMaterial") var doExtrude: Callable = _do_extrude

## Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if not Engine.is_editor_hint(): GeneralVariables.add_to_stagger_queue(_do_extrude)
	else: _do_extrude()

## Creates the final shape.
func _do_extrude() -> void:
	for child in get_children(): child.queue_free()
	var offset: float = 0
	var finalPoints: PackedVector2Array = []
	for i in curve.point_count:
		if i == 0:
			var pointPosition: Vector3 = curve.get_point_position(i)
			finalPoints.append(get_vec2(pointPosition))
			offset += get_offset(pointPosition)
		elif curve.get_point_in(i) == Vector3.ZERO and curve.get_point_out(i - 1) == Vector3.ZERO:
			var pointPosition: Vector3 = curve.get_point_position(i)
			finalPoints.append(get_vec2(pointPosition))
			offset += get_offset(pointPosition)
		else:
			if resolution > 0:
				var placeholderCurve: Curve3D = Curve3D.new()
				placeholderCurve.add_point(curve.get_point_position(i - 1), Vector3.ZERO, curve.get_point_out(i - 1))
				placeholderCurve.add_point(curve.get_point_position(i), curve.get_point_in(i), Vector3.ZERO)
				var interval: float = placeholderCurve.get_baked_length() / resolution
				for j in range(1, resolution + 1):
					var pointPosition: Vector3 = placeholderCurve.sample_baked(j * interval)
					finalPoints.append(get_vec2(pointPosition))
					if j == resolution:
						offset += get_offset(pointPosition)
			else:
				var pointPosition: Vector3 = curve.get_point_position(i)
				finalPoints.append(get_vec2(pointPosition))
				offset += get_offset(pointPosition)
	if curve.closed and (curve.get_point_in(curve.point_count - 1) != Vector3.ZERO or curve.get_point_out(0) != Vector3.ZERO) and resolution > 0:
		var placeholderCurve: Curve3D = Curve3D.new()
		placeholderCurve.add_point(curve.get_point_position(curve.point_count - 1), Vector3.ZERO, curve.get_point_out(curve.point_count - 1))
		placeholderCurve.add_point(curve.get_point_position(0), curve.get_point_in(0), Vector3.ZERO)
		var interval: float = placeholderCurve.get_baked_length() / resolution
		for i in range(1, resolution):
			var pointPosition: Vector3 = placeholderCurve.sample_baked(i * interval)
			finalPoints.append(get_vec2(pointPosition))
			if i == resolution:
				offset += get_offset(pointPosition)
	var shape: CSGPolygon3D = CSGPolygon3D.new()
	shape.polygon = finalPoints
	shape.mode = CSGPolygon3D.MODE_DEPTH
	shape.depth = shapeThickness
	if collisionLayer > 0:
		shape.use_collision = true
		shape.collision_mask = 0
		shape.layers = collisionLayer
	shape.material = material.duplicate() if uniqueMaterial else material
	add_child(shape)
	match extrudeDirection:
		Directions.UP:
			shape.rotation.x = PI / 2.0
			shape.position = Vector3(0.0, offset / float(curve.point_count), 0.0)
		Directions.DOWN:
			shape.rotation.x = PI / 2.0
			shape.position = Vector3(0.0, offset / float(curve.point_count) - shapeThickness, 0.0)
		Directions.FORWARD:
			shape.position = Vector3(0.0, 0.0, offset / float(curve.point_count) + shapeThickness)
		Directions.BACK:
			shape.position = Vector3(0.0, 0.0, offset / float(curve.point_count))
		Directions.LEFT:
			shape.rotation.y = PI / 2.0
			shape.rotation.z = PI / 2.0
			shape.position = Vector3(offset / float(curve.point_count), 0.0, 0.0)
		Directions.RIGHT:
			shape.rotation.y = PI / 2.0
			shape.rotation.z = PI / 2.0
			shape.position = Vector3(offset / float(curve.point_count) + shapeThickness, 0.0, 0.0)

## Returns the direction as a pointer vector.
func get_vec2(point: Vector3) -> Vector2:
	match extrudeDirection:
		Directions.UP, Directions.DOWN:
			return Vector2(point.x, point.z)
		Directions.FORWARD, Directions.BACK:
			return Vector2(point.x, point.y)
		Directions.LEFT, Directions.RIGHT:
			return Vector2(point.y, point.z)
		_:
			return Vector2.ZERO

## Returns the offset for the current extrude direction.
func get_offset(point: Vector3) -> float:
	match extrudeDirection:
		Directions.UP, Directions.DOWN:
			return point.y
		Directions.FORWARD, Directions.BACK:
			return point.z
		Directions.LEFT, Directions.RIGHT:
			return point.x
		_:
			return 0
