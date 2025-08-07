extends Area3D
class_name NoGravityZone

func _ready() -> void:
	body_entered.connect(enter)
	body_exited.connect(exit)

func enter(body: Node3D) -> void:
	if body.has_method("enter_no_gravity"): body.enter_no_gravity(self)

func exit(body: Node3D) -> void:
	if body.has_method("exit_no_gravity"): body.exit_no_gravity(self)
