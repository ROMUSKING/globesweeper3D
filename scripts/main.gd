extends Node3D

# Globe Minesweeper - Clean Implementation
# Difficulty settings
enum DifficultyLevel {EASY, MEDIUM, HARD}
@export var difficulty_level: DifficultyLevel = DifficultyLevel.MEDIUM

# Game parameters that will be adjusted based on difficulty
@export var globe_radius: float = 20.0
@export var subdivision_level: int = 3
@export var mine_percentage: float = 0.15
@export var tile_scale: float = 1.8

var tiles: Array = []
const GlobeGeneratorScript = preload("res://scripts/globe_generator.gd")
const AudioManagerScript = preload("res://scripts/audio_manager.gd")
const InteractionManagerScript = preload("res://scripts/interaction_manager.gd")
const PowerupManagerScript = preload("res://scripts/powerup_manager.gd")
const GameStateManagerScript = preload("res://scripts/game_state_manager.gd")
const DifficultyScalingManagerScript = preload("res://scripts/difficulty_scaling_manager.gd")
const ScoringSystemScript = preload("res://scripts/scoring_system.gd")
const SoundVFXManagerScript = preload("res://scripts/sound_vfx_manager.gd")
const VFXSystemScript = preload("res://scripts/vfx_system.gd")
const CURSOR_SCENE = preload("res://scenes/cursor.tscn")
var globe_generator
var audio_manager
var powerup_manager
var game_state_manager
var difficulty_scaling_manager
var scoring_system
var sound_vfx_manager
var vfx_system
var ui_scene = preload("res://scenes/ui.tscn")
var ui

# Timer and statistics
var game_timer: float = 0.0
var game_started: bool = false
var mines_placed: bool = false
var game_statistics = {
	"games_played": 0,
	"games_won": 0,
	"best_time": 9999.0,
	"total_time": 0.0,
	"current_streak": 0,
	"best_streak": 0,
	"high_score": 0,
	"best_efficiency": 0.0,
	"best_streak_score": 0
}

# Current game scoring variables
var current_game_score: int = 0
var safe_tiles_revealed: int = 0
var total_safe_tiles: int = 0
var flags_used: int = 0
var correct_flags: int = 0

# Powerup system variables
var reveal_protection_count: int = 0
var timer_frozen: bool = false
var timer_freeze_remaining: float = 0.0

# Input state
var interaction_manager
var cursor: Node3D
var hovered_tile_index: int = -1

# Camera and Game Feel State
var rotation_velocity: Vector2 = Vector2.ZERO
const ROTATION_FRICTION: float = 2.5 # Adjusted for time-based lerp
const ROTATION_SENSITIVITY: float = 0.003
var is_dragging_globe: bool = false
var target_zoom: float = 60.0
var current_zoom: float = 60.0
const ZOOM_SPEED: float = 5.0
var shake_strength: float = 0.0
const SHAKE_DECAY: float = 5.0

# Hex tile sizing (computed to make edges touch)
var hex_radius: float = 0.9

# Materials
var tile_material_template: ShaderMaterial
const TILE_SHADER = preload("res://shaders/tile.gdshader")

