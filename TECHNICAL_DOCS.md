# GlobeSweeper 3D - Technical Documentation

## Core Components

**Main.gd (569 lines)** - Primary game controller

- Globe/icosphere generation with configurable subdivision levels
- Mine placement and neighbor calculation algorithms
- Input handling (mouse, touch, keyboard)
- Game state management (win/lose conditions)
- Visual effects (fireworks, materials)
- UI coordination

**UI.gd** - User interface management

- HUD management with mine counter and game status
- Button handling for reset functionality
- Real-time UI updates during gameplay

**Tile.gd** - Tile data structure

- Properties for tile state and position
- References to visual nodes and neighbors

## Key Algorithms

### Icosphere Generation

1. Start with icosahedron (12 vertices, 20 triangular faces)
2. Subdivide each triangular face into 4 smaller triangles
3. Project vertices onto unit sphere surface
4. Convert triangular faces to hexagonal tiles

### Neighbor Calculation

1. Use icosphere face data to determine adjacency
2. Identify shared edges between triangular faces
3. Build adjacency graph for each vertex
4. Ensure proper hexagonal connectivity

### Mine Placement

1. Random distribution based on percentage setting
2. Ensure fair distribution across globe surface
3. Calculate neighbor mine counts for all tiles

## Configuration

```gdscript
@export var globe_radius: float = 20.0      # Globe size
@export var subdivision_level: int = 3      # Detail level (2-5 recommended)
@export var mine_percentage: float = 0.15   # Mine density (0.1-0.3 recommended)
@export var tile_scale: float = 1.8         # Visual tile size multiplier
```

## Performance Guidelines

- Low End: subdivision_level = 2 (42 tiles)
- Mid Range: subdivision_level = 3 (162 tiles)
- High End: subdivision_level = 4 (642 tiles)
- Ultra: subdivision_level = 5 (2562 tiles)

## Data Structures

### Tile Dictionary

```gdscript
{
    "index": int,                    # Unique identifier
    "position": Vector3,             # Unit sphere position
    "world_position": Vector3,       # Scaled world coordinates
    "has_mine": bool,                # Mine presence
    "is_revealed": bool,             # Current revelation state
    "is_flagged": bool,              # Flag state
    "neighbor_mines": int,           # Adjacent mine count (0-8)
    "neighbors": Array,              # Array of adjacent tile indices
    "node": StaticBody3D,            # Visual node reference
    "mesh": MeshInstance3D           # Mesh component reference
}
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
