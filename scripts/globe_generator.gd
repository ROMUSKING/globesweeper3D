class_name GlobeGenerator
extends Node

var icosphere_faces: Array = []
var globe_radius: float
var subdivision_level: int
var hex_radius: float
var unrevealed_material: StandardMaterial3D

func generate(parent_node: Node3D, radius: float, subdivisions: int, material: StandardMaterial3D) -> Dictionary:
	globe_radius = radius
	subdivision_level = subdivisions
	unrevealed_material = material
	
	var start_time = Time.get_unix_time_from_system()
	
	# Generate icosphere vertices
	var vertices = get_icosphere_vertices()

	# Compute hex radius from neighbor spacing so edges touch: R = d / sqrt(3)
	# Build adjacency like in calculate_neighbors but from faces directly
	var neighbor_sets: Array = []
	neighbor_sets.resize(vertices.size())
	for i in range(vertices.size()):
		neighbor_sets[i] = {}
	for face in icosphere_faces:
		var a: int = face[0]
		var b: int = face[1]
		var c: int = face[2]
		neighbor_sets[a][b] = true
		neighbor_sets[a][c] = true
		neighbor_sets[b][a] = true
		neighbor_sets[b][c] = true
		neighbor_sets[c][a] = true
		neighbor_sets[c][b] = true
	var min_d := INF
	for i in range(vertices.size()):
		for k in neighbor_sets[i].keys():
			var j: int = int(k)
			var d = (vertices[i] * globe_radius).distance_to(vertices[j] * globe_radius)
			if d < min_d:
				min_d = d
	# Slightly reduce to prevent overlap
	if min_d < INF:
		hex_radius = (min_d / sqrt(3.0)) * 0.99
	
	# Create tiles at each vertex
	var tiles = []
	for i in range(vertices.size()):
		var tile = create_tile_at_position(i, vertices[i], parent_node)
		tiles.append(tile)
	
	# Calculate neighbors
	calculate_neighbors(vertices, tiles)
	
	var end_time = Time.get_unix_time_from_system()
	var generation_time = end_time - start_time
	
	return {
		"tiles": tiles,
		"hex_radius": hex_radius,
		"generation_time": generation_time
	}

func get_icosphere_vertices() -> Array:
	# Start with icosahedron vertices
	var phi = (1.0 + sqrt(5.0)) / 2.0 # Golden ratio
	var vertices = [
		Vector3(-1, phi, 0), Vector3(1, phi, 0), Vector3(-1, -phi, 0), Vector3(1, -phi, 0),
		Vector3(0, -1, phi), Vector3(0, 1, phi), Vector3(0, -1, -phi), Vector3(0, 1, -phi),
		Vector3(phi, 0, -1), Vector3(phi, 0, 1), Vector3(-phi, 0, -1), Vector3(-phi, 0, 1)
	]
	
	# Normalize to unit sphere
	for i in range(vertices.size()):
		vertices[i] = vertices[i].normalized()
	
	# Subdivide for more tiles
	var faces = [
		[0, 11, 5], [0, 5, 1], [0, 1, 7], [0, 7, 10], [0, 10, 11],
		[1, 5, 9], [5, 11, 4], [11, 10, 2], [10, 7, 6], [7, 1, 8],
		[3, 9, 4], [3, 4, 2], [3, 2, 6], [3, 6, 8], [3, 8, 9],
		[4, 9, 5], [2, 4, 11], [6, 2, 10], [8, 6, 7], [9, 8, 1]
	]
	
	for level in range(subdivision_level):
		var new_vertices = vertices.duplicate()
		var new_faces = []
		var midpoint_cache = {}
		
		for face in faces:
			var v1 = face[0]
			var v2 = face[1]
			var v3 = face[2]
			
			var a = get_midpoint(v1, v2, new_vertices, midpoint_cache)
			var b = get_midpoint(v2, v3, new_vertices, midpoint_cache)
			var c = get_midpoint(v3, v1, new_vertices, midpoint_cache)
			
			new_faces.append([v1, a, c])
			new_faces.append([v2, b, a])
			new_faces.append([v3, c, b])
			new_faces.append([a, b, c])
		
		vertices = new_vertices
		faces = new_faces
	
	# Persist faces for adjacency calculation
	icosphere_faces = faces
	return vertices

