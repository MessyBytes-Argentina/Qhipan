extends Node3D
class_name AlternatingGroup

var altChildren: Array = []

func _ready() -> void:
	var children: Array[Node] = recursive_get_children(self)
	for child in children:
		if child is AlternatingObject or child is MovingPlatform:
			altChildren.append(child)

func recursive_get_children(parent: Node) -> Array[Node]:
	var children: Array[Node] = parent.get_children()
	for child in children.duplicate():
		children.append_array(recursive_get_children(child))
	return children

func switch_children(activeObjects: Array) -> void:
	for child in altChildren:
		if not activeObjects.has(child):
			child.switch_state()
