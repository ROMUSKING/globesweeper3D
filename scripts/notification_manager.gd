extends Control

class_name NotificationManager

# Configuration
@export var notification_duration: float = 2.0
@export var notification_opacity: float = 0.7
@export var max_notifications: int = 5
@export var animation_speed: float = 0.35

# Runtime flags
var _suppressed: bool = false

# UI Elements
@onready var container = $NotificationContainer
@onready var template = $NotificationContainer/NotificationTemplate

# Notifications queue
var notifications: Array = []
var active_notifications: Array = []

# Signals
signal notification_shown(message: String)
signal notification_hidden(message: String)

func _ready():
	# Hide template if it exists
	if template:
		template.visible = false
	
	# Anchor container to bottom-right and set min size (avoid full-screen overlay)
	if container:
		container.anchor_top = 1.0
		container.anchor_bottom = 1.0
		# Use custom_minimum_size to avoid property mismatch on Container types
		container.custom_minimum_size = Vector2(400, 100)
		container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Manager itself should ignore mouse so it doesn't block gameplay
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Validate template exists
	if not template:
		push_warning("NotificationManager: NotificationTemplate node not found - notifications will be disabled")
		return

func show_notification(message: String, type: String = "info", duration: float = -1, bypass_suppression: bool = false):
	# When suppressed (e.g., during tutorial), normal notifications are ignored unless explicitly bypassed
	if _suppressed and not bypass_suppression:
		return
	if not template:
		push_warning("NotificationManager.show_notification called but NotificationTemplate is missing")
		return
	# Create new notification (use instance to preserve scenes in Godot 4 if template is a PackedScene)
	var notification = template.duplicate()
	notification.name = "Notification_%d" % randi()
	notification.visible = true
	# Make spawned notification a fixed-size control and ignore mouse events so UI below remains clickable
	notification.custom_minimum_size = Vector2(400, 50)
	# Allow children (Close button) to receive mouse events
	notification.mouse_filter = Control.MOUSE_FILTER_PASS
	
	# Set content - new path with MarginContainer/HBoxContainer
	var message_label = notification.get_node_or_null("MarginContainer/HBoxContainer/MessageLabel")
	if message_label:
		message_label.text = message
	# Connect close/dismiss button
	var close_btn = notification.get_node_or_null("MarginContainer/HBoxContainer/CloseButton")
	if not close_btn:
		close_btn = notification.find_child("CloseButton", true, false)
	if close_btn:
		# Ensure the button receives input and connect its press to remove this notification
		close_btn.mouse_filter = Control.MOUSE_FILTER_STOP
		close_btn.custom_minimum_size = Vector2(28, 28)
		close_btn.visible = true
		close_btn.disabled = false
		# Primary connection via pressed
		close_btn.pressed.connect(Callable(self, "_on_close_pressed").bind(notification))
		# Fallback: connect gui_input to capture click events if pressed isn't firing
		if close_btn.has_signal("gui_input"):
			close_btn.gui_input.connect(Callable(self, "_on_close_gui_input").bind(notification))
		print("NotificationManager: connected CloseButton for %s" % notification.name)
	else:
		print("NotificationManager: CloseButton not found for %s" % notification.name)
	
	# Set type styling - Background is now a sibling of MarginContainer
	var bg = notification.get_node_or_null("Background")
	if bg:
		match type:
			"info":
				bg.modulate = Color(0.2, 0.6, 1.0, notification_opacity) # Blue
			"success":
				bg.modulate = Color(0.2, 0.8, 0.2, notification_opacity) # Green
			"warning":
				bg.modulate = Color(1.0, 0.8, 0.2, notification_opacity) # Yellow
			"error":
				bg.modulate = Color(1.0, 0.3, 0.3, notification_opacity) # Red
			_:
				bg.modulate = Color(0.8, 0.8, 0.8, notification_opacity) # Gray
		# Ensure background doesn't block mouse input
		bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Add to container
	container.add_child(notification)
	notifications.append(notification)
	active_notifications.append(notification)
	
	# Ensure notification is positioned off-screen to the left so it animates in
	notification.position = Vector2(-400, 0)
	# Start animation
	var tween = create_tween()
	tween.tween_property(notification, "position:x", 0, animation_speed)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	
	# Set duration
	var display_duration = duration if duration > 0 else notification_duration
	
	# Schedule removal
	var timer = Timer.new()
	timer.wait_time = display_duration
	timer.one_shot = true
	timer.timeout.connect(_on_notification_timeout.bind(notification))
	add_child(timer)
	timer.start()
	
	notification_shown.emit(message)
	
	# Limit number of notifications
	if notifications.size() > max_notifications:
		var old_notification = notifications.pop_front()
		if old_notification in active_notifications:
			active_notifications.erase(old_notification)
		_remove_notification(old_notification)

func _on_notification_timeout(notification: Control):
	if notification in active_notifications:
		active_notifications.erase(notification)
		_remove_notification(notification)

func _remove_notification(notification: Control):
	if not notification or not is_instance_valid(notification):
		return
	
	# Fade out animation (works with container layouts)
	var tween = create_tween()
	tween.tween_property(notification, "modulate:a", 0.0, animation_speed)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_IN)
	tween.tween_callback(func(): _on_notification_removed(notification))
	print_debug("NotificationManager: removing %s" % notification.name)

func _on_notification_removed(notification: Control):
	if notification and is_instance_valid(notification):
		notification.queue_free()
		if notification in notifications:
			notifications.erase(notification)

func show_performance_notification(message: String, severity: int):
	var type = "info"
	match severity:
		0: type = "info"
		1: type = "warning"
		2: type = "error"
	
	show_notification(message, type, 5.0)

func show_tutorial_hint(message: String):
	# Tutorial hints bypass suppression so they can be shown while tutorial is active
	show_notification(message, "info", 4.0, true)

func show_game_tip(message: String):
	show_notification(message, "success", 3.0)

func clear_all_notifications():
	for notification in notifications.duplicate():
		_remove_notification(notification)
	notifications.clear()
	active_notifications.clear()

func suppress_notifications(enable: bool, clear_existing: bool = true):
	# When enabling suppression, optionally clear existing notifications; tutorial hints can still bypass suppression
	_suppressed = enable
	if enable and clear_existing:
		clear_all_notifications()
	# Ensure container visibility respects suppression
	if container:
		container.visible = not enable

func _on_close_pressed(notification: Control):
	# Called when CloseButton pressed; remove the notification
	print("NotificationManager: Close pressed for %s" % (notification.name if notification else "<null>"))
	_remove_notification(notification)

func _on_close_gui_input(event: InputEvent, notification: Control):
	# Fallback GUI input handler in case pressed signal doesn't fire
	if event is InputEventMouseButton and event.pressed:
		print("NotificationManager: gui_input click for %s" % (notification.name if notification else "<null>"))
		_remove_notification(notification)

func get_notification_count() -> int:
	return notifications.size()