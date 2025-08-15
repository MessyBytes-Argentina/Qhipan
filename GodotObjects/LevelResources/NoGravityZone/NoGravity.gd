extends Area3D
class_name NoGravityZone

## Called when the node enters the scene tree for the first time.
func _ready() -> void:
	body_entered.connect(enter)
	body_exited.connect(exit)

## On body_entered gives area to the player
func enter(body: Node3D) -> void:
	if body.has_method("enter_no_gravity"): body.enter_no_gravity(self)

## On body_exited removes area from the player
func exit(body: Node3D) -> void:
	if body.has_method("exit_no_gravity"): body.exit_no_gravity(self)
