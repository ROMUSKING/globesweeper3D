extends Node3D

var is_dragging = false
var previous_mouse_position = Vector2()
@export var subdivision_level = 4 # was 1, increase for 8x density (2^3 = 8)
@export var globe_radius = 44.0 # was 3.0, 8x larger
@export var hex_size = 1.8 # reduced from 2.8 for better tile size
var camera_distance = 64.0 # was 8.0, 8x further for larger globe
var tiles = []
@export var mine_percentage = 0.15
var ui_scene = preload("res://scenes/ui.tscn")
var ui
var _cached_font = null

var revealed_material = StandardMaterial3D.new()
var flagged_material = StandardMaterial3D.new()
var hover_material = StandardMaterial3D.new()
var default_material = StandardMaterial3D.new()
var game_over = false

func _ready():
	# configure materials for clear visual feedback
	revealed_material.albedo_color = Color(0.3, 0.7, 1.0) # distinct light blue
	revealed_material.metallic = 0.0
	revealed_material.roughness = 0.3
	revealed_material.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
	revealed_material.cull_mode = BaseMaterial3D.CULL_BACK
	flagged_material.albedo_color = Color(1.0, 0.2, 0.2)
	flagged_material.metallic = 0.0
	flagged_material.roughness = 0.6
	flagged_material.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
	flagged_material.cull_mode = BaseMaterial3D.CULL_BACK
	hover_material.albedo_color = Color(0.8, 0.8, 0.2) # Yellowish color for hover
	hover_material.metallic = 0.0
	hover_material.roughness = 0.3
	hover_material.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
	hover_material.cull_mode = BaseMaterial3D.CULL_BACK
	default_material.albedo_color = Color(0.7, 0.7, 0.7) # Gray for unrevealed tiles
	default_material.metallic = 0.0
	default_material.roughness = 0.5
	default_material.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
	default_material.cull_mode = BaseMaterial3D.CULL_BACK
	
	ui = ui_scene.instantiate()
	add_child(ui)
	$Timer.timeout.connect(_on_timer_timeout)
	# Position camera further back to fit the larger globe
	if $Camera3D:
		$Camera3D.global_transform.origin = Vector3(0, 0, camera_distance)
	
	_cached_font = Control.new().get_theme_default_font()
	if _cached_font == null:
		push_error("Failed to load default font for tile numbers!")
	
	var game_over_timer = Timer.new()
	game_over_timer.name = "GameOverTimer"
	add_child(game_over_timer)
	game_over_timer.one_shot = true
	game_over_timer.timeout.connect(_on_game_over_delay_timeout)
	
	reset_game()

func _on_timer_timeout():
	if not game_over:
		game_over = true
		$GameOverTimer.start(1.0) # 1 second delay

func _process(_delta):
	if not game_over and $Timer.time_left > 0:
		ui.update_time(int($Timer.time_left))
	elif not game_over and $Timer.time_left <= 0:
		game_over = true
		ui.show_game_over("Time's Up!")

func reset_game():
	game_over = false
	$Timer.start()
	generate_icosahedron()
	place_mines()
	calculate_neighbor_mines()
	update_mine_count()

func _input(event):
	if game_over:
		return

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				is_dragging = true
				previous_mouse_position = event.position
			else:
				is_dragging = false
				if event.position.distance_to(previous_mouse_position) < 5:
					handle_left_click(event.position)
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			handle_right_click(event.position)

	if event is InputEventMouseMotion and is_dragging:
		var delta = event.position - previous_mouse_position
		previous_mouse_position = event.position

		# Rotate the Globe node instead of the Main node so the camera stays fixed
		if $Globe:
			$Globe.rotate_y(deg_to_rad(-delta.x * 0.5))
			$Globe.rotate_x(deg_to_rad(-delta.y * 0.5))

func handle_left_click(mouse_pos):
	var tile = get_tile_from_mouse_pos(mouse_pos)
	if tile and not tile.is_revealed and not tile.is_flagged:
		reveal_tile(tile)

