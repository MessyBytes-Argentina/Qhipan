extends Area3D

var groupParent: AlternatingGroup

func _ready() -> void:
	var parent = get_parent()
	if parent is AlternatingGroup: 
		groupParent = parent
	else:
		prints(name," isn't in a group")
