extends Control

# Main Menu Controller - Handles main menu UI logic
signal start_game_requested
signal difficulty_selected(difficulty_level: int)
signal quit_requested

# UI Elements
@onready var start_button = $StartButton
@onready var quit_button = $QuitButton
@onready var easy_button = $DifficultyContainer/EasyButton
@onready var medium_button = $DifficultyContainer/MediumButton
@onready var hard_button = $DifficultyContainer/HardButton

# Selected difficulty (0 = EASY, 1 = MEDIUM, 2 = HARD)
var selected_difficulty: int = 1 # Default to MEDIUM

func _ready():
    # Connect button signals
    if start_button:
        start_button.pressed.connect(_on_start_button_pressed)
    if quit_button:
        quit_button.pressed.connect(_on_quit_button_pressed)
    
    # Connect difficulty button signals
    if easy_button:
        easy_button.pressed.connect(_on_easy_button_pressed)
    if medium_button:
        medium_button.pressed.connect(_on_medium_button_pressed)
    if hard_button:
        hard_button.pressed.connect(_on_hard_button_pressed)
    
    # Set default difficulty selection
    set_difficulty_selection(selected_difficulty)

func _on_start_button_pressed():
    # Emit difficulty_selected signal before starting game
    difficulty_selected.emit(selected_difficulty)
    start_game_requested.emit()

func _on_quit_button_pressed():
    quit_requested.emit()

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