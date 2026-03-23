@tool
extends Camera3D
class_name RailCamera

enum CameraModes {FREE, ROTATION_LOCKED, FOLLOW_PLAYER, FIXED, FIXED_FOLLOW_PLAYER}
@export var mode: CameraModes = CameraModes.FREE:
	set(value):
		mode = value
		if Engine.is_editor_hint() and is_node_ready():
			setup_rail()
@export_custom(PROPERTY_HINT_RANGE, "-180,180,1,radians_as_degrees") var freeBaseRotation: Vector3 = Vector3.ZERO
@export_range(0.0, 5.0, 0.01) var offsetToStartFollowing: float = 0.25
@export_range(0.0, 20.0, 0.01) var followSpeed: float = 1.5
@export_range(0.0, 1.0, 0.01) var progress: float = 0:
	set(value):
		progress = value
		if Engine.is_editor_hint() and is_node_ready():
			update_camera_position()
var path: Path3D
var pathFollower: PathFollow3D
var player: Player
var curve: Curve3D
var points: PackedVector3Array
var curveLength: float = 0
var currentOffset: float

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	set_cull_mask_value(18, false)
	set_cull_mask_value(19, false)
	setup_rail()
	get_player()
	progress = 0
	update_camera_position()

func setup_rail() -> void:
	if not path:
		for child in get_children():
			if child is Path3D and child.has_meta("CameraPath"):
				path = child
				break
	if mode == CameraModes.FIXED:
		if path: path.queue_free()
		path = null
		pathFollower = null
		return
	if not path:
		path = Path3D.new()
		path.name = "CameraPath"
		path.top_level = true
		path.set_meta("CameraPath", true)
		add_child(path)
		path.owner = get_tree().edited_scene_root
	pathFollower = PathFollow3D.new()
	path.add_child(pathFollower)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if not current or Engine.is_editor_hint(): return
	get_progress(delta)
	update_camera_position()

func get_progress(delta: float) -> void:
	if Engine.is_editor_hint() or mode in [CameraModes.FIXED, CameraModes.FIXED_FOLLOW_PLAYER]: return
	if not curve:
		curve = path.curve
		points = curve.get_baked_points()
		curveLength = curve.get_baked_length()
	get_player()
	if not player: return
	var closestOffset: float = curve.get_closest_offset(player.global_position)
	var distance: float = get_distance_between_points(currentOffset, closestOffset)
	if distance < offsetToStartFollowing: return
	var targetProgress: float = clamp(closestOffset / curveLength, 0.0, 1.0)
	progress = lerp(progress, targetProgress, followSpeed * delta)

func get_distance_between_points(a: float, b: float) -> float:
	var res: float = 0
	for i in range(min(a, b), max(a, b)):
		res += points[i].distance_to(points[i + 1])
	return res

func update_camera_position() -> void:
	if not pathFollower:
		if mode == CameraModes.FIXED_FOLLOW_PLAYER:
			get_player()
			if player: look_at(player.global_position)
		return
	pathFollower.progress_ratio = progress
	match mode:
		CameraModes.FREE:
			global_transform = pathFollower.global_transform
			rotation += freeBaseRotation
		CameraModes.ROTATION_LOCKED:
			global_position = pathFollower.global_position
		CameraModes.FOLLOW_PLAYER:
			global_position = pathFollower.global_position
			get_player()
			if player: look_at(player.global_position)
	if curve: currentOffset = curve.get_closest_offset(global_position)

func get_player() -> void:
	if not player: 
		player = get_tree().get_first_node_in_group("Player")
		if player: player.currentCamera = self
