@tool
extends FogVolume

class_name DarknessArea

@export var collisionShape: Shape3D:
	set(value):
		collisionShape = value
		if Engine.is_editor_hint(): _collision_shape_set()

@onready var darknessCollisionShape: CollisionShape3D = %DarknessCollisionShape
@onready var darknessAreaShape: CollisionShape3D = %DarknessAreaShape

func _collision_shape_set() -> void:
	darknessCollisionShape.shape = collisionShape
	darknessAreaShape.shape = collisionShape

func _on_body_entered(body: Node3D) -> void:
	if Engine.is_editor_hint(): return
	if body.has_node("DarknessBlockerModule"): body.get_node("DarknessBlockerModule").darkness_area_entered(self)

func _on_body_exited(body: Node3D) -> void:
	if Engine.is_editor_hint(): return
	if body.has_node("DarknessBlockerModule"): body.get_node("DarknessBlockerModule").darkness_area_exited(self)
