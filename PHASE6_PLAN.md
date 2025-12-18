# Phase 6: Game Loop & UI Framework Plan

This document outlines the step-by-step implementation plan for moving GlobeSweeper 3D from a prototype to a structured game with a proper loop (Menu -> Playing -> Game Over).

## 1. UI Architecture Restructuring

We will move away from the monolithic `ui.tscn` and create modular UI components.

### 1.1 Directory Setup

- Create directory: `scenes/ui/`

### 1.2 Modular Scenes

Create the following scenes. Root nodes should be `Control` (set to Full Rect).

1. **`scenes/ui/MainMenu.tscn`**
    - **Root:** Control (`MainMenu`)
    - **Children:**
        - `TitleLabel`: Label (Large font, centered top)
        - `StartButton`: Button (Centered)
        - `QuitButton`: Button (Optional, below start)
    - **Script:** None required initially, or a simple one to emit signals. For simplicity, the `UIManager` can connect directly to these if they are exposed, but a script on root emitting `start_game` is cleaner.

2. **`scenes/ui/HUD.tscn`**
    - **Root:** Control (`HUD`)
    - **Children:**
        - `TopBar`: PanelContainer (Top wide)
            - `HBoxContainer`:
                - `TimeLabel`: Label ("00:00")
                - `MineCounter`: Label ("Mines: 10")
                - `MenuButton`: Button (Pause/Menu)

3. **`scenes/ui/GameOver.tscn`**
    - **Root:** Control (`GameOver`)
    - **Children:**
        - `Background`: ColorRect (Black with alpha 0.5 for overlay)
        - `VBoxContainer` (Centered):
            - `ResultLabel`: Label ("You Win!" / "Game Over")
            - `StatsLabel`: Label (Time, Best Streak, etc.)
            - `RestartButton`: Button
            - `MainMenuButton`: Button

### 1.3 UIManager (`scenes/ui.tscn`) refactor

Refactor the existing `scenes/ui.tscn` and `scripts/ui.gd` to act as the orchestrator.

- **Structure:**
  - `UI` (Control - Full Rect)
    - `MainMenu` (Instance of `MainMenu.tscn`)
    - `HUD` (Instance of `HUD.tscn`)
    - `GameOver` (Instance of `GameOver.tscn`)
- **Script (`scripts/ui.gd`):**
  - **Responsibilities:**
    - Manage visibility of child scenes.
    - Expose high-level signals: `start_game`, `restart_game`, `quit_to_menu`.
    - Provide methods for `Main.gd` to update data: `update_timer(time)`, `update_mine_count(count)`, `show_game_over(win: bool)`.

## 2. Game State Machine (`scripts/main.gd`)

Refactor `scripts/main.gd` to use a robust State Machine pattern instead of boolean flags.

### 2.1 Define States

Add an enum at the top of the script:

```gdscript
enum GameState {
    MENU,
    PLAYING,
    PAUSED,
    GAME_OVER
}
var current_state: GameState = GameState.MENU
```

### 2.2 State Management Functions

Implement `change_state(new_state: GameState)`:

- **`MENU`**:
  - Show Main Menu UI.
  - Disable `InteractionManager` (or block tile clicks).
  - Reset Globe (generate new or clear mines).
  - Camera: Maybe auto-rotate slowly?
- **`PLAYING`**:
  - Show HUD UI.
  - Enable `InteractionManager`.
  - Start Timer (if not resuming).
- **`PAUSED`**:
  - Show Pause UI (can reuse MainMenu or a dedicated Pause modal).
  - Pause Timer.
  - Disable `InteractionManager`.
- **`GAME_OVER`**:
  - Show Game Over UI.
  - Disable `InteractionManager`.
  - Stop Timer.

### 2.3 Refactoring Existing Logic

- **`_process`**: Only update timer if `current_state == GameState.PLAYING`.
- **`_input`**: Update to respect states.
- **`_ready`**: Initialize into `GameState.MENU` instead of immediately starting.
- **`reveal_tile`**: Check `current_state == GameState.PLAYING`.
  - On Game Over/Win: Call `change_state(GameState.GAME_OVER)`.

## 3. Integration Steps

### Step 1: Create UI Scenes

1. Create the folder `scenes/ui`.
2. Create `MainMenu.tscn`, `HUD.tscn`, `GameOver.tscn` with the structure defined above.
3. Modify `scripts/ui.gd` to handle these instances and their signals.

### Step 2: Implement State Machine

1. Open `scripts/main.gd`.
2. Add the `GameState` enum.
3. Replace `game_over`, `game_won`, `game_paused`, `game_started` flags with `current_state` logic where appropriate.
4. Implement `change_state` function.

### Step 3: Connect Logic

1. In `Main._ready()`:
    - Connect `ui.start_game` signal -> `change_state(GameState.PLAYING)`.
    - Connect `ui.restart_game` signal -> `reset_game()` then `change_state(GameState.PLAYING)`.
2. Update `InteractionManager` integration to respect the new states.

## 4. Technical Details

### `Main.gd` Changes

```gdscript
# New State Variable
var current_state: GameState = GameState.MENU

func change_state(new_state: GameState):
    current_state = new_state
    match current_state:
        GameState.MENU:
            ui.show_main_menu()
            interaction_manager.set_process_input(false) # Block input
            # Optional: Auto-rotate camera
        GameState.PLAYING:
            ui.show_hud()
            interaction_manager.set_process_input(true)
        GameState.GAME_OVER:
            ui.show_game_over(game_won)
            interaction_manager.set_process_input(false)
```

### `UI.gd` API

```gdscript
signal start_game_requested
signal restart_game_requested
signal menu_requested

func show_main_menu()
func show_hud()
func show_game_over(is_win: bool)
func update_time(value)
func update_mines(value)
```

## 5. Next Steps for Implementation

Switch to **Code Mode** and follow the steps:

1. Create the UI scenes (`MainMenu`, `HUD`, `GameOver`).
2. Update `ui.tscn` and `ui.gd`.
3. Refactor `main.gd` to implement the State Machine.