const NEIGHBOR_COLORS = [
	Color(0.8, 0.8, 0.8), # 0 - unused
	Color(0.2, 0.6, 1.0), # 1 - blue
	Color(0.2, 0.8, 0.2), # 2 - green
	Color(1.0, 1.0, 0.2), # 3 - yellow
	Color(0.6, 0.2, 0.6), # 4 - purple
	Color(0.2, 0.8, 0.8), # 5 - cyan
	Color(0.8, 0.8, 0.2), # 6 - yellow
	Color(0.5, 0.5, 0.5), # 7 - gray
	Color(0.4, 0.2, 1.0) # 8 - violet
]

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
	
	# Initialize Game State Manager first
	game_state_manager = GameStateManagerScript.new()
	add_child(game_state_manager)
	game_state_manager.state_changed.connect(_on_game_state_changed)
	game_state_manager.state_entered.connect(_on_game_state_entered)
	game_state_manager.game_paused.connect(_on_game_paused)
	game_state_manager.game_resumed.connect(_on_game_resumed)
	game_state_manager.main_menu_requested.connect(_on_main_menu_requested)
	
	# Initialize VFX System
	vfx_system = VFXSystemScript.new()
	add_child(vfx_system)
	
	# Initialize Sound/VFX Event Manager
	sound_vfx_manager = SoundVFXManagerScript.new()
	add_child(sound_vfx_manager)
	
	ui = ui_scene.instantiate()
	ui.start_game_requested.connect(_on_start_game_requested)
	ui.restart_game_requested.connect(reset_game)
	ui.menu_requested.connect(_on_menu_requested)
	ui.difficulty_selected.connect(_on_difficulty_selected)
	ui.pause_requested.connect(_on_pause_requested)
	ui.resume_requested.connect(_on_resume_requested)
	ui.settings_requested.connect(_on_settings_requested)
	ui.settings_closed.connect(_on_settings_closed)
	ui.powerup_purchased_ui.connect(_on_powerup_purchased_ui)
	ui.powerup_activated_ui.connect(_on_powerup_activated_ui)
	ui.difficulty_scaling_toggled.connect(_on_difficulty_scaling_toggled)
	ui.difficulty_scaling_mode_changed.connect(_on_difficulty_scaling_mode_changed)
	ui.difficulty_reset_requested.connect(_on_difficulty_reset_requested)
	ui.difficulty_rollback_requested.connect(_on_difficulty_rollback_requested)
	add_child(ui)
	
	# Connect UI to Game State Manager
	ui.set_game_state_manager_reference(game_state_manager)
	
	globe_generator = GlobeGeneratorScript.new()
	add_child(globe_generator)
	
	# Initialize audio manager
	audio_manager = AudioManagerScript.new()
	add_child(audio_manager)
	
	# Inject audio manager reference into game state manager
	game_state_manager.set_audio_manager_ref(audio_manager)
	
	# Initialize Sound/VFX Event Manager after audio manager is ready
	sound_vfx_manager.initialize({
		"audio_manager": audio_manager,
		"vfx_system": vfx_system,
		"game_state_machine": game_state_manager,
		"scoring_system": game_statistics,
		"interaction_manager": interaction_manager
	})

	# Initialize powerup manager
	powerup_manager = PowerupManagerScript.new()
	add_child(powerup_manager)
	powerup_manager.set_main_script_reference(self)
	powerup_manager.score_deducted.connect(_on_score_deducted)
	powerup_manager.powerup_activated.connect(_on_powerup_activated)
	
	# Initialize difficulty scaling manager
	difficulty_scaling_manager = DifficultyScalingManagerScript.new()
	add_child(difficulty_scaling_manager)
	# Set difficulty scaling manager reference after initialization
	powerup_manager.set_difficulty_scaling_manager_reference(difficulty_scaling_manager)
	difficulty_scaling_manager.set_main_script_reference(self)
	difficulty_scaling_manager.set_powerup_manager_reference(powerup_manager)
	difficulty_scaling_manager.set_game_state_manager_reference(game_state_manager)
	difficulty_scaling_manager.difficulty_changed.connect(_on_difficulty_changed)
	difficulty_scaling_manager.player_skill_assessed.connect(_on_player_skill_assessed)
	
	# Initialize scoring system
	scoring_system = ScoringSystemScript.new()
	add_child(scoring_system)
	scoring_system.set_game_state_manager_reference(game_state_manager)
	scoring_system.set_difficulty_scaling_manager_reference(difficulty_scaling_manager)
	scoring_system.score_updated.connect(_on_score_updated)
	scoring_system.high_score_updated.connect(_on_high_score_updated)
	
	# Initialize interaction manager
	interaction_manager = InteractionManagerScript.new()
	add_child(interaction_manager)
	interaction_manager.tile_hovered.connect(_on_tile_hovered)
	interaction_manager.tile_clicked.connect(_on_tile_clicked)
	interaction_manager.drag_started.connect(func(): is_dragging_globe = true)
	interaction_manager.drag_ended.connect(func(): is_dragging_globe = false)
	interaction_manager.drag_active.connect(_on_globe_dragged)
	interaction_manager.zoom_changed.connect(_on_zoom_changed)
	# Connect powerup activation signals
	interaction_manager.powerup_activation_requested.connect(_on_powerup_activation_requested)
	interaction_manager.powerup_hover_requested.connect(_on_powerup_hover_requested)
	
	# Connect interaction manager to Game State Manager
	interaction_manager.set_game_state_manager_reference(game_state_manager)
	
	# Connect UI to powerup manager
	ui.set_powerup_manager_reference(powerup_manager)
	
	# Connect UI to difficulty scaling manager
	ui.set_difficulty_scaling_manager_reference(difficulty_scaling_manager)
	
	# Initialize cursor
	cursor = CURSOR_SCENE.instantiate()
	add_child(cursor)
	cursor.visible = false
	
	# Ensure a container for fireworks exists
	if not has_node("Fireworks"):
		var fw = Node3D.new()
		fw.name = "Fireworks"
		add_child(fw)
	
	# Position camera
	target_zoom = globe_radius * 3
	current_zoom = target_zoom
	$Camera3D.position = Vector3(0, 0, current_zoom)
	
	# Apply difficulty settings
	apply_difficulty_settings()
	
	# Start game
	load_game_statistics()

func _process(delta):
	if game_state_manager.is_playing():
		if game_started:
			# Handle timer freeze - timer only advances when not frozen and not paused
			if not timer_frozen:
				game_timer += delta
			else:
				timer_freeze_remaining -= delta
				if timer_freeze_remaining <= 0.0:
					timer_frozen = false
					timer_freeze_remaining = 0.0
				
			ui.update_time(format_time(game_timer))
			
			# Update score display
	if scoring_system:
		ui.update_score(scoring_system.get_current_score())
			
		# Update powerup manager cooldowns
		if powerup_manager:
			powerup_manager.update_cooldowns(delta)
			
		update_mine_counter()
	elif game_state_manager.is_paused():
		# Update powerup manager cooldowns even when paused
		if powerup_manager:
			powerup_manager.update_cooldowns(delta)
		# Timer doesn't advance when paused
	
	# Update cursor position to follow rotating tile
	if hovered_tile_index != -1 and hovered_tile_index < tiles.size():
		var tile = tiles[hovered_tile_index]
		if is_instance_valid(tile.node):
			cursor.global_position = tile.node.global_position
			cursor.global_basis = tile.node.global_basis
			cursor.translate_object_local(Vector3(0, 0.01, 0))

	_process_camera_feel(delta)
	
	# Process Sound/VFX events
	if sound_vfx_manager:
		sound_vfx_manager.process_events(delta)
	
	# Update performance stats every frame
	update_performance_stats()

