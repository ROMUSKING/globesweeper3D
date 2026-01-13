extends Control

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

@onready var main_menu = $MainMenu
@onready var hud = $HUD
@onready var game_over = $GameOver
@onready var pause_menu = $PauseMenu
@onready var settings_menu = $SettingsMenu

# HUD Elements
@onready var time_label = $HUD/TopBar/HBoxContainer/TimeLabel
@onready var mine_counter = $HUD/TopBar/HBoxContainer/MineCounter
@onready var score_label = $HUD/TopBar/HBoxContainer/ScoreLabel
@onready var menu_button = $HUD/TopBar/HBoxContainer/MenuButton
@onready var difficulty_label = $HUD/TopBar/HBoxContainer/DifficultyLabel

# Main Menu Elements
@onready var start_button = $MainMenu/StartButton
@onready var quit_button = $MainMenu/QuitButton

# Difficulty Selection Elements
@onready var easy_button = $MainMenu/DifficultyContainer/EasyButton
@onready var medium_button = $MainMenu/DifficultyContainer/MediumButton
@onready var hard_button = $MainMenu/DifficultyContainer/HardButton

# Game Over Elements
@onready var result_label = $GameOver/VBoxContainer/ResultLabel
@onready var restart_button = $GameOver/VBoxContainer/RestartButton
@onready var main_menu_button = $GameOver/VBoxContainer/MainMenuButton

# Pause Menu Elements
@onready var pause_resume_button = $PauseMenu/VBoxContainer/ResumeButton
@onready var pause_restart_button = $PauseMenu/VBoxContainer/RestartButton
@onready var pause_menu_button = $PauseMenu/VBoxContainer/MenuButton
@onready var pause_settings_button = $PauseMenu/VBoxContainer/SettingsButton

# Settings Menu Elements
@onready var settings_back_button = $SettingsMenu/VBoxContainer/BackButton
@onready var scaling_toggle = $SettingsMenu/VBoxContainer/ScalingContainer/ScalingToggle
@onready var scaling_mode_selector = $SettingsMenu/VBoxContainer/ScalingContainer/ScalingModeSelector
@onready var reset_difficulty_button = $SettingsMenu/VBoxContainer/ScalingContainer/ResetDifficultyButton
@onready var rollback_difficulty_button = $SettingsMenu/VBoxContainer/ScalingContainer/RollbackDifficultyButton
@onready var scaling_status_label = $SettingsMenu/VBoxContainer/ScalingContainer/ScalingStatusLabel
@onready var performance_metrics_label = $SettingsMenu/VBoxContainer/ScalingContainer/PerformanceMetricsLabel

# Powerup UI Elements
@onready var powerup_panel = $HUD/PowerupPanel

# Game State Manager reference
var game_state_manager: Node = null

# Reveal Protection Elements
@onready var reveal_protection_status = $HUD/PowerupPanel/PowerupVBox/PowerupScroll/PowerupList/RevealProtectionCard/RevealProtectionHBox/RevealProtectionInfo/RevealProtectionStatus
@onready var reveal_protection_buy_button = $HUD/PowerupPanel/PowerupVBox/PowerupScroll/PowerupList/RevealProtectionCard/RevealProtectionHBox/RevealProtectionButtons/RevealProtectionBuyButton
@onready var reveal_protection_activate_button = $HUD/PowerupPanel/PowerupVBox/PowerupScroll/PowerupList/RevealProtectionCard/RevealProtectionHBox/RevealProtectionButtons/RevealProtectionActivateButton
@onready var reveal_protection_cooldown = $HUD/PowerupPanel/PowerupVBox/PowerupScroll/PowerupList/RevealProtectionCard/RevealProtectionHBox/RevealProtectionCooldown

