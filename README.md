# 💅 Hand Decoration - OpenGL Nail Art System

An interactive 3D nail decoration application built with OpenGL and GLSL Geometry Shaders. Features real-time growth animations, camera controls, and various decorative effects.

![Wood Background](https://img.shields.io/badge/Background-Wood_Texture-8B4513)
![OpenGL](https://img.shields.io/badge/OpenGL-3.3-blue)
![C++](https://img.shields.io/badge/C++-11-00599C)

---

## ✨ Features

### 🎨 Five Unique Finger Designs
- **Thumb** - Pink-purple base + Purple crystal diamonds
- **Index Finger** - White base + Exploding white pyramids
- **Middle Finger** - Deep purple base + Rotating silver stars
- **Ring Finger** - Pink-white base + Gradient highlight effect
- **Pinky** - Deep purple base + Silver-white grid pattern

### 🎬 Animation Effects
- ⏱️ **Growth Animation** - Decorations gradually grow from nothing
- 🔄 **Rotation Animation** - Stars continuously rotate, slow down when finished
- 💥 **Explosion Animation** - Pyramids pop out and rotate
- 🎉 **Celebration Mode** - Automatic rotation showcase after completing all five fingers

### 🎥 Interactive Camera System
- 🖱️ Mouse drag to rotate view
- 🔍 Scroll wheel to zoom
- ⌨️ Arrow keys to move viewpoint
- 🎯 Auto-focus on selected finger
- 🔄 Smooth interpolation transitions

### 🌳 Visual Effects
- Realistic procedural wood grain background
- Blinn-Phong lighting model
- Fresnel rim lighting
- Anti-aliasing processing

---

## 🎮 Controls

### Keyboard

| Key | Function |
|-----|----------|
| `A` | Select Thumb |
| `B` | Select Index Finger |
| `C` | Select Middle Finger |
| `D` | Select Ring Finger |
| `E` | Select Pinky |
| `S` | Start decoration animation |
| `Space` | Reset view to center |
| `↑↓←→` | Move camera target |
| `ESC` | Exit program |

### Mouse

| Action | Function |
|--------|----------|
| Left Click + Drag | Rotate camera |
| Scroll Wheel | Zoom in/out |

---

## 🏗️ Project Structure

```
project/
├── src/
│   ├── main.cpp                    # Main program
│   ├── shaders/
│   │   ├── vertexShader.vert      # Vertex shader
│   │   ├── geometryShader.geom    # Geometry shader (generates 3D decorations)
│   │   ├── fragmentShader.frag    # Fragment shader (painting effects)
│   │   ├── backgroundShader.vert  # Background vertex shader
│   │   └── backgroundShader.frag  # Background fragment shader (wood grain)
│   ├── asset/
│   │   ├── obj/
│   │   │   └── female_hand.obj    # Hand 3D model
│   │   └── texture/
│   │       └── female_hand.png    # Hand texture
│   └── header/
│       ├── Object.h                # OBJ loader
│       └── stb_image.h            # Image loading library
└── README.md
```

---

## 🔧 Technical Details

### Technologies Used
- **OpenGL 3.3 Core Profile**
- **GLSL 330**
- **Geometry Shader** - Dynamically generates 3D decorative geometry
- **GLM** - Mathematics library
- **GLFW** - Window management
- **GLAD** - OpenGL function loader
- **stb_image** - Image loading

### Shader Pipeline

#### Vertex Shader
- Receives model vertices, normals, UV coordinates
- Passes raw coordinates to Geometry Shader

#### Geometry Shader
- **Input**: Triangles
- **Output**: Up to 256 vertices (triangle strip)
- **Functions**:
  - Outputs original hand model
  - Generates 3D decorations based on finger index and progress
  - Supports various geometric shapes (diamonds, pyramids, stars, bows)
  - Implements explosion and rotation animations

#### Fragment Shader
- **3D Decoration Lighting**: Blinn-Phong + Fresnel rim lighting
- **Nail Painting**:
  - Base color blending (smoothstep smooth transition)
  - Ring finger gradient highlight
  - Pinky grid pattern effect
  
#### Background Shader
- **Procedural Wood Grain**:
  - Multi-layer Perlin noise
  - Tree ring effect (sine wave)
  - Detail texture
  - Anti-aliasing (`dFdx`, `dFdy`, `fwidth`)

### Camera System
- **Spherical coordinate system**
- **Smooth interpolation** (`glm::mix`)
- **Auto-focus** - Automatically moves to optimal viewing position when switching fingers

### Animation System
- **Progress control** - `patternProgress` (0.0 → 1.0)
- **State persistence** - `fingerPainted[]` array records completion status
- **Time-driven** - Uses `glfwGetTime()` to drive rotation animations

---

## 📦 Build & Run

### Dependencies
```bash
# Ubuntu/Debian
sudo apt-get install libglfw3-dev libglm-dev

# macOS (using Homebrew)
brew install glfw glm

# Windows
# Manually download and configure GLFW and GLM
```

### Compilation
```bash
# Using CMake (Recommended)
mkdir build
cd build
cmake ..
make

# Or using g++ (Example)
g++ -std=c++11 src/main.cpp -o hand_decoration \
    -lglfw -lGL -ldl -lpthread
```

### Execution
```bash
./hand_decoration
```

---

## 🎨 Design Philosophy

### Color Theme
Adopts **purple** as the main theme, accented with silver-white:
- Pink-purple and deep purple base colors create elegance
- White and silver decorations add sophistication
- Pink-white and pink as transition colors

### Decoration Distribution
- **Static Decorations** (Thumb diamonds) - Show stability
- **Dynamic Decorations** (Index pyramids, Middle stars) - Show vitality
- **Flat Effects** (Ring highlight, Pinky grid) - Show delicacy

### Visual Hierarchy
1. **3D Decorations** - Most prominent, attracts focus
2. **Base Nail Polish** - Middle layer, provides background
3. **Wood Grain Background** - Bottom layer, enhances subject

---

## 🐛 Known Issues

- Wood grain may show slight moiré patterns at certain resolutions
- Occasional gimbal lock when rotating camera

---

## 📝 License

This project is for academic purposes only.

---


## 🙏 Acknowledgments

- **3D Model**: female_hand.obj
- **Libraries**: GLFW, GLM, GLAD, stb_image
- **Inspiration**: Modern nail art designs

---

**Enjoy decorating! 💅✨**