func _process_camera_feel(delta):
	# Auto-rotate in menu
	if game_state_manager.is_state(game_state_manager.GameState.MENU):
		$Globe.rotate_y(0.1 * delta)
		
	# Apply rotation momentum only when not dragging
	if not is_dragging_globe and rotation_velocity.length_squared() > 0.000001:
		# Scale rotation by delta to maintain consistent speed across framerates
		# Assuming velocity is captured as "movement per tick", we normalize with 60FPS reference
		var frame_adjust = delta * 60.0
		$Globe.rotate_y(rotation_velocity.x * frame_adjust)
		$Globe.rotate_x(rotation_velocity.y * frame_adjust)
		
		# Time-step independent friction
		rotation_velocity = rotation_velocity.lerp(Vector2.ZERO, delta * ROTATION_FRICTION)
		
		# Stop if very slow
		if rotation_velocity.length() < 0.0001:
			rotation_velocity = Vector2.ZERO
			
	# Apply zoom smoothing
	if abs(current_zoom - target_zoom) > 0.01:
		current_zoom = lerp(current_zoom, target_zoom, delta * ZOOM_SPEED)
		$Camera3D.position.z = current_zoom
	
	# Apply screen shake
	if shake_strength > 0.01:
		shake_strength = lerp(shake_strength, 0.0, SHAKE_DECAY * delta)
		$Camera3D.h_offset = randf_range(-shake_strength, shake_strength)
		$Camera3D.v_offset = randf_range(-shake_strength, shake_strength)
	else:
		$Camera3D.h_offset = 0
		$Camera3D.v_offset = 0

func format_time(time_seconds: float) -> String:
	var minutes = int(time_seconds / 60.0)
	var seconds = int(time_seconds) % 60
	return "%02d:%02d" % [minutes, seconds]

func setup_materials():
	tile_material_template = ShaderMaterial.new()
	tile_material_template.shader = TILE_SHADER

func generate_globe():
	# Clear existing tiles
	for child in $Globe.get_children():
		child.free()
	tiles.clear()
	
	var result = globe_generator.generate($Globe, globe_radius, subdivision_level, tile_material_template)
	tiles = result.tiles
	hex_radius = result.hex_radius
	performance_stats.generation_time = result.generation_time
	
	# Apply tile scale to all tiles
	apply_tile_scale()

func apply_tile_scale():
	"""Applies the tile_scale export variable to all generated tiles"""
	for tile in tiles:
		if is_instance_valid(tile.node):
			tile.node.scale = Vector3(tile_scale, tile_scale, tile_scale)

func place_mines(excluded_tile_index: int = -1):
	var num_mines = int(tiles.size() * mine_percentage)
	var available_tiles = []
	
	var excluded_indices = {}
	if excluded_tile_index != -1:
		excluded_indices[excluded_tile_index] = true
		# Enhanced safe-start guarantee: exclude a larger area around the first click
		for neighbor_idx in tiles[excluded_tile_index].neighbors:
			excluded_indices[neighbor_idx] = true
			# Also exclude neighbors of neighbors for better safe start
			for second_level_neighbor_idx in tiles[neighbor_idx].neighbors:
				excluded_indices[second_level_neighbor_idx] = true
	
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
	# Handle debug keys and pause
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_F12:
			print_performance_report()
		elif event.keycode == KEY_ESCAPE:
			# Toggle pause state
			game_state_manager.toggle_pause()

func _on_tile_hovered(index: int):
	hovered_tile_index = index
	if index != -1 and index < tiles.size():
		cursor.visible = true
		# Position update will happen in _process
	else:
		cursor.visible = false

func _on_tile_clicked(index: int, button_index: int):
	if not game_state_manager.can_interact():
		return
		
	var tile = tiles[index]
	
	if button_index == MOUSE_BUTTON_LEFT:
		if tile.is_revealed and tile.neighbor_mines > 0:
			# Chord functionality: click on revealed number to reveal neighbors
			var chord_success = chord_reveal(tile)
			track_player_action("chord", chord_success, {"tiles_revealed": chord_success})
		else:
			# Use protection check for left clicks
			var reveal_success = reveal_tile_with_protection_check(tile)
			track_player_action("reveal", reveal_success, {"tile_index": index})
	elif button_index == MOUSE_BUTTON_RIGHT:
		var flag_success = toggle_flag(tile)
		track_player_action("flag", flag_success, {"tile_index": index})
		
		# Update scoring system for flag placement
		if scoring_system:
			scoring_system.record_flag_placement(flag_success)
		
		# Trigger streak update event through Sound/VFX Event Manager
		if scoring_system:
			var current_streak = game_statistics.current_streak
			var best_streak = game_statistics.best_streak
			sound_vfx_manager.trigger_event(
				SoundVFXEventManager.EventType.STREAK_UPDATE,
				{
					"new_streak": current_streak,
					"best_streak": best_streak
				}
			)

func _on_globe_dragged(relative: Vector2):
	# Direct manipulation
	# Inverted controls: drag right -> globe rotates right
	var drag_rot = relative * ROTATION_SENSITIVITY
	$Globe.rotate_y(drag_rot.x)
	$Globe.rotate_x(drag_rot.y)
	
	# Store velocity for momentum on release
	rotation_velocity = drag_rot
	
	# Trigger globe rotation event through Sound/VFX Event Manager
	sound_vfx_manager.trigger_event(
		SoundVFXEventManager.EventType.GLOBE_ROTATION,
		{"rotation_speed": relative.length()}
	)

