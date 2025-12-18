# GlobeSweeper 3D - Technical Documentation

## Core Components

**Main.gd** - Primary game controller

- Manages game state (timer, win/lose conditions, statistics)
- Handles input coordination (rotation vs. interaction)
- Coordinates between `GlobeGenerator`, `AudioManager`, and `UI`
- Implements first-click safety and mine placement logic

**GlobeGenerator.gd** - Geometry generation system

- Handles icosphere generation and subdivision
- Converts triangular faces to hexagonal tile positions
- Instantiates `Tile` objects and their visual nodes (`StaticBody3D`)
- Calculates tile neighbors for adjacency logic

**AudioManager.gd** - Procedural audio system

- Dynamic sound effect generation using `AudioStreamGenerator`
- Tile reveal, explosion, win, and lose sound algorithms
- Real-time audio synthesis without external files

**UI.gd** - User interface management

- HUD management with mine counter, timer, and game status
- Communicates with `Main.gd` via signals
- Real-time UI updates during gameplay

**Tile.gd** - Tile data structure

- `RefCounted` class representing a single tile's state
- Properties for index, position, mine status, revelation, and neighbors
- References to visual nodes and meshes

## Key Algorithms

### Icosphere Generation

1. Start with icosahedron (12 vertices, 20 triangular faces)
2. Subdivide each triangular face into 4 smaller triangles
3. Project vertices onto unit sphere surface
4. Convert triangular faces to hexagonal tiles
5. Apply enhanced geometry (3.0 unit height, inward positioning)

### Neighbor Calculation

1. Use icosphere face data to determine adjacency
2. Identify shared edges between triangular faces
3. Build adjacency graph for each vertex
4. Ensure proper hexagonal connectivity
5. Validate for chord reveals and flood-fill operations

### Mine Placement

1. Random distribution based on percentage setting
2. Ensure fair distribution across globe surface
3. Calculate neighbor mine counts for all tiles
4. First-click safety guarantee implementation

### Audio Generation

1. Initialize AudioStreamGenerator with appropriate parameters
2. Create algorithmic waveforms for different sound types
3. Apply frequency modulation and amplitude shaping
4. Push audio frames to playback stream in real-time

### Performance Monitoring

1. Initialize performance tracking variables
2. Update metrics every frame using Godot's Performance singleton
3. Calculate generation timing using system time functions
4. Display comprehensive reports via F12 keyboard shortcut

## Configuration

```gdscript
@export var globe_radius: float = 20.0      # Globe size (affects camera distance)
@export var mine_percentage: float = 0.15   # Mine density (15% default)
@export var subdivision_level: int = 1      # Icosphere detail level
```

## Performance Characteristics

- **Frame Rate**: 60+ FPS on modern hardware
- **Memory Usage**: ~50-100MB depending on globe size
- **Audio Latency**: <10ms for procedural sound generation
- **Generation Time**: <1 second for standard globe sizes
- **Draw Calls**: Optimized for Forward+ rendering pipeline

## Development Environment

- **Godot Version**: 4.4.1 (stable)
- **GDScript**: Full utilization of Godot 4 features
- **Version Control**: Git with comprehensive commit history
- **Documentation**: Markdown-based technical documentation
- **Testing**: Manual testing with performance monitoring

## Known Limitations & Future Improvements

1. **Memory Scaling**: Large globe sizes may require memory optimization
2. **Mobile Performance**: Touch controls optimized but performance may vary
3. **Audio Variety**: Current procedural audio is functional but could be enhanced
4. **Visual Effects**: Basic materials could be enhanced with shaders
5. **Save/Load**: Game state persistence not yet implemented

## Build & Deployment

- **Export Templates**: Configured for multiple platforms
- **Resource Optimization**: Automatic texture compression
- **Script Compilation**: AOT compilation for performance
- **Distribution**: Single executable with no external dependencies

## Performance Guidelines

- Low End: subdivision_level = 2 (42 tiles)
- Mid Range: subdivision_level = 3 (162 tiles)
- High End: subdivision_level = 4 (642 tiles)
- Ultra: subdivision_level = 5 (2562 tiles)

## Data Structures

### Tile Class (scripts/tile.gd)

