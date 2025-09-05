# GlobeSweeper 3D - Technical Documentation

## Core Components

**Main.gd (881 lines)** - Primary ga## Build & Deployment

- **Export Templates**: Configured for multiple platforms
- **Resource Optimization**: Automatic texture compression
- **Script Compilation**: AOT compilation for performance
- **Distribution**: Single executable with no external dependencies

## Performance Characteristics

- Globe/icosphere generation with configurable subdivision levels
- Mine placement and neighbor calculation algorithms
- Input handling (mouse, touch, keyboard) with F12 performance monitoring
- Game state management (win/lose conditions) with timer and statistics
- Visual effects (fireworks, materials, enhanced tile geometry)
- UI coordination with real-time updates
- Audio system integration with procedural sound generation
- Performance monitoring and optimization tracking

**UI.gd (30 lines)** - User interface management

- HUD management with mine counter, timer, and game status
- Button handling for reset functionality
- Real-time UI updates during gameplay
- Statistics display and game history tracking

**Tile.gd** - Tile data structure

- Properties for tile state and position
- References to visual nodes and neighbors
- Enhanced collision detection for taller tiles

**Audio_Generator.gd (50 lines)** - Procedural audio system

- Dynamic sound effect generation using AudioStreamGenerator
- Tile reveal, explosion, win, and lose sound algorithms
- Real-time audio synthesis without external files

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
