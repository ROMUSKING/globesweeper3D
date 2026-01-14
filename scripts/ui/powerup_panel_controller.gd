extends PanelContainer

# Powerup Panel Controller - Handles powerup UI logic
signal powerup_purchased_ui(powerup_type: String)
signal powerup_activated_ui(powerup_type: String)

# Powerup Manager reference
var powerup_manager: Node = null

# Reveal Protection Elements
@onready var reveal_protection_status = $PowerupVBox/PowerupScroll/PowerupList/RevealProtectionCard/RevealProtectionHBox/RevealProtectionInfo/RevealProtectionStatus
@onready var reveal_protection_buy_button = $PowerupVBox/PowerupScroll/PowerupList/RevealProtectionCard/RevealProtectionHBox/RevealProtectionButtons/RevealProtectionBuyButton
@onready var reveal_protection_activate_button = $PowerupVBox/PowerupScroll/PowerupList/RevealProtectionCard/RevealProtectionHBox/RevealProtectionButtons/RevealProtectionActivateButton
@onready var reveal_protection_cooldown = $PowerupVBox/PowerupScroll/PowerupList/RevealProtectionCard/RevealProtectionHBox/RevealProtectionCooldown

# Reveal Mine Elements
@onready var reveal_mine_status = $PowerupVBox/PowerupScroll/PowerupList/RevealMineCard/RevealMineHBox/RevealMineInfo/RevealMineStatus
@onready var reveal_mine_buy_button = $PowerupVBox/PowerupScroll/PowerupList/RevealMineCard/RevealMineHBox/RevealMineButtons/RevealMineBuyButton
@onready var reveal_mine_activate_button = $PowerupVBox/PowerupScroll/PowerupList/RevealMineCard/RevealMineHBox/RevealMineButtons/RevealMineActivateButton
@onready var reveal_mine_cooldown = $PowerupVBox/PowerupScroll/PowerupList/RevealMineCard/RevealMineHBox/RevealMineCooldown

# Reveal Safe Tile Elements
@onready var reveal_safe_tile_status = $PowerupVBox/PowerupScroll/PowerupList/RevealSafeTileCard/RevealSafeTileHBox/RevealSafeTileInfo/RevealSafeTileStatus
@onready var reveal_safe_tile_buy_button = $PowerupVBox/PowerupScroll/PowerupList/RevealSafeTileCard/RevealSafeTileHBox/RevealSafeTileButtons/RevealSafeTileBuyButton
@onready var reveal_safe_tile_activate_button = $PowerupVBox/PowerupScroll/PowerupList/RevealSafeTileCard/RevealSafeTileHBox/RevealSafeTileButtons/RevealSafeTileActivateButton
@onready var reveal_safe_tile_cooldown = $PowerupVBox/PowerupScroll/PowerupList/RevealSafeTileCard/RevealSafeTileHBox/RevealSafeTileCooldown

# Hint System Elements
@onready var hint_system_status = $PowerupVBox/PowerupScroll/PowerupList/HintSystemCard/HintSystemHBox/HintSystemInfo/HintSystemStatus
@onready var hint_system_buy_button = $PowerupVBox/PowerupScroll/PowerupList/HintSystemCard/HintSystemHBox/HintSystemButtons/HintSystemBuyButton
@onready var hint_system_activate_button = $PowerupVBox/PowerupScroll/PowerupList/HintSystemCard/HintSystemHBox/HintSystemButtons/HintSystemActivateButton
@onready var hint_system_cooldown = $PowerupVBox/PowerupScroll/PowerupList/HintSystemCard/HintSystemHBox/HintSystemCooldown

# Time Freeze Elements
@onready var time_freeze_status = $PowerupVBox/PowerupScroll/PowerupList/TimeFreezeCard/TimeFreezeHBox/TimeFreezeInfo/TimeFreezeStatus
@onready var time_freeze_buy_button = $PowerupVBox/PowerupScroll/PowerupList/TimeFreezeCard/TimeFreezeHBox/TimeFreezeButtons/TimeFreezeBuyButton
@onready var time_freeze_activate_button = $PowerupVBox/PowerupScroll/PowerupList/TimeFreezeCard/TimeFreezeHBox/TimeFreezeButtons/TimeFreezeActivateButton
@onready var time_freeze_cooldown = $PowerupVBox/PowerupScroll/PowerupList/TimeFreezeCard/TimeFreezeHBox/TimeFreezeCooldown

