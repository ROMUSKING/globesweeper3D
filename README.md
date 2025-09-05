# GlobeSweeper 3D

A unique 3D implementation of the classic Minesweeper game featuring spherical gameplay on an icosphere geometry.

![Game Screenshot](icon.svg)

## 🎮 Overview

GlobeSweeper 3D transforms the traditional Minesweeper experience into a spherical adventure. Instead of a flat grid, mines are hidden on the surface of a 3D globe composed of hexagonal tiles arranged in an icosphere pattern. Navigate the globe, reveal tiles, and avoid mines in this innovative twist on a classic game.

## ✨ Features

### Core Gameplay

- **Spherical Minesweeper**: Minesweeper gameplay on a 3D globe surface
- **Hexagonal Tiles**: Tiles arranged in geodesic patterns for optimal spherical coverage
- **Dynamic Difficulty**: Adjustable mine percentage and globe subdivision levels
- **Classic Mechanics**: Flag mines, reveal safe tiles, chord reveals, and flood-fill
- **Game Timer**: Real-time timer with pause/resume functionality
- **Statistics Tracking**: Comprehensive game statistics and best times

### Audio System

- **Procedural Audio Generation**: Dynamic sound effects using AudioStreamGenerator
- **Tile Reveal Sounds**: Satisfying "pop" sounds for tile interactions
- **Explosion Effects**: Dramatic sound effects for mine detonations
- **Win/Lose Melodies**: Musical feedback for game outcomes
- **No External Files**: All audio generated procedurally for lightweight distribution

### Visual & Interactive

- **3D Rendering**: Built with Godot's Forward+ renderer
- **Enhanced Tile Design**: Taller tiles (3x height) for better sphere obstruction
- **Material System**: Distinct visual states for unrevealed, revealed, flagged, and mine tiles
- **Mouse Controls**: Click to reveal, right-click to flag, drag to rotate globe
- **Touch Support**: Mobile-friendly touch controls with double-tap reveals
- **Fireworks Effects**: Celebratory particle effects when you win
- **Hexagonal Integrity**: Maintained hexagonal tile shape with rounded top edges

### User Interface

- **Real-time Mine Counter**: Shows remaining mines to flag
- **Game Status Display**: Win/lose messages with visual feedback
- **Timer Display**: MM:SS format with pause functionality
- **Reset Functionality**: Quick restart button to start a new game
- **Statistics Panel**: Track games played, win rate, and best times
- **Responsive Design**: Adapts to different window sizes

### Performance & Technical

- **Real-time Monitoring**: F12 shortcut for performance statistics
- **FPS Tracking**: Frame rate monitoring and optimization
- **Memory Usage**: Real-time memory consumption tracking
- **Generation Timing**: Globe creation performance measurement
- **Cross-platform**: Verified compatibility across platforms

## 🛠 Technical Details

### Engine & Requirements

- **Godot Engine**: Version 4.4.1 (tested and optimized)
- **Rendering**: Forward+ with mobile compatibility
- **Physics**: 3D physics for raycasting and collision detection
- **Audio**: Procedural sound generation using AudioStreamGenerator
- **Platform**: Windows (primary), macOS, Linux, Android, iOS, Web

### Geometry System

- **Icosphere Generation**: Starts with icosahedron and subdivides faces
- **Hexagonal Tiles**: Each face becomes 6 hexagonal tiles with enhanced height (3.0 units)
- **Neighbor Calculation**: Accurate adjacency detection for mine counting
- **Dynamic Sizing**: Tile radius calculated to prevent overlap
- **Interior Obstruction**: Tiles positioned inward to block sphere interior view

### Audio Architecture

- **Procedural Generation**: All sounds created algorithmically
- **AudioStreamGenerator**: Real-time audio synthesis
- **Multi-channel Support**: Separate streams for different sound types
- **Performance Optimized**: Lightweight audio processing

### Performance Monitoring

- **Real-time Metrics**: FPS, frame time, memory usage, draw calls
- **Generation Tracking**: Globe creation performance measurement
- **F12 Integration**: Keyboard shortcut for performance reports
- **Optimization Ready**: Framework for continuous performance improvement

### Performance Optimizations

- **Efficient Rendering**: Uses Godot's optimized 3D rendering pipeline
- **Memory Management**: Proper cleanup of nodes and resources
- **Input Optimization**: Smart drag detection to prevent accidental reveals

## 🚀 Getting Started

### Prerequisites

