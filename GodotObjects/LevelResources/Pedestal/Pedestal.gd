extends StaticBody3D
class_name Pedestal

@export var pedestalName: String

@onready var area3d: Area3D = %Area3D

## Activates pedestal.
func activate_pedestal() -> void:
	area3d.set_deferred("monitorable", false)
	get_tree().call_group("Metaprogression", "pedestal_activated", pedestalName)
