@tool
extends GridMap

@export var mesh: ArrayMesh
@export_tool_button("Do it") var doIt: Callable = button

func button() -> void:
	var returnedMeshes: Array = get_bake_meshes()
	#var mdt = MeshDataTool.new()
	#mdt.create_from_surface(returnedMeshes[0], 0)
	#var vertices: PackedVector3Array = []
	#for i in mdt.get_vertex_count():
		#var vertex: Vector3 = mdt.get_vertex(i).round()
		#vertices.push_back(vertex)
		#if vertex not in vertices and vertex != null: vertices.push_back(vertex)
	#var arr_mesh = ArrayMesh.new()
	#var arrays = []
	#arrays.resize(Mesh.ARRAY_MAX)
	#arrays[Mesh.ARRAY_VERTEX] = vertices
	#arrays[Mesh.ARRAY_INDEX] = get_triangles(vertices)
	#print(arrays)
	## Create the Mesh.
	#arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	#mesh = arr_mesh
	mesh = returnedMeshes[0]

func get_triangles(array: PackedVector3Array) -> PackedInt32Array:
	var triangles: PackedInt32Array = []
	for i in range(len(array)):
		var connectedPoints: PackedInt32Array = get_all_connected_points(array, i)
		if len(connectedPoints) < 2: continue
		for j in range(len(connectedPoints) - 1):
			for k in range(j, len(connectedPoints)):
				triangles.append_array([i, connectedPoints[j], connectedPoints[k]])
	return triangles

func get_all_connected_points(array: PackedVector3Array, index: int, exclude: int = -1) -> PackedInt32Array:
	var points: PackedInt32Array = []
	for i in range(len(array)):
		if i in [index, exclude]: continue
		if array[i].distance_to(array[index]) <= 1.0: points.append(i)
	return points
