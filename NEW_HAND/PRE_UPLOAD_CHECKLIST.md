# Pre-Upload Checklist

在將專案推送到 GitHub 前，請確認以下事項：

## 必須包含的文件

✅ 核心代碼
- [ ] `src/` 目錄（所有 .cpp 文件）
- [ ] `include/` 目錄（所有 .h 文件）
- [ ] `shaders/` 目錄（所有 shader 文件）
- [ ] `CMakeLists.txt`

✅ 文檔
- [ ] `README.md`
- [ ] `DEPENDENCIES.md`
- [ ] `QUICKSTART.md`
- [ ] `.gitignore`

✅ 資源文件
- [ ] `hand.obj` - 手部模型（必須）
- [ ] `hand.mtl` - 材質文件（如果有）
- [ ] `textures/` 目錄（如果有貼圖）

## 不應包含的文件

❌ 構建產物
- `build/` 目錄
- `*.o`, `*.obj` 文件
- 可執行文件

❌ IDE 配置
- `.vscode/`
- `.idea/`
- `.vs/`

❌ 臨時文件
- `*.swp`, `*.swo`
- `*~`
- `.DS_Store`

## 文件大小檢查

⚠️ 注意事項：
- `hand.obj` 如果太大（>100MB），考慮：
  1. 使用 Git LFS（Large File Storage）
  2. 在 README 中提供下載連結
  3. 簡化模型

## 測試清單

在不同環境測試：
- [ ] Linux 編譯成功
- [ ] macOS 編譯成功（如果可能）
- [ ] Windows 編譯成功（如果可能）

## Git 準備

```bash
# 1. 初始化 Git（如果還沒有）
git init

# 2. 添加所有文件
git add .

# 3. 檢查將要提交的文件
git status

# 4. 確認不包含 build/ 等不必要的文件
# 如果有，添加到 .gitignore

# 5. 提交
git commit -m "Initial commit: Nail Manicure OpenGL Project"

# 6. 創建 GitHub 倉庫後，添加遠程倉庫
git remote add origin https://github.com/[your-username]/[repo-name].git

# 7. 推送
git branch -M main
git push -u origin main
```

## 如果模型文件太大

### 選項 1: 使用 Git LFS

```bash
# 安裝 Git LFS
git lfs install

# 追蹤大文件
git lfs track "*.obj"
git lfs track "*.mtl"
git add .gitattributes

# 正常提交和推送
git add .
git commit -m "Add models with Git LFS"
git push
```

### 選項 2: 外部託管

1. 將模型上傳到 Google Drive / Dropbox / 其他雲端
2. 在 README 中提供下載連結
3. 在 .gitignore 中添加：
```
hand.obj
hand.mtl
textures/
```

## README 中需要更新的內容

- [ ] 替換 `[your-repo-url]` 為實際的 GitHub 倉庫 URL
- [ ] 添加你的名字和聯繫方式
- [ ] 添加授權信息
- [ ] 如果使用了別人的模型，添加致謝

## Windows 支援說明

✅ 已支援 Windows：
- CMakeLists.txt 已針對 Windows 優化
- 支援 vcpkg 套件管理器
- 文檔中包含 Windows 安裝說明

⚠️ Windows 用戶注意事項：
1. 必須使用 vcpkg 或手動安裝依賴
2. 推薦使用 Visual Studio 2017 或更新版本
3. 路徑使用相對路徑，應該可以正常工作

## 最終檢查命令

```bash
# 清理舊的構建
rm -rf build/

# 重新構建測試
mkdir build && cd build
cmake ..
make

# 執行測試
./NailManicureGL

# 如果一切正常，準備推送！
```
