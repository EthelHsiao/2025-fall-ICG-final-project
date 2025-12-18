# Dependencies for Nail Manicure OpenGL Project

## Required Libraries and Versions

### Core Dependencies
- CMake >= 3.16
- C++ Compiler with C++17 support
  - GCC >= 7.0
  - Clang >= 5.0
  - MSVC >= 19.14 (Visual Studio 2017)

### Graphics Libraries
- OpenGL >= 3.3
- GLFW3 >= 3.3
- GLEW >= 2.1.0
- Assimp >= 5.0.0
- GLM >= 0.9.9

### Installation Commands

#### Ubuntu/Debian
```bash
sudo apt-get update
sudo apt-get install -y \
    cmake \
    build-essential \
    libglfw3-dev \
    libglew-dev \
    libassimp-dev \
    libglm-dev
```

#### Fedora/RHEL
```bash
sudo dnf install -y \
    cmake \
    gcc-c++ \
    glfw-devel \
    glew-devel \
    assimp-devel \
    glm-devel
```

#### Arch Linux
```bash
sudo pacman -S \
    cmake \
    base-devel \
    glfw-x11 \
    glew \
    assimp \
    glm
```

#### macOS (using Homebrew)
```bash
brew install cmake glfw glew assimp glm
```

#### Windows (using vcpkg)
```bash
vcpkg install glfw3:x64-windows glew:x64-windows assimp:x64-windows glm:x64-windows
```

## Tested Versions

This project has been tested with:
- GLFW 3.3.8
- GLEW 2.2.0
- Assimp 5.2.5
- GLM 0.9.9.8
- CMake 3.22.1

## Optional Dependencies

None - all required dependencies are listed above.

## Notes for Windows Users

### Using vcpkg (Recommended)
vcpkg provides the easiest way to manage dependencies on Windows.

1. Install vcpkg:
```bash
git clone https://github.com/Microsoft/vcpkg.git
cd vcpkg
.\bootstrap-vcpkg.bat
```

2. Install packages:
```bash
.\vcpkg install glfw3:x64-windows glew:x64-windows assimp:x64-windows glm:x64-windows
```

3. Use with CMake:
```bash
cmake -B build -DCMAKE_TOOLCHAIN_FILE=[vcpkg_root]/scripts/buildsystems/vcpkg.cmake
cmake --build build --config Release
```

### Manual Installation
If you prefer manual installation:
1. Download pre-built binaries from official websites
2. Extract to a common location (e.g., C:\Libraries)
3. Set CMake variables:
   - CMAKE_PREFIX_PATH
   - Or individual *_DIR variables for each library

## Runtime Requirements

- OpenGL 3.3+ compatible graphics driver
- Recommended: GPU with at least 512MB VRAM
- Display resolution: 1024x768 or higher

## Troubleshooting

### Linux: Cannot find package
```bash
# Update package lists
sudo apt-get update
# Or for Fedora
sudo dnf check-update
```

### macOS: Homebrew not found
Install Homebrew first:
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### Windows: vcpkg integration failed
Ensure you've run:
```bash
.\vcpkg integrate install
```

### General: OpenGL version not supported
- Update your graphics drivers
- Check GPU compatibility with `glxinfo` (Linux) or GPU-Z (Windows)
