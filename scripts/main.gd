extends Node3D

# Globe Minesweeper - Clean Implementation
@export var globe_radius: float = 20.0
@export var subdivision_level: int = 3
@export var mine_percentage: float = 0.15
@export var tile_scale: float = 1.8

var tiles: Array = []
var icosphere_faces: Array = []
var game_over: bool = false
var game_won: bool = false
var ui_scene = preload("res://scenes/ui.tscn")
var ui

# Input state
var pressed_tile_index: int = -1
var mouse_dragging: bool = false
var mouse_down_pos: Vector2 = Vector2.ZERO
const DRAG_THRESHOLD: float = 4.0

# Hex tile sizing (computed to make edges touch)
var hex_radius: float = 0.9

# Materials
var unrevealed_material: StandardMaterial3D
var revealed_material: StandardMaterial3D
var flagged_material: StandardMaterial3D
var mine_material: StandardMaterial3D

func _ready():
	setup_materials()
	ui = ui_scene.instantiate()
	add_child(ui)
	# Ensure a container for fireworks exists
	if not has_node("Fireworks"):
		var fw = Node3D.new()
		fw.name = "Fireworks"
		add_child(fw)
	
	# Position camera
	$Camera3D.position = Vector3(0, 0, globe_radius * 3)
	
	# Start game
	generate_globe()
	place_mines()
	calculate_neighbor_counts()
	update_mine_counter()

func setup_materials():
	# Unrevealed tiles - dark gray
	unrevealed_material = StandardMaterial3D.new()
	unrevealed_material.albedo_color = Color(0.3, 0.3, 0.3)
	unrevealed_material.metallic = 0.1
	unrevealed_material.roughness = 0.7
	
	# Revealed tiles - light blue
	revealed_material = StandardMaterial3D.new()
	revealed_material.albedo_color = Color(0.7, 0.8, 1.0)
	revealed_material.metallic = 0.0
	revealed_material.roughness = 0.5
	
	# Flagged tiles - red
	flagged_material = StandardMaterial3D.new()
	flagged_material.albedo_color = Color(1.0, 0.2, 0.2)
	flagged_material.metallic = 0.0
	flagged_material.roughness = 0.6
	
	# Mine tiles - dark red
	mine_material = StandardMaterial3D.new()
	mine_material.albedo_color = Color(0.8, 0.1, 0.1)
	mine_material.metallic = 0.2
	mine_material.roughness = 0.4

func generate_globe():
	# Clear existing tiles
	for child in $Globe.get_children():
		child.free()
	tiles.clear()
	
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
	for i in range(vertices.size()):
		create_tile_at_position(i, vertices[i])
	
	# Calculate neighbors
	calculate_neighbors(vertices)

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

func create_tile_at_position(index: int, pos: Vector3):
	var tile_data = {
		"index": index,
		"position": pos,
		"world_position": pos * globe_radius,
		"has_mine": false,
		"is_revealed": false,
		"is_flagged": false,
		"neighbor_mines": 0,
		"neighbors": []
	}
	
	# Create visual tile
	var tile_node = StaticBody3D.new()
	tile_node.name = "Tile_" + str(index)
	# Ensure collisions are on a default visible layer/mask for ray picking
	tile_node.collision_layer = 1
	tile_node.collision_mask = 1
	$Globe.add_child(tile_node)
	
	# Position on globe surface
	tile_node.global_position = tile_data.world_position
	
	# Orient to face outward from globe center
	tile_node.look_at(tile_node.global_position + pos, Vector3.UP)
	
	# Create mesh
	var mesh_instance = MeshInstance3D.new()
	var hex_mesh = CylinderMesh.new()
	hex_mesh.top_radius = hex_radius
	hex_mesh.bottom_radius = hex_radius
	hex_mesh.height = 0.1
	hex_mesh.radial_segments = 6
	hex_mesh.rings = 1
	mesh_instance.mesh = hex_mesh
	mesh_instance.material_override = unrevealed_material
	# Rotate so the flat hex face points along -Z (to match label placement)
	mesh_instance.rotate_x(deg_to_rad(90))
	tile_node.add_child(mesh_instance)
	
	# Create collision (hexagonal prism via cylinder shape)
	var collision = CollisionShape3D.new()
	var cyl_shape = CylinderShape3D.new()
	cyl_shape.radius = hex_mesh.top_radius
	cyl_shape.height = hex_mesh.height
	collision.shape = cyl_shape
	# Match mesh rotation so the collision aligns with the visual
	collision.rotate_x(deg_to_rad(90))
	tile_node.add_child(collision)
	
	# Store references
	tile_data["node"] = tile_node
	tile_data["mesh"] = mesh_instance
	tiles.append(tile_data)

func calculate_neighbors(vertices: Array):
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

func place_mines():
	var num_mines = int(tiles.size() * mine_percentage)
	var available_tiles = range(tiles.size())
	available_tiles.shuffle()
	
	for i in range(num_mines):
		tiles[available_tiles[i]].has_mine = true

