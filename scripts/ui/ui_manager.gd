extends Control

signal start_game_requested
signal restart_game_requested
signal menu_requested
signal difficulty_selected(difficulty_level: int)
signal powerup_purchased_ui(powerup_type: String)
signal powerup_activated_ui(powerup_type: String)

@onready var main_menu = $MainMenu
@onready var hud = $HUD
@onready var game_over = $GameOver

# HUD Elements
@onready var time_label = $HUD/TopBar/HBoxContainer/TimeLabel
@onready var mine_counter = $HUD/TopBar/HBoxContainer/MineCounter
@onready var score_label = $HUD/TopBar/HBoxContainer/ScoreLabel
@onready var menu_button = $HUD/TopBar/HBoxContainer/MenuButton

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

# Powerup UI Elements
@onready var powerup_panel = $HUD/PowerupPanel

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

func show_hud():
	main_menu.visible = false
	hud.visible = true
	game_over.visible = false

func show_game_over(is_win: bool):
	main_menu.visible = false
	hud.visible = false
	game_over.visible = true
	
	if is_win:
		result_label.text = "You Win!"
	else:
		result_label.text = "Game Over"

func update_time(time_value):
	# Assuming time_value is already formatted or we format it here
	# For now, just setting text
	time_label.text = str(time_value)

func update_mines(count):
	mine_counter.text = "Mines: " + str(count)

func update_score(score):
	score_label.text = "Score: " + str(score)

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
	
	# Initial UI update
	update_powerup_ui()

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
	if reveal_protection_status:
		reveal_protection_status.text = "Owned: %d | Available: %d" % [status.get("owned", 0), status.get("available", 0)]
	
	# Update buy button
	if reveal_protection_buy_button:
		var can_purchase = status.get("can_purchase", false)
		reveal_protection_buy_button.disabled = not can_purchase
		reveal_protection_buy_button.modulate = Color.GRAY if not can_purchase else Color.WHITE
	
	# Update activate button
	if reveal_protection_activate_button:
		var can_activate = status.get("can_activate", false)
		reveal_protection_activate_button.disabled = not can_activate
		reveal_protection_activate_button.modulate = Color.GRAY if not can_activate else Color.GREEN
	
	# Update cooldown display
	if reveal_protection_cooldown:
		var cooldown = status.get("cooldown", 0.0)
		if cooldown > 0.0:
			reveal_protection_cooldown.text = "Cooldown: %.1fs" % cooldown
			reveal_protection_cooldown.visible = true
		else:
			reveal_protection_cooldown.visible = false

func update_reveal_mine_ui(status: Dictionary):
	if reveal_mine_status:
		reveal_mine_status.text = "Owned: %d | Available: %d" % [status.get("owned", 0), status.get("available", 0)]
	
	# Update buy button
	if reveal_mine_buy_button:
		var can_purchase = status.get("can_purchase", false)
		reveal_mine_buy_button.disabled = not can_purchase
		reveal_mine_buy_button.modulate = Color.GRAY if not can_purchase else Color.WHITE
	
	# Update activate button
	if reveal_mine_activate_button:
		var can_activate = status.get("can_activate", false)
		reveal_mine_activate_button.disabled = not can_activate
		reveal_mine_activate_button.modulate = Color.GRAY if not can_activate else Color.GREEN
	
	# Update cooldown display
	if reveal_mine_cooldown:
		var cooldown = status.get("cooldown", 0.0)
		if cooldown > 0.0:
			reveal_mine_cooldown.text = "Cooldown: %.1fs" % cooldown
			reveal_mine_cooldown.visible = true
		else:
			reveal_mine_cooldown.visible = false

func update_reveal_safe_tile_ui(status: Dictionary):
	if reveal_safe_tile_status:
		reveal_safe_tile_status.text = "Owned: %d | Available: %d" % [status.get("owned", 0), status.get("available", 0)]
	
	# Update buy button
	if reveal_safe_tile_buy_button:
		var can_purchase = status.get("can_purchase", false)
		reveal_safe_tile_buy_button.disabled = not can_purchase
		reveal_safe_tile_buy_button.modulate = Color.GRAY if not can_purchase else Color.WHITE
	
	# Update activate button
	if reveal_safe_tile_activate_button:
		var can_activate = status.get("can_activate", false)
		reveal_safe_tile_activate_button.disabled = not can_activate
		reveal_safe_tile_activate_button.modulate = Color.GRAY if not can_activate else Color.GREEN
	
	# Update cooldown display
	if reveal_safe_tile_cooldown:
		var cooldown = status.get("cooldown", 0.0)
		if cooldown > 0.0:
			reveal_safe_tile_cooldown.text = "Cooldown: %.1fs" % cooldown
			reveal_safe_tile_cooldown.visible = true
		else:
			reveal_safe_tile_cooldown.visible = false

