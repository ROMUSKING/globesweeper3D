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

# Audio nodes
var background_audio_stream_player: AudioStreamPlayer
var tile_reveal_sound: AudioStreamPlayer
var mine_explosion_sound: AudioStreamPlayer
var game_win_sound: AudioStreamPlayer
var game_lose_sound: AudioStreamPlayer

# Timer and statistics
var game_timer: float = 0.0
var game_paused: bool = false
var game_started: bool = false
var game_statistics = {
	"games_played": 0,
	"games_won": 0,
	"best_time": 9999.0,
	"total_time": 0.0,
	"current_streak": 0,
	"best_streak": 0
}

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

# Performance monitoring
var performance_stats = {
	"fps": 0,
	"frame_time": 0.0,
	"memory_usage": 0,
	"draw_calls": 0,
	"vertices": 0,
	"generation_time": 0.0,
	"tile_count": 0
}

func _ready():
	setup_materials()
	ui = ui_scene.instantiate()
	add_child(ui)
	
	# Initialize audio nodes
	background_audio_stream_player = $Audio/BackgroundMusic
	tile_reveal_sound = $Audio/TileReveal
	mine_explosion_sound = $Audio/MineExplosion
	game_win_sound = $Audio/GameWin
	game_lose_sound = $Audio/GameLose
	
	# Setup procedural audio
	setup_audio()
	
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
	load_game_statistics()

func _process(delta):
	if game_started and not game_over and not game_won and not game_paused:
		game_timer += delta
		ui.update_time(format_time(game_timer))
	elif game_paused:
		# Keep displaying current time when paused
		ui.update_time(format_time(game_timer))
	
	# Update performance stats every frame
	update_performance_stats()

func format_time(time_seconds: float) -> String:
	var minutes = int(time_seconds) / 60
	var seconds = int(time_seconds) % 60
	return "%02d:%02d" % [minutes, seconds]

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

func setup_audio():
	# Create procedural sound effects
	create_tile_reveal_sound()
	create_mine_explosion_sound()
	create_game_win_sound()
	create_game_lose_sound()
	create_background_music()

func create_tile_reveal_sound():
	var stream = AudioStreamGenerator.new()
	stream.mix_rate = 22050
	stream.buffer_length = 0.1
	tile_reveal_sound.stream = stream

func create_mine_explosion_sound():
	var stream = AudioStreamGenerator.new()
	stream.mix_rate = 22050
	stream.buffer_length = 0.3
	mine_explosion_sound.stream = stream

func create_game_win_sound():
	var stream = AudioStreamGenerator.new()
	stream.mix_rate = 22050
	stream.buffer_length = 0.8
	game_win_sound.stream = stream

func create_game_lose_sound():
	var stream = AudioStreamGenerator.new()
	stream.mix_rate = 22050
	stream.buffer_length = 0.8
	game_lose_sound.stream = stream

func create_background_music():
	var stream = AudioStreamGenerator.new()
	stream.mix_rate = 22050
	stream.buffer_length = 10.0
	background_audio_stream_player.stream = stream

func play_tile_reveal_sound():
	if not tile_reveal_sound.stream:
		return
	
	tile_reveal_sound.play()
	var playback = tile_reveal_sound.get_stream_playback()
	var sample_rate = 22050
	var duration = 0.1
	var samples = int(sample_rate * duration)
	
	for i in range(samples):
		var t = float(i) / sample_rate
		var freq = 1000 - (t * 500) # Descending frequency
		var sample = sin(t * freq * 2 * PI) * (1.0 - t / duration) * 0.3
		playback.push_frame(Vector2(sample, sample))
	
	tile_reveal_sound.play()

func play_mine_explosion_sound():
	if not mine_explosion_sound.stream:
		return
	
	mine_explosion_sound.play()
	var playback = mine_explosion_sound.get_stream_playback()
	var sample_rate = 22050
	var duration = 0.3
	var samples = int(sample_rate * duration)
	
	for i in range(samples):
		var t = float(i) / sample_rate
		var noise = randf() * 2.0 - 1.0
		var envelope = sin(t * PI / duration) * exp(-t * 2.0)
		var sample = noise * envelope * 0.4
		playback.push_frame(Vector2(sample, sample))

func play_game_win_sound():
	if not game_win_sound.stream:
		return
	
	game_win_sound.play()
	var playback = game_win_sound.get_stream_playback()
	var sample_rate = 22050
	var duration = 0.8
	var samples = int(sample_rate * duration)
	
	var notes = [523.25, 659.25, 783.99, 1046.50] # C, E, G, C
	
	for i in range(samples):
		var t = float(i) / sample_rate
		var note_index = int(t * 4) % 4
		var freq = notes[note_index]
		var envelope = sin(t * PI / duration)
		var sample = sin(t * freq * 2 * PI) * envelope * 0.2
		playback.push_frame(Vector2(sample, sample))

