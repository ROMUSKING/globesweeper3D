extends Node

class_name TutorialManager

# Tutorial states
enum TutorialState {
	NOT_STARTED,
	INTRO,
	ROTATION,
	CLICKING,
	FLAGGING,
	CHORDING,
	COMPLETED
}

# Configuration
@export var tutorial_enabled: bool = true
@export var auto_start_tutorial: bool = true
@export var tutorial_speed: float = 1.0
@export var show_skip_confirmation: bool = true

# State
var current_state: TutorialState = TutorialState.NOT_STARTED
var tutorial_progress: int = 0
var is_active: bool = false
var tutorial_data: Dictionary = {}
var skip_requested: bool = false

# References
var main_game: Node
var ui_manager: Node
var interaction_manager: Node
var notification_manager: Node

# Tutorial steps with enhanced descriptions
var tutorial_steps = [
	{
		"id": "intro",
		"title": "Welcome to GlobeSweeper 3D",
		"description": "A 3D twist on the classic Minesweeper! Your goal is to clear all safe tiles without hitting any mines. Use the globe to explore and plan your strategy.",
		"image": "res://icons/tutorial_intro.png",
		"action_required": false,
		"duration": 3.0,
		"hint": "Tip: The globe rotates to show you all the tiles. Take your time to explore!",
		"interactive_elements": []
	},
	{
		"id": "rotation",
		"title": "Rotate the Globe",
		"description": "Left-click and drag to rotate the globe. This helps you see all tiles and plan your moves. The camera will smoothly follow your movements.",
		"image": "res://icons/tutorial_rotation.png",
		"action_required": true,
		"action_type": "rotation",
		"min_rotation": 0.5,
		"duration": 5.0,
		"hint": "Pro Tip: Rotate slowly to get a better view of the tile layout before making moves.",
		"interactive_elements": ["rotation_guide"]
	},
	{
		"id": "clicking",
		"title": "Reveal Tiles",
		"description": "Left-click on a tile to reveal it. Numbers show how many mines are adjacent to that tile. Start with tiles that have no adjacent mines for safe exploration.",
		"image": "res://icons/tutorial_clicking.png",
		"action_required": true,
		"action_type": "tile_click",
		"tile_type": "safe",
		"duration": 4.0,
		"hint": "Strategy: Look for patterns in the numbers to deduce mine locations.",
		"interactive_elements": ["click_guide"]
	},
	{
		"id": "flagging",
		"title": "Mark Mines",
		"description": "Right-click to place a flag on tiles you think contain mines. This helps you track dangerous areas and prevents accidental clicks.",
		"image": "res://icons/tutorial_flagging.png",
		"action_required": true,
		"action_type": "tile_flag",
		"duration": 3.0,
		"hint": "Remember: Flags are just markers. Double-check before flagging!",
		"interactive_elements": ["flag_guide"]
	},
	{
		"id": "chording",
		"title": "Advanced Technique",
		"description": "Click on a revealed number when all adjacent mines are flagged to automatically reveal safe neighbors. This speeds up gameplay significantly.",
		"image": "res://icons/tutorial_chording.png",
		"action_required": true,
		"action_type": "chord_click",
		"duration": 4.0,
		"hint": "Expert Move: Use chording to clear large areas quickly once you're confident about mine locations.",
		"interactive_elements": ["chord_guide"]
	},
	{
		"id": "completion",
		"title": "Tutorial Complete!",
		"description": "You're ready to play! Use the skills you've learned to clear the globe efficiently. Remember to rotate, reveal, flag, and chord your way to victory.",
		"image": "res://icons/tutorial_complete.png",
		"action_required": false,
		"duration": 2.0,
		"hint": "Challenge: Try different difficulty levels to test your skills!",
		"interactive_elements": []
	}
]

# Signals
signal tutorial_started
signal tutorial_step_changed(step_data: Dictionary)
signal tutorial_completed
signal action_completed(action_type: String, data: Dictionary)
signal tutorial_hint(message: String)
signal skip_tutorial_requested
signal skip_tutorial_confirmed
signal skip_tutorial_cancelled

func _ready():
	# Connect to main game systems
	if get_parent():
		main_game = get_parent()
		if main_game.has_node("UI"):
			ui_manager = main_game.get_node("UI")
		if main_game.has_node("InteractionManager"):
			interaction_manager = main_game.get_node("InteractionManager")
		if main_game.has_node("NotificationManager"):
			notification_manager = main_game.get_node("NotificationManager")
	
	# Load tutorial progress from save
	load_tutorial_progress()
	
	# Initialize skip state
	skip_requested = false

