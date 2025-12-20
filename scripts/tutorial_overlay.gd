extends Control

class_name TutorialOverlay

# References
var tutorial_manager

# UI Elements
@onready var title_label = $Container/TitleLabel
@onready var description_label = $Container/DescriptionLabel
@onready var tutorial_image = $Container/ImageContainer/TutorialImage
@onready var progress_bar = $Container/ProgressBar
@onready var skip_button = $Container/ButtonContainer/SkipButton
@onready var next_button = $Container/ButtonContainer/NextButton
@onready var skip_confirmation_panel = $Container/SkipConfirmationPanel
@onready var skip_confirm_button = $Container/SkipConfirmationPanel/ButtonContainer/ConfirmButton
@onready var skip_cancel_button = $Container/SkipConfirmationPanel/ButtonContainer/CancelButton

# Animation - create tweens on demand (avoids start/stop compatibility issues)
# Tweens will be created when showing/hiding to ensure they exist and run correctly

# State
var showing_skip_confirmation: bool = false

func _ready():
	# Connect button signals safely
	if skip_button:
		skip_button.pressed.connect(_on_skip_pressed)
	if next_button:
		next_button.pressed.connect(_on_next_pressed)
	# Use get_node_or_null to avoid crashes if buttons are missing (scene changes)
	if skip_confirm_button:
		skip_confirm_button.pressed.connect(_on_skip_confirm_pressed)
	else:
		push_warning("TutorialOverlay: ConfirmButton missing")
	if skip_cancel_button:
		skip_cancel_button.pressed.connect(_on_skip_cancel_pressed)
	else:
		push_warning("TutorialOverlay: CancelButton missing")
	
	# Ensure proper initial state
	hide_tutorial_overlay()
	hide_skip_confirmation()

func show_tutorial_overlay(step_data: Dictionary):
	if step_data.is_empty():
		return
	
	visible = true
	modulate = Color(1, 1, 1, 0)
	
	# Update UI elements
	title_label.text = step_data.get("title", "")
	description_label.text = step_data.get("description", "")
	
	# Load tutorial image if available
	if step_data.has("image"):
		var image_path = step_data.image
		if ResourceLoader.exists(image_path):
			var texture = load(image_path)
			tutorial_image.texture = texture
		else:
			tutorial_image.texture = null
	
	# Update progress bar
	if tutorial_manager:
		var progress = tutorial_manager.get_tutorial_completion_percentage()
		progress_bar.value = progress
	
	# Configure buttons
	if step_data.get("action_required", false):
		next_button.visible = false
		skip_button.text = "Skip Tutorial"
	else:
		next_button.visible = true
		skip_button.text = "Skip Tutorial"
	
	# Play fade in animation (create tween on demand)
	var fade_tween = create_tween()
	fade_tween.tween_property(self, "modulate:a", 1.0, 0.5)
	fade_tween.set_trans(Tween.TRANS_QUAD)
	fade_tween.set_ease(Tween.EASE_OUT)

func hide_tutorial_overlay():
	if not visible:
		return
	
	# Create fade-out tween on demand
	var fade_tween = create_tween()
	fade_tween.tween_property(self, "modulate:a", 0.0, 0.5)
	fade_tween.set_trans(Tween.TRANS_QUAD)
	fade_tween.set_ease(Tween.EASE_IN)
	fade_tween.finished.connect(_on_fade_out_complete)

func _on_fade_out_complete():
	visible = false
	modulate = Color(1, 1, 1, 0)

func _on_skip_pressed():
	if tutorial_manager:
		if tutorial_manager.show_skip_confirmation:
			show_skip_confirmation()
		else:
			tutorial_manager.confirm_skip_tutorial()
			hide_tutorial_overlay()

func _on_next_pressed():
	if tutorial_manager:
		tutorial_manager.advance_tutorial_step()

func show_skip_confirmation():
	if showing_skip_confirmation:
		return
	
	showing_skip_confirmation = true
	skip_confirmation_panel.visible = true
	skip_confirmation_panel.modulate = Color(1, 1, 1, 0)
	
	# Hide main buttons
	skip_button.visible = false
	next_button.visible = false
	
	# Play fade in animation (create tween on demand)
	var skip_in = create_tween()
	skip_in.tween_property(skip_confirmation_panel, "modulate:a", 1.0, 0.3)
	skip_in.set_trans(Tween.TRANS_QUAD)
	skip_in.set_ease(Tween.EASE_OUT)

func hide_skip_confirmation():
	if not showing_skip_confirmation:
		return
	
	showing_skip_confirmation = false
	var skip_out = create_tween()
	skip_out.tween_property(skip_confirmation_panel, "modulate:a", 0.0, 0.3)
	skip_out.set_trans(Tween.TRANS_QUAD)
	skip_out.set_ease(Tween.EASE_IN)
	skip_out.finished.connect(_on_skip_confirmation_fade_out_complete)

func _on_skip_confirmation_fade_out_complete():
	skip_confirmation_panel.visible = false
	skip_confirmation_panel.modulate = Color(1, 1, 1, 0)
	
	# Show main buttons again
	skip_button.visible = true
	next_button.visible = true

func _on_skip_confirm_pressed():
	if tutorial_manager:
		tutorial_manager.confirm_skip_tutorial()
		hide_tutorial_overlay()
		hide_skip_confirmation()

func _on_skip_cancel_pressed():
	if tutorial_manager:
		tutorial_manager.cancel_skip_tutorial()
		hide_skip_confirmation()

func set_tutorial_manager(manager):
	tutorial_manager = manager