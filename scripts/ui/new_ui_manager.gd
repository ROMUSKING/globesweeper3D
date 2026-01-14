class_name NewUIManager
extends Control

# New UI Manager - Handles scene management and signal routing
# This is a simplified version that focuses on scene management and signal routing
# rather than direct UI element manipulation

signal start_game_requested
signal restart_game_requested
signal menu_requested
signal difficulty_selected(difficulty_level: int)
signal powerup_purchased_ui(powerup_type: String)
signal powerup_activated_ui(powerup_type: String)
signal pause_requested
signal resume_requested
signal settings_requested
signal settings_closed
signal difficulty_scaling_toggled(enabled: bool)
signal difficulty_scaling_mode_changed(mode: int)
signal difficulty_reset_requested
signal difficulty_rollback_requested(steps: int)

# Scene references
@onready var main_menu = $MainMenu
@onready var hud = $HUD
@onready var game_over = $GameOver
@onready var pause_menu = $PauseMenu
@onready var settings_menu = $SettingsMenu

# Powerup Panel reference (accessed through HUD)
@onready var powerup_panel = $HUD/PowerupPanel

# Game State Manager reference
var game_state_manager: Node = null

# Powerup Manager reference
var powerup_manager: Node = null

# Difficulty Scaling Manager reference
var difficulty_scaling_manager: Node = null

func _ready():
	# Connect signals from child controllers
	connect_child_signals()
	
	# Show main menu by default
	show_main_menu()

func connect_child_signals():
	# Connect Main Menu signals
	if main_menu:
		main_menu.start_game_requested.connect(start_game_requested.emit)
		main_menu.difficulty_selected.connect(difficulty_selected.emit)
		main_menu.quit_requested.connect(_on_quit_requested)
	
	# Connect HUD signals
	if hud:
		hud.menu_requested.connect(menu_requested.emit)
		hud.pause_requested.connect(pause_requested.emit)
	
	# Connect Game Over signals
	if game_over:
		game_over.restart_game_requested.connect(restart_game_requested.emit)
		game_over.menu_requested.connect(menu_requested.emit)
	
	# Connect Pause Menu signals
	if pause_menu:
		pause_menu.resume_requested.connect(resume_requested.emit)
		pause_menu.restart_requested.connect(restart_game_requested.emit)
		pause_menu.menu_requested.connect(menu_requested.emit)
		pause_menu.settings_requested.connect(settings_requested.emit)
	
	# Connect Settings Menu signals
	if settings_menu:
		settings_menu.settings_closed.connect(settings_closed.emit)
		settings_menu.difficulty_scaling_toggled.connect(difficulty_scaling_toggled.emit)
		settings_menu.difficulty_scaling_mode_changed.connect(difficulty_scaling_mode_changed.emit)
		settings_menu.difficulty_reset_requested.connect(difficulty_reset_requested.emit)
		settings_menu.difficulty_rollback_requested.connect(difficulty_rollback_requested.emit)
	
	# Connect Powerup Panel signals
	if powerup_panel:
		powerup_panel.powerup_purchased_ui.connect(powerup_purchased_ui.emit)
		powerup_panel.powerup_activated_ui.connect(powerup_activated_ui.emit)

func show_main_menu():
	set_scene_visibility(main_menu, true)
	set_scene_visibility(hud, false)
	set_scene_visibility(game_over, false)
	set_scene_visibility(pause_menu, false)
	set_scene_visibility(settings_menu, false)

func show_hud():
	set_scene_visibility(main_menu, false)
	set_scene_visibility(hud, true)
	set_scene_visibility(game_over, false)
	set_scene_visibility(pause_menu, false)
	set_scene_visibility(settings_menu, false)

func show_game_over(is_win: bool):
	set_scene_visibility(main_menu, false)
	set_scene_visibility(hud, false)
	set_scene_visibility(game_over, true)
	set_scene_visibility(pause_menu, false)
	set_scene_visibility(settings_menu, false)
	
	if game_over:
		game_over.show_game_over(is_win)

func show_pause_menu():
	set_scene_visibility(main_menu, false)
	set_scene_visibility(hud, false)
	set_scene_visibility(game_over, false)
	set_scene_visibility(pause_menu, true)
	set_scene_visibility(settings_menu, false)

func show_settings_menu():
	set_scene_visibility(main_menu, false)
	set_scene_visibility(hud, false)
	set_scene_visibility(game_over, false)
	set_scene_visibility(pause_menu, false)
	set_scene_visibility(settings_menu, true)

# Helper function to set scene visibility
func set_scene_visibility(scene: Node, visible: bool):
	if scene:
		scene.visible = visible

# Game State Manager integration
func set_game_state_manager_reference(manager: Node):
	game_state_manager = manager
	
	# Pass game state manager reference to child controllers that need it
	if hud:
		hud.set_game_state_manager_reference(manager)
	
	# Connect to Game State Manager signals if available
	if game_state_manager and game_state_manager.has_signal("state_changed"):
		game_state_manager.state_changed.connect(_on_game_state_changed)
	if game_state_manager and game_state_manager.has_signal("state_entered"):
		game_state_manager.state_entered.connect(_on_game_state_entered)

func _on_game_state_changed(from_state, to_state):
	"""Handle game state changes from Game State Manager"""
	match to_state:
		game_state_manager.GameState.MENU:
			show_main_menu()
		game_state_manager.GameState.PLAYING:
			show_hud()
		game_state_manager.GameState.PAUSED:
			show_pause_menu()
		game_state_manager.GameState.GAME_OVER:
			show_game_over(false)
		game_state_manager.GameState.VICTORY:
			show_game_over(true)
		game_state_manager.GameState.SETTINGS:
			show_settings_menu()

func _on_game_state_entered(state):
	"""Handle entering a specific game state"""
	print("UI: Entered game state: ", _state_to_string(state))

func _state_to_string(state) -> String:
	"""Convert state enum to string for debugging"""
	if not game_state_manager:
		return "UNKNOWN"
	match state:
		game_state_manager.GameState.MENU: return "MENU"
		game_state_manager.GameState.PLAYING: return "PLAYING"
		game_state_manager.GameState.PAUSED: return "PAUSED"
		game_state_manager.GameState.GAME_OVER: return "GAME_OVER"
		game_state_manager.GameState.VICTORY: return "VICTORY"
		game_state_manager.GameState.SETTINGS: return "SETTINGS"
		_: return "UNKNOWN"

# Powerup Manager integration
func set_powerup_manager_reference(manager: Node):
	powerup_manager = manager
	
	# Pass powerup manager reference to powerup panel
	if powerup_panel:
		powerup_panel.set_powerup_manager_reference(manager)

# Difficulty Scaling Manager integration
func set_difficulty_scaling_manager_reference(manager: Node):
	difficulty_scaling_manager = manager
	
	# Pass difficulty scaling manager reference to settings menu
	if settings_menu:
		settings_menu.set_difficulty_scaling_manager_reference(manager)

# UI Update Methods (proxy to child controllers)
func update_time(time_value):
	if hud:
		hud.update_time(time_value)

func update_mines(count):
	if hud:
		hud.update_mines(count)

func update_score(score):
	if hud:
		hud.update_score(score)

func update_difficulty_display(difficulty_level: float):
	if hud:
		hud.update_difficulty_display(difficulty_level)

func show_powerup_panel(show: bool):
	if hud:
		hud.show_powerup_panel(show)

func refresh_powerup_ui():
	if powerup_panel:
		powerup_panel.refresh_powerup_ui()

# Signal handlers
func _on_quit_requested():
	get_tree().quit()