func start_tutorial():
	if not tutorial_enabled:
		return
	
	current_state = TutorialState.INTRO
	tutorial_progress = 0
	is_active = true
	skip_requested = false
	
	# Disable normal gameplay by telling the interaction manager to stop processing input
	if interaction_manager and interaction_manager.has_method("set_input_processing"):
		interaction_manager.set_input_processing(false)
	
	# Show tutorial UI
	show_tutorial_ui(get_current_step())
	
	# Show welcome notification as a tutorial hint (bypasses suppression)
	if notification_manager:
		notification_manager.show_tutorial_hint("Welcome to GlobeSweeper 3D Tutorial!")
	
	# Suppress non-tutorial notifications while tutorial is active
	if notification_manager:
		notification_manager.suppress_notifications(true, false)

	tutorial_started.emit()
	_process_tutorial_step()

func complete_tutorial():
	is_active = false
	current_state = TutorialState.COMPLETED
	tutorial_progress = tutorial_steps.size()
	
	# Re-enable normal gameplay by telling the interaction manager to resume input
	if interaction_manager and interaction_manager.has_method("set_input_processing"):
		interaction_manager.set_input_processing(true)
	
	# Save progress
	save_tutorial_progress()
	
	# Re-enable notifications and show completion notification
	if notification_manager:
		notification_manager.suppress_notifications(false)
		notification_manager.show_notification("Tutorial completed! You're ready to play!", "success", 4.0)
	
	tutorial_completed.emit()

func get_current_step() -> Dictionary:
	if tutorial_progress < tutorial_steps.size():
		return tutorial_steps[tutorial_progress]
	return {}

func _process_tutorial_step():
	if skip_requested:
		return
	
	var step = get_current_step()
	if step.is_empty():
		return
	
	tutorial_step_changed.emit(step)
	
	# Show hint if available
	if step.has("hint") and notification_manager:
		notification_manager.show_tutorial_hint(step.hint)
	
	# Show interactive elements for this step
	show_interactive_elements(step)
	
	if step.action_required:
		start_action_monitoring(step)
	else:
		# Auto-advance after duration
		var timer = get_tree().create_timer(step.duration / tutorial_speed)
		await timer.timeout
		if not skip_requested: # Only advance if not skipped
			advance_tutorial_step()

func show_interactive_elements(step: Dictionary):
	# This method will be called to show visual guides for each step
	if step.has("interactive_elements"):
		var elements = step.interactive_elements
		for element in elements:
			show_visual_guide(element)

func show_visual_guide(element_type: String):
	# Create visual guides for tutorial steps
	match element_type:
		"rotation_guide":
			create_rotation_guide()
		"click_guide":
			create_click_guide()
		"flag_guide":
			create_flag_guide()
		"chord_guide":
			create_chord_guide()

func create_rotation_guide():
	# Create a visual arrow or highlight to show rotation
	if main_game and main_game.has_node("Globe"):
		var globe = main_game.get_node("Globe")
		# This would create a visual rotation guide
		# For now, we'll just show a notification
		if notification_manager:
			notification_manager.show_notification("Drag with left mouse to rotate the globe", "info", 2.0)

func create_click_guide():
	# Highlight a safe tile to click
	if main_game and main_game.has_node("Globe"):
		var globe = main_game.get_node("Globe")
		# This would highlight a specific tile
		if notification_manager:
			notification_manager.show_notification("Click on a tile to reveal it", "info", 2.0)

func create_flag_guide():
	# Show how to flag a tile
	if notification_manager:
		notification_manager.show_notification("Right-click to place a flag on suspected mines", "info", 2.0)

func create_chord_guide():
	# Show how to use chord clicking
	if notification_manager:
		notification_manager.show_notification("Click on a number when all mines are flagged to reveal neighbors", "info", 2.0)

func start_action_monitoring(step: Dictionary):
	# Disconnect any existing connections first
	disconnect_action_signals()
	
	match step.action_type:
		"rotation":
			# Monitor rotation input
			if interaction_manager:
				interaction_manager.drag_active.connect(_on_rotation_action)
		"tile_click":
			# Monitor tile clicks
			if interaction_manager:
				interaction_manager.tile_clicked.connect(_on_tile_action)
		"tile_flag":
			# Monitor flag actions
			if interaction_manager:
				interaction_manager.tile_clicked.connect(_on_flag_action)
		"chord_click":
			# Monitor chord actions
			if interaction_manager:
				interaction_manager.tile_clicked.connect(_on_chord_action)