func handle_right_click(mouse_pos):
	var tile = get_tile_from_mouse_pos(mouse_pos)
	if tile and not tile.is_revealed:
		tile.is_flagged = not tile.is_flagged
		update_tile_visual(tile)
		update_mine_count()

func update_mine_count():
	var mine_count = 0
	var flag_count = 0
	for tile in tiles:
		if tile.has_mine:
			mine_count += 1
		if tile.is_flagged:
			flag_count += 1
	ui.update_mines(mine_count - flag_count)

func reveal_tile(tile):
	tile.is_revealed = true
	update_tile_visual(tile)

	if tile.has_mine:
		game_over = true
		$Timer.stop()
		# Reveal all mines when game is over
		for t in tiles:
			if t.has_mine:
				t.is_revealed = true
				update_tile_visual(t)
				set_tile_decal_number(t, "*")
		$GameOverTimer.start(1.0) # 1 second delay
		return

	if tile.neighbor_mines > 0:
		set_tile_decal_number(tile, str(tile.neighbor_mines))
	else: # flood fill
		for neighbor_index in tile.neighbors:
			var neighbor = tiles[neighbor_index]
			if not neighbor.is_revealed and not neighbor.is_flagged:
				reveal_tile(neighbor)

	check_win_condition()

# Helper to draw a number or symbol onto a Decal as a texture
func set_tile_decal_number(tile, text):
		# Remove existing label if present
		if tile.label and is_instance_valid(tile.label):
			tile.label.queue_free()

		var label3d = Label3D.new()
		label3d.text = text
		label3d.font_size = 48
		label3d.pixel_size = 0.02
		label3d.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label3d.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label3d.set_draw_flag(Label3D.FLAG_DOUBLE_SIDED, false)
		label3d.billboard = BaseMaterial3D.BILLBOARD_DISABLED
		label3d.modulate = Color(1, 1, 1, 1) # White text
		label3d.set_draw_flag(Label3D.FLAG_DISABLE_DEPTH_TEST, false)
		label3d.alpha_cut = Label3D.ALPHA_CUT_OPAQUE_PREPASS

		# Position label slightly above the tile surface in local space
		label3d.position = Vector3(0, 0, 0.05)
		# Orient the label to face the same direction as the tile
		label3d.rotation = Vector3.ZERO

		tile.node.add_child(label3d)
		tile.label = label3d

func check_win_condition():
	for tile in tiles:
		if not tile.has_mine and not tile.is_revealed:
			return # game not won yet

	game_over = true
	$Timer.stop()
	ui.show_game_over("You Win!")

func _on_game_over_delay_timeout():
	if $Timer.time_left <= 0: # Check if it was a time-out game over
		ui.show_game_over("Time's Up!")
	else:
		ui.show_game_over("Game Over!")

func update_tile_visual(tile):
	var tile_node = $Globe.get_node("Tile" + str(tile.index))
	var mesh_instance = tile_node.get_child(0)
	if tile.is_revealed:
		mesh_instance.material_override = revealed_material
	elif tile.is_flagged:
		mesh_instance.material_override = flagged_material
	else:
		mesh_instance.material_override = default_material

func get_tile_from_mouse_pos(mouse_pos):
	var camera = $Camera3D
	if not camera:
		return null
		
	var from = camera.project_ray_origin(mouse_pos)
	var to = from + camera.project_ray_normal(mouse_pos) * 1000
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(from, to, 1)
	var result = space_state.intersect_ray(query)

	if result and result.has("collider"):
		var node = result.collider
		# climb up the parent chain in case the collider is a child (MeshInstance3D)
		while node and not node.name.begins_with("Tile"):
			if node.get_parent() != null:
				node = node.get_parent()
			else:
				node = null
				break
		if node:
			var index_str = node.name.substr(4)
			if index_str.is_valid_int():
				var index = int(index_str)
				if index >= 0 and index < tiles.size():
					return tiles[index]
	return null

