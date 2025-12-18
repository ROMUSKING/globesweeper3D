# Phase 5 Implementation Plan

This document outlines the step-by-step instructions for the Code Mode to implement the visual and mechanical refinements.

## Step 1: Geometry & Metadata Refactor

**Goal:** Optimize tile generation and prepare for robust interaction.

1. **Modify `scripts/globe_generator.gd`:**
    * **Optimization:** Instead of generating a new CSG mesh for every tile, generate **one** reference Hexagon mesh and **one** reference Pentagon mesh at the start. Reuse this `Mesh` resource for all `MeshInstance3D` nodes.
    * **Metadata:** When creating the `StaticBody3D` for a tile, add metadata:

        ```gdscript
        tile_node.set_meta("tile_index", index)
        ```

    * **Material:** Assign a placeholder `ShaderMaterial` (created in Step 4) instead of `StandardMaterial3D`.

## Step 2: Interaction Manager

**Goal:** Decouple input handling from `Main.gd` and improve accuracy.

1. **Create `scripts/interaction_manager.gd`:**
    * **Inherits:** `Node3D`.
    * **Signals:** `tile_hovered(index)`, `tile_clicked(index, button)`, `drag_started`, `drag_ended`, `drag_active(relative)`.
    * **Logic:**
        * Implement `_unhandled_input` to catch mouse events.
        * Perform raycasts using `PhysicsDirectSpaceState3D`.
        * On collision, check `collider.get_meta("tile_index")`.
        * Emit appropriate signals.
2. **Modify `scripts/main.gd`:**
    * Remove `_input` logic related to raycasting and dragging.
    * Instantiate `InteractionManager` in `_ready`.
    * Connect `InteractionManager` signals to local handler functions (e.g., `_on_tile_clicked`, `_on_globe_dragged`).

## Step 3: Cursor System

**Goal:** Efficient high-quality hover feedback.

1. **Create `scenes/cursor.tscn`:**
    * A simple `Node3D` containing a `MeshInstance3D`.
    * **Mesh:** A slightly larger version of the Hexagon mesh, but using `ImmediateMesh` or a wireframe shader, or simply a slightly scaled-up semi-transparent material.
    * **Animation:** Add a simple bobbing or glowing animation using an `AnimationPlayer`.
2. **Update `InteractionManager`:**
    * Instance the cursor scene.
    * In `_process` or `_physics_process`, if a tile is hovered:
        * `cursor.visible = true`
        * `cursor.global_position = hovered_tile.world_position`
        * `cursor.look_at(cursor.global_position + tile_normal)`
    * If no tile is hovered, `cursor.visible = false`.

## Step 4: Shader & Visuals

**Goal:** Replace flat colors with a polished shader system.

1. **Create `shaders/tile.gdshader`:**
    * Implement the uniform structure defined in `TECHNICAL_DOCS.md`.
    * Logic to switch appearance based on `u_state` (0=Hidden, 1=Revealed, etc.).
    * Add Fresnel rim lighting for a "glassy" or "tech" look.
2. **Update `scripts/globe_generator.gd`:**
    * Load this shader.
    * Create a `ShaderMaterial` instance.
    * Assign it to generated meshes.
3. **Update `scripts/main.gd`:**
    * Update `reveal_tile` to set shader uniforms instead of swapping materials.

        ```gdscript
        mesh.get_active_material(0).set_shader_parameter("u_state", 1.0)
        mesh.get_active_material(0).set_shader_parameter("u_revealed_color", get_color_for_mines(n))
        ```

## Step 5: Camera & Game Feel

**Goal:** Smooth controls and juicy interactions.

1. **Create `scripts/camera_controller.gd`:**
    * Move camera logic here.
    * Implement "Momentum":
        * Variable `angular_velocity` (Vector2).
        * Input adds to velocity.
        * Process loop applies velocity to rotation and applies friction (`velocity *= friction`).
2. **Update `scripts/main.gd`:**
    * Refactor `reveal_tile` to use Tweens.
    * **Tween Sequence:**

        ```gdscript
        var tween = create_tween()
        tween.tween_property(mesh, "scale", Vector3(1, 0.1, 1), 0.1)
        tween.tween_callback(func(): update_visuals())
        tween.tween_property(mesh, "scale", Vector3(1, 1.1, 1), 0.1)
        tween.tween_property(mesh, "scale", Vector3.ONE, 0.1)
        ```

## Execution Order for Code Mode

1. **Refactor Geometry:** Modify `globe_generator.gd` (Mesh reuse + Metadata).
2. **Input System:** Create `interaction_manager.gd` and integrate into `main.gd`.
3. **Cursor:** Implement the cursor visual.
4. **Visuals:** Write `tile.gdshader` and update material logic.
5. **Polish:** Implement Camera smoothing and Tween animations.
