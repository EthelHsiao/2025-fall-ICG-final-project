# Quick Start Guide

## For Linux Users

```bash
# 1. Install dependencies
sudo apt-get update
sudo apt-get install libglfw3-dev libglew-dev libassimp-dev libglm-dev cmake g++

# 2. Clone and build
git clone [your-repo-url] NailManicureGL
cd NailManicureGL
mkdir build && cd build
cmake ..
make -j4

# 3. Run
./NailManicureGL
```

## For macOS Users

```bash
# 1. Install Homebrew (if not installed)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 2. Install dependencies
brew install cmake glfw glew assimp glm

# 3. Clone and build
git clone [your-repo-url] NailManicureGL
cd NailManicureGL
mkdir build && cd build
cmake ..
make -j4

# 4. Run
./NailManicureGL
```

## For Windows Users (vcpkg)

```bash
# 1. Install vcpkg
git clone https://github.com/Microsoft/vcpkg.git
cd vcpkg
.\bootstrap-vcpkg.bat
.\vcpkg integrate install

# 2. Install dependencies
.\vcpkg install glfw3:x64-windows glew:x64-windows assimp:x64-windows glm:x64-windows

# 3. Clone and build project
cd ..
git clone [your-repo-url] NailManicureGL
cd NailManicureGL
mkdir build && cd build

# 4. Configure with vcpkg toolchain
cmake .. -DCMAKE_TOOLCHAIN_FILE=[vcpkg_path]/scripts/buildsystems/vcpkg.cmake

# 5. Build
cmake --build . --config Release

# 6. Run
cd Release
.\NailManicureGL.exe
```

## Controls

- **A/D**: Rotate left/right
- **Space/Shift**: Rotate up/down
- **W/S**: Zoom in/out
- **Left Mouse + Drag**: Free rotation
- **Mouse Wheel**: Zoom
- **ESC**: Exit

## Common Issues

### "hand.obj not found"
Make sure `hand.obj` is in the project root directory.

### Black screen
- Try zooming out (press S key)
- Check if model file is loaded correctly
- Update graphics drivers

### Slow performance
- VSync is enabled by default
- Reduce window size if needed
- Update graphics drivers

### Build errors on Windows
- Make sure to use x64-windows architecture in vcpkg
- Use Visual Studio 2017 or newer
- Set CMAKE_TOOLCHAIN_FILE correctly

## Need Help?

Check the full README.md and DEPENDENCIES.md for detailed information.
