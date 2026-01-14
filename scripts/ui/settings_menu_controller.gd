extends Control

# Settings Menu Controller - Handles settings menu UI logic
signal settings_closed
signal difficulty_scaling_toggled(enabled: bool)
signal difficulty_scaling_mode_changed(mode: int)
signal difficulty_reset_requested
signal difficulty_rollback_requested(steps: int)

# Settings Menu Elements
@onready var back_button = $VBoxContainer/BackButton
@onready var scaling_toggle = $VBoxContainer/ScalingContainer/ScalingToggle
@onready var scaling_mode_selector = $VBoxContainer/ScalingContainer/ScalingModeSelector
@onready var reset_difficulty_button = $VBoxContainer/ScalingContainer/ResetDifficultyButton
@onready var rollback_difficulty_button = $VBoxContainer/ScalingContainer/RollbackDifficultyButton
@onready var scaling_status_label = $VBoxContainer/ScalingContainer/ScalingStatusLabel
@onready var performance_metrics_label = $VBoxContainer/ScalingContainer/PerformanceMetricsLabel

# Difficulty Scaling Manager reference
var difficulty_scaling_manager: Node = null

func _ready():
	# Connect settings menu button signals
	if back_button:
		back_button.pressed.connect(_on_back_button_pressed)
	
	# Connect difficulty scaling signals
	connect_difficulty_scaling_signals()

func _on_back_button_pressed():
	settings_closed.emit()

func connect_difficulty_scaling_signals():
	if scaling_toggle:
		scaling_toggle.toggled.connect(_on_scaling_toggle_toggled)
	if scaling_mode_selector:
		scaling_mode_selector.item_selected.connect(_on_scaling_mode_selected)
	if reset_difficulty_button:
		reset_difficulty_button.pressed.connect(_on_reset_difficulty_pressed)
	if rollback_difficulty_button:
		rollback_difficulty_button.pressed.connect(_on_rollback_difficulty_pressed)

# Difficulty Scaling Signal Handlers
func _on_scaling_toggle_toggled(enabled: bool):
	if difficulty_scaling_manager:
		difficulty_scaling_manager.set_scaling_enabled(enabled)
	difficulty_scaling_toggled.emit(enabled)

func _on_scaling_mode_selected(mode_index: int):
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
	if difficulty_scaling_manager:
		difficulty_scaling_manager.reset_difficulty()
	difficulty_reset_requested.emit()

func _on_rollback_difficulty_pressed():
	if difficulty_scaling_manager:
		difficulty_scaling_manager.rollback_difficulty(1)
	difficulty_rollback_requested.emit(1)

# Difficulty Scaling Manager integration
func set_difficulty_scaling_manager_reference(manager: Node):
	difficulty_scaling_manager = manager
	update_difficulty_scaling_ui()

func update_difficulty_scaling_ui():
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