# Reveal Mine Elements
@onready var reveal_mine_status = $HUD/PowerupPanel/PowerupVBox/PowerupScroll/PowerupList/RevealMineCard/RevealMineHBox/RevealMineInfo/RevealMineStatus
@onready var reveal_mine_buy_button = $HUD/PowerupPanel/PowerupVBox/PowerupScroll/PowerupList/RevealMineCard/RevealMineHBox/RevealMineButtons/RevealMineBuyButton
@onready var reveal_mine_activate_button = $HUD/PowerupPanel/PowerupVBox/PowerupScroll/PowerupList/RevealMineCard/RevealMineHBox/RevealMineButtons/RevealMineActivateButton
@onready var reveal_mine_cooldown = $HUD/PowerupPanel/PowerupVBox/PowerupScroll/PowerupList/RevealMineCard/RevealMineHBox/RevealMineCooldown

# Reveal Safe Tile Elements
@onready var reveal_safe_tile_status = $HUD/PowerupPanel/PowerupVBox/PowerupScroll/PowerupList/RevealSafeTileCard/RevealSafeTileHBox/RevealSafeTileInfo/RevealSafeTileStatus
@onready var reveal_safe_tile_buy_button = $HUD/PowerupPanel/PowerupVBox/PowerupScroll/PowerupList/RevealSafeTileCard/RevealSafeTileHBox/RevealSafeTileButtons/RevealSafeTileBuyButton
@onready var reveal_safe_tile_activate_button = $HUD/PowerupPanel/PowerupVBox/PowerupScroll/PowerupList/RevealSafeTileCard/RevealSafeTileHBox/RevealSafeTileButtons/RevealSafeTileActivateButton
@onready var reveal_safe_tile_cooldown = $HUD/PowerupPanel/PowerupVBox/PowerupScroll/PowerupList/RevealSafeTileCard/RevealSafeTileHBox/RevealSafeTileCooldown

# Hint System Elements
@onready var hint_system_status = $HUD/PowerupPanel/PowerupVBox/PowerupScroll/PowerupList/HintSystemCard/HintSystemHBox/HintSystemInfo/HintSystemStatus
@onready var hint_system_buy_button = $HUD/PowerupPanel/PowerupVBox/PowerupScroll/PowerupList/HintSystemCard/HintSystemHBox/HintSystemButtons/HintSystemBuyButton
@onready var hint_system_activate_button = $HUD/PowerupPanel/PowerupVBox/PowerupScroll/PowerupList/HintSystemCard/HintSystemHBox/HintSystemButtons/HintSystemActivateButton
@onready var hint_system_cooldown = $HUD/PowerupPanel/PowerupVBox/PowerupScroll/PowerupList/HintSystemCard/HintSystemHBox/HintSystemCooldown

# Time Freeze Elements
@onready var time_freeze_status = $HUD/PowerupPanel/PowerupVBox/PowerupScroll/PowerupList/TimeFreezeCard/TimeFreezeHBox/TimeFreezeInfo/TimeFreezeStatus
@onready var time_freeze_buy_button = $HUD/PowerupPanel/PowerupVBox/PowerupScroll/PowerupList/TimeFreezeCard/TimeFreezeHBox/TimeFreezeButtons/TimeFreezeBuyButton
@onready var time_freeze_activate_button = $HUD/PowerupPanel/PowerupVBox/PowerupScroll/PowerupList/TimeFreezeCard/TimeFreezeHBox/TimeFreezeButtons/TimeFreezeActivateButton
@onready var time_freeze_cooldown = $HUD/PowerupPanel/PowerupVBox/PowerupScroll/PowerupList/TimeFreezeCard/TimeFreezeHBox/TimeFreezeCooldown

# Selected difficulty (0 = EASY, 1 = MEDIUM, 2 = HARD)
var selected_difficulty: int = 1 # Default to MEDIUM

# Powerup Manager reference
var powerup_manager: Node = null

# Difficulty Scaling Manager reference
var difficulty_scaling_manager: Node = null

# Current game score
var current_score: int = 0

