# FinderHover

**macOS 檔案的數據透視鏡**
一指即現，免按 `Cmd+I`

<p align="center">
  <a href="README.md">🇺🇸 English</a> | <a href="README_zh-Hant.md">🇹🇼 繁體中文</a> | <a href="README_ja.md">🇯🇵 日本語</a>
</p>

<p align="center">
  <img src="/FinderHover/Assets.xcassets/AppIcon.appiconset/Icon-256.png" alt="FinderHover Icon" width="128">
</p>

<p align="center">
  <img src="https://img.shields.io/badge/macOS-14.0+-000000.svg?style=flat&logo=apple&logoColor=white" alt="macOS 14.0+">
  <img src="https://img.shields.io/badge/Swift-5.0-F05138.svg?style=flat&logo=swift&logoColor=white" alt="Swift 5.0">
  <img src="https://img.shields.io/badge/SwiftUI-007AFF.svg?style=flat&logo=swift&logoColor=white" alt="SwiftUI">
  <img src="https://img.shields.io/badge/%E9%9A%B1%E7%A7%81%E5%84%AA%E5%85%88-00C853.svg?style=flat&logo=apple&logoColor=white" alt="隱私優先">
  <img src="https://img.shields.io/badge/License-MIT-yellow.svg?style=flat" alt="License MIT">
</p>

---