func _ready():
    # Connect powerup button signals
    connect_powerup_signals()
    
    # Initialize powerup UI
    initialize_powerup_ui()

func connect_powerup_signals():
    # Connect purchase buttons
    if reveal_protection_buy_button:
        reveal_protection_buy_button.pressed.connect(_on_reveal_protection_buy_pressed)
    if reveal_mine_buy_button:
        reveal_mine_buy_button.pressed.connect(_on_reveal_mine_buy_pressed)
    if reveal_safe_tile_buy_button:
        reveal_safe_tile_buy_button.pressed.connect(_on_reveal_safe_tile_buy_pressed)
    if hint_system_buy_button:
        hint_system_buy_button.pressed.connect(_on_hint_system_buy_pressed)
    if time_freeze_buy_button:
        time_freeze_buy_button.pressed.connect(_on_time_freeze_buy_pressed)
    
    # Connect activation buttons
    if reveal_protection_activate_button:
        reveal_protection_activate_button.pressed.connect(_on_reveal_protection_activate_pressed)
    if reveal_mine_activate_button:
        reveal_mine_activate_button.pressed.connect(_on_reveal_mine_activate_pressed)
    if reveal_safe_tile_activate_button:
        reveal_safe_tile_activate_button.pressed.connect(_on_reveal_safe_tile_activate_pressed)
    if hint_system_activate_button:
        hint_system_activate_button.pressed.connect(_on_hint_system_activate_pressed)
    if time_freeze_activate_button:
        time_freeze_activate_button.pressed.connect(_on_time_freeze_activate_pressed)

func initialize_powerup_ui():
    # Set up tooltips for powerup descriptions
    if reveal_protection_buy_button:
        reveal_protection_buy_button.tooltip_text = "Prevents mine explosion for one wrong click"
    if reveal_mine_buy_button:
        reveal_mine_buy_button.tooltip_text = "Automatically reveals one mine location"
    if reveal_safe_tile_buy_button:
        reveal_safe_tile_buy_button.tooltip_text = "Automatically reveals a safe tile"
    if hint_system_buy_button:
        hint_system_buy_button.tooltip_text = "Shows safe tiles around a specific area"
    if time_freeze_buy_button:
        time_freeze_buy_button.tooltip_text = "Pauses timer for 30 seconds"
    
    # Set up hover effects for all buttons
    setup_hover_effects()
    
    # Initial UI update
    update_powerup_ui()

func setup_hover_effects():
    # Setup hover effects for buy buttons
    setup_button_hover(reveal_protection_buy_button, "buy")
    setup_button_hover(reveal_mine_buy_button, "buy")
    setup_button_hover(reveal_safe_tile_buy_button, "buy")
    setup_button_hover(hint_system_buy_button, "buy")
    setup_button_hover(time_freeze_buy_button, "buy")
    
    # Setup hover effects for activate buttons
    setup_button_hover(reveal_protection_activate_button, "activate")
    setup_button_hover(reveal_mine_activate_button, "activate")
    setup_button_hover(reveal_safe_tile_activate_button, "activate")
    setup_button_hover(hint_system_activate_button, "activate")
    setup_button_hover(time_freeze_activate_button, "activate")

func setup_button_hover(button: Button, button_type: String):
    if not button:
        return
    
    # Connect mouse enter and exit signals for hover effects
    button.mouse_entered.connect(func():
        if not button.disabled:
            if button_type == "buy":
                button.modulate = Color(1.2, 1.2, 1.2) # Lighten on hover
            else:
                button.modulate = Color(1.1, 1.3, 1.1) # Green tint for activate
    )
    
    button.mouse_exited.connect(func():
        # Reset to normal color based on state
        if not button.disabled:
            if button_type == "buy":
                button.modulate = Color.WHITE
            else:
                button.modulate = Color.GREEN
        else:
            button.modulate = Color.GRAY
    )