func _ready():
	# Connect signals from children
	if start_button:
		start_button.pressed.connect(_on_start_button_pressed)
	if quit_button:
		quit_button.pressed.connect(_on_quit_button_pressed)
	
	if menu_button:
		menu_button.pressed.connect(_on_menu_button_pressed)
		
	if restart_button:
		restart_button.pressed.connect(_on_restart_button_pressed)
	if main_menu_button:
		main_menu_button.pressed.connect(_on_main_menu_button_pressed)
	
	# Connect pause menu button signals
	if pause_resume_button:
		pause_resume_button.pressed.connect(_on_pause_resume_button_pressed)
	if pause_restart_button:
		pause_restart_button.pressed.connect(_on_pause_restart_button_pressed)
	if pause_menu_button:
		pause_menu_button.pressed.connect(_on_pause_menu_button_pressed)
	if pause_settings_button:
		pause_settings_button.pressed.connect(_on_pause_settings_button_pressed)
	
	# Connect settings menu button signals
	if settings_back_button:
		settings_back_button.pressed.connect(_on_settings_back_button_pressed)

	# Connect difficulty button signals
	if easy_button:
		easy_button.pressed.connect(_on_easy_button_pressed)
	if medium_button:
		medium_button.pressed.connect(_on_medium_button_pressed)
	if hard_button:
		hard_button.pressed.connect(_on_hard_button_pressed)
	
	# Connect powerup button signals
	connect_powerup_signals()
	
	# Set default difficulty selection (MEDIUM)
	set_difficulty_selection(selected_difficulty)
	
	# Initialize powerup UI
	initialize_powerup_ui()

func show_main_menu():
	main_menu.visible = true
	hud.visible = false
	game_over.visible = false
	pause_menu.visible = false
	settings_menu.visible = false

func show_hud():
	main_menu.visible = false
	hud.visible = true
	game_over.visible = false
	pause_menu.visible = false
	settings_menu.visible = false

func show_game_over(is_win: bool):
	main_menu.visible = false
	hud.visible = false
	game_over.visible = true
	pause_menu.visible = false
	settings_menu.visible = false
	
	if is_win:
		result_label.text = "You Win!"
	else:
		result_label.text = "Game Over"

func show_pause_menu():
	main_menu.visible = false
	hud.visible = false
	game_over.visible = false
	pause_menu.visible = true
	settings_menu.visible = false

func show_settings_menu():
	main_menu.visible = false
	hud.visible = false
	game_over.visible = false
	pause_menu.visible = false
	settings_menu.visible = true

# Game State Manager integration
func set_game_state_manager_reference(manager: Node):
	"""Sets the Game State Manager reference for state-based UI updates"""
	game_state_manager = manager
	
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

func update_time(time_value):
	# Assuming time_value is already formatted or we format it here
	# For now, just setting text
	time_label.text = str(time_value)

func update_mines(count):
	mine_counter.text = "Mines: " + str(count)

func update_score(score):
	score_label.text = "Score: " + str(score)

func update_difficulty_display(difficulty_level: float):
	"""Update the difficulty display in HUD"""
	if difficulty_label:
		difficulty_label.text = "Difficulty: %.2fx" % difficulty_level

# Signal Handlers
func _on_start_button_pressed():
	# Emit difficulty_selected signal before starting game
	difficulty_selected.emit(selected_difficulty)
	start_game_requested.emit()

func _on_restart_button_pressed():
	restart_game_requested.emit()

func _on_menu_button_pressed():
	menu_requested.emit()

func _on_main_menu_button_pressed():
	menu_requested.emit()

func _on_quit_button_pressed():
	get_tree().quit()

# Difficulty Selection Signal Handlers
func _on_easy_button_pressed():
	set_difficulty_selection(0)

func _on_medium_button_pressed():
	set_difficulty_selection(1)

func _on_hard_button_pressed():
	set_difficulty_selection(2)

# Helper function to update difficulty selection visuals and store selection
func set_difficulty_selection(difficulty: int):
	selected_difficulty = difficulty
	
	# Update button visuals to show selection
	if easy_button:
		easy_button.modulate = Color.YELLOW if difficulty == 0 else Color.WHITE
	if medium_button:
		medium_button.modulate = Color.YELLOW if difficulty == 1 else Color.WHITE
	if hard_button:
		hard_button.modulate = Color.YELLOW if difficulty == 2 else Color.WHITE

