@tool
extends Node3D

## Class for leyline chain pieces.
class_name LeylinePiece

## Animation time for pieces.
const PIECEANIMATIONTIME: float = 0.1
## PArameters for the arrow that only shows in the editor.
const EDITORARROW: Dictionary[String, Variant] = {
	"size" = Vector3(0.3, 0.2, 0.1),
	"rotation" = Vector3(-PI / 2.0, -PI / 2.0, 0.0),
	"color" = Color.CYAN
}
## Angles for the leyline piece.
enum VerticalAngles {Flat, SmallSlope, BigSlope, Wall}

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
## Test animation.
@export_tool_button("Test", "Play") var doTest: Callable = animate

## Reference to the leyline piece.
@onready var leylinePiece: MeshInstance3D = %LeylinePiece
## Reference to the pivot point of the piece.
@onready var pivot: Node3D = %Pivot

## This piece's mesh.
var mesh: QuadMesh
## This piece's material.
var material: ShaderMaterial
## This piece's parent if it's a leyline piece.
var leylineParent: LeylinePiece
## This piece's leyline piece children.
var leylineChildren: Array[LeylinePiece] = []
## This piece's alternable children.
var alternableChildren: Array[Node] = []
## Tracks if this piece is on currently.
var isOn: bool = false
## Animating tween.
var tween: Tween
## Curent animation progress.
var progress: float = 0.0

## Called when the node enters the scene tree for the first time.
func _ready() -> void:
	mesh = leylinePiece.mesh.duplicate()
	leylinePiece.mesh = mesh
	material = leylinePiece.get_surface_override_material(0).duplicate()
	leylinePiece.set_surface_override_material(0, material)
	set_length()
	leylineParent = get_parent() if get_parent() is LeylinePiece else null
	for child in get_children(): 
		if child is LeylinePiece: leylineChildren.append(child)
		if child is AlternatingObject or child is MovingPlatform or child is LitGlass: alternableChildren.append(child)
	if not Engine.is_editor_hint(): return
	GeneralVariables.to_cutout_materials([material], true, true)
	var editorMesh: MeshInstance3D = MeshInstance3D.new()
	editorMesh.mesh = PrismMesh.new()
	editorMesh.mesh.size = EDITORARROW.size
	editorMesh.rotation = EDITORARROW.rotation
	var editorMaterial: ORMMaterial3D = ORMMaterial3D.new()
	editorMaterial.albedo_color = EDITORARROW.color
	editorMesh.set_surface_override_material(0, editorMaterial)
	pivot.add_child(editorMesh)

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
	leylinePiece.position.x = mesh.size.x / 2.0
	material.set_shader_parameter("segments", length)

## Switches state.
func switch_state() -> void:
	if leylineParent: return
	if not isOn: animate()
	else: animate_last() 

## Animates the last piece first, used for turning off.
func animate_last() -> void:
	if len(leylineChildren) == 0: animate()
	else: for child in leylineChildren: child.animate_last()

## Animates this piece and subsequent ones.
func animate() -> void:
	if isOn: for child in leylineChildren: if child.progress > 0: return
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
		if not Engine.is_editor_hint(): for child in alternableChildren: child.switch_state()
	elif leylineParent:
		leylineParent.animate()

## Cleans unique materials.
func _notification(what) -> void:
	if Engine.is_editor_hint(): return
	if what == NOTIFICATION_PREDELETE:
		GeneralVariables.to_cutout_materials([material], false, true)