```gdscript
class_name Tile
extends RefCounted

var index: int                   # Unique identifier
var position: Vector3            # Normalized position on unit sphere
var world_position: Vector3      # Scaled world coordinates
var has_mine: bool = false       # Mine presence
var neighbor_mines: int = 0      # Adjacent mine count
var is_revealed: bool = false    # Current revelation state
var is_flagged: bool = false     # Flag state
var neighbors: Array = []        # Array of adjacent tile indices
var node: Node3D                 # Visual node reference (StaticBody3D)
var mesh: MeshInstance3D         # Mesh component reference
```

## Controls

### Mouse

- Left Click: Reveal tile
- Right Click: Toggle flag
- Drag: Rotate globe
- Double Click: Chord reveal

### Touch

- Single Tap: Reveal tile
- Double Tap: Chord reveal
- Touch Drag: Rotate globe

## Materials

- Unrevealed: Dark gray, metallic appearance
- Revealed: Light blue, smooth finish
- Flagged: Bright red, high visibility
- Mine: Dark red, metallic sheen

## Dependencies

- Godot Engine 4.4+
- No external assets (procedural generation)

## Extension Points

- Export variables for easy configuration
- Modular design allows feature additions
- Comprehensive comments for maintainability

## Testing

- Test geometry generation at different subdivision levels
- Verify neighbor calculations
- Test input handling across platforms
- Performance testing with various configurations

# Phase 5: Visual Polish & Mechanics Refinement

## Visual Architecture

### Shader-Based Material System

Instead of swapping distinct `StandardMaterial3D` resources, we will utilize a unified `ShaderMaterial` for all tiles. This improves batching and allows for smooth transitions.

**Shader Logic (`tiles.gdshader`):**

- **Uniforms:**
  - `vec3 u_base_color`: Color for the unrevealed state.
  - `vec3 u_revealed_color`: Color for the revealed state.
  - `float u_state`: Integer/Float representing state (0=Hidden, 1=Revealed, 2=Flagged, 3=Mine).
  - `float u_hover_intensity`: 0.0 to 1.0 for hover highlight logic (if tile-based hover is used).
  - `sampler2D u_noise_texture`: For surface detail/roughness variation.
- **Fragment Shader:**
  - Mixes colors based on `u_state`.
  - Adds a rim light effect (Fresnel) to accentuate the 3D curvature.
  - Optional: Subtle pulse effect for unrevealed tiles.

### Cursor System

To avoid modifying thousands of tile materials per frame for hover effects, we will implement a dedicated **Cursor** object.

- **Visual:** A glowing wireframe hexagon mesh.
- **Behavior:** The cursor snaps to the `global_position` and `rotation` of the currently hovered tile.
- **Benefit:** Decouples the "selection" visual from the "tile" visual, allowing for a high-fidelity selection effect without uniform updates on the terrain.

## Interaction Design

### InteractionManager

A dedicated node `InteractionManager` (or `InteractionController`) will handle input raycasting, decoupling it from `Main.gd`.

**Core Logic:**

1. **Input Processing:** Listens to `_unhandled_input` or `_physics_process` for mouse/touch events.
2. **Raycasting:** Uses `PhysicsDirectSpaceState3D` to detect collisions.
3. **Identification:**
    - **Refinement:** Instead of parsing string names (`Tile_123`), we will assign metadata to the `StaticBody3D` nodes during generation: `collision_object.set_meta("tile_index", index)`.
    - The raycast result simply retrieves `collider.get_meta("tile_index")`.
4. **Signals:**
    - `tile_hovered(index: int)`
    - `tile_clicked(index: int, button: int)`
    - `background_dragged(relative: Vector2)`

### Camera & Controls

- **Orbiting:** Continue using the existing rotation logic but move it to a `CameraController`.
- **Smoothing (Momentum):** Implement an inertia system.
  - `angular_velocity`: Adds to rotation every frame.
  - `drag`: Decays velocity over time.
  - Mouse drag adds to `angular_velocity` instead of directly setting rotation.

## Animation Strategy

### Reveal Animations

Avoid instant state changes. Use `Tween` for "Game Feel".

- **Sequence:**
  1. **Squash:** Scale Y down to 0.1 over 0.1s.
  2. **State Change:** Update internal state (is_revealed) and visuals (add number, change color).
  3. **Stretch:** Scale Y up to 1.1 over 0.1s.
  4. **Settle:** Scale Y back to 1.0 over 0.05s.
- **Audio Sync:** Trigger "pop" sound at the start of the sequence.
