extends Control

@onready var time_label = $HBoxContainer/TimeLabel
@onready var mine_label = $HBoxContainer/MineLabel
@onready var reset_button = $HBoxContainer/ResetButton
@onready var game_over_label = $GameOverLabel

func _ready():
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
	var main_node = get_node("../")
	if main_node.has_method("reset_game"):
		main_node.reset_game()
