class_name PauseMenuController
extends Control

# Pause Menu Controller - Handles pause menu UI logic
signal resume_requested
signal restart_requested
signal menu_requested
signal settings_requested

# Pause Menu Elements
@onready var resume_button = $VBoxContainer/ResumeButton
@onready var restart_button = $VBoxContainer/RestartButton
@onready var menu_button = $VBoxContainer/MenuButton
@onready var settings_button = $VBoxContainer/SettingsButton

func _ready():
    # Connect pause menu button signals
    if resume_button:
        resume_button.pressed.connect(_on_resume_button_pressed)
    if restart_button:
        restart_button.pressed.connect(_on_restart_button_pressed)
    if menu_button:
        menu_button.pressed.connect(_on_menu_button_pressed)
    if settings_button:
        settings_button.pressed.connect(_on_settings_button_pressed)

func _on_resume_button_pressed():
    resume_requested.emit()

func _on_restart_button_pressed():
    restart_requested.emit()

func _on_menu_button_pressed():
    menu_requested.emit()

func _on_settings_button_pressed():
    settings_requested.emit()