class_name GlobeGenerator
extends Node

## Generates a 3D icosphere globe with hexagonal and pentagonal tiles for the GlobeSweeper game.
## Uses procedural mesh generation for optimal performance.

var icosphere_faces: Array = []
var globe_radius: float
var subdivision_level: int
var hex_radius: float
var tile_material_template: ShaderMaterial

# Optimization: Store generated meshes to reuse them
var shared_hex_mesh: Mesh = null
var shared_pent_mesh: Mesh = null

# Mesh cache for different side configurations
var _mesh_cache: Dictionary = {}

func generate(parent_node: Node3D, radius: float, subdivisions: int, material_template: ShaderMaterial) -> Dictionary:
	"""Generates a complete icosphere globe with tiles.
	
	Args:
		parent_node: The node to add tiles as children of
		radius: The radius of the globe
		subdivisions: Number of subdivisions (higher = more tiles)
		material_template: ShaderMaterial to use for tile rendering
	
	Returns: Dictionary containing 'tiles' array, 'hex_radius', and 'generation_time'
	"""
	globe_radius = radius
	subdivision_level = subdivisions
	tile_material_template = material_template
	
	var start_time = Time.get_unix_time_from_system()
	
	# Generate icosphere vertices
	var vertices = get_icosphere_vertices()

	# Compute hex radius from neighbor spacing so edges touch
	# We use the adjacency of the first few vertices to determine spacing
	# (approximate based on average or min distance)
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
	# Check a sample of vertices to find minimum edge length
	var check_count = min(vertices.size(), 50)
	for i in range(check_count):
		for k in neighbor_sets[i].keys():
			var j: int = int(k)
			var d = (vertices[i] * globe_radius).distance_to(vertices[j] * globe_radius)
			if d < min_d:
				min_d = d
				
	# Slightly reduce to prevent overlap
	if min_d < INF:
		hex_radius = (min_d / sqrt(3.0)) * 0.98
	else:
		hex_radius = 1.0 # Fallback
	
	# Generate shared meshes
	shared_hex_mesh = generate_tile_mesh(6)
	shared_pent_mesh = generate_tile_mesh(5)
	
	# Create tiles at each vertex
	var tiles = []
	for i in range(vertices.size()):
		# The first 12 vertices (0-11) of an icosphere are always the pentagons in the dual
		var is_pentagon = (i < 12)
		var tile = create_tile_at_position(i, vertices[i], parent_node, is_pentagon)
		tiles.append(tile)
	
	# Calculate neighbors (fully populate tile.neighbors)
	calculate_neighbors(vertices, tiles)
	
	var end_time = Time.get_unix_time_from_system()
	var generation_time = end_time - start_time
	
	return {
		"tiles": tiles,
		"hex_radius": hex_radius,
		"generation_time": generation_time
	}

func get_icosphere_vertices() -> Array:
	"""Generates icosphere vertices using subdivision of an icosahedron.
	
	Returns: Array of Vector3 vertices normalized to unit sphere
	"""
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
	"""Gets or creates a normalized midpoint vertex between two vertices.
	
	Uses caching to avoid duplicate midpoints for efficiency.
	
	Args:
		i1: Index of first vertex
		i2: Index of second vertex
		vertices: Array to add new midpoint to
		cache: Dictionary mapping vertex pairs to indices
	
	Returns: Index of the midpoint vertex in the vertices array
	"""
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