# Powerup UI Functions
func connect_powerup_signals():
	# Connect purchase buttons
	if reveal_protection_buy_button:
		reveal_protection_buy_button.pressed.connect(_on_reveal_protection_buy_pressed)
	if reveal_mine_buy_button:
		reveal_mine_buy_button.pressed.connect(_on_reveal_mine_buy_pressed)
	if reveal_safe_tile_buy_button:
		reveal_safe_tile_buy_button.pressed.connect(_on_reveal_safe_tile_buy_pressed)
	if hint_system_buy_button:
		hint_system_buy_button.pressed.connect(_on_hint_system_buy_pressed)
	if time_freeze_buy_button:
		time_freeze_buy_button.pressed.connect(_on_time_freeze_buy_pressed)
	
	# Connect activation buttons
	if reveal_protection_activate_button:
		reveal_protection_activate_button.pressed.connect(_on_reveal_protection_activate_pressed)
	if reveal_mine_activate_button:
		reveal_mine_activate_button.pressed.connect(_on_reveal_mine_activate_pressed)
	if reveal_safe_tile_activate_button:
		reveal_safe_tile_activate_button.pressed.connect(_on_reveal_safe_tile_activate_pressed)
	if hint_system_activate_button:
		hint_system_activate_button.pressed.connect(_on_hint_system_activate_pressed)
	if time_freeze_activate_button:
		time_freeze_activate_button.pressed.connect(_on_time_freeze_activate_pressed)

func initialize_powerup_ui():
	# Set up tooltips for powerup descriptions
	if reveal_protection_buy_button:
		reveal_protection_buy_button.tooltip_text = "Prevents mine explosion for one wrong click"
	if reveal_mine_buy_button:
		reveal_mine_buy_button.tooltip_text = "Automatically reveals one mine location"
	if reveal_safe_tile_buy_button:
		reveal_safe_tile_buy_button.tooltip_text = "Automatically reveals a safe tile"
	if hint_system_buy_button:
		hint_system_buy_button.tooltip_text = "Shows safe tiles around a specific area"
	if time_freeze_buy_button:
		time_freeze_buy_button.tooltip_text = "Pauses timer for 30 seconds"
	
	# Set up hover effects for all buttons
	setup_hover_effects()
	
	# Connect difficulty scaling signals
	connect_difficulty_scaling_signals()
	
	# Initial UI update
	update_powerup_ui()
	update_difficulty_scaling_ui()

func setup_hover_effects():
	# Setup hover effects for buy buttons
	setup_button_hover(reveal_protection_buy_button, "buy")
	setup_button_hover(reveal_mine_buy_button, "buy")
	setup_button_hover(reveal_safe_tile_buy_button, "buy")
	setup_button_hover(hint_system_buy_button, "buy")
	setup_button_hover(time_freeze_buy_button, "buy")
	
	# Setup hover effects for activate buttons
	setup_button_hover(reveal_protection_activate_button, "activate")
	setup_button_hover(reveal_mine_activate_button, "activate")
	setup_button_hover(reveal_safe_tile_activate_button, "activate")
	setup_button_hover(hint_system_activate_button, "activate")
	setup_button_hover(time_freeze_activate_button, "activate")

func setup_button_hover(button: Button, button_type: String):
	if not button:
		return
	
	# Connect mouse enter and exit signals for hover effects
	button.mouse_entered.connect(func():
		if not button.disabled:
			if button_type == "buy":
				button.modulate = Color(1.2, 1.2, 1.2) # Lighten on hover
			else:
				button.modulate = Color(1.1, 1.3, 1.1) # Green tint for activate
	)
	
	button.mouse_exited.connect(func():
		# Reset to normal color based on state
		if not button.disabled:
			if button_type == "buy":
				button.modulate = Color.WHITE
			else:
				button.modulate = Color.GREEN
		else:
			button.modulate = Color.GRAY
	)

