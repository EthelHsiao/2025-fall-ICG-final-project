# Group 8 Final Project - Slayyyyyyyyyyyy

An interactive 3D OpenGL application that allows users to decorate fingernails with animated patterns. The project features a realistic female hand model with dynamic nail art generation, smooth camera controls, and a wood-grain textured background.

DEMO Video：https://www.youtube.com/watch?v=CY3sKjor4DY
## Project Structure

```
.
├── src/
│   ├── main.cpp                    # Main application entry point
│   ├── CMakeLists.txt
│   ├── stb_image.cpp
│   ├── header/
│   │   ├── Object.h                # OBJ model loader
│   │   └── stb_image.h             # Image loading library
│   ├── shaders/
│   │   ├── vertexShader.vert       # Vertex shader
│   │   ├── fragmentShader.frag     # Fragment shader
│   │   ├── geometryShader.geom     # Geometry shader (pattern generation)
│   │   ├── backgroundShader.vert   # Background vertex shader
│   │   └── backgroundShader.frag   # Background fragment shader
│   └── asset/
│       ├── obj/
│       │   └── female_hand.obj     # 3D hand model
│       └── texture/
│           └── female_hand.png     # Hand texture
├── build/                          # Build output directory
├── extern/
├── CMakeLists.txt                  # CMake configuration
└── README.md                       # This file
```

## How to Build

### Using CMake (Recommended)

1. **Create a build directory and navigate to it:**
   ```bash
   mkdir build
   cd build
   ```

2. **Run CMake to configure the project:**
   ```bash
   cmake ..
   ```

3. **Build the project:**
   ```bash
   make
   ```

4. **Run the application:**
   ```bash
   cd src
   ./ICG_2025_HW2
   ```



## Controls

| Key/Action | Description |
|------------|-------------|
| **A** | Select Thumb |
| **B** | Select Index finger |
| **C** | Select Middle finger |
| **D** | Select Ring finger |
| **E** | Select Pinky finger |
| **S** | Start decoration animation (when finger selected) |
| **Left Mouse + Drag** | Rotate camera |
| **Mouse Wheel** | Zoom in/out |
| **Arrow Keys** | Move camera position |
| **Space** | Reset view to center |
| **ESC** | Exit application |

## Usage Instructions

1. **Launch the application** - A 3D hand model will appear on a wood-grain background
2. **Select a finger** - Press A, B, C, D, or E to select a finger
3. **Start decoration** - Press S to begin the nail art animation
4. **Rotate view** - Click and drag with the left mouse button to rotate
5. **Zoom** - Use the mouse wheel to zoom in/out
6. **Complete all nails** - Once all five fingers are decorated, the hand will start a celebration spin animation
