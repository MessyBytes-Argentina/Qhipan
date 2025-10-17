extends Node3D
class_name AlternatingGroup

var altChildren: Array = []

func _ready() -> void:
	var children: Array = get_children()
	for obj in children:
		if obj is AlternatingObject or obj is MovingPlatform:
			altChildren.append(obj)


func switch_children(activeObjects: Array) -> void:
	for obj in altChildren:
		if not activeObjects.has(obj):
			obj.switch_state()