func set_powerup_manager_reference(manager: Node):
	"""Sets the powerup manager reference for UI updates"""
	powerup_manager = manager
	
	# Connect powerup manager signals if available
	if powerup_manager and powerup_manager.has_signal("powerup_purchased"):
		powerup_manager.powerup_purchased.connect(_on_powerup_purchased)
	if powerup_manager and powerup_manager.has_signal("powerup_activated"):
		powerup_manager.powerup_activated.connect(_on_powerup_activated)
	if powerup_manager and powerup_manager.has_signal("powerup_deactivated"):
		powerup_manager.powerup_deactivated.connect(_on_powerup_deactivated)
	
	# Initial UI update
	update_powerup_ui()

func set_difficulty_scaling_manager_reference(manager: Node):
	"""Sets the difficulty scaling manager reference for UI updates"""
	difficulty_scaling_manager = manager
	
	# Connect difficulty scaling manager signals if available
	if difficulty_scaling_manager and difficulty_scaling_manager.has_signal("difficulty_changed"):
		difficulty_scaling_manager.difficulty_changed.connect(_on_difficulty_changed)
	if difficulty_scaling_manager and difficulty_scaling_manager.has_signal("player_skill_assessed"):
		difficulty_scaling_manager.player_skill_assessed.connect(_on_player_skill_assessed)
	if difficulty_scaling_manager and difficulty_scaling_manager.has_signal("scaling_enabled"):
		difficulty_scaling_manager.scaling_enabled.connect(_on_scaling_enabled)
	if difficulty_scaling_manager and difficulty_scaling_manager.has_signal("scaling_disabled"):
		difficulty_scaling_manager.scaling_disabled.connect(_on_scaling_disabled)
	
	# Initial UI update
	update_difficulty_scaling_ui()

func update_powerup_ui():
	"""Updates all powerup UI elements based on current state"""
	if not powerup_manager:
		return
	
	# Get current score from main script
	current_score = powerup_manager.get_available_score()
	
	# Update all powerup displays
	update_powerup_display("reveal_protection")
	update_powerup_display("reveal_mine")
	update_powerup_display("reveal_safe_tile")
	update_powerup_display("hint_system")
	update_powerup_display("time_freeze")

func update_powerup_display(powerup_type: String):
	"""Updates the display for a specific powerup"""
	if not powerup_manager:
		return
	
	var status = powerup_manager.get_powerup_status(powerup_type)
	if status.is_empty():
		return
	
	match powerup_type:
		"reveal_protection":
			update_reveal_protection_ui(status)
		"reveal_mine":
			update_reveal_mine_ui(status)
		"reveal_safe_tile":
			update_reveal_safe_tile_ui(status)
		"hint_system":
			update_hint_system_ui(status)
		"time_freeze":
			update_time_freeze_ui(status)

func update_reveal_protection_ui(status: Dictionary):
	update_powerup_card_ui("reveal_protection", status, {
		"status": reveal_protection_status,
		"buy_button": reveal_protection_buy_button,
		"activate_button": reveal_protection_activate_button,
		"cooldown": reveal_protection_cooldown,
		"activate_color": Color.GREEN
	})

func update_reveal_mine_ui(status: Dictionary):
	update_powerup_card_ui("reveal_mine", status, {
		"status": reveal_mine_status,
		"buy_button": reveal_mine_buy_button,
		"activate_button": reveal_mine_activate_button,
		"cooldown": reveal_mine_cooldown,
		"activate_color": Color.GREEN
	})

func update_reveal_safe_tile_ui(status: Dictionary):
	update_powerup_card_ui("reveal_safe_tile", status, {
		"status": reveal_safe_tile_status,
		"buy_button": reveal_safe_tile_buy_button,
		"activate_button": reveal_safe_tile_activate_button,
		"cooldown": reveal_safe_tile_cooldown,
		"activate_color": Color.GREEN
	})

func update_hint_system_ui(status: Dictionary):
	update_powerup_card_ui("hint_system", status, {
		"status": hint_system_status,
		"buy_button": hint_system_buy_button,
		"activate_button": hint_system_activate_button,
		"cooldown": hint_system_cooldown,
		"activate_color": Color.GREEN
	})