# Powerup Manager integration
func set_powerup_manager_reference(manager: Node):
    powerup_manager = manager
    
    # Connect powerup manager signals if available
    if powerup_manager and powerup_manager.has_signal("powerup_purchased"):
        powerup_manager.powerup_purchased.connect(_on_powerup_purchased)
    if powerup_manager and powerup_manager.has_signal("powerup_activated"):
        powerup_manager.powerup_activated.connect(_on_powerup_activated)
    if powerup_manager and powerup_manager.has_signal("powerup_deactivated"):
        powerup_manager.powerup_deactivated.connect(_on_powerup_deactivated)
    
    # Initial UI update
    update_powerup_ui()

func update_powerup_ui():
    """Updates all powerup UI elements based on current state"""
    if not powerup_manager:
        return
    
    # Update all powerup displays
    update_powerup_display("reveal_protection")
    update_powerup_display("reveal_mine")
    update_powerup_display("reveal_safe_tile")
    update_powerup_display("hint_system")
    update_powerup_display("time_freeze")

func update_powerup_display(powerup_type: String):
    """Updates the display for a specific powerup"""
    if not powerup_manager:
        return
    
    var status = powerup_manager.get_powerup_status(powerup_type)
    if status.is_empty():
        return
    
    match powerup_type:
        "reveal_protection":
            update_reveal_protection_ui(status)
        "reveal_mine":
            update_reveal_mine_ui(status)
        "reveal_safe_tile":
            update_reveal_safe_tile_ui(status)
        "hint_system":
            update_hint_system_ui(status)
        "time_freeze":
            update_time_freeze_ui(status)

func update_reveal_protection_ui(status: Dictionary):
    update_powerup_card_ui("reveal_protection", status, {
        "status": reveal_protection_status,
        "buy_button": reveal_protection_buy_button,
        "activate_button": reveal_protection_activate_button,
        "cooldown": reveal_protection_cooldown,
        "activate_color": Color.GREEN
    })

func update_reveal_mine_ui(status: Dictionary):
    update_powerup_card_ui("reveal_mine", status, {
        "status": reveal_mine_status,
        "buy_button": reveal_mine_buy_button,
        "activate_button": reveal_mine_activate_button,
        "cooldown": reveal_mine_cooldown,
        "activate_color": Color.GREEN
    })

func update_reveal_safe_tile_ui(status: Dictionary):
    update_powerup_card_ui("reveal_safe_tile", status, {
        "status": reveal_safe_tile_status,
        "buy_button": reveal_safe_tile_buy_button,
        "activate_button": reveal_safe_tile_activate_button,
        "cooldown": reveal_safe_tile_cooldown,
        "activate_color": Color.GREEN
    })

func update_hint_system_ui(status: Dictionary):
    update_powerup_card_ui("hint_system", status, {
        "status": hint_system_status,
        "buy_button": hint_system_buy_button,
        "activate_button": hint_system_activate_button,
        "cooldown": hint_system_cooldown,
        "activate_color": Color.GREEN
    })

func update_time_freeze_ui(status: Dictionary):
    update_powerup_card_ui("time_freeze", status, {
        "status": time_freeze_status,
        "buy_button": time_freeze_buy_button,
        "activate_button": time_freeze_activate_button,
        "cooldown": time_freeze_cooldown,
        "activate_color": Color.CYAN
    })

