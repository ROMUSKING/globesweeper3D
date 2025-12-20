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

# State
var current_state: TutorialState = TutorialState.NOT_STARTED
var tutorial_progress: int = 0
var is_active: bool = false
var tutorial_data: Dictionary = {}

# References
var main_game: Node
var ui_manager: Node
var interaction_manager: Node

# Tutorial steps
var tutorial_steps = [
	{
		"id": "intro",
		"title": "Welcome to GlobeSweeper 3D",
		"description": "A 3D twist on the classic Minesweeper! Your goal is to clear all safe tiles without hitting any mines.",
		"image": "res://icons/tutorial_intro.png",
		"action_required": false,
		"duration": 3.0
	},
	{
		"id": "rotation",
		"title": "Rotate the Globe",
		"description": "Left-click and drag to rotate the globe. This helps you see all tiles and plan your moves.",
		"image": "res://icons/tutorial_rotation.png",
		"action_required": true,
		"action_type": "rotation",
		"min_rotation": 0.5,
		"duration": 5.0
	},
	{
		"id": "clicking",
		"title": "Reveal Tiles",
		"description": "Left-click on a tile to reveal it. Numbers show how many mines are adjacent to that tile.",
		"image": "res://icons/tutorial_clicking.png",
		"action_required": true,
		"action_type": "tile_click",
		"tile_type": "safe",
		"duration": 4.0
	},
	{
		"id": "flagging",
		"title": "Mark Mines",
		"description": "Right-click to place a flag on tiles you think contain mines. This helps you track dangerous areas.",
		"image": "res://icons/tutorial_flagging.png",
		"action_required": true,
		"action_type": "tile_flag",
		"duration": 3.0
	},
	{
		"id": "chording",
		"title": "Advanced Technique",
		"description": "Click on a revealed number when all adjacent mines are flagged to automatically reveal safe neighbors.",
		"image": "res://icons/tutorial_chording.png",
		"action_required": true,
		"action_type": "chord_click",
		"duration": 4.0
	},
	{
		"id": "completion",
		"title": "Tutorial Complete!",
		"description": "You're ready to play! Use the skills you've learned to clear the globe efficiently.",
		"image": "res://icons/tutorial_complete.png",
		"action_required": false,
		"duration": 2.0
	}
]

# Signals
signal tutorial_started
signal tutorial_step_changed(step_data: Dictionary)
signal tutorial_completed
signal action_completed(action_type: String, data: Dictionary)

func _ready():
	# Connect to main game systems
	if get_parent():
		main_game = get_parent()
		if main_game.has_node("UI"):
			ui_manager = main_game.get_node("UI")
		if main_game.has_node("InteractionManager"):
			interaction_manager = main_game.get_node("InteractionManager")
	
	# Load tutorial progress from save
	load_tutorial_progress()

func start_tutorial():
	if not tutorial_enabled:
		return
	
	current_state = TutorialState.INTRO
	tutorial_progress = 0
	is_active = true
	
	# Disable normal gameplay
	if main_game:
		main_game.set_input_processing(false)
	
	# Show tutorial UI
	show_tutorial_ui(get_current_step())
	
	tutorial_started.emit()
	_process_tutorial_step()

func complete_tutorial():
	is_active = false
	current_state = TutorialState.COMPLETED
	tutorial_progress = tutorial_steps.size() - 1
	
	# Re-enable normal gameplay
	if main_game:
		main_game.set_input_processing(true)
	
	# Save progress
	save_tutorial_progress()
	
	tutorial_completed.emit()

func get_current_step() -> Dictionary:
	if tutorial_progress < tutorial_steps.size():
		return tutorial_steps[tutorial_progress]
	return {}

func _process_tutorial_step():
	var step = get_current_step()
	if step.is_empty():
		return
	
	tutorial_step_changed.emit(step)
	
	if step.action_required:
		start_action_monitoring(step)
	else:
		# Auto-advance after duration
		var timer = get_tree().create_timer(step.duration / tutorial_speed)
		await timer.timeout
		advance_tutorial_step()

func start_action_monitoring(step: Dictionary):
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

func _on_rotation_action(relative: Vector2):
	var step = get_current_step()
	if step.action_type == "rotation" and relative.length() > step.min_rotation:
		action_completed.emit("rotation", {"rotation_amount": relative.length()})
		advance_tutorial_step()

func _on_tile_action(index: int, button_index: int):
	var step = get_current_step()
	if step.action_type == "tile_click" and button_index == MOUSE_BUTTON_LEFT:
		# Check if it's a safe tile (this would need integration with game logic)
		action_completed.emit("tile_click", {"tile_index": index})
		advance_tutorial_step()

func _on_flag_action(index: int, button_index: int):
	var step = get_current_step()
	if step.action_type == "tile_flag" and button_index == MOUSE_BUTTON_RIGHT:
		action_completed.emit("tile_flag", {"tile_index": index})
		advance_tutorial_step()

func _on_chord_action(index: int, button_index: int):
	var step = get_current_step()
	if step.action_type == "chord_click" and button_index == MOUSE_BUTTON_LEFT:
		# This would need integration with chord detection logic
		action_completed.emit("chord_click", {"tile_index": index})
		advance_tutorial_step()

func advance_tutorial_step():
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

func skip_tutorial():
	complete_tutorial()
	hide_tutorial_ui()

func reset_tutorial():
	tutorial_progress = 0
	current_state = TutorialState.NOT_STARTED
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