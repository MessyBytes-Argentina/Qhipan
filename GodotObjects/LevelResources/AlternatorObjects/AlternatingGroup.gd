extends Node3D
class_name AlternatingGroup

var altChildren: Array[AlternatingObject] = []

func _ready() -> void:
	var children: Array = get_children()
	for obj in children:
		if obj is AlternatingObject:
			altChildren.append(obj)


func switch_children(node: AlternatingObject) -> void:
	for obj in altChildren:
		if obj != node:
			obj.switch_state()
