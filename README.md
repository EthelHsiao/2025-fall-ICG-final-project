# Manicure Shader Project

This is a framework for the "Animation and Geometry Shader Manicure" project.

## Prerequisites

You need to have the following libraries installed or available:
- **CMake** (Build system)
- **GLFW** (Windowing)
- **GLAD** or **GLEW** (OpenGL Loader)
- **GLM** (Mathematics)
- **Assimp** (Model Loading)

### Setting up GLAD
If you are using GLAD, go to [https://glad.dav1d.de/](https://glad.dav1d.de/), generate a loader for C/C++ and OpenGL 3.3 (Core), and download the zip.
- Copy `glad.c` to `src/`.
- Copy the `include/glad` and `include/KHR` folders to your system include path or a local `include` folder (you may need to update `CMakeLists.txt` to include it).

## Build Instructions

```bash
mkdir build
cd build
cmake ..
make
```

## Running

```bash
./ManicureShader
```

## Hand Model

You need to place a 3D hand model (e.g., `hand.obj`) in the `models/` directory.
Update `src/main.cpp` to load this specific file using Assimp.

### Where to find free Hand Models:
1.  **Free3D**: [https://free3d.com/3d-models/hand](https://free3d.com/3d-models/hand) (Filter by OBJ and Free)
2.  **TurboSquid**: [https://www.turbosquid.com/Search/3D-Models/free/hand](https://www.turbosquid.com/Search/3D-Models/free/hand)
3.  **Sketchfab**: [https://sketchfab.com/tags/hand](https://sketchfab.com/tags/hand) (Check for downloadable ones)

**Note:** Ensure the model has UV coordinates if you plan to use textures.
