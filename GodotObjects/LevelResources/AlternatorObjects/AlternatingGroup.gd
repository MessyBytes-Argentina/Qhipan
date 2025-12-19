extends Node3D
class_name AlternatingGroup

## List of alternating nodes in the group
var altChildren: Array = []

## Executed when node first enters the scene tree
func _ready() -> void:
	var children: Array[Node] = recursive_get_children(self)
	for child in children:
		if child is AlternatingObject or child is MovingPlatform or child is LeylinePath:
			altChildren.append(child)

## Returns an array with all the children nodes of this group
func recursive_get_children(parent: Node) -> Array[Node]:
	var children: Array[Node] = parent.get_children()
	for child in children.duplicate():
		children.append_array(recursive_get_children(child))
	return children

## Switches the state of the nodes in altChildren
func switch_children() -> void:
	for child in altChildren:
		child.switch_state()
