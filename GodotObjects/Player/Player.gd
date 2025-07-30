extends CharacterBody3D

@export_range(1, 100, 1) var maxSpeed: int = 5
@export_range(1, 100, 1) var acceleration: int = 10
@export_range(1, 100, 1) var decceleration: int = 10
@export_range(1, 100, 1) var gravity: int = 10

var moveDirection: Vector3 = Vector3.ZERO
var currentSpeed: float = 0

func _physics_process(delta: float) -> void:
	if is_on_floor():
		if moveDirection != Vector3.ZERO:
			velocity +=  (moveDirection * acceleration) * delta
			velocity = velocity.limit_length(maxSpeed)
		else:
			velocity = velocity.lerp( Vector3.ZERO, decceleration * delta)
	else :
		velocity += (Vector3.DOWN * gravity) * delta
	move_and_slide()

func _input(_event: InputEvent) -> void:
	moveDirection.x = Input.get_action_strength("right") - Input.get_action_strength("left")
	moveDirection.z = Input.get_action_strength("backwards") - Input.get_action_strength("forwards")
	
