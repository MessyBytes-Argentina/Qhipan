extends Node3D
class_name AlternatingGroup

var altChildren: Array[AlternatingObject] = []

func _ready() -> void:
	var children: Array = get_children()
	for obj in children:
		if obj is AlternatingObject:
			altChildren.append(obj)


func switch_children(activeObjects: Array[AlternatingObject]) -> void:
	for obj in altChildren:
		if not activeObjects.has(obj):
			obj.switch_state()