func update_time_freeze_ui(status: Dictionary):
	update_powerup_card_ui("time_freeze", status, {
		"status": time_freeze_status,
		"buy_button": time_freeze_buy_button,
		"activate_button": time_freeze_activate_button,
		"cooldown": time_freeze_cooldown,
		"activate_color": Color.CYAN
	})

## Generic method to update powerup card UI elements.
## Handles common UI update logic for all powerup types.
## 
## Args:
## 	powerup_type: The type of powerup being updated
## 	status: Dictionary containing powerup status information
## 	elements: Dictionary containing UI element references and configuration
func update_powerup_card_ui(powerup_type: String, status: Dictionary, elements: Dictionary) -> void:
	# Update status label
	if elements.has("status") and elements.status:
		elements.status.text = "Owned: %d | Available: %d" % [status.get("owned", 0), status.get("available", 0)]
	
	# Update buy button
	if elements.has("buy_button") and elements.buy_button:
		var can_purchase = status.get("can_purchase", false)
		elements.buy_button.disabled = not can_purchase
		elements.buy_button.modulate = Color.GRAY if not can_purchase else Color.WHITE
	
	# Update activate button
	if elements.has("activate_button") and elements.activate_button:
		var can_activate = status.get("can_activate", false)
		elements.activate_button.disabled = not can_activate
		var activate_color = elements.get("activate_color", Color.GREEN)
		elements.activate_button.modulate = Color.GRAY if not can_activate else activate_color
	
	# Update cooldown display
	if elements.has("cooldown") and elements.cooldown:
		var cooldown = status.get("cooldown", 0.0)
		var active_duration = status.get("active_duration", 0.0)
		
		if powerup_type == "time_freeze":
			# Special handling for time freeze with active duration
			if active_duration > 0.0:
				elements.cooldown.text = "Active: %.1fs" % active_duration
				elements.cooldown.visible = true
				elements.cooldown.modulate = Color.CYAN
			elif cooldown > 0.0:
				elements.cooldown.text = "Cooldown: %.1fs" % cooldown
				elements.cooldown.visible = true
				elements.cooldown.modulate = Color.RED
			else:
				elements.cooldown.visible = false
		else:
			# Standard cooldown display
			if cooldown > 0.0:
				elements.cooldown.text = "Cooldown: %.1fs" % cooldown
				elements.cooldown.visible = true
			else:
				elements.cooldown.visible = false

# Powerup Button Event Handlers
func _on_reveal_protection_buy_pressed():
	pulse_button(reveal_protection_buy_button)
	powerup_purchased_ui.emit("reveal_protection")

func _on_reveal_mine_buy_pressed():
	pulse_button(reveal_mine_buy_button)
	powerup_purchased_ui.emit("reveal_mine")

func _on_reveal_safe_tile_buy_pressed():
	pulse_button(reveal_safe_tile_buy_button)
	powerup_purchased_ui.emit("reveal_safe_tile")

func _on_hint_system_buy_pressed():
	pulse_button(hint_system_buy_button)
	powerup_purchased_ui.emit("hint_system")

func _on_time_freeze_buy_pressed():
	pulse_button(time_freeze_buy_button)
	powerup_purchased_ui.emit("time_freeze")

func _on_reveal_protection_activate_pressed():
	pulse_button(reveal_protection_activate_button)
	powerup_activated_ui.emit("reveal_protection")

func _on_reveal_mine_activate_pressed():
	pulse_button(reveal_mine_activate_button)
	powerup_activated_ui.emit("reveal_mine")

func _on_reveal_safe_tile_activate_pressed():
	pulse_button(reveal_safe_tile_activate_button)
	powerup_activated_ui.emit("reveal_safe_tile")

func _on_hint_system_activate_pressed():
	pulse_button(hint_system_activate_button)
	powerup_activated_ui.emit("hint_system")

func _on_time_freeze_activate_pressed():
	pulse_button(time_freeze_activate_button)
	powerup_activated_ui.emit("time_freeze")

