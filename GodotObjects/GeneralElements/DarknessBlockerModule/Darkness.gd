@tool
extends FogVolume

class_name DarknessArea

@export var collisionShape: Shape3D:
	set(value):
		collisionShape = value
		if Engine.is_editor_hint(): _collision_shape_set()
@export var areaShape: Shape3D:
	set(value):
		areaShape = value
		if Engine.is_editor_hint(): _collision_shape_set()

var darknessCollisionShape: CollisionShape3D
var darknessAreaShape: CollisionShape3D

func _ready() -> void:
	darknessCollisionShape = %DarknessCollisionShape
	darknessAreaShape = %DarknessAreaShape

func _collision_shape_set() -> void:
	if not is_node_ready():
		await ready
	darknessCollisionShape.shape = collisionShape
	darknessAreaShape.shape = areaShape

func _on_body_entered(body: Node3D) -> void:
	if Engine.is_editor_hint(): return
	if body.has_node("DarknessBlockerModule"): body.get_node("DarknessBlockerModule").darkness_area_entered(self)

func _on_body_exited(body: Node3D) -> void:
	if Engine.is_editor_hint(): return
	if body.has_node("DarknessBlockerModule"): body.get_node("DarknessBlockerModule").darkness_area_exited(self)