func play_game_lose_sound():
	if not game_lose_sound.stream:
		return
	
	game_lose_sound.play()
	var playback = game_lose_sound.get_stream_playback()
	var sample_rate = 22050
	var duration = 0.8
	var samples = int(sample_rate * duration)
	
	var notes = [392.00, 329.63, 261.63, 196.00] # G, E, C, G
	
	for i in range(samples):
		var t = float(i) / sample_rate
		var note_index = int(t * 4) % 4
		var freq = notes[note_index]
		var envelope = sin(t * PI / duration)
		var sample = sin(t * freq * 2 * PI) * envelope * 0.15
		playback.push_frame(Vector2(sample, sample))
	
	game_lose_sound.play()
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
	var start_time = Time.get_unix_time_from_system()
	
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
	
	# Record generation time
	var end_time = Time.get_unix_time_from_system()
	performance_stats.generation_time = end_time - start_time

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
	
	# Position on globe surface, but offset inward to obstruct interior
	var inward_offset = pos.normalized() * 1.0 # Move 1 unit inward along normal
	tile_node.global_position = (tile_data.world_position - inward_offset)
	
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
	
	# Handle keyboard input for pause/resume
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_SPACE:
			if game_started:
				if game_paused:
					resume_game()
				else:
					pause_game()
			return # Don't process mouse input when space is pressed
		elif event.keycode == KEY_F12:
			print_performance_report()
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
	
	# Start timer on first tile reveal
	if not game_started:
		game_started = true
		game_paused = false
	
	# Play tile reveal sound
	if tile_reveal_sound:
		play_tile_reveal_sound()
	
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
		game_paused = true # Stop timer
		update_game_statistics() # Update stats for loss
		
		# Play mine explosion sound
		if mine_explosion_sound:
			play_mine_explosion_sound()
		
		# Play game lose sound
		if game_lose_sound:
			play_game_lose_sound()
		
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
	game_paused = true # Stop timer
	update_game_statistics() # Update stats for win
	
	# Play game win sound
	if game_win_sound:
		play_game_win_sound()
	
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
		var dir = Vector3(rng.randf_range(-1, 1), rng.randf_range(-1, 1), rng.randf_range(-1, 1)).normalized()
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
	mat.color = Color(1, 1, 1)
	# Color ramp for nice fade
	var grad = Gradient.new()
	grad.colors = PackedColorArray([Color(1, 1, 1), Color(1, 0, 0), Color(1, 1, 0), Color(0, 1, 1), Color(0, 0, 0, 0)])
	grad.offsets = PackedFloat32Array([0.0, 0.2, 0.5, 0.8, 1.0])
	mat.color_ramp = grad
	# Slight upward burst
	mat.direction = Vector3(0, 1, 0)
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
	# Reset timer
	reset_timer()
	generate_globe()
	place_mines()
	calculate_neighbor_counts()
	update_mine_counter()

# Statistics and timer functions
func load_game_statistics():
	var save_path = "user://game_statistics.save"
	if FileAccess.file_exists(save_path):
		var file = FileAccess.open(save_path, FileAccess.READ)
		game_statistics = file.get_var()
		file.close()

func save_game_statistics():
	var save_path = "user://game_statistics.save"
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	file.store_var(game_statistics)
	file.close()

func update_game_statistics():
	game_statistics.games_played += 1
	
	if game_won:
		game_statistics.games_won += 1
		game_statistics.current_streak += 1
		if game_statistics.current_streak > game_statistics.best_streak:
			game_statistics.best_streak = game_statistics.current_streak
		
		if game_timer < game_statistics.best_time:
			game_statistics.best_time = game_timer
	else:
		game_statistics.current_streak = 0
	
	game_statistics.total_time += game_timer
	save_game_statistics()

func pause_game():
	game_paused = true

func resume_game():
	game_paused = false

func reset_timer():
	game_timer = 0.0
	game_started = false
	game_paused = false
	ui.update_time("00:00")

# Performance monitoring functions
func update_performance_stats():
	performance_stats.fps = Performance.get_monitor(Performance.TIME_FPS)
	performance_stats.frame_time = Performance.get_monitor(Performance.TIME_PROCESS)
	performance_stats.memory_usage = Performance.get_monitor(Performance.MEMORY_STATIC)
	performance_stats.draw_calls = Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
	performance_stats.vertices = 0 # Placeholder - vertices monitoring not available in this Godot version
	performance_stats.tile_count = tiles.size()

func get_performance_report() -> String:
	update_performance_stats()
	var report = "=== Performance Report ===\n"
	report += "FPS: %d\n" % performance_stats.fps
	report += "Frame Time: %.2f ms\n" % (performance_stats.frame_time * 1000)
	report += "Memory Usage: %.2f MB\n" % (performance_stats.memory_usage / 1024 / 1024)
	report += "Draw Calls: %d\n" % performance_stats.draw_calls
	report += "Vertices: %d\n" % performance_stats.vertices
	report += "Tiles: %d\n" % performance_stats.tile_count
	report += "Generation Time: %.2f ms\n" % (performance_stats.generation_time * 1000)
	return report

func print_performance_report():
	print(get_performance_report())