func _on_zoom_changed(amount: float):
	target_zoom += amount * 5.0
	target_zoom = clamp(target_zoom, globe_radius * 1.2, globe_radius * 5.0)
	
	# Trigger zoom change event through Sound/VFX Event Manager
	sound_vfx_manager.trigger_event(
		SoundVFXEventManager.EventType.ZOOM_CHANGE,
		{"zoom_level": target_zoom}
	)

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
		
	# Track safe tiles revealed for scoring
	if not tile.has_mine:
		safe_tiles_revealed += 1
		
	# Start timer on first tile reveal
	if not game_started:
		game_started = true
		
		# Trigger first click event through Sound/VFX Event Manager
		sound_vfx_manager.trigger_event(
			SoundVFXEventManager.EventType.FIRST_CLICK,
			{"position": tile.world_position}
		)
		
	# Trigger tile reveal event through Sound/VFX Event Manager
	sound_vfx_manager.trigger_event(
		SoundVFXEventManager.EventType.TILE_REVEAL,
		{
			"tile_index": tile.index,
			"has_mine": tile.has_mine,
			"neighbor_mines": tile.neighbor_mines,
			"position": tile.world_position
		}
	)
		
	# Animate reveal if it's a safe tile
	if not tile.has_mine:
		var mesh = tile.mesh
		var tween = create_tween()
		tween.tween_property(mesh, "scale", Vector3(1, 0.1, 1), 0.1)
		tween.tween_callback(func(): _apply_reveal_visuals(tile))
		tween.tween_property(mesh, "scale", Vector3(1, 1.1, 1), 0.1)
		tween.tween_property(mesh, "scale", Vector3.ONE, 0.1)
		
	if tile.has_mine:
		# Game over
		update_game_statistics(false) # Update stats for loss
		
		# Record game end for difficulty scaling
		if difficulty_scaling_manager:
			difficulty_scaling_manager.record_game_end(false, game_timer, current_game_score)
		 
		# Update scoring system for game end
		if scoring_system:
			scoring_system.calculate_final_score(game_timer, false)
			scoring_system.calculate_performance_metrics(game_timer)
		 
		# Trigger screen shake
		shake_strength = 2.5
		
		# Trigger mine explosion event through Sound/VFX Event Manager
		sound_vfx_manager.trigger_event(
			SoundVFXEventManager.EventType.MINE_EXPLOSION,
			{"position": tile.world_position},
			SoundVFXEventManager.EventPriority.HIGH
		)
		
		# Trigger game lose event through Sound/VFX Event Manager
		sound_vfx_manager.trigger_event(
			SoundVFXEventManager.EventType.GAME_LOSE,
			{},
			SoundVFXEventManager.EventPriority.HIGH
		)
		
		reveal_all_mines()
		game_state_manager.end_game(false)
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

func chord_reveal(tile) -> bool:
	"""Returns true if chord reveal was successful"""
	# Only proceed if the tile is already revealed and has a number
	if not tile.is_revealed or tile.neighbor_mines <= 0:
		return false

	# Count flags around
	var flag_count = 0
	for neighbor_idx in tile.neighbors:
		if tiles[neighbor_idx].is_flagged:
			flag_count += 1

	# Only chord when placed flags equal the number
	if flag_count != tile.neighbor_mines:
		return false

	# Reveal all unflagged, unrevealed neighbors
	var revealed_count = 0
	for neighbor_idx in tile.neighbors:
		var n = tiles[neighbor_idx]
		if not n.is_flagged and not n.is_revealed:
			reveal_tile(n)
			revealed_count += 1

	# Add bonus points for successful chord reveals
	if revealed_count > 0:
		# Update scoring system for chord reveal
		if scoring_system:
			scoring_system.record_chord_reveal(true)
		
	# Trigger chord reveal event through Sound/VFX Event Manager
	sound_vfx_manager.trigger_event(
		SoundVFXEventManager.EventType.CHORD_REVEAL,
		{
			"position": tile.world_position,
			"tile_count": revealed_count
		}
	)
	
	return revealed_count > 0 # Success if any tiles were revealed

