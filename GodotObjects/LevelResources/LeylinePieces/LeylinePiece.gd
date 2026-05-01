@icon("uid://cq26nlkrot578")
@tool
extends Node3D

## Class for leyline chain pieces.
class_name LeylinePiece

## Animation time for pieces.
const PIECEANIMATIONTIME: float = 0.1
## Piece size.
const PIECESIZE: Vector2 = Vector2.ONE
## Piece vertical displacement for contraresting zfighting.
const PIECEAVERTICALDISPLACEMENT: float = 0.001
## Parameters for the arrow that only shows in the editor.
const EDITORARROW: Dictionary[String, Variant] = {
	"size" = Vector3(0.3, 0.2, 0.01),
	"rotation" = Vector3(-PI / 2.0, -PI / 2.0, 0.0),
	"color" = Color.CYAN
}
## Textures and parameters to use for building materials. Under, Over, Mask, Rotation (1.0 for 90CW, -1.0 for 90CCW, 2.0 or -2.0 for 180), FlipX, FlipY.
const TEXTURES: Dictionary[String, Array] = {
	"straight": ["uid://bwcoxx6h3l152", "uid://bt22jfakxwfss", "uid://651tv8rs7ag0", 0.0, false, false],
	"left": ["uid://cb71j3f3f0oul", "uid://ba0qwb8r4neva", "uid://dirv54paxt7fw", 0.0, false, false],
	"right": ["uid://cb71j3f3f0oul", "uid://ba0qwb8r4neva", "uid://dirv54paxt7fw", 0.0, false, true],
	"straight_left": ["uid://cin0f8j3c5jbo", "uid://bq2pjjdkqsrv1", "uid://del1hhu1lv7db", 1.0, false, false],
	"straight_right": ["uid://cin0f8j3c5jbo", "uid://bq2pjjdkqsrv1", "uid://del1hhu1lv7db", 1.0, true, false],
	"left_right": ["uid://cin0f8j3c5jbo", "uid://bq2pjjdkqsrv1", "uid://fhqq8ydrjryj", 0.0, false, false],
	"all": ["uid://bpnqecrgdunnu", "uid://btq814mew58v5", "uid://en53ahccgueq", 0.0, false, false]
}
## Material for the leyline piece.
const LEYLINEMATERIAL: ShaderMaterial = preload("uid://dt4jndoftnsvs")
## Exits for the leyline piece.
enum ExitValues {Straight = 1, Left = 2, Right = 4}
## Angles for the leyline piece.
enum VerticalAngles {Flat, SmallSlope, BigSlope, Wall, WallDown}

## Length of this piece. Used only for straight pieces.
@export_range(1.0, 100.0, 1.0) var length: float = 1.0:
	set(value):
		length = value
		if Engine.is_editor_hint() and is_node_ready():
			set_length()
## Vertical angle of this piece.
@export var verticalAngle: VerticalAngles = VerticalAngles.Flat:
	set(value):
		verticalAngle = value
		if Engine.is_editor_hint() and is_node_ready():
			set_length()
## Exits for the path piece.
@export_flags("Straight", "Left", "Right") var exits: int = 1:
	set(value):
		if value == 0: value = 1
		exits = value
		if Engine.is_editor_hint() and is_node_ready():
			set_piece()
## Test animation.
@export_tool_button("Test", "Play") var doTest: Callable = switch_state

## Reference to the leyline piece.
var leylinePiece: MeshInstance3D
## Reference to the pivot point of the piece.
var pivot: Node3D
## This piece's mesh.
var mesh: QuadMesh
## This piece's material.
var material: ShaderMaterial
## This piece's parent if it's a leyline piece.
var leylineParent: LeylinePiece
## This piece's parent if it's a CubeCheck.
var cubeCheckParent: LeylineCubeCheck
## This piece's leyline piece children.
var leylineChildren: Array[LeylinePiece] = []
## This piece's LeylineCubeCheck children.
var leylineCubeChildren: Array[LeylineCubeCheck] = []
## This piece's alternable children.
var alternableChildren: Array[Node] = []
## Tracks if this piece is on currently.
var isOn: bool = false
## Animating tween.
var tween: Tween
## Curent animation progress.
var progress: float = 0.0
## Count for child checks in case multiple come out at one time.
var childOffChecks: int = 0

## Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pivot = Node3D.new()
	pivot.name = "Pivot"
	leylinePiece = MeshInstance3D.new()
	leylinePiece.name = "LeylinePieceMesh"
	mesh = QuadMesh.new()
	mesh.size = PIECESIZE
	mesh.orientation = PlaneMesh.FACE_Y
	leylinePiece.mesh = mesh
	leylinePiece.position = Vector3(PIECESIZE.x / 2.0, PIECEAVERTICALDISPLACEMENT, 0.0)
	pivot.add_child(leylinePiece)
	add_child(pivot)
	material = LEYLINEMATERIAL.duplicate()
	material.render_priority = 1
	leylinePiece.set_surface_override_material(0, material)
	set_piece()
	set_length()
	if not Engine.is_editor_hint(): GeneralVariables.queue_to_cutout_materials([material], true)
	leylineParent = get_parent() if get_parent() is LeylinePiece else null
	cubeCheckParent = get_parent() if get_parent() is LeylineCubeCheck else null
	for child in get_children(): 
		if child is LeylinePiece: leylineChildren.append(child)
		elif child is LeylineCubeCheck: leylineCubeChildren.append(child)
		elif child is AlternatingObject or child is MovingPlatform or child is LitGlass or child is RemoteSwitcher: alternableChildren.append(child)
	if not Engine.is_editor_hint(): return
	var editorMesh: MeshInstance3D = MeshInstance3D.new()
	editorMesh.mesh = PrismMesh.new()
	editorMesh.mesh.size = EDITORARROW.size
	editorMesh.position.x = EDITORARROW.size.x / 3.0
	editorMesh.rotation = EDITORARROW.rotation
	var editorMaterial: ORMMaterial3D = ORMMaterial3D.new()
	editorMaterial.albedo_color = EDITORARROW.color
	editorMaterial.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	editorMaterial.disable_receive_shadows = true
	editorMaterial.emission_enabled = true
	editorMaterial.emission = EDITORARROW.color
	editorMaterial.emission_energy_multiplier = 2.0
	editorMesh.set_surface_override_material(0, editorMaterial)
	pivot.add_child(editorMesh)
	if Engine.is_editor_hint(): 
		for child in get_children(): 
			if child != pivot and child.name == "Pivot": 
				for granchild in child.get_children():
					if granchild.name == "LeylinePieceMesh" and granchild is MeshInstance3D:
						child.queue_free()
						return

## Sets this piece's length.
func set_length() -> void:
	match verticalAngle:
		VerticalAngles.Flat:
			pivot.rotation.z = 0
			mesh.size.x = length
		VerticalAngles.SmallSlope:
			pivot.rotation.z = PI / 8.0
			mesh.size.x = length / cos(pivot.rotation.z)
		VerticalAngles.BigSlope:
			pivot.rotation.z = PI / 4.0
			mesh.size.x = length / cos(pivot.rotation.z)
		VerticalAngles.Wall:
			pivot.rotation.z = PI / 2.0
			mesh.size.x = length
		VerticalAngles.WallDown:
			pivot.rotation.z = PI * 1.5
			mesh.size.x = length
	leylinePiece.position.x = mesh.size.x / 2.0
	material.set_shader_parameter("segments", length)

## Sets this piece's material.
func set_piece() -> void:
	if exits & (ExitValues.Straight + ExitValues.Left + ExitValues.Right) == ExitValues.Straight + ExitValues.Left + ExitValues.Right:
		apply_textures("all")
	elif exits & ExitValues.Straight != 0:
		if exits & ExitValues.Left != 0: apply_textures("straight_left")
		elif exits & ExitValues.Right != 0: apply_textures("straight_right")
		else: apply_textures("straight")
	elif exits & ExitValues.Left != 0:
		if exits & ExitValues.Right != 0: apply_textures("left_right")
		else: apply_textures("left")
	else: apply_textures("right")

## Applies piece's textures.
func apply_textures(piece: String) -> void:
	material.set_shader_parameter("under", load(TEXTURES[piece][0]))
	material.set_shader_parameter("over", load(TEXTURES[piece][1]))
	material.set_shader_parameter("mask", load(TEXTURES[piece][2]))
	material.set_shader_parameter("rotationAngle", TEXTURES[piece][3])
	material.set_shader_parameter("flipX", TEXTURES[piece][4])
	material.set_shader_parameter("flipY", TEXTURES[piece][5])

## Switches state.
func switch_state() -> void:
	if leylineParent or cubeCheckParent: return
	if not isOn: animate()
	else: animate_last()

## Animates the last piece first, used for turning off.
func animate_last() -> void:
	if len(leylineChildren) == 0 and len(leylineCubeChildren) == 0: animate()
	else: 
		for child in leylineChildren: child.animate_last()
		for child in leylineCubeChildren: child.animate_last()

## Animates this piece and subsequent ones.
func animate() -> void:
	if isOn: 
		childOffChecks += 1
		if childOffChecks < len(leylineChildren) + len(leylineCubeChildren): return
	childOffChecks = 0
	isOn = not isOn
	if tween: if tween.is_running(): tween.kill()
	tween = create_tween()
	var goal: float = 1.0 if isOn else 0.0
	var time: float = ((1.0 - progress) if isOn else progress) * PIECEANIMATIONTIME * length
	tween.tween_method(_animation_tick, progress, goal, time)
	tween.play()
	tween.finished.connect(animation_finished)
	if not Engine.is_editor_hint(): if not isOn: for child in alternableChildren: child.switch_state()

## A tick of animation.
func _animation_tick(currentProgres: float) -> void:
	progress = currentProgres
	material.set_shader_parameter("progress", progress)

## Executed when animation is finished.
func animation_finished() -> void:
	if isOn: 
		for child in leylineChildren: child.animate()
		for child in leylineCubeChildren: child.animate_cube(true)
		if not Engine.is_editor_hint(): for child in alternableChildren: child.switch_state()
	elif leylineParent:
		leylineParent.animate()
	elif cubeCheckParent:
		cubeCheckParent.leyline_child_off()

## Cleans unique materials.
func _notification(what) -> void:
	if Engine.is_editor_hint(): return
	if what == NOTIFICATION_PREDELETE:
		GeneralVariables.queue_to_cutout_materials([material], false)
		queue_free()
