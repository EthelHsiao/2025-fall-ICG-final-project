# Nail Manicure OpenGL Project

一個使用 OpenGL 實現的互動式美甲展示專案，具有動態生長的裝飾物和逼真的光影效果。

## 系統需求

- CMake 3.16 或更高版本
- C++17 編譯器
- OpenGL 3.3 或更高版本支援

## 依賴函式庫

本專案需要以下外部函式庫：

- **GLFW 3.x** - 視窗管理和輸入處理
- **GLEW** - OpenGL 擴展加載器
- **Assimp** - 3D 模型載入
- **GLM** - OpenGL 數學運算
- **OpenGL** - 圖形 API

### Linux (Ubuntu/Debian) 安裝

```bash
sudo apt update
sudo apt install libglfw3-dev libglew-dev libassimp-dev libglm-dev cmake g++ build-essential
```

### Linux (Fedora/RHEL) 安裝

```bash
sudo dnf install glfw-devel glew-devel assimp-devel glm-devel cmake gcc-c++
```

### macOS 安裝

```bash
brew install cmake glfw glew assimp glm
```

### Windows 安裝

Windows 用戶有兩種選擇：

#### 選項 1: 使用 vcpkg（推薦）

```bash
# 安裝 vcpkg
git clone https://github.com/Microsoft/vcpkg.git
cd vcpkg
.\bootstrap-vcpkg.bat

# 安裝依賴
.\vcpkg install glfw3:x64-windows glew:x64-windows assimp:x64-windows glm:x64-windows

# 使用 CMake 時指定 vcpkg toolchain
cmake -B build -S . -DCMAKE_TOOLCHAIN_FILE=[vcpkg root]/scripts/buildsystems/vcpkg.cmake
cmake --build build --config Release
```

#### 選項 2: 手動安裝

1. 下載預編譯的函式庫：
   - GLFW: https://www.glfw.org/download.html
   - GLEW: http://glew.sourceforge.net/
   - Assimp: https://github.com/assimp/assimp/releases
   - GLM: https://github.com/g-truc/glm/releases

2. 將函式庫放置在適當位置並設定 CMake 變數

## 編譯與執行

### Linux/macOS

```bash
# 克隆專案
git clone [your-repo-url]
cd FP

# 創建 build 目錄
mkdir build
cd build

# 編譯
cmake ..
make

# 執行
./NailManicureGL
```

### Windows (使用 Visual Studio)

```bash
# 創建 build 目錄
mkdir build
cd build

# 生成 Visual Studio 專案
cmake .. -G "Visual Studio 16 2019" -A x64

# 使用 Visual Studio 打開 NailManicureGL.sln 並編譯
# 或使用命令行編譯
cmake --build . --config Release

# 執行
cd Release
.\NailManicureGL.exe
```

## 專案結構

```
FP/
├── CMakeLists.txt       # CMake 建置設定
├── README.md            # 本文件
├── hand.obj             # 手部 3D 模型（需要）
├── hand.mtl             # 材質文件
├── include/             # 標頭檔
│   ├── Camera.h
│   ├── Mesh.h
│   ├── Model.h
│   ├── Shader.h
│   └── stb_image.h
├── src/                 # 源代碼
│   ├── Camera.cpp
│   ├── main.cpp
│   ├── Mesh.cpp
│   ├── Model.cpp
│   └── Shader.cpp
├── shaders/             # 著色器程式
│   ├── manicure.vs      # 頂點著色器
│   ├── manicure.fs      # 片段著色器
│   └── manicure.geom    # 幾何著色器
├── textures/            # 貼圖資源（可選）
└── build/               # 建置目錄（生成）
```

## 模型文件

專案需要 `hand.obj` 模型文件。請確保：
- 將 `hand.obj` 和 `hand.mtl` 放在專案根目錄
- 如有貼圖文件，放在 `textures/` 目錄下

## 功能特色

- **軌道相機系統**：圍繞模型旋轉觀察
- **動態裝飾生成**：使用幾何著色器生成立體裝飾物
- **手指識別**：根據 UV 座標識別不同手指
- **特殊效果**：
  - 大拇指：藤蔓狀裝飾，隨時間波動
  - 其他手指：錐形裝飾，呼吸式生長
- **多光源照明**：主光源、補光、輪廓光
- **彩虹色特效**：裝飾物的動態虹彩效果

## 操作方式

### 鍵盤控制
- **A/D**：左右旋轉視角
- **Space/Shift**：上下旋轉視角
- **W/S**：拉近/拉遠（縮放）
- **ESC**：退出程式

### 滑鼠控制
- **左鍵拖曳**：自由旋轉視角
- **滾輪**：縮放視角

## 技術細節

- **OpenGL 版本**：3.3 Core Profile
- **GLSL 版本**：4.10
- **渲染技術**：
  - 基於物理的光照（PBR-inspired）
  - 幾何著色器動態生成裝飾
  - 多 pass 渲染

## 故障排除

### 錯誤：找不到 GLFW/GLEW/Assimp

確保已正確安裝所有依賴函式庫。在 Linux 上，可以使用 `pkg-config` 檢查：

```bash
pkg-config --modversion glfw3
pkg-config --modversion glew
pkg-config --modversion assimp
```

### Windows：找不到 DLL

如果執行時提示缺少 DLL，請確保：
1. DLL 文件在可執行文件同目錄下
2. 或將 DLL 路徑加入 PATH 環境變數

### 模型不顯示

1. 檢查 `hand.obj` 是否在正確位置
2. 查看終端輸出的錯誤訊息
3. 嘗試調整相機距離（W/S 鍵）

### 程式卡頓

- 確認顯卡驅動已更新
- 檢查是否啟用了 VSync

## 開發環境

本專案在以下環境測試通過：
- Ubuntu 22.04 LTS
- GCC 11.4
- CMake 3.22.1
- OpenGL 4.1

## 授權

[添加你的授權信息]

## 作者

[添加你的信息]

## 致謝

- 模型資源：[如有使用他人模型請註明]
- 參考資料：LearnOpenGL (learnopengl.com)