func toggle_flag(tile) -> bool:
	"""Returns true if flag action was successful"""
	if tile.is_revealed:
		return false
		
	tile.is_flagged = not tile.is_flagged
		
	# Track flag usage for scoring
	flags_used += 1
	if tile.is_flagged and tile.has_mine:
		correct_flags += 1
	elif not tile.is_flagged and tile.has_mine:
		correct_flags -= 1
		
	var mat = tile.mesh.material_override as ShaderMaterial
	if mat:
		if tile.is_flagged:
			mat.set_shader_parameter("u_state", 2.0) # Flagged
		else:
			mat.set_shader_parameter("u_state", 0.0) # Unrevealed
		
	# Animate flag toggle
	var mesh = tile.mesh
	var tween = create_tween()
	tween.tween_property(mesh, "scale", Vector3(1.2, 1.2, 1.2), 0.1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(mesh, "scale", Vector3.ONE, 0.1)
		
	update_mine_counter()
	
	# Return success based on whether flag placement was correct
	return (tile.is_flagged and tile.has_mine) or (not tile.is_flagged and not tile.has_mine)

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
			var mat = tile.mesh.material_override as ShaderMaterial
			if mat:
				mat.set_shader_parameter("u_state", 3.0) # Mine
			add_number_to_tile(tile, "*")

func check_win_condition():
	for tile in tiles:
		if not tile.has_mine and not tile.is_revealed:
			return # Still have unrevealed safe tiles
	
	# All safe tiles revealed
	update_game_statistics(true) # Update stats for win
	
	# Record game end for difficulty scaling
	if difficulty_scaling_manager:
		difficulty_scaling_manager.record_game_end(true, game_timer, current_game_score)
	
	# Update scoring system for game end
	if scoring_system:
		scoring_system.calculate_final_score(game_timer, true)
		scoring_system.calculate_performance_metrics(game_timer)
	
	# Trigger game win event through Sound/VFX Event Manager
	sound_vfx_manager.trigger_event(
		SoundVFXEventManager.EventType.GAME_WIN,
		{
			"current_streak": game_statistics.current_streak,
			"current_difficulty": difficulty_level
		},
		SoundVFXEventManager.EventPriority.HIGH
	)
	
	game_state_manager.end_game(true)
	trigger_fireworks()

func trigger_fireworks():
	# Trigger fireworks event through Sound/VFX Event Manager
	sound_vfx_manager.trigger_event(
		SoundVFXEventManager.EventType.GAME_WIN,
		{
			"fireworks_type": "standard_fireworks",
			"current_streak": game_statistics.current_streak,
			"current_difficulty": difficulty_level
		},
		SoundVFXEventManager.EventPriority.HIGH
	)

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

func apply_difficulty_settings():
	# Adjust game parameters based on selected difficulty level
	match difficulty_level:
		DifficultyLevel.EASY:
			globe_radius = 15.0
			subdivision_level = 2
			mine_percentage = 0.10
			
		DifficultyLevel.MEDIUM:
			globe_radius = 20.0
			subdivision_level = 3
			mine_percentage = 0.15
			
		DifficultyLevel.HARD:
			globe_radius = 25.0
			subdivision_level = 4
			mine_percentage = 0.20
		
	# Update camera zoom based on globe radius
	target_zoom = globe_radius * 3
	current_zoom = target_zoom
	$Camera3D.position = Vector3(0, 0, current_zoom)

func calculate_score():
	# Calculate score based on various factors
	var base_score = 100
	var time_bonus = max(0, 1000 - int(game_timer * 10)) # Max 1000 points for speed
	var efficiency_bonus = 0
	
	if total_safe_tiles > 0:
		var efficiency = float(safe_tiles_revealed) / float(total_safe_tiles)
		efficiency_bonus = int(efficiency * 500) # Max 500 points for efficiency
	
	var flag_accuracy_bonus = 0
	if flags_used > 0:
		var flag_accuracy = float(correct_flags) / float(flags_used)
		flag_accuracy_bonus = int(flag_accuracy * 300) # Max 300 points for flag accuracy
	
	var streak_bonus = game_statistics.current_streak * 50 # 50 points per streak
	
	# Difficulty multiplier
	var difficulty_multiplier = 1.0
	match difficulty_level:
		DifficultyLevel.EASY:
			difficulty_multiplier = 0.8
		DifficultyLevel.MEDIUM:
			difficulty_multiplier = 1.0
		DifficultyLevel.HARD:
			difficulty_multiplier = 1.2
	
	current_game_score = int((base_score + time_bonus + efficiency_bonus + flag_accuracy_bonus + streak_bonus) * difficulty_multiplier)
	
	return current_game_score

func calculate_efficiency():
	if total_safe_tiles > 0:
		return float(safe_tiles_revealed) / float(total_safe_tiles)
	return 0.0

func reset_game():
	# Reset globe orientation and camera position to defaults for consistency after reset
	$Globe.rotation = Vector3.ZERO
	rotation_velocity = Vector2.ZERO
	target_zoom = globe_radius * 3
	current_zoom = target_zoom
	$Camera3D.position = Vector3(0, 0, current_zoom)
	
	# Clear any fireworks effects
	clear_fireworks()
	
	# Reset timer
	reset_timer()
	
	# Reset scoring variables
	current_game_score = 0
	safe_tiles_revealed = 0
	flags_used = 0
	correct_flags = 0
	
	# Reset powerup state
	reset_powerup_state()
	
	# Apply difficulty settings before generating globe
	apply_difficulty_settings()
	
	generate_globe()
	
	# Calculate total safe tiles for scoring
	total_safe_tiles = tiles.size() - int(tiles.size() * mine_percentage)
	
	mines_placed = false
	update_mine_counter()
	game_state_manager.start_game()

# Game State Manager Signal Handlers
func _on_game_state_changed(from_state, to_state):
	"""Handle state changes from the Game State Manager"""
	print("Game state changed from ", _state_to_string(from_state), " to ", _state_to_string(to_state))
	
	# Update UI and systems based on new state
	match to_state:
		game_state_manager.GameState.MENU:
			ui.show_main_menu()
			interaction_manager.set_input_processing(false)
			cursor.visible = false
		game_state_manager.GameState.PLAYING:
			ui.show_hud()
			interaction_manager.set_input_processing(true)
		game_state_manager.GameState.PAUSED:
			# Pause menu will be shown by UI system
			interaction_manager.set_input_processing(false)
		game_state_manager.GameState.GAME_OVER, game_state_manager.GameState.VICTORY:
			var is_win = (to_state == game_state_manager.GameState.VICTORY)
			ui.show_game_over(is_win)
			interaction_manager.set_input_processing(false)
			cursor.visible = false
		game_state_manager.GameState.SETTINGS:
			# Settings menu will be shown by UI system
			interaction_manager.set_input_processing(false)

func _on_game_state_entered(state):
	"""Handle entering a specific state"""
	print("Entered game state: ", _state_to_string(state))

func _on_game_paused():
	"""Handle game pause"""
	print("Game paused")
	# Pause timer is handled in _process by checking is_paused()
	
	# Trigger game pause event through Sound/VFX Event Manager
	sound_vfx_manager.trigger_event(
		SoundVFXEventManager.EventType.GAME_PAUSE,
		{}
	)

func _on_game_resumed():
	"""Handle game resume"""
	print("Game resumed")
	
	# Trigger game resume event through Sound/VFX Event Manager
	sound_vfx_manager.trigger_event(
		SoundVFXEventManager.EventType.GAME_RESUME,
		{}
	)

func _on_main_menu_requested():
	"""Handle main menu request"""
	# Clear globe
	for child in $Globe.get_children():
		child.queue_free()
	tiles.clear()
	update_mine_counter()

func _state_to_string(state) -> String:
	"""Convert state enum to string for debugging"""
	match state:
		game_state_manager.GameState.MENU: return "MENU"
		game_state_manager.GameState.PLAYING: return "PLAYING"
		game_state_manager.GameState.PAUSED: return "PAUSED"
		game_state_manager.GameState.GAME_OVER: return "GAME_OVER"
		game_state_manager.GameState.VICTORY: return "VICTORY"
		game_state_manager.GameState.SETTINGS: return "SETTINGS"
		_: return "UNKNOWN"

func _on_start_game_requested():
	reset_game()
	
	# Trigger game start event through Sound/VFX Event Manager
	sound_vfx_manager.trigger_event(
		SoundVFXEventManager.EventType.GAME_START,
		{}
	)

# Handle difficulty selection from UI
func _on_difficulty_selected(ui_difficulty_level: int):
	# Convert UI difficulty (0,1,2) to game difficulty enum
	match ui_difficulty_level:
		0:
			difficulty_level = DifficultyLevel.EASY
		1:
			difficulty_level = DifficultyLevel.MEDIUM
		2:
			difficulty_level = DifficultyLevel.HARD
	# Apply the selected difficulty settings
	apply_difficulty_settings()

# Game State Manager UI Signal Handlers
func _on_pause_requested():
	"""Handle pause request from UI"""
	game_state_manager.pause_game()

func _on_resume_requested():
	"""Handle resume request from UI"""
	game_state_manager.resume_game()

func _on_settings_requested():
	"""Handle settings request from UI"""
	game_state_manager.open_settings()

func _on_settings_closed():
	"""Handle settings closed from UI"""
	game_state_manager.close_settings()

# Powerup UI Signal Handlers
func _on_powerup_purchased_ui(powerup_type: String):
	"""Handle powerup purchase request from UI"""
	if powerup_manager:
		powerup_manager.purchase_powerup(powerup_type)

func _on_powerup_activated_ui(powerup_type: String):
	"""Handle powerup activation request from UI"""
	if powerup_manager:
		powerup_manager.activate_powerup(powerup_type)

# Difficulty Scaling UI Signal Handlers
func _on_difficulty_scaling_toggled(enabled: bool):
	"""Handle difficulty scaling toggle from UI"""
	if difficulty_scaling_manager:
		difficulty_scaling_manager.set_scaling_enabled(enabled)

func _on_difficulty_scaling_mode_changed(mode: int):
	"""Handle difficulty scaling mode change from UI"""
	if difficulty_scaling_manager:
		var mode_name = "ADAPTIVE"
		match mode:
			0: mode_name = "CONSERVATIVE"
			1: mode_name = "AGGRESSIVE"
			2: mode_name = "ADAPTIVE"
			3: mode_name = "STATIC"
		difficulty_scaling_manager.set_scaling_mode(mode_name)

func _on_difficulty_reset_requested():
	"""Handle difficulty reset request from UI"""
	if difficulty_scaling_manager:
		difficulty_scaling_manager.reset_difficulty()

func _on_difficulty_rollback_requested(steps: int):
	"""Handle difficulty rollback request from UI"""
	if difficulty_scaling_manager:
		difficulty_scaling_manager.rollback_difficulty(steps)

func _on_menu_requested():
	# Clear globe or just stop processing
	for child in $Globe.get_children():
		child.queue_free()
	tiles.clear()
	game_state_manager.return_to_menu()
	update_mine_counter()

# Statistics and timer functions
func load_game_statistics():
	var save_path = "user://game_statistics.save"
	var default_statistics = {
		"games_played": 0,
		"games_won": 0,
		"best_time": 9999.0,
		"total_time": 0.0,
		"current_streak": 0,
		"best_streak": 0,
		"high_score": 0,
		"best_efficiency": 0.0,
		"best_streak_score": 0
	}
	
	if FileAccess.file_exists(save_path):
		var file = FileAccess.open(save_path, FileAccess.READ)
		if file:
			var loaded_data = file.get_var()
			file.close()
			# Validate loaded data has expected structure
			if typeof(loaded_data) == TYPE_DICTIONARY and loaded_data.has("games_played"):
				game_statistics = loaded_data
			else:
				printerr("Invalid game statistics format in save file")
				game_statistics = default_statistics
		else:
			printerr("Failed to open save file for reading: ", save_path)
			game_statistics = default_statistics
	else:
		# No save file exists, use default statistics
		game_statistics = default_statistics

func save_game_statistics():
	var save_path = "user://game_statistics.save"
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	file.store_var(game_statistics)
	file.close()

func update_game_statistics(is_win: bool):
	game_statistics.games_played += 1
	
	if is_win:
		game_statistics.games_won += 1
		game_statistics.current_streak += 1
		if game_statistics.current_streak > game_statistics.best_streak:
			game_statistics.best_streak = game_statistics.current_streak
			
		if game_timer < game_statistics.best_time:
			game_statistics.best_time = game_timer
		
		# Update scoring statistics
		calculate_score()
		if current_game_score > game_statistics.high_score:
			game_statistics.high_score = current_game_score
		
		var efficiency = calculate_efficiency()
		if efficiency > game_statistics.best_efficiency:
			game_statistics.best_efficiency = efficiency
		
		# Calculate streak score (score * streak)
		var streak_score = current_game_score * game_statistics.current_streak
		if streak_score > game_statistics.best_streak_score:
			game_statistics.best_streak_score = streak_score
	else:
		game_statistics.current_streak = 0
	
	game_statistics.total_time += game_timer
	save_game_statistics()

func reset_timer():
	game_timer = 0.0
	game_started = false
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

func _apply_reveal_visuals(tile):
	if tile.is_revealed and not tile.has_mine:
		var mesh_instance = tile.mesh
		var mat = mesh_instance.material_override as ShaderMaterial
		if mat:
			var n = clamp(tile.neighbor_mines, 0, 8)
			mat.set_shader_parameter("u_state", 1.0) # Revealed
			mat.set_shader_parameter("u_revealed_color", NEIGHBOR_COLORS[n])

# Powerup System Integration Methods

# Powerup callback methods
func _on_score_deducted(amount: int, reason: String):
	# Visual feedback for score deduction
	print("Score deducted: ", amount, " points for ", reason)
	# TODO: Add UI feedback for score deduction

func _on_powerup_activated(powerup_type: String):
	print("Powerup activated: ", powerup_type)
	# Add visual/audio feedback for powerup activation
	audio_manager.play_powerup_sound()
	# Additional powerup-specific effects can be added here

# Powerup activation callback methods
func _on_powerup_activation_requested(powerup_type: String):
	print("Powerup activation requested: ", powerup_type)
	if powerup_manager and powerup_manager.can_activate_powerup(powerup_type):
		var result = powerup_manager.activate_powerup(powerup_type)
		if result.success:
			print("Powerup ", powerup_type, " activated successfully")
		else:
			print("Failed to activate powerup ", powerup_type, ": ", result.message)
	else:
		print("Cannot activate powerup ", powerup_type, " - not available or on cooldown")

func _on_powerup_hover_requested(tile_index: int):
	print("Powerup hover requested for tile index: ", tile_index)
	# This could be used for hint system or targeted powerups
	# For now, just update the hovered tile
	hovered_tile_index = tile_index

# Difficulty Scaling Manager Signal Handlers
func _on_difficulty_changed(from_level: float, to_level: float, reason: String):
	"""Handle difficulty changes from the scaling manager"""
	print("Difficulty changed from %.2f to %.2f: %s" % [from_level, to_level, reason])
	
	# Apply new difficulty parameters
	apply_difficulty_scaling_parameters()
	
	# Update UI to reflect new difficulty
	if ui:
		ui.update_difficulty_display(to_level)
	
	# Trigger difficulty change event through Sound/VFX Event Manager
	sound_vfx_manager.trigger_event(
		SoundVFXEventManager.EventType.DIFFICULTY_CHANGE,
		{
			"new_difficulty": to_level,
			"old_difficulty": from_level,
			"reason": reason
		}
	)

func _on_player_skill_assessed(skill_level: float, confidence: float):
	"""Handle player skill assessment from the scaling manager"""
	print("Player skill assessed: %.2f (confidence: %.2f)" % [skill_level, confidence])

func _on_score_updated(new_score: int, delta: int, reason: String):
	"""Handle score updates from the scoring system"""
	print("Score updated: ", new_score, " (", reason, ")")
	# Update UI with new score
	if ui:
		ui.update_score(new_score)

func _on_high_score_updated(new_high_score: int, difficulty_level: float):
	"""Handle high score updates from the scoring system"""
	print("New high score: ", new_high_score, " at difficulty ", difficulty_level)
	# Update UI with new high score
	if ui:
		ui.update_high_score(new_high_score)

# Difficulty Scaling Integration Methods
func apply_difficulty_scaling_parameters():
	"""Apply difficulty scaling parameters to game"""
	if not difficulty_scaling_manager:
		return
	
	var scaled_params = difficulty_scaling_manager.get_scaled_parameters()
	
	# Update game parameters based on scaling
	mine_percentage = scaled_params.mine_density
	subdivision_level = scaled_params.subdivision_level
	
	# Update camera zoom based on new subdivision level
	target_zoom = globe_radius * 3
	current_zoom = target_zoom
	$Camera3D.position = Vector3(0, 0, current_zoom)

func track_player_action(action_type: String, success: bool = true, data: Dictionary = {}):
	"""Track player actions for difficulty scaling analysis"""
	if difficulty_scaling_manager:
		difficulty_scaling_manager.record_player_action(action_type, success, data)

func get_difficulty_scaling_status() -> Dictionary:
	"""Get current difficulty scaling status"""
	if difficulty_scaling_manager:
		return difficulty_scaling_manager.get_scaling_status()
	return {}

# Powerup integration methods called by PowerupManager
func add_reveal_protection():
	reveal_protection_count += 1
	print("Reveal protection added. Total protections: ", reveal_protection_count)

func reveal_random_mine() -> Dictionary:
	# Find unrevealed mines
	var unrevealed_mines = []
	for i in range(tiles.size()):
		var current_tile = tiles[i]
		if current_tile.has_mine and not current_tile.is_revealed:
			unrevealed_mines.append(i)
	
	if unrevealed_mines.is_empty():
		return {"revealed": false, "message": "No unrevealed mines found"}
	
	# Randomly select a mine to reveal
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	var mine_index = unrevealed_mines[rng.randi_range(0, unrevealed_mines.size() - 1)]
	var tile = tiles[mine_index]
	
	# Reveal the mine with special visual indication
	tile.is_revealed = true
	var mat = tile.mesh.material_override as ShaderMaterial
	if mat:
		mat.set_shader_parameter("u_state", 4.0) # Powerup revealed mine
	add_number_to_tile(tile, "💣")
	
	print("Mine revealed at index: ", mine_index)
	return {"revealed": true, "mine_index": mine_index, "position": tile.world_position}

func reveal_random_safe_tile() -> Dictionary:
	# Find unrevealed safe tiles
	var unrevealed_safe_tiles = []
	for i in range(tiles.size()):
		var current_tile = tiles[i]
		if not current_tile.has_mine and not current_tile.is_revealed:
			unrevealed_safe_tiles.append(i)
	
	if unrevealed_safe_tiles.is_empty():
		return {"revealed": false, "message": "No unrevealed safe tiles found"}
	
	# Randomly select a safe tile to reveal
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	var safe_index = unrevealed_safe_tiles[rng.randi_range(0, unrevealed_safe_tiles.size() - 1)]
	var tile = tiles[safe_index]
	
	# Reveal the safe tile
	reveal_tile(tile)
	
	print("Safe tile revealed at index: ", safe_index)
	return {"revealed": true, "tile_index": safe_index, "position": tile.world_position, "neighbor_mines": tile.neighbor_mines}

func show_hints() -> Dictionary:
	# Show hints by temporarily highlighting safe tiles around hovered area
	var hints_shown = 0
	
	if hovered_tile_index != -1 and hovered_tile_index < tiles.size():
		var center_tile = tiles[hovered_tile_index]
		var safe_tiles_in_area = []
		
		# Find safe tiles in the area around the hovered tile
		for neighbor_idx in center_tile.neighbors:
			var neighbor = tiles[neighbor_idx]
			if not neighbor.has_mine and not neighbor.is_revealed:
				safe_tiles_in_area.append(neighbor_idx)
		
		# Highlight safe tiles temporarily
		for tile_idx in safe_tiles_in_area:
			var tile = tiles[tile_idx]
			var mat = tile.mesh.material_override as ShaderMaterial
			if mat:
				# Store original color
				var original_color = mat.get_shader_parameter("u_revealed_color")
				# Set hint color (bright green)
				mat.set_shader_parameter("u_revealed_color", Color(0.0, 1.0, 0.0, 0.8))
				mat.set_shader_parameter("u_state", 5.0) # Hint state
				
				# Remove hint after 3 seconds
				var timer = get_tree().create_timer(3.0)
				timer.timeout.connect(func():
					if is_instance_valid(tile.mesh):
						var hint_mat = tile.mesh.material_override as ShaderMaterial
						if hint_mat:
							hint_mat.set_shader_parameter("u_state", 0.0) # Back to unrevealed
							hint_mat.set_shader_parameter("u_revealed_color", original_color)
					)
				
				hints_shown += 1
	
	print("Hints shown for ", hints_shown, " tiles")
	return {"hints_shown": hints_shown, "center_index": hovered_tile_index}

func freeze_timer(duration: float):
	timer_frozen = true
	timer_freeze_remaining = duration
	print("Timer frozen for ", duration, " seconds")
	# TODO: Add visual indicator for frozen timer

# Game integration methods
func get_current_score() -> int:
	return current_game_score

func consume_reveal_protection() -> bool:
	if reveal_protection_count > 0:
		reveal_protection_count -= 1
		return true
	return false

# Modified reveal_tile to integrate with reveal protection
func reveal_tile_with_protection_check(tile) -> bool:
	"""Returns true if reveal was successful, false if it was a mine"""
	if tile.has_mine and reveal_protection_count > 0:
		# Use protection instead of game over
		consume_reveal_protection()
		print("Reveal protection used! Mine at index ", tile.index, " was protected.")
		# Visual feedback for protection
		var mat = tile.mesh.material_override as ShaderMaterial
		if mat:
			mat.set_shader_parameter("u_state", 6.0) # Protected mine state
		add_number_to_tile(tile, "🛡️")
		return true # Protected reveals are considered successful
	else:
		reveal_tile(tile)
		return not tile.has_mine # Return true if safe tile, false if mine

# Additional powerup integration methods
func activate_powerup_from_ui(powerup_type: String, _target_index: int = -1):
	"""Public method to activate powerups from UI"""
	if powerup_manager and powerup_manager.can_activate_powerup(powerup_type):
		var result = powerup_manager.activate_powerup(powerup_type)
		if result.success:
			print("Powerup ", powerup_type, " activated successfully from UI")
			# Visual feedback
			audio_manager.play_powerup_sound()
			# Screen flash or other visual feedback could be added here
		else:
			print("Failed to activate powerup ", powerup_type, " from UI: ", result.message)
			audio_manager.play_click_sound() # Error sound
	else:
		print("Cannot activate powerup ", powerup_type, " - not available or on cooldown")
		audio_manager.play_click_sound() # Error sound

func get_powerup_status_for_ui(powerup_type: String) -> Dictionary:
	"""Returns powerup status for UI display"""
	if powerup_manager:
		return powerup_manager.get_powerup_status(powerup_type)
	return {}

func get_all_powerups_status_for_ui() -> Dictionary:
	"""Returns all powerup statuses for UI display"""
	if powerup_manager:
		return powerup_manager.get_all_powerup_status()
	return {}

func get_difficulty_scaling_manager() -> Node:
	"""Get reference to difficulty scaling manager for UI"""
	return difficulty_scaling_manager

# Reset powerup state on new game
func reset_powerup_state():
	reveal_protection_count = 0
	timer_frozen = false
	timer_freeze_remaining = 0.0
	if powerup_manager:
		powerup_manager.reset_inventory()