func generate_icosahedron():
	var vertices = [
		Vector3(-0.525731, 0.850651, 0.0), Vector3(0.525731, 0.850651, 0.0),
		Vector3(-0.525731, -0.850651, 0.0), Vector3(0.525731, -0.850651, 0.0),
		Vector3(0.0, -0.525731, 0.850651), Vector3(0.0, 0.525731, 0.850651),
		Vector3(0.0, -0.525731, -0.850651), Vector3(0.0, 0.525731, -0.850651),
		Vector3(0.850651, 0.0, -0.525731), Vector3(0.850651, 0.0, 0.525731),
		Vector3(-0.850651, 0.0, -0.525731), Vector3(-0.850651, 0.0, 0.525731)
	]

	var indices = [
		0, 11, 5, 0, 5, 1, 0, 1, 7, 0, 7, 10, 0, 10, 11,
		1, 5, 9, 5, 11, 4, 11, 10, 2, 10, 7, 6, 7, 1, 8,
		3, 9, 4, 3, 4, 2, 3, 2, 6, 3, 6, 8, 3, 8, 9,
		4, 9, 5, 2, 4, 11, 6, 2, 10, 8, 6, 7, 9, 8, 1
	]

	for i in range(subdivision_level):
		var new_data = subdivide(vertices, indices)
		vertices = new_data[0]
		indices = new_data[1]

	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var unique_vertices = []
	var unique_indices = {}
	var final_indices = []

	for i in range(vertices.size()):
		var v = vertices[i]
		var found = false
		for j in range(unique_vertices.size()):
			if v.is_equal_approx(unique_vertices[j]):
				unique_indices[i] = j
				found = true
				break
		if not found:
			unique_indices[i] = unique_vertices.size()
			unique_vertices.append(v)

	for i in range(indices.size()):
		final_indices.append(unique_indices[indices[i]])
		st.add_vertex(vertices[indices[i]])

	st.generate_normals()
	st.commit()

	create_tiles(unique_vertices, final_indices)

func create_tiles(vertices, indices):
	for c in $Globe.get_children():
		c.queue_free()
	tiles.clear()

	for i in range(vertices.size()):
		var tile = load("res://scripts/tile.gd").new(i, vertices[i])
		tiles.append(tile)

		var tile_node = StaticBody3D.new()
		tile_node.name = "Tile" + str(i)
		tile_node.collision_layer = 1
		tile_node.collision_mask = 1
		$Globe.add_child(tile_node)
		# Place tiles on a larger sphere by scaling the normalized vertex by globe_radius
		tile_node.global_transform.origin = tile.position * globe_radius

		# Store the tile_node for later use in set_tile_decal_number
		tile.node = tile_node
		tile.label = null
		
		var mesh_instance = MeshInstance3D.new()
		mesh_instance.mesh = generate_hexagon_mesh(hex_size)
		tile_node.add_child(mesh_instance)
		# Orient the tile so its normal points outward from the sphere center
		var normal = tile.position.normalized()
		var up = Vector3.UP
		if abs(normal.dot(up)) > 0.999: # Use a higher threshold for robustness
			up = Vector3.FORWARD
		var right = up.cross(normal).normalized()
		var new_up = normal.cross(right).normalized()
		var new_basis = Basis(right, new_up, normal)
		tile_node.global_transform.basis = new_basis

		var collision_shape = CollisionShape3D.new()
		var shape
		# If the generated mesh has faces available use them, otherwise fallback to a small sphere
		if mesh_instance.mesh and mesh_instance.mesh.get_faces().size() > 0:
			shape = ConvexPolygonShape3D.new()
			shape.points = mesh_instance.mesh.get_faces()
		else:
			shape = SphereShape3D.new()
			shape.radius = hex_size * 0.1 # A small sphere
		collision_shape.shape = shape
		tile_node.add_child(collision_shape)

		tile_node.mouse_entered.connect(_on_tile_mouse_entered.bind(tile_node))
		tile_node.mouse_exited.connect(_on_tile_mouse_exited.bind(tile_node))


	# Initialize neighbors as Dictionaries for faster lookups
	for tile in tiles:
		tile.neighbors = {}

	for i in range(0, indices.size(), 3):
		var i1 = indices[i]
		var i2 = indices[i + 1]
		var i3 = indices[i + 2]

		tiles[i1].neighbors[i2] = true
		tiles[i1].neighbors[i3] = true
		tiles[i2].neighbors[i1] = true
		tiles[i2].neighbors[i3] = true
		tiles[i3].neighbors[i1] = true
		tiles[i3].neighbors[i2] = true

	# Convert neighbor Dictionaries to Arrays
	for tile in tiles:
		tile.neighbors = tile.neighbors.keys()