func update_hint_system_ui(status: Dictionary):
	if hint_system_status:
		hint_system_status.text = "Owned: %d | Available: %d" % [status.get("owned", 0), status.get("available", 0)]
	
	# Update buy button
	if hint_system_buy_button:
		var can_purchase = status.get("can_purchase", false)
		hint_system_buy_button.disabled = not can_purchase
		hint_system_buy_button.modulate = Color.GRAY if not can_purchase else Color.WHITE
	
	# Update activate button
	if hint_system_activate_button:
		var can_activate = status.get("can_activate", false)
		hint_system_activate_button.disabled = not can_activate
		hint_system_activate_button.modulate = Color.GRAY if not can_activate else Color.GREEN
	
	# Update cooldown display
	if hint_system_cooldown:
		var cooldown = status.get("cooldown", 0.0)
		if cooldown > 0.0:
			hint_system_cooldown.text = "Cooldown: %.1fs" % cooldown
			hint_system_cooldown.visible = true
		else:
			hint_system_cooldown.visible = false

func update_time_freeze_ui(status: Dictionary):
	if time_freeze_status:
		time_freeze_status.text = "Owned: %d | Available: %d" % [status.get("owned", 0), status.get("available", 0)]
	
	# Update buy button
	if time_freeze_buy_button:
		var can_purchase = status.get("can_purchase", false)
		time_freeze_buy_button.disabled = not can_purchase
		time_freeze_buy_button.modulate = Color.GRAY if not can_purchase else Color.WHITE
	
	# Update activate button
	if time_freeze_activate_button:
		var can_activate = status.get("can_activate", false)
		time_freeze_activate_button.disabled = not can_activate
		time_freeze_activate_button.modulate = Color.GRAY if not can_activate else Color.GREEN
	
	# Update cooldown display
	if time_freeze_cooldown:
		var cooldown = status.get("cooldown", 0.0)
		var active_duration = status.get("active_duration", 0.0)
		
		if active_duration > 0.0:
			time_freeze_cooldown.text = "Active: %.1fs" % active_duration
			time_freeze_cooldown.visible = true
			time_freeze_cooldown.modulate = Color.CYAN
		elif cooldown > 0.0:
			time_freeze_cooldown.text = "Cooldown: %.1fs" % cooldown
			time_freeze_cooldown.visible = true
			time_freeze_cooldown.modulate = Color.RED
		else:
			time_freeze_cooldown.visible = false

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

# Test function for validating powerup UI functionality
func test_powerup_ui():
	"""Test function to validate powerup UI components"""
	print("=== POWERUP UI TEST RESULTS ===")
	
	# Test HUD visibility
	var hud_visible = hud and hud.visible
	print("HUD visible: ", hud_visible)
	
	# Test powerup panel visibility
	var panel_visible = powerup_panel and powerup_panel.visible
	print("Powerup panel visible: ", panel_visible)
	
	# Test button references
	var buttons_working = true
	var test_buttons = [
		["Reveal Protection Buy", reveal_protection_buy_button],
		["Reveal Mine Buy", reveal_mine_buy_button],
		["Reveal Safe Tile Buy", reveal_safe_tile_buy_button],
		["Hint System Buy", hint_system_buy_button],
		["Time Freeze Buy", time_freeze_buy_button],
		["Reveal Protection Activate", reveal_protection_activate_button],
		["Reveal Mine Activate", reveal_mine_activate_button],
		["Reveal Safe Tile Activate", reveal_safe_tile_activate_button],
		["Hint System Activate", hint_system_activate_button],
		["Time Freeze Activate", time_freeze_activate_button]
	]
	
	for button_info in test_buttons:
		var button_name = button_info[0]
		var button = button_info[1]
		if not button:
			print("ERROR: ", button_name, " button is null")
			buttons_working = false
		else:
			print("✓ ", button_name, " button found")
	
	print("All buttons working: ", buttons_working)
	
	# Test status labels
	var status_labels_working = true
	var test_status_labels = [
		["Reveal Protection Status", reveal_protection_status],
		["Reveal Mine Status", reveal_mine_status],
		["Reveal Safe Tile Status", reveal_safe_tile_status],
		["Hint System Status", hint_system_status],
		["Time Freeze Status", time_freeze_status]
	]
	
	for status_info in test_status_labels:
		var status_name = status_info[0]
		var status_label = status_info[1]
		if not status_label:
			print("ERROR: ", status_name, " label is null")
			status_labels_working = false
		else:
			print("✓ ", status_name, " label found")
	
	print("All status labels working: ", status_labels_working)
	
	# Test cooldown labels
	var cooldown_labels_working = true
	var test_cooldown_labels = [
		["Reveal Protection Cooldown", reveal_protection_cooldown],
		["Reveal Mine Cooldown", reveal_mine_cooldown],
		["Reveal Safe Tile Cooldown", reveal_safe_tile_cooldown],
		["Hint System Cooldown", hint_system_cooldown],
		["Time Freeze Cooldown", time_freeze_cooldown]
	]
	
	for cooldown_info in test_cooldown_labels:
		var cooldown_name = cooldown_info[0]
		var cooldown_label = cooldown_info[1]
		if not cooldown_label:
			print("ERROR: ", cooldown_name, " label is null")
			cooldown_labels_working = false
		else:
			print("✓ ", cooldown_name, " label found")
	
	print("All cooldown labels working: ", cooldown_labels_working)
	
	# Test powerup manager reference
	var manager_connected = powerup_manager != null
	print("Powerup manager connected: ", manager_connected)
	
	# Overall test result
	var all_tests_passed = hud_visible and panel_visible and buttons_working and status_labels_working and cooldown_labels_working
	print("\nOVERALL TEST RESULT: ", "PASSED" if all_tests_passed else "FAILED")
	print("============================")
	
	return all_tests_passed