func get_midpoint(i1: int, i2: int, vertices: Array, cache: Dictionary) -> int:
	var key = [min(i1, i2), max(i1, i2)]
	if key in cache:
		return cache[key]
	
	var v1 = vertices[i1]
	var v2 = vertices[i2]
	var midpoint = ((v1 + v2) / 2.0).normalized()
	
	vertices.append(midpoint)
	var index = vertices.size() - 1
	cache[key] = index
	return index

func create_tile_at_position(index: int, pos: Vector3, parent_node: Node3D) -> Tile:
	var world_pos = pos * globe_radius
	var tile = Tile.new(index, pos, world_pos)
	
	# Create visual tile
	var tile_node = StaticBody3D.new()
	tile_node.name = "Tile_" + str(index)
	# Ensure collisions are on a default visible layer/mask for ray picking
	tile_node.collision_layer = 1
	tile_node.collision_mask = 1
	parent_node.add_child(tile_node)
	
	# Position on globe surface, but offset inward to obstruct interior
	var inward_offset = pos.normalized() * 1.0 # Move 1 unit inward along normal
	tile_node.global_position = (tile.world_position - inward_offset)
	
	# Orient to face outward from globe center
	tile_node.look_at(tile_node.global_position + pos, Vector3.UP)
	
	# Create mesh with flat top and rounded edges using CSG
	var mesh_instance = MeshInstance3D.new()

	# Create temporary CSG scene for mesh generation
	var temp_csg = CSGCombiner3D.new()

	# Main hexagonal cylinder body
	var csg_cylinder = CSGCylinder3D.new()
	csg_cylinder.radius = hex_radius
	csg_cylinder.height = 2.6 # Leave space for rounded edges
	csg_cylinder.sides = 6 # Hexagonal shape
	temp_csg.add_child(csg_cylinder)

	# Add small spheres at corners for rounded edges
	for i in range(6):
		var angle = (i * PI * 2) / 6
		var sphere = CSGSphere3D.new()
		sphere.radius = hex_radius * 0.15 # Small radius for edge rounding
		sphere.position = Vector3(
			cos(angle) * hex_radius,
			1.3, # Position at top of cylinder
			sin(angle) * hex_radius
		)
		temp_csg.add_child(sphere)

	# Bake the CSG mesh
	var meshes = temp_csg.get_meshes()
	var baked_mesh: Mesh = null
	if meshes.size() > 1:
		baked_mesh = meshes[1] as Mesh
	else:
		# Fallback: create a simple cylinder mesh
		var cylinder_mesh = CylinderMesh.new()
		cylinder_mesh.top_radius = hex_radius
		cylinder_mesh.bottom_radius = hex_radius
		cylinder_mesh.height = 3.0
		cylinder_mesh.radial_segments = 6
		cylinder_mesh.rings = 2
		baked_mesh = cylinder_mesh

	mesh_instance.mesh = baked_mesh
	mesh_instance.material_override = unrevealed_material

	# Rotate so the flat top faces outward
	mesh_instance.rotate_x(deg_to_rad(90))
	tile_node.add_child(mesh_instance) # Create collision (hexagonal prism via cylinder shape)
	var collision = CollisionShape3D.new()
	var cyl_shape = CylinderShape3D.new()
	cyl_shape.radius = hex_radius
	cyl_shape.height = 3.0 # Match total height of compound mesh
	collision.shape = cyl_shape
	# Match mesh rotation so the collision aligns with the visual
	collision.rotate_x(deg_to_rad(90))
	tile_node.add_child(collision)
	
	# Store references
	tile.node = tile_node
	tile.mesh = mesh_instance
	return tile

func calculate_neighbors(vertices: Array, tiles: Array):
	# Build adjacency from icosphere face edges (exact hex/pent adjacency)
	var neighbor_sets: Array = []
	neighbor_sets.resize(vertices.size())
	for i in range(vertices.size()):
		neighbor_sets[i] = {}
	
	for face in icosphere_faces:
		var a: int = face[0]
		var b: int = face[1]
		var c: int = face[2]
		# Undirected edges
		neighbor_sets[a][b] = true
		neighbor_sets[a][c] = true
		neighbor_sets[b][a] = true
		neighbor_sets[b][c] = true
		neighbor_sets[c][a] = true
		neighbor_sets[c][b] = true
	
	for i in range(tiles.size()):
		var set_dict: Dictionary = neighbor_sets[i]
		# Convert keys to array of indices
		var arr: Array = []
		for k in set_dict.keys():
			arr.append(int(k))
		tiles[i].neighbors = arr