func subdivide(vertices, indices):
	var new_vertices = vertices
	var new_indices = []
	var midpoints = {}

	for i in range(0, indices.size(), 3):
		var i1 = indices[i]
		var i2 = indices[i + 1]
		var i3 = indices[i + 2]

		var m1 = get_midpoint(i1, i2, new_vertices, midpoints)
		var m2 = get_midpoint(i2, i3, new_vertices, midpoints)
		var m3 = get_midpoint(i3, i1, new_vertices, midpoints)

		new_indices.append_array([
			i1, m1, m3,
			m1, i2, m2,
			m3, m2, i3,
			m1, m2, m3
		])

	return [new_vertices, new_indices]

func get_midpoint(i1, i2, vertices, midpoints):
	var key = [min(i1, i2), max(i1, i2)]
	if not midpoints.has(key):
		var v1 = vertices[i1]
		var v2 = vertices[i2]
		var mid = (v1 + v2) / 2.0
		vertices.append(mid.normalized())
		midpoints[key] = vertices.size() - 1
	return midpoints[key]

func generate_hexagon_mesh(size):
	var vertices = []
	var center = Vector3.ZERO
	
	# Add center vertex
	vertices.append(center)
	
	# Add outer vertices
	for i in range(6):
		var angle = 2 * PI * i / 6
		vertices.append(Vector3(size * cos(angle), size * sin(angle), 0))

	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	# Create triangles from center to each edge
	for i in range(6):
		var next = (i + 1) % 6
		st.add_vertex(vertices[0]) # center
		st.add_vertex(vertices[i + 1]) # current vertex
		st.add_vertex(vertices[next + 1]) # next vertex

	st.generate_normals()
	return st.commit()

# Helper to avoid colinear target/up vectors when calling look_at
func safe_look_at(node: Node3D, target: Vector3, up := Vector3.UP):
	var dir = (target - node.global_transform.origin)
	if dir.length() == 0:
		return
	var forward = dir.normalized()
	# if forward is nearly parallel to up, pick an alternative up vector
	if abs(forward.dot(up)) > 0.999:
		up = Vector3(0, 0, 1)
		if abs(forward.dot(up)) > 0.999:
			up = Vector3(1, 0, 0)
	node.look_at(target, up)

func place_mines():
	if tiles.size() == 0:
		push_error("No tiles available for mine placement")
		return
		
	var num_mines = int(tiles.size() * mine_percentage)
	num_mines = min(num_mines, tiles.size() - 1) # Ensure at least one safe tile
	
	var tiles_copy = tiles.duplicate()
	tiles_copy.shuffle()
	
	for i in range(num_mines):
		tiles_copy[i].has_mine = true

func calculate_neighbor_mines():
	for tile in tiles:
		if not tile.has_mine:
			var mine_count = 0
			for neighbor_index in tile.neighbors:
				if neighbor_index >= 0 and neighbor_index < tiles.size():
					if tiles[neighbor_index].has_mine:
						mine_count += 1
				else:
					push_error("Invalid neighbor index: " + str(neighbor_index))
			tile.neighbor_mines = mine_count

func _on_tile_mouse_entered(tile_node):
	var tile_data = tiles[int(tile_node.name.substr(4))]
	if not tile_data.is_revealed and not tile_data.is_flagged:
		var mesh_instance = tile_node.get_child(0)
		mesh_instance.material_override = hover_material

func _on_tile_mouse_exited(tile_node):
	var tile_data = tiles[int(tile_node.name.substr(4))]
	if not tile_data.is_revealed and not tile_data.is_flagged:
		var mesh_instance = tile_node.get_child(0)
		mesh_instance.material_override = null # Revert to default material
