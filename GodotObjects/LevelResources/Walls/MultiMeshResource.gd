@tool
extends Resource
class_name MultiMeshResource

@export var multiMesh: MultiMesh
@export var applyOnlyToNodes: bool = false
@export_range(0.01, 200.0, 0.01) var distanceBetweenPieces = 1.0
@export_range(0.00, 200.0, 0.01) var offsetStart: float = 0.0
@export_range(0.00, 200.0, 0.01) var offsetEnd: float = 0.0
@export var useOffsetEnd: bool = true
@export var normalAlwaysPointsUp: bool = false