func calculate_neighbor_counts():
	for tile in tiles:
		if not tile.has_mine:
			var count = 0
			for neighbor_idx in tile.neighbors:
				if tiles[neighbor_idx].has_mine:
					count += 1
			tile.neighbor_mines = count

func update_mine_counter():
	var total_mines = 0
	var flagged_count = 0
	
	for tile in tiles:
		if tile.has_mine:
			total_mines += 1
		if tile.is_flagged:
			flagged_count += 1
	
	ui.update_mines(total_mines - flagged_count)

func _input(event):
	if game_over or game_won:
		return
	
	if event is InputEventMouseButton:
		var tile = get_tile_under_mouse(event.position)
		# LEFT PRESS: record pressed tile, reset drag
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			pressed_tile_index = tile.index if tile != null else -1
			mouse_dragging = false
			mouse_down_pos = event.position
			# Double-click chord: immediate chord on already revealed numbered tiles
			if tile and event.double_click:
				if tile.is_revealed and tile.neighbor_mines > 0:
					chord_reveal(tile)
				else:
					# Optional: allow double-click to also reveal immediately
					reveal_tile(tile)
		# LEFT RELEASE: reveal only if no drag and same tile under cursor
		elif event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			var release_tile = tile
			if not mouse_dragging and release_tile and pressed_tile_index == release_tile.index:
				reveal_tile(release_tile)
			pressed_tile_index = -1
			mouse_dragging = false
			mouse_down_pos = Vector2.ZERO
		# RIGHT PRESS: toggle flag immediately
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed and tile:
			toggle_flag(tile)

	if event is InputEventScreenTouch and event.pressed and event.double_tap:
		var t = get_tile_under_mouse(event.position)
		if t:
			if t.is_revealed and t.neighbor_mines > 0:
				chord_reveal(t)
			else:
				reveal_tile(t)
	
	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		# Determine drag based on threshold from initial press
		if (event.position - mouse_down_pos).length() > DRAG_THRESHOLD:
			mouse_dragging = true
		# Rotate globe once we are dragging, even if cursor is over a tile
		if mouse_dragging:
			# Inverted controls: drag right -> globe rotates right; drag up -> globe rotates up
			$Globe.rotate_y(event.relative.x * 0.01)
			$Globe.rotate_x(event.relative.y * 0.01)

func get_tile_under_mouse(mouse_pos: Vector2):
	var camera = $Camera3D
	var from = camera.project_ray_origin(mouse_pos)
	var to = from + camera.project_ray_normal(mouse_pos) * 1000
	
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(from, to)
	var result = space_state.intersect_ray(query)
	
	if result and "collider" in result:
		var node = result.collider as Node
		# Walk up parents to find the Tile_* StaticBody3D
		while node and node is Node:
			if node.name.begins_with("Tile_"):
				var index = int(node.name.substr(5))
				return tiles[index]
			node = node.get_parent()
	
	return null

func reveal_tile(tile):
	if tile.is_revealed or tile.is_flagged:
		return
	
	tile.is_revealed = true
	
	# Color mapping for neighboring mines (1-8)
	var color_map = [
		Color(0.8, 0.8, 0.8), # 0 - unused
		Color(0.2, 0.6, 1.0), # 1 - blue
		Color(0.2, 0.8, 0.2), # 2 - green
		Color(1.0, 1.0, 0.2), # 3 - yellow (was orange)
		Color(0.6, 0.2, 0.6), # 4 - purple (was red)
		Color(0.2, 0.8, 0.8), # 5 - cyan
		Color(0.8, 0.8, 0.2), # 6 - yellow
		Color(0.5, 0.5, 0.5), # 7 - gray
		Color(0.4, 0.2, 1.0) # 8 - violet
	]

	if tile.is_revealed and not tile.has_mine:
		var mesh_instance = tile.mesh
		var mat = revealed_material.duplicate()
		var n = clamp(tile.neighbor_mines, 0, 8)
		mat.albedo_color = color_map[n]
		mesh_instance.material_override = mat
	
	if tile.has_mine:
		# Game over
		game_over = true
		reveal_all_mines()
		ui.show_game_over("Game Over!")
		return
	
	# Show number if has neighboring mines
	if tile.neighbor_mines > 0:
		add_number_to_tile(tile, str(tile.neighbor_mines))
	else:
		# Flood fill reveal empty neighbors
		for neighbor_idx in tile.neighbors:
			var neighbor = tiles[neighbor_idx]
			if not neighbor.is_revealed and not neighbor.is_flagged:
				reveal_tile(neighbor)
	
	check_win_condition()

func chord_reveal(tile):
	# Only proceed if the tile is already revealed and has a number
	if not tile.is_revealed or tile.neighbor_mines <= 0:
		return
	# Count flags around
	var flag_count := 0
	for neighbor_idx in tile.neighbors:
		if tiles[neighbor_idx].is_flagged:
			flag_count += 1
	# Only chord when placed flags equal the number
	if flag_count != tile.neighbor_mines:
		return
	# Reveal all unflagged, unrevealed neighbors
	for neighbor_idx in tile.neighbors:
		var n = tiles[neighbor_idx]
		if not n.is_flagged and not n.is_revealed:
			reveal_tile(n)