# Powerup Manager Signal Handlers
func _on_powerup_purchased(powerup_type: String, cost: int):
	# Update UI when a powerup is purchased
	update_powerup_ui()
	
	# Show visual feedback
	show_powerup_feedback("Purchased: " + powerup_type.replace("_", " ").capitalize(), Color.GREEN)

func _on_powerup_activated(powerup_type: String):
	# Update UI when a powerup is activated
	update_powerup_ui()
	
	# Show visual feedback
	show_powerup_feedback("Activated: " + powerup_type.replace("_", " ").capitalize(), Color.CYAN)

func _on_powerup_deactivated(powerup_type: String):
	# Update UI when a powerup is deactivated
	update_powerup_ui()
	
	# Show visual feedback
	show_powerup_feedback("Deactivated: " + powerup_type.replace("_", " ").capitalize(), Color.ORANGE)

# Enhanced visual feedback function
func show_powerup_feedback(message: String, color: Color, duration: float = 2.0):
	# Create a notification panel for better feedback
	var notification_panel = PanelContainer.new()
	var notification_label = Label.new()
	
	# Style the notification
	notification_label.text = message
	notification_label.modulate = color
	notification_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	notification_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	notification_label.add_theme_font_size_override("font_size", 16)
	
	# Add to panel
	notification_panel.add_child(notification_label)
	
	# Style the panel
	notification_panel.modulate = Color(0, 0, 0, 0.8)
	notification_panel.size = Vector2(300, 50)
	notification_panel.position = Vector2((hud.size.x - 300) / 2, 50)
	
	# Add to HUD
	if hud:
		hud.add_child(notification_panel)
		
		# Animate entrance
		notification_panel.position.y = -50
		var entrance_tween = create_tween()
		entrance_tween.tween_property(notification_panel, "position:y", 50, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		
		# Animate exit
		var exit_tween = create_tween()
		exit_tween.tween_interval(duration * 0.7)
		exit_tween.tween_property(notification_panel, "position:y", -50, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		exit_tween.tween_callback(notification_panel.queue_free)

# Add visual pulse effect for button clicks
func pulse_button(button: Button):
	if not button or button.disabled:
		return
	
	var original_scale = button.scale
	var pulse_tween = create_tween()
	pulse_tween.tween_property(button, "scale", original_scale * 1.1, 0.1)
	pulse_tween.tween_property(button, "scale", original_scale, 0.1)

# Process function for cooldown updates
func _process(delta: float):
	# Update powerup UI for cooldown timers
	if powerup_manager:
		update_powerup_cooldowns(delta)

func update_powerup_cooldowns(delta: float):
	# Update cooldown displays in real-time
	if powerup_manager and powerup_panel.visible:
		update_powerup_ui()

# Public API for external script integration
func show_powerup_panel(show: bool):
	"""Shows or hides the powerup panel"""
	if powerup_panel:
		powerup_panel.visible = show

func refresh_powerup_ui():
	"""Manually refreshes the powerup UI"""
	update_powerup_ui()

# Game State Manager Signal Handlers
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

# Pause Menu Button Handlers
func _on_pause_resume_button_pressed():
	"""Resume game from pause"""
	resume_requested.emit()

func _on_pause_restart_button_pressed():
	"""Restart game from pause menu"""
	restart_game_requested.emit()

func _on_pause_menu_button_pressed():
	"""Return to main menu from pause"""
	menu_requested.emit()

func _on_pause_settings_button_pressed():
	"""Open settings from pause menu"""
	settings_requested.emit()

func _on_settings_back_button_pressed():
	"""Close settings menu"""
	settings_closed.emit()

# Test function for validating powerup UI functionality
func connect_difficulty_scaling_signals():
	"""Connect difficulty scaling UI signals"""
	if scaling_toggle:
		scaling_toggle.toggled.connect(_on_scaling_toggle_toggled)
	if scaling_mode_selector:
		scaling_mode_selector.item_selected.connect(_on_scaling_mode_selected)
	if reset_difficulty_button:
		reset_difficulty_button.pressed.connect(_on_reset_difficulty_pressed)
	if rollback_difficulty_button:
		rollback_difficulty_button.pressed.connect(_on_rollback_difficulty_pressed)

func update_difficulty_scaling_ui():
	"""Update difficulty scaling UI elements"""
	if not difficulty_scaling_manager:
		return
	
	var scaling_status = difficulty_scaling_manager.get_scaling_status()
	
	# Update scaling toggle
	if scaling_toggle:
		scaling_toggle.button_pressed = scaling_status.get("enabled", true)
	
	# Update scaling mode selector
	if scaling_mode_selector:
		var mode = scaling_status.get("mode", "ADAPTIVE")
		var mode_index = 0
		match mode:
			"CONSERVATIVE": mode_index = 0
			"AGGRESSIVE": mode_index = 1
			"ADAPTIVE": mode_index = 2
			"STATIC": mode_index = 3
		scaling_mode_selector.select(mode_index)
	
	# Update scaling status display
	if scaling_status_label:
		var current_diff = scaling_status.get("current_difficulty", 1.0)
		var min_diff = scaling_status.get("min_difficulty", 0.5)
		var max_diff = scaling_status.get("max_difficulty", 2.0)
		scaling_status_label.text = "Current: %.2fx (Range: %.2f-%.2f)" % [current_diff, min_diff, max_diff]
	
	# Update performance metrics display
	if performance_metrics_label:
		var metrics = scaling_status.get("metrics", {})
		var efficiency = metrics.get("efficiency_score", 0.0)
		var error_rate = metrics.get("error_rate", 0.0)
		var powerup_dep = metrics.get("powerup_dependency", 0.0)
		performance_metrics_label.text = "Efficiency: %.1f%% | Errors: %.1f%% | Powerup Dep: %.1f%%" % [efficiency * 100, error_rate * 100, powerup_dep * 100]

# Difficulty Scaling Signal Handlers
func _on_difficulty_changed(from_level: float, to_level: float, reason: String):
	"""Handle difficulty changes"""
	update_difficulty_display(to_level)
	show_powerup_feedback("Difficulty: %.2fx → %.2fx (%s)" % [from_level, to_level, reason], Color.YELLOW, 3.0)

func _on_player_skill_assessed(skill_level: float, confidence: float):
	"""Handle player skill assessment"""
	# Could show skill level in UI for advanced users
	pass

func _on_scaling_enabled():
	"""Handle scaling being enabled"""
	update_difficulty_scaling_ui()
	show_powerup_feedback("Difficulty Scaling Enabled", Color.GREEN)

func _on_scaling_disabled():
	"""Handle scaling being disabled"""
	update_difficulty_scaling_ui()
	show_powerup_feedback("Difficulty Scaling Disabled", Color.ORANGE)

# Difficulty Scaling Control Signal Handlers
func _on_scaling_toggle_toggled(enabled: bool):
	"""Handle scaling toggle"""
	if difficulty_scaling_manager:
		difficulty_scaling_manager.set_scaling_enabled(enabled)
	difficulty_scaling_toggled.emit(enabled)

func _on_scaling_mode_selected(mode_index: int):
	"""Handle scaling mode selection"""
	if difficulty_scaling_manager:
		var mode_name = "ADAPTIVE"
		match mode_index:
			0: mode_name = "CONSERVATIVE"
			1: mode_name = "AGGRESSIVE"
			2: mode_name = "ADAPTIVE"
			3: mode_name = "STATIC"
		difficulty_scaling_manager.set_scaling_mode(mode_name)
	difficulty_scaling_mode_changed.emit(mode_index)

func _on_reset_difficulty_pressed():
	"""Handle difficulty reset"""
	if difficulty_scaling_manager:
		difficulty_scaling_manager.reset_difficulty()
	difficulty_reset_requested.emit()
	show_powerup_feedback("Difficulty Reset to Default", Color.CYAN)

func _on_rollback_difficulty_pressed():
	"""Handle difficulty rollback"""
	if difficulty_scaling_manager:
		difficulty_scaling_manager.rollback_difficulty(1)
	difficulty_rollback_requested.emit(1)
	show_powerup_feedback("Difficulty Rolled Back", Color.PURPLE)
