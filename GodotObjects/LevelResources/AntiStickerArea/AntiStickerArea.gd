extends Area3D

## This area blocks the player from moving stickers
class_name AntiStickerArea

## Speed of decay of ripple effect.
const DECAY_SPEED: float = 0.5
## Delay between ripple effects.
const DELAY: float = 0.15
## Amount of ripple effects.
const AMOUNT: float = 3
## Time offset for ripple effect.
const OFFSET: float = 0.4

## Reference to the mesh.
@onready var mesh: MeshInstance3D = %MeshInstance3D
## Reference to the collision shape.
@onready var collisionShape: CollisionShape3D = %CollisionShape3D
## Sound player
@onready var soundPlayer: RandomSoundPlayer = $RandomSoundPlayer
## Mesh Material.
var material: ShaderMaterial
## Reference to the player pickup handler
var pickupHandler: PickupHandler
## Point bufffer for area shader
var _points: PointBuffer = PointBuffer.new(32)
## Has player just entered
var playerEntered: bool = false

## Point bufffer class for area shader
class PointBuffer:
	var _buffer_index:int = 0
	var _points: Array[Vector4]
	
	func _init(buffer_size: int) -> void:
		_points.resize(buffer_size)
	
	func push(point: Vector3) -> void:
		_points[_buffer_index] = Vector4(point.x, point.y, point.z, 1.0)
		_buffer_index += 1
		if _buffer_index >= _points.size():
			_buffer_index = 0

	func decay_points(delta: float, decay_speed: float) -> Array[Vector4]:
		var new_points:Array[Vector4]
		for point in _points:
			new_points.append(Vector4(point.x, point.y, point.z, clamp(point.w - decay_speed * delta, 0, 1.0 - OFFSET)))
		_points = new_points
		
		return _points

## Called when the node enters the scene tree for the first time.
func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	var player: Player = get_tree().get_first_node_in_group("Player")
	while not player:
		player = get_tree().get_first_node_in_group("Player")
		await get_tree().process_frame
	if not player.is_node_ready(): await player.ready
	pickupHandler = player.grabArea
	material = mesh.get_surface_override_material(0).duplicate()
	mesh.set_surface_override_material(0, material)
	mesh.mesh = mesh.mesh.duplicate()
	mesh.mesh.size = Vector2(scale.x, scale.y)
	collisionShape.shape = collisionShape.shape.duplicate()
	collisionShape.shape.size = Vector3(scale.x, scale.y, 0.0)
	scale = Vector3.ONE

func _process(delta: float) -> void:
	var decayed_points:Array[Vector4] = _points.decay_points(delta, DECAY_SPEED)
	material.set_shader_parameter("impact_points", decayed_points)

## Called when a body enters the area.
func _on_body_entered(body: Node3D) -> void:
	if body is not Player: return
	if playerEntered: return
	if pickupHandler.pickupOnHand: pickupHandler.drop(false, true)
	pickupHandler.inNoStickerArea = true
	soundPlayer.play_sound()
	var pos: Vector3 = body.global_position
	for i in AMOUNT:
		_points.push(to_local(pos))
		await get_tree().create_timer(DELAY).timeout
	playerEntered = true

## Called when a body exits the area.
func _on_body_exited(body: Node3D) -> void:
	if body is not Player: return
	playerEntered = false
	pickupHandler.inNoStickerArea = false
