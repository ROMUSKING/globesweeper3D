class_name GameOverController
extends Control

# Game Over Controller - Handles game over screen UI logic
signal restart_game_requested
signal menu_requested

# Game Over Elements
@onready var result_label = $VBoxContainer/ResultLabel
@onready var restart_button = $VBoxContainer/RestartButton
@onready var main_menu_button = $VBoxContainer/MainMenuButton

func _ready():
    # Connect button signals
    if restart_button:
        restart_button.pressed.connect(_on_restart_button_pressed)
    if main_menu_button:
        main_menu_button.pressed.connect(_on_main_menu_button_pressed)

func _on_restart_button_pressed():
    restart_game_requested.emit()

func _on_main_menu_button_pressed():
    menu_requested.emit()

func show_game_over(is_win: bool):
    if result_label:
        if is_win:
            result_label.text = "You Win!"
        else:
            result_label.text = "Game Over"