1. Download and install [Godot Engine](https://godotengine.org/) (version 4.4+)
2. Clone or download this repository

### Running the Game

1. Open Godot Engine
2. Click "Import" and select the project folder
3. Open the project
4. Click the "Play" button or press F5

### Controls

- **Left Click**: Reveal tile
- **Right Click**: Flag/unflag tile
- **Drag**: Rotate the globe
- **Double Click/Tap**: Chord reveal (on numbered tiles)
- **Reset Button**: Start a new game

## 📁 Project Structure

```bash
globesweeper3D/
├── project.godot          # Godot project configuration
├── README.md             # This documentation
├── icon.svg              # Project icon
├── scripts/
│   ├── main.gd           # Main game logic and globe generation
│   ├── ui.gd             # User interface management
│   ├── tile.gd           # Tile data structure
│   └── main_old.gd       # Previous version (backup)
└── scenes/
    ├── main.tscn         # Main 3D scene with camera and lighting
    ├── ui.tscn           # UI overlay scene
    └── main_old.tscn     # Previous scene version (backup)
```

## 🎯 Game Mechanics

### Objective

Reveal all safe tiles without triggering any mines. Flag all mines to win.

### Tile States

- **Unrevealed**: Dark gray hexagonal tiles
- **Revealed**: Light blue tiles showing numbers (1-8) indicating adjacent mines
- **Flagged**: Red tiles marked as potential mines
- **Mine**: Dark red tiles (revealed when game ends)

### Special Rules

- **Empty Tiles**: Tiles with 0 adjacent mines trigger flood-fill reveal
- **Chord Reveal**: Double-click numbered tiles to reveal all unflagged neighbors
- **Win Condition**: All safe tiles revealed
- **Lose Condition**: Mine tile revealed

### Globe Configuration

- **Radius**: 20 units (configurable)
- **Subdivision Level**: 3 (configurable, affects tile count)
- **Mine Percentage**: 15% (configurable)
- **Tile Scale**: 1.8 (configurable)

## 🔧 Configuration Options

### Export Variables (in main.gd)

```gdscript
@export var globe_radius: float = 20.0      # Globe size
@export var subdivision_level: int = 3      # Detail level (2-5 recommended)
@export var mine_percentage: float = 0.15   # Mine density (0.1-0.3 recommended)
@export var tile_scale: float = 1.8         # Visual tile size multiplier
```

### Performance Tuning

- Lower subdivision levels for better performance
- Adjust mine percentage for difficulty
- Modify globe radius for different viewing distances

## 🎨 Visual Design

### Materials

- **Unrevealed**: Metallic gray with subtle roughness
- **Revealed**: Light blue with smooth finish
- **Flagged**: Bright red for visibility
- **Mine**: Dark red with metallic sheen

### Lighting

- **Directional Light**: Main illumination source
- **Camera Positioning**: Automatic placement at 3x globe radius
- **Environment**: Default Godot environment settings

## 📱 Mobile Support

The game includes touch controls optimized for mobile devices:

- **Single Tap**: Reveal tile
- **Double Tap**: Chord reveal
- **Touch Drag**: Rotate globe
- **Responsive UI**: Adapts to different screen sizes

## 🏗 Architecture

### Main Components

#### Main.gd (569 lines)

- **Globe Generation**: Icosphere creation and subdivision
- **Game Logic**: Mine placement, neighbor calculation, win/lose detection
- **Input Handling**: Mouse and touch event processing
- **Visual Effects**: Fireworks and material management

#### UI.gd

- **HUD Management**: Mine counter and game status display
- **Button Handling**: Reset functionality
- **State Updates**: Real-time UI updates during gameplay

#### Tile.gd

- **Data Structure**: Tile state and properties
- **Reference Management**: Links to visual nodes and neighbors

### Key Algorithms

#### Icosphere Generation

1. Start with icosahedron vertices and faces
2. Subdivide each triangular face into 4 smaller triangles
3. Project vertices onto unit sphere
4. Convert triangular faces to hexagonal tiles

#### Neighbor Detection

1. Build adjacency graph from icosphere face edges
2. Calculate exact neighbor relationships
3. Use graph traversal for flood-fill reveals

#### Mine Placement

1. Random distribution based on percentage
2. Ensure fair distribution across globe surface
3. Calculate neighbor mine counts for all tiles

## 🔄 Development History

### Version Evolution

- **Initial Version**: Basic 3D Minesweeper on flat surface
- **Spherical Upgrade**: Transition to icosphere geometry
- **Optimization**: Performance improvements and mobile support
- **Polish**: Visual effects, better UI, touch controls

### Backup Files

- `main_old.gd` and `main_old.tscn`: Previous implementation versions
- Preserved for reference and potential rollback

## 🤝 Contributing

### Code Style

- Follow Godot GDScript best practices
- Use descriptive variable and function names
- Include comments for complex algorithms
- Maintain consistent indentation and formatting

### Testing

- Test on multiple platforms (desktop, mobile, web)
- Verify performance with different subdivision levels
- Ensure touch controls work properly
- Test edge cases (small globes, high mine density)

## 📄 License

This project is licensed under the terms specified in the LICENSE file.

## 🙏 Acknowledgments

- Inspired by the classic Minesweeper game
- Built with the Godot Engine
- Uses icosphere geometry for spherical tile arrangement
- Implements traditional Minesweeper rules with 3D twist

---

## Enjoy sweeping the globe! 🌍💣