## Generic method to update powerup card UI elements.
## Handles common UI update logic for all powerup types.
##
## Args:
##  powerup_type: The type of powerup being updated
##  status: Dictionary containing powerup status information
##  elements: Dictionary containing UI element references and configuration
func update_powerup_card_ui(powerup_type: String, status: Dictionary, elements: Dictionary) -> void:
    # Update status label
    if elements.has("status") and elements.status:
        elements.status.text = "Owned: %d | Available: %d" % [status.get("owned", 0), status.get("available", 0)]
    
    # Update buy button
    if elements.has("buy_button") and elements.buy_button:
        var can_purchase = status.get("can_purchase", false)
        elements.buy_button.disabled = not can_purchase
        elements.buy_button.modulate = Color.GRAY if not can_purchase else Color.WHITE
    
    # Update activate button
    if elements.has("activate_button") and elements.activate_button:
        var can_activate = status.get("can_activate", false)
        elements.activate_button.disabled = not can_activate
        var activate_color = elements.get("activate_color", Color.GREEN)
        elements.activate_button.modulate = Color.GRAY if not can_activate else activate_color
    
    # Update cooldown display
    if elements.has("cooldown") and elements.cooldown:
        var cooldown = status.get("cooldown", 0.0)
        var active_duration = status.get("active_duration", 0.0)
        
        if powerup_type == "time_freeze":
            # Special handling for time freeze with active duration
            if active_duration > 0.0:
                elements.cooldown.text = "Active: %.1fs" % active_duration
                elements.cooldown.visible = true
                elements.cooldown.modulate = Color.CYAN
            elif cooldown > 0.0:
                elements.cooldown.text = "Cooldown: %.1fs" % cooldown
                elements.cooldown.visible = true
                elements.cooldown.modulate = Color.RED
            else:
                elements.cooldown.visible = false
        else:
            # Standard cooldown display
            if cooldown > 0.0:
                elements.cooldown.text = "Cooldown: %.1fs" % cooldown
                elements.cooldown.visible = true
            else:
                elements.cooldown.visible = false

# Powerup Button Event Handlers
func _on_reveal_protection_buy_pressed():
    pulse_button(reveal_protection_buy_button)
    powerup_purchased_ui.emit("reveal_protection")

func _on_reveal_mine_buy_pressed():
    pulse_button(reveal_mine_buy_button)
    powerup_purchased_ui.emit("reveal_mine")

func _on_reveal_safe_tile_buy_pressed():
    pulse_button(reveal_safe_tile_buy_button)
    powerup_purchased_ui.emit("reveal_safe_tile")

func _on_hint_system_buy_pressed():
    pulse_button(hint_system_buy_button)
    powerup_purchased_ui.emit("hint_system")

func _on_time_freeze_buy_pressed():
    pulse_button(time_freeze_buy_button)
    powerup_purchased_ui.emit("time_freeze")

func _on_reveal_protection_activate_pressed():
    pulse_button(reveal_protection_activate_button)
    powerup_activated_ui.emit("reveal_protection")

func _on_reveal_mine_activate_pressed():
    pulse_button(reveal_mine_activate_button)
    powerup_activated_ui.emit("reveal_mine")

func _on_reveal_safe_tile_activate_pressed():
    pulse_button(reveal_safe_tile_activate_button)
    powerup_activated_ui.emit("reveal_safe_tile")

func _on_hint_system_activate_pressed():
    pulse_button(hint_system_activate_button)
    powerup_activated_ui.emit("hint_system")

func _on_time_freeze_activate_pressed():
    pulse_button(time_freeze_activate_button)
    powerup_activated_ui.emit("time_freeze")

# Powerup Manager Signal Handlers
func _on_powerup_purchased(powerup_type: String, cost: int):
    # Update UI when a powerup is purchased
    update_powerup_ui()

func _on_powerup_activated(powerup_type: String):
    # Update UI when a powerup is activated
    update_powerup_ui()

func _on_powerup_deactivated(powerup_type: String):
    # Update UI when a powerup is deactivated
    update_powerup_ui()

# Add visual pulse effect for button clicks
func pulse_button(button: Button):
    if not button or button.disabled:
        return
    
    var original_scale = button.scale
    var pulse_tween = create_tween()
    pulse_tween.tween_property(button, "scale", original_scale * 1.1, 0.1)
    pulse_tween.tween_property(button, "scale", original_scale, 0.1)

# Process function for cooldown updates
func _process(delta: float):
    # Update powerup UI for cooldown timers
    if powerup_manager:
        update_powerup_cooldowns(delta)

func update_powerup_cooldowns(delta: float):
    # Update cooldown displays in real-time
    if powerup_manager and visible:
        update_powerup_ui()

# Public API for external script integration
func refresh_powerup_ui():
    """Manually refreshes the powerup UI"""
    update_powerup_ui()