> **🎬 示範影片準備中：** 我們正在製作 GIF/影片來展示 FinderHover 的實際操作。
> *目前可以先查看[下方的螢幕截圖](#-螢幕截圖)來了解介面樣貌。*

<img width="1926" height="1324" alt="功能概覽" src="https://github.com/user-attachments/assets/7d27934e-5e11-4196-a6ac-5c7ebc6a1f17" />

---

## ⚡️ 為什麼需要 FinderHover?

**遇到的問題：**
想確認照片解析度？影片編碼？壓縮檔內容？你得這樣做：
1. 右鍵點擊 → 簡介（或按 `Cmd+I`）
2. 等待視窗開啟
3. 手動關閉視窗
4. 每個檔案都要重複一次

**解決方案：**
FinderHover 就像是 Finder 的 **X 光透視層**。只要把滑鼠停在任何檔案上，就能立刻看到你需要的數據。

### 對比：簡介視窗 vs FinderHover

|  | macOS 簡介視窗 (`Cmd+I`) | FinderHover |
|---|---|---|
| **觸發方式** | 右鍵 → 簡介（或 `Cmd+I`） | 滑鼠懸停 |
| **速度** | 慢，視窗會堆疊 | 即時，自動消失 |
| **資訊深度** | 基本資訊（大小、類型、日期） | **深度中繼資料**（EXIF、編碼、壓縮檔內容、Git 資訊） |
| **工作流程** | 打斷你的操作流程 | 不干擾的浮動顯示 |

---

## ✨ 功能特色

### 🔍 比 Finder 更懂你的檔案
FinderHover 揭露 Finder **永遠不會顯示**的中繼資料：

#### 📦 壓縮檔 X 光透視
**免解壓縮**，直接偷看 `zip`、`rar`、`7z`、`tar.gz`、`iso` 的內容。
- 📋 立即看見檔案清單與數量
- 🔐 偵測加密狀態（開啟前就知道是否需要密碼）
- 📊 檢查壓縮率與實際解壓縮後的大小

#### 💻 開發者專屬
由開發者打造，為開發者服務。
- **程式碼洞察：** 即時行數統計與語法偵測，支援 **38+ 種程式語言**
- **Git 感知：** 顯示目前分支、提交次數、遠端 URL、未提交的變更
- **二進制分析：** 檢視 Mach-O 標頭、架構（`arm64`/`x86_64`/Universal）、程式碼簽章狀態、SDK 版本
- **Xcode 專案：** 顯示 Target 數、建置配置、Swift 版本、部署目標

#### 📸 攝影與媒體
- **照片：** 相機型號、鏡頭資訊、焦距、ISO、光圈、快門速度、GPS 座標、IPTC/XMP 中繼資料（作者、版權、關鍵字、評分）
- **影片：** 編碼（H.264、HEVC 等）、解析度、位元率、幀率、HDR 格式（Dolby Vision、HDR10、HLG）、章節、字幕軌道
- **音訊：** 曲目名稱、演出者、專輯、類型、時長、位元率、取樣率、聲道數

---

### 🎨 聰明且可自訂

#### 🧠 智慧情境感知
- **即時預覽：** 可調整懸停延遲（0.1 秒 - 2.0 秒）
- **自動隱藏：** 重新命名檔案、拖曳項目或使用右鍵選單時自動消失
- **QuickLook 整合：** 原生縮圖顯示，支援 PDF、圖片、文件

#### 🌈 雙重介面風格
- **macOS 風格：** 豐富的視覺呈現，包含縮圖、圖示和完整中繼資料
- **Windows 風格：** 簡約的工具提示樣式，只顯示必要資訊

#### 🎛️ 完整控制
- 可調整視窗大小、透明度（70-100%）、字體縮放
- **版面編輯器：** 拖曳重新排序中繼資料欄位，並針對每個類別切換顯示/隱藏
- **多語系：** 原生支援**英文**、**繁體中文**、**日本語**

---

### 📊 豐富的中繼資料支援（120+ 種檔案格式）

| 類別 | 支援的中繼資料 |
|----------|-------------------|
| **📷 攝影** | 相機型號、鏡頭、ISO、光圈、快門速度、GPS、IPTC/XMP 資料、色彩描述檔、HDR 增益圖 |
| **🎬 影片** | 編碼、解析度、位元率、幀率、HDR 格式（Dolby Vision、HDR10、HLG）、章節、字幕軌道 |
| **🎵 音訊** | 曲目名稱、演出者、專輯、類型、時長、位元率、取樣率、聲道數 |
| **💻 程式碼** | 支援 38+ 種語言的行數統計、檔案編碼、語法偵測 |
| **📝 Markdown** | 標題、Frontmatter（YAML/TOML/JSON）、標題/圖片/連結/程式碼區塊數量 |
| **🌐 HTML/網頁** | 標題、描述、關鍵字、作者、語言、Open Graph 標籤 |
| **⚙️ 設定檔** | JSON/YAML/TOML 鍵值數量、巢狀深度、語法有效性 |
| **🎨 設計** | PSD 圖層/色彩模式/位元深度、SVG/AI 尺寸、字型字符數 |
| **📦 壓縮檔** | 格式類型、檔案數量、壓縮率、加密狀態 |
| **📚 電子書** | 書名、作者、出版商、ISBN、語言 |
| **🖼️ 向量圖形** | SVG viewBox、EPS 色彩模式、元素數量 |
| **📱 App 套件** | Bundle ID、版本、最低 macOS 需求、程式碼簽章、權限、架構 |
| **⚡ 可執行檔** | 架構（arm64/x86_64）、程式碼簽章、最低 OS 需求、SDK 版本 |
| **🗄️ SQLite** | 資料表/索引/觸發器/檢視數量、總列數、Schema 版本、編碼 |
| **📂 Git 儲存庫** | 目前分支、提交次數、遠端 URL、未提交的變更、標籤 |
| **💿 磁碟映像** | 格式（DMG、ISO）、壓縮率、加密狀態、分割區架構 |
| **🧊 3D 模型** | 頂點/面數量、網格/材質數量、動畫、邊界框 |
| **🛠️ Xcode** | 專案名稱、Target 數、建置配置、Swift 版本、部署目標 |
| **🏷️ 系統** | Finder 標籤、下載來源、隔離資訊、iCloud 狀態、符號連結目標 |

---

## 🛡️ 隱私優先

> **100% 本機處理。**
> FinderHover 使用 macOS **輔助使用 API** 來偵測滑鼠下的檔案。所有中繼資料擷取都在**你的電腦上**進行——沒有網路請求、沒有分析、沒有追蹤。

- ✅ **零網路存取：** 所有處理都在本機進行
- ✅ **開源透明：** 在 GitHub 上自行檢視程式碼
- ✅ **Apple 原生：** 使用 Swift、AVFoundation、PDFKit 等原生框架打造

**為什麼使用輔助使用 API？**
不同於依賴緩慢 AppleScript 輪詢的傳統工具，FinderHover 直接監聽系統的輔助使用事件流，帶來高效能與極低負載。

---

## 📦 安裝方式

### Homebrew（推薦）

```bash
brew install koukeneko/tap/finderhover
```

**為什麼推薦 Homebrew？** 它會自動處理 Gatekeeper 驗證，省去你在系統設定中手動允許 App 的步驟。

---

### 直接下載

1. 從 [Releases](../../releases) 下載 `FinderHover.app.zip`
2. 解壓縮並移動到「應用程式」資料夾
3. 右鍵點擊 → 打開（略過 Gatekeeper）
4. 系統提示時授予輔助使用權限

---

### 從原始碼建置

```bash
git clone https://github.com/KoukeNeko/FinderHover.git
cd FinderHover
xcodebuild -scheme FinderHover -configuration Release
```

**需求：** Xcode 15+ 與 macOS Sonoma 14.0+

---

## ⚙️ 設定與使用

### 首次啟動

1. 從 Launchpad 或「應用程式」開啟 FinderHover
2. App 會出現在你的**選單列**
3. 授予**輔助使用權限**（系統設定 → 隱私與安全性 → 輔助使用）
4. 將滑鼠懸停在 Finder 中的任何檔案上，即可看到中繼資料

### 偏好設定

點擊選單列圖示或按 `Cmd+,` 開啟設定面板。

**提示：** 啟用「登入時啟動」，讓 FinderHover 在開機時自動執行。

---

## 🚀 技術亮點

### ⚡️ 高效能架構
- **響應式 UI 更新：** 使用 **Combine** 框架搭配 `debounce` 運算子，確保流暢的 UI 更新，同時保持 CPU 使用率幾乎為零
- **原生框架：** 基於 Apple 的 `AVFoundation`、`PDFKit`、`QuickLookThumbnailing`、`SQLite3`、`CoreGraphics`——無外部依賴
- **智慧快取：** 縮圖與中繼資料快取減少重複處理

### 🛠️ 強大的中繼資料引擎
支援 **120+ 種檔案格式**，具備深度檢視能力：
- **壓縮檔：** 使用 `libarchive` 與原生 API，無需解壓縮即可讀取 zip/rar/7z/iso 結構
- **媒體：** 使用 `AVFoundation` 擷取影片編碼、HDR 中繼資料與音訊規格
- **程式碼：** 偵測 38+ 種程式語言，精確統計行數
- **Git：** 解析 `.git` 目錄，取得分支、提交與遠端資訊
- **二進制檔：** 分析 Mach-O 標頭，取得架構與程式碼簽章資訊

---

## 🛠️ 專案結構

```
FinderHover/
├── App/          # 應用程式生命週期（FinderHoverApp、HoverManager）
├── Core/         # MouseTracker、FinderInteraction、FileInfo
├── Extractors/   # 中繼資料擷取邏輯（ArchiveExtractor、DeveloperExtractor 等）
├── UI/
│   ├── Windows/  # 浮動懸停視窗、設定容器
│   └── Settings/ # 模組化設定頁面
└── Utilities/    # 本地化、日誌、格式化輔助工具
```

---

## 📸 螢幕截圖

<p float="left">
  <img src="https://github.com/user-attachments/assets/fe969256-a07d-4db6-8715-a3bb3226782b" width="45%" />
  <img src="https://github.com/user-attachments/assets/f492dc51-9fd8-49f2-b854-d9fc4ac026a6" width="45%" />
</p>
<p float="left">
  <img src="https://github.com/user-attachments/assets/dc04ba05-2bcb-4308-b0cc-bd5ed2259d07" width="45%" />
  <img src="https://github.com/user-attachments/assets/140accdd-6034-4b2d-b4d9-ccc55a28586c" width="45%" />
</p>

---

## 📝 最新更新

### v1.7.0 - 進階中繼資料更新
- **新增：** 3D 模型中繼資料（USDZ、OBJ、GLTF、FBX）
- **新增：** Xcode 專案檢視（Target 數、Swift 版本、部署目標）
- **新增：** 進階檔案系統中繼資料（已分配空間、Resource Fork、磁碟區資訊）
- **強化：** 壓縮檔格式支援（新增 ISO、TAR、CPIO）
- **強化：** 系統中繼資料（Finder 標籤、下載來源、iCloud 狀態）

[查看完整更新日誌](CHANGELOG.md)

---

## 🤝 貢獻

歡迎貢獻！以下是你可以幫忙的方式：

- **新增擷取器：** 查看 [Core/FileInfo.swift](FinderHover/Core/FileInfo.swift) 了解中繼資料擷取邏輯
- **UI 改進：** 探索 [UI/Windows/](FinderHover/UI/Windows/) 進行視覺增強
- **本地化：** 在 [Localizable.strings](FinderHover/Utilities/Localizable.strings) 新增翻譯

**功能請求與錯誤回報：** 在 [GitHub Issues](../../issues) 開啟 issue。

---

## 📄 授權條款

MIT License - 詳見 [LICENSE](LICENSE) 檔案。

---

<p align="center">
  <strong>用 ❤️ 與 Swift 打造</strong><br>
  為 Power User、開發者與檔案收藏家而生
</p>