func generate_tile_mesh(sides: int) -> Mesh:
	"""Generates a procedural mesh for a tile with the given number of sides.
	
	Uses SurfaceTool for efficient mesh generation with proper UV coordinates.
	Results are cached to avoid regeneration for the same side count.
	
	Args:
		sides: Number of sides (6 for hexagon, 5 for pentagon)
	
	Returns: The generated ArrayMesh
	"""
	# Check cache first
	if _mesh_cache.has(sides):
		return _mesh_cache[sides]
	
	# Create procedural mesh using SurfaceTool for efficiency
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_smooth_group(0)
	
	# Calculate tile height based on hex_radius
	var tile_height = hex_radius * 1.0
	var top_y = tile_height / 2.0
	var bottom_y = - tile_height / 2.0
	
	# Generate vertices for the prism/pyramid shape
	for i in range(sides):
		var angle = (i * PI * 2) / sides
		var next_angle = ((i + 1) % sides) * PI * 2 / sides
		
		var x1 = cos(angle) * hex_radius
		var z1 = sin(angle) * hex_radius
		var x2 = cos(next_angle) * hex_radius
		var z2 = sin(next_angle) * hex_radius
		
		# Top face vertex (center)
		var top_center = Vector3(0, top_y, 0)
		var top_v1 = Vector3(x1, top_y, z1)
		var top_v2 = Vector3(x2, top_y, z2)
		
		# Bottom face vertex (center)
		var bottom_center = Vector3(0, bottom_y, 0)
		var bottom_v1 = Vector3(x1, bottom_y, z1)
		var bottom_v2 = Vector3(x2, bottom_y, z2)
		
		# Calculate normal for side face
		var edge_center = (top_v1 + top_v2 + bottom_v1 + bottom_v2) / 4.0
		var side_normal = edge_center.normalized()
		
		# UV coordinates
		var uv_center = Vector2(0.5, 0.5)
		var uv_v1 = Vector2(0.5 + cos(angle) * 0.5, 0.5 + sin(angle) * 0.5)
		var uv_v2 = Vector2(0.5 + cos(next_angle) * 0.5, 0.5 + sin(next_angle) * 0.5)
		
		# Top face (two triangles)
		st.set_normal(Vector3.UP)
		st.set_uv(uv_center)
		st.add_vertex(top_center)
		st.set_normal(Vector3.UP)
		st.set_uv(uv_v1)
		st.add_vertex(top_v1)
		st.set_normal(Vector3.UP)
		st.set_uv(uv_v2)
		st.add_vertex(top_v2)
		
		# Bottom face (two triangles, winding reversed)
		st.set_normal(Vector3.DOWN)
		st.set_uv(uv_center)
		st.add_vertex(bottom_center)
		st.set_normal(Vector3.DOWN)
		st.set_uv(uv_v2)
		st.add_vertex(bottom_v2)
		st.set_normal(Vector3.DOWN)
		st.set_uv(uv_v1)
		st.add_vertex(bottom_v1)
		
		# Side face (two triangles)
		st.set_normal(side_normal)
		st.set_uv(Vector2(0.0, 0.0))
		st.add_vertex(top_v1)
		st.set_normal(side_normal)
		st.set_uv(Vector2(1.0, 0.0))
		st.add_vertex(top_v2)
		st.set_normal(side_normal)
		st.set_uv(Vector2(1.0, 1.0))
		st.add_vertex(bottom_v2)
		
		st.set_normal(side_normal)
		st.set_uv(Vector2(0.0, 0.0))
		st.add_vertex(top_v1)
		st.set_normal(side_normal)
		st.set_uv(Vector2(1.0, 1.0))
		st.add_vertex(bottom_v2)
		st.set_normal(side_normal)
		st.set_uv(Vector2(0.0, 1.0))
		st.add_vertex(bottom_v1)
	
	# Commit the mesh
	st.generate_normals()
	var mesh = st.commit()
	
	# Cache the mesh for reuse
	_mesh_cache[sides] = mesh
	
	return mesh

func create_tile_at_position(index: int, pos: Vector3, parent_node: Node3D, is_pentagon: bool) -> Tile:
	"""Creates a tile at the specified position on the globe.
	
	Creates the visual mesh, collision shape, and sets up metadata for interaction.
	
	Args:
		index: Unique index for this tile
		pos: Normalized position vector on the sphere
		parent_node: Parent node to attach the tile to
		is_pentagon: True if this is a pentagonal tile (first 12 vertices)
	
	Returns: The created Tile object with references to its node and mesh
	"""
	var world_pos = pos * globe_radius
	var tile = Tile.new(index, pos, world_pos)
	
	# Create visual tile node
	var tile_node = StaticBody3D.new()
	tile_node.name = "Tile_" + str(index)
	tile_node.collision_layer = 1
	tile_node.collision_mask = 1
	
	# IMPORTANT: Add metadata for interaction system
	tile_node.set_meta("tile_index", index)
	
	parent_node.add_child(tile_node)
	
	# Position on globe surface, but offset inward to obstruct interior
	var inward_offset = pos.normalized() * 1.0 # Move 1 unit inward along normal
	tile_node.global_position = (tile.world_position - inward_offset)
	
	# Orient to face outward from globe center
	tile_node.look_at(tile_node.global_position + pos, Vector3.UP)
	
	# Create mesh instance using shared mesh
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = shared_pent_mesh if is_pentagon else shared_hex_mesh
	
	# Create a unique material instance for this tile so we can change its uniforms independently
	# For higher performance with thousands of tiles, we would use Instance Uniforms (Godot 4.x),
	# but for simplicity and compatibility with the current shader structure, unique materials work well enough for < 1000 tiles.
	# Given the Ultra target is 2500+ tiles, we should ideally use set_instance_shader_parameter,
	# but that requires the shader to use `global uniform` or `instance uniform`.
	# For this phase, let's stick to unique materials as per instructions, or better yet, use set_instance_shader_parameter if available.
	# Checking Godot 4 docs: GeometryInstance3D.set_instance_shader_parameter is the way.
	# However, to use that, the shader uniform needs `instance` keyword.
	# Our shader doesn't have it yet.
	# So we will clone the material for now to ensure functionality.
	mesh_instance.material_override = tile_material_template.duplicate()
	
	# Rotate so the flat top faces outward (CSG cylinder is Y-up)
	mesh_instance.rotate_x(deg_to_rad(90))
	tile_node.add_child(mesh_instance)
	
	# Create collision shape
	var collision = CollisionShape3D.new()
	var cyl_shape = CylinderShape3D.new()
	cyl_shape.radius = hex_radius
	cyl_shape.height = 3.0
	collision.shape = cyl_shape
	
	# Match mesh rotation
	collision.rotate_x(deg_to_rad(90))
	tile_node.add_child(collision)
	
	# Store references
	tile.node = tile_node
	tile.mesh = mesh_instance
	return tile

func calculate_neighbors(vertices: Array, tiles: Array):
	"""Calculates and populates the neighbor relationships for all tiles.
	
	Builds adjacency from icosphere face edges for exact hex/pent adjacency.
	
	Args:
		vertices: Array of vertex positions
		tiles: Array of Tile objects to populate with neighbors
	"""
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
