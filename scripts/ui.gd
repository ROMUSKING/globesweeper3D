extends Control

signal game_reset_requested

@onready var time_label = $HBoxContainer/TimeLabel
@onready var mine_label = $HBoxContainer/MineLabel
@onready var reset_button = $HBoxContainer/ResetButton
@onready var game_over_label = $GameOverLabel

func _ready():
	# Ensure UI root doesn't block mouse input for the game
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	reset_button.pressed.connect(_on_reset_button_pressed)
	game_over_label.visible = false

func update_time(time):
	time_label.text = "Time: " + str(time)

func update_mines(mines):
	mine_label.text = "Mines: " + str(mines)

func show_game_over(message):
	game_over_label.text = message
	game_over_label.visible = true

func hide_game_over():
	game_over_label.visible = false

func _on_reset_button_pressed():
	game_over_label.visible = false
	game_reset_requested.emit()
