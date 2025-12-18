extends Node3D

# Globe Minesweeper - Clean Implementation
@export var globe_radius: float = 20.0
@export var subdivision_level: int = 3
@export var mine_percentage: float = 0.15
@export var tile_scale: float = 1.8

var tiles: Array = []
const GlobeGeneratorScript = preload("res://scripts/globe_generator.gd")
const AudioManagerScript = preload("res://scripts/audio_manager.gd")
var globe_generator
var audio_manager
var game_over: bool = false
var game_won: bool = false
var ui_scene = preload("res://scenes/ui.tscn")
var ui

# Timer and statistics
var game_timer: float = 0.0
var game_paused: bool = false
var game_started: bool = false
var mines_placed: bool = false
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
	ui.game_reset_requested.connect(reset_game)
	add_child(ui)
	
	globe_generator = GlobeGeneratorScript.new()
	add_child(globe_generator)
	
	# Initialize audio manager
	audio_manager = AudioManagerScript.new()
	add_child(audio_manager)
	
	# Ensure a container for fireworks exists
	if not has_node("Fireworks"):
		var fw = Node3D.new()
		fw.name = "Fireworks"
		add_child(fw)
	
	# Position camera
	$Camera3D.position = Vector3(0, 0, globe_radius * 3)
	
	# Start game
	generate_globe()
	mines_placed = false
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

func generate_globe():
	# Clear existing tiles
	for child in $Globe.get_children():
		child.free()
	tiles.clear()
	
	var result = globe_generator.generate($Globe, globe_radius, subdivision_level, unrevealed_material)
	tiles = result.tiles
	hex_radius = result.hex_radius
	performance_stats.generation_time = result.generation_time

func place_mines(excluded_tile_index: int = -1):
	var num_mines = int(tiles.size() * mine_percentage)
	var available_tiles = []
	
	var excluded_indices = {}
	if excluded_tile_index != -1:
		excluded_indices[excluded_tile_index] = true
		# Also exclude neighbors for a safe start area
		for neighbor_idx in tiles[excluded_tile_index].neighbors:
			excluded_indices[neighbor_idx] = true
	
	for i in range(tiles.size()):
		if not i in excluded_indices:
			available_tiles.append(i)
	
	available_tiles.shuffle()
	
	var mines_to_place = min(num_mines, available_tiles.size())
	for i in range(mines_to_place):
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
	
	if not mines_placed:
		# If mines aren't placed yet, use the theoretical count
		total_mines = int(tiles.size() * mine_percentage)
	else:
		for tile in tiles:
			if tile.has_mine:
				total_mines += 1
	
	var flagged_count = 0
	for tile in tiles:
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
	
	# First click safety: generate mines if not yet placed
	if not mines_placed:
		place_mines(tile.index)
		calculate_neighbor_counts()
		mines_placed = true
		update_mine_counter()
	
	tile.is_revealed = true
	
	# Start timer on first tile reveal
	if not game_started:
		game_started = true
		game_paused = false
	
	# Play tile reveal sound
	audio_manager.play_reveal_sound()
	
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
		audio_manager.play_explosion_sound()
		
		# Play game lose sound
		audio_manager.play_lose_sound()
		
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
	audio_manager.play_win_sound()
	
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
	mines_placed = false
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