func disconnect_action_signals():
	# Disconnect all action monitoring signals - only if connected
	if interaction_manager:
		if interaction_manager.drag_active.is_connected(_on_rotation_action):
			interaction_manager.drag_active.disconnect(_on_rotation_action)
		if interaction_manager.tile_clicked.is_connected(_on_tile_action):
			interaction_manager.tile_clicked.disconnect(_on_tile_action)
		if interaction_manager.tile_clicked.is_connected(_on_flag_action):
			interaction_manager.tile_clicked.disconnect(_on_flag_action)
		if interaction_manager.tile_clicked.is_connected(_on_chord_action):
			interaction_manager.tile_clicked.disconnect(_on_chord_action)

func _on_rotation_action(relative: Vector2):
	if skip_requested:
		return
	
	var step = get_current_step()
	if step.action_type == "rotation" and relative.length() > step.min_rotation:
		action_completed.emit("rotation", {"rotation_amount": relative.length()})
		advance_tutorial_step()

func _on_tile_action(index: int, button_index: int):
	if skip_requested:
		return
	
	var step = get_current_step()
	if step.action_type == "tile_click" and button_index == MOUSE_BUTTON_LEFT:
		# Check if it's a safe tile (this would need integration with game logic)
		action_completed.emit("tile_click", {"tile_index": index})
		advance_tutorial_step()

func _on_flag_action(index: int, button_index: int):
	if skip_requested:
		return
	
	var step = get_current_step()
	if step.action_type == "tile_flag" and button_index == MOUSE_BUTTON_RIGHT:
		action_completed.emit("tile_flag", {"tile_index": index})
		advance_tutorial_step()

func _on_chord_action(index: int, button_index: int):
	if skip_requested:
		return
	
	var step = get_current_step()
	if step.action_type == "chord_click" and button_index == MOUSE_BUTTON_LEFT:
		# This would need integration with chord detection logic
		action_completed.emit("chord_click", {"tile_index": index})
		advance_tutorial_step()

func advance_tutorial_step():
	if skip_requested:
		return
		
	tutorial_progress += 1
	
	if tutorial_progress >= tutorial_steps.size():
		complete_tutorial()
	else:
		_process_tutorial_step()

func show_tutorial_ui(step: Dictionary):
	if ui_manager and ui_manager.has_method("show_tutorial_overlay"):
		ui_manager.show_tutorial_overlay(step)

func hide_tutorial_ui():
	if ui_manager and ui_manager.has_method("hide_tutorial_overlay"):
		ui_manager.hide_tutorial_overlay()

func request_skip_tutorial():
	if not show_skip_confirmation:
		confirm_skip_tutorial()
	else:
		skip_tutorial_requested.emit()

func confirm_skip_tutorial():
	skip_requested = true
	complete_tutorial()
	hide_tutorial_ui()
	skip_tutorial_confirmed.emit()

func cancel_skip_tutorial():
	skip_requested = false
	skip_tutorial_cancelled.emit()

func reset_tutorial():
	tutorial_progress = 0
	current_state = TutorialState.NOT_STARTED
	skip_requested = false
	save_tutorial_progress()

func save_tutorial_progress():
	var save_data = {
		"tutorial_progress": tutorial_progress,
		"tutorial_enabled": tutorial_enabled,
		"auto_start_tutorial": auto_start_tutorial
	}
	
	var save_path = "user://tutorial_progress.save"
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	if file:
		file.store_var(save_data)
		file.close()

func load_tutorial_progress():
	var save_path = "user://tutorial_progress.save"
	if FileAccess.file_exists(save_path):
		var file = FileAccess.open(save_path, FileAccess.READ)
		if file:
			var save_data = file.get_var()
			file.close()
			
			if save_data.has("tutorial_progress"):
				tutorial_progress = save_data.tutorial_progress
			if save_data.has("tutorial_enabled"):
				tutorial_enabled = save_data.tutorial_enabled
			if save_data.has("auto_start_tutorial"):
				auto_start_tutorial = save_data.auto_start_tutorial

func should_show_tutorial() -> bool:
	return tutorial_enabled and auto_start_tutorial and tutorial_progress == 0

func get_tutorial_completion_percentage() -> float:
	if tutorial_steps.size() == 0:
		return 0.0
	return float(tutorial_progress) / float(tutorial_steps.size())