func toggle_flag(tile):
	if tile.is_revealed:
		return
	
	tile.is_flagged = not tile.is_flagged
	
	if tile.is_flagged:
		tile.mesh.material_override = flagged_material
	else:
		tile.mesh.material_override = unrevealed_material
	
	update_mine_counter()

func add_number_to_tile(tile, text: String):
	# Remove existing label
	var existing_label = tile.node.find_child("NumberLabel")
	if existing_label:
		existing_label.queue_free()
	
	# Create 3D label
	var label = Label3D.new()
	label.name = "NumberLabel"
	label.text = text
	label.font_size = 128
	label.pixel_size = 0.004
	label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.set_draw_flag(Label3D.FLAG_DOUBLE_SIDED, false)
	
	# Color based on number for better visibility
	match int(text):
		1: label.modulate = Color.BLUE
		2: label.modulate = Color.GREEN
		3: label.modulate = Color.RED
		4: label.modulate = Color.PURPLE
		5: label.modulate = Color.ORANGE
		6: label.modulate = Color.CYAN
		7: label.modulate = Color.BLACK
		8: label.modulate = Color.DARK_GRAY
		_: label.modulate = Color.WHITE
	
	# Position directly on tile surface (negative Z to face outward)
	label.position = Vector3(0, 0, -0.051)
	label.outline_size = 4
	label.outline_modulate = Color.WHITE
	
	tile.node.add_child(label)

func reveal_all_mines():
	for tile in tiles:
		if tile.has_mine:
			tile.is_revealed = true
			tile.mesh.material_override = mine_material
			add_number_to_tile(tile, "*")

func check_win_condition():
	for tile in tiles:
		if not tile.has_mine and not tile.is_revealed:
			return # Still have unrevealed safe tiles
	
	# All safe tiles revealed
	game_won = true
	ui.show_game_over("You Win!")
	trigger_fireworks()

func trigger_fireworks():
	# Create several fireworks around the globe
	var fw_root: Node3D = get_node("Fireworks")
	if fw_root == null:
		fw_root = Node3D.new()
		fw_root.name = "Fireworks"
		add_child(fw_root)
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	var bursts := 10
	for i in range(bursts):
		var dir = Vector3(rng.randf_range(-1,1), rng.randf_range(-1,1), rng.randf_range(-1,1)).normalized()
		var pos = dir * (globe_radius * 1.2)
		create_firework_at(fw_root, pos)

func create_firework_at(parent: Node3D, pos: Vector3):
	var p = GPUParticles3D.new()
	p.name = "Firework"
	p.one_shot = true
	p.amount = 200
	p.lifetime = 1.8
	p.preprocess = 0.0
	p.emitting = false
	p.draw_pass_1 = SphereMesh.new()
	# Process material
	var mat = ParticleProcessMaterial.new()
	mat.gravity = Vector3(0, -3.0, 0)
	mat.initial_velocity_min = 8.0
	mat.initial_velocity_max = 14.0
	mat.angle_min = 0.0
	mat.angle_max = 360.0
	mat.scale_min = 0.05
	mat.scale_max = 0.1
	mat.hue_variation_min = -0.2
	mat.hue_variation_max = 0.2
	mat.spread = 180.0
	mat.color = Color(1,1,1)
	# Color ramp for nice fade
	var grad = Gradient.new()
	grad.colors = PackedColorArray([Color(1,1,1), Color(1,0,0), Color(1,1,0), Color(0,1,1), Color(0,0,0,0)])
	grad.offsets = PackedFloat32Array([0.0, 0.2, 0.5, 0.8, 1.0])
	mat.color_ramp = grad
	# Slight upward burst
	mat.direction = Vector3(0,1,0)
	mat.spread = 360.0
	p.process_material = mat
	parent.add_child(p)
	p.global_position = pos
	# Start emitting after a tiny delay to stagger
	var delay = randf() * 0.6
	var t = get_tree().create_timer(delay)
	await t.timeout
	p.emitting = true
	# Queue free after it's done
	var cleanup_t = get_tree().create_timer(p.lifetime + 0.5)
	await cleanup_t.timeout
	if is_instance_valid(p):
		p.queue_free()

func clear_fireworks():
	if has_node("Fireworks"):
		var fw_root: Node3D = get_node("Fireworks")
		for c in fw_root.get_children():
			c.queue_free()

func reset_game():
	game_over = false
	game_won = false
	# Reset globe orientation and camera position to defaults for consistency after reset
	$Globe.rotation = Vector3.ZERO
	$Camera3D.position = Vector3(0, 0, globe_radius * 3)
	# Reset input state
	pressed_tile_index = -1
	mouse_dragging = false
	if ui and ui.has_method("hide_game_over"):
		ui.hide_game_over()
	# Clear any fireworks effects
	clear_fireworks()
	generate_globe()
	place_mines()
	calculate_neighbor_counts()
	update_mine_counter()
