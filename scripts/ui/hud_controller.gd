extends Control

# HUD Controller - Handles heads-up display UI logic
signal menu_requested
signal pause_requested

# HUD Elements
@onready var time_label = $TopBar/HBoxContainer/TimeLabel
@onready var mine_counter = $TopBar/HBoxContainer/MineCounter
@onready var score_label = $TopBar/HBoxContainer/ScoreLabel
@onready var menu_button = $TopBar/HBoxContainer/MenuButton
@onready var difficulty_label = $TopBar/HBoxContainer/DifficultyLabel

# Powerup Panel
@onready var powerup_panel = $PowerupPanel

# Game State Manager reference
var game_state_manager: Node = null

func _ready():
    # Connect menu button signal
    if menu_button:
        menu_button.pressed.connect(_on_menu_button_pressed)

func _on_menu_button_pressed():
    menu_requested.emit()

func update_time(time_value):
    # Update time display
    if time_label:
        time_label.text = str(time_value)

func update_mines(count):
    # Update mine counter
    if mine_counter:
        mine_counter.text = "Mines: " + str(count)

func update_score(score):
    # Update score display
    if score_label:
        score_label.text = "Score: " + str(score)

func update_difficulty_display(difficulty_level: float):
    # Update difficulty display
    if difficulty_label:
        difficulty_label.text = "Difficulty: %.2fx" % difficulty_level

# Game State Manager integration
func set_game_state_manager_reference(manager: Node):
    game_state_manager = manager

func show_powerup_panel(show: bool):
    # Show or hide powerup panel
    if powerup_panel:
        powerup_panel.visible = show