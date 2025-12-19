extends Control

signal start_game_requested
signal restart_game_requested
signal menu_requested

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

# Game Over Elements
@onready var result_label = $GameOver/VBoxContainer/ResultLabel
@onready var restart_button = $GameOver/VBoxContainer/RestartButton
@onready var main_menu_button = $GameOver/VBoxContainer/MainMenuButton

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
	start_game_requested.emit()

func _on_restart_button_pressed():
	restart_game_requested.emit()

func _on_menu_button_pressed():
	menu_requested.emit()

func _on_main_menu_button_pressed():
	menu_requested.emit()

func _on_quit_button_pressed():
	get_tree().